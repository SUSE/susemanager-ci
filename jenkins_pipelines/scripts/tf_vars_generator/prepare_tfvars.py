import argparse
import logging
import sys
import re
import hcl2

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class TfvarsGenerator:
    def __init__(self):
        self.data = {}

    # --- HCL FORMATTING ---
    def to_hcl(self, obj, indent_level=0):
        indent = "  " * indent_level
        if isinstance(obj, dict):
            lines = []
            for key, value in obj.items():
                formatted_value = self.to_hcl(value, indent_level + 1)
                if isinstance(value, dict):
                    lines.append(f"{indent}{key} = {{\n{formatted_value}\n{indent}}}")
                else:
                    lines.append(f"{indent}{key} = {formatted_value}")
            return "\n".join(lines)
        elif isinstance(obj, list):
            items = [self.to_hcl(item, 0) for item in obj]
            return f"[{', '.join(items)}]"
        elif isinstance(obj, str):
            safe_str = obj.replace('"', '\\"')
            return f'"{safe_str}"'
        elif isinstance(obj, bool):
            return str(obj).lower()
        elif obj is None:
            return "null"
        else:
            return str(obj)

    # --- DATA LOADING & MERGING ---
    def parse_env_reference_file(self, file_path, user):
        """
        Parses the legacy environment reference file using regex to extract
        MAC addresses and core info for a specific user.
        """
        logger.info(f"Parsing environment file {file_path} for user {user}")
        with open(file_path, 'r') as f:
            content = f.read()

        user_start_pattern = re.compile(fr'^\s*{user}\s*=\s*{{', re.MULTILINE)
        match = user_start_pattern.search(content)
        if not match:
            raise ValueError(f"User '{user}' not found in {file_path}")

        start_index = match.end()
        open_braces = 1
        block_content = ""
        for char in content[start_index:]:
            if char == '{': open_braces += 1
            elif char == '}': open_braces -= 1
            if open_braces == 0: break
            block_content += char

        macs = {}
        mac_block_match = re.search(r'mac\s*=\s*{(.*?)}', block_content, re.DOTALL)
        if mac_block_match:
            for m in re.finditer(r'([\w-]+)\s*=\s*"([^"]+)"', mac_block_match.group(1)):
                macs[m.group(1)] = m.group(2)

        core_info = {}
        for key in ['hypervisor', 'pool', 'bridge', 'additional_network']:
            m = re.search(fr'{key}\s*=\s*"([^"]+)"', block_content)
            if m: core_info[key] = m.group(1)

        return macs, core_info

    # Used for personal BV
    def generate_base_config(self, user, macs, core_info, params):
        """
        Generates the initial ENVIRONMENT_CONFIGURATION dictionary.
        """
        logger.info("Generating base configuration structure...")
        slot_mapping = {
            'minion1': 'suse-client',
            'minion2': 'suse-minion',
            'minion3': 'suse-sshminion',
            'minion4': 'rhlike-minion',
            'minion5': 'deblike-minion',
            'minion6': 'build-host',
            'minion7': 'kvm-host',
        }

        env_config = {
            'controller': {'mac': macs.get("controller", "MISSING"), 'name': "controller"},
            'server_containerized': {
                'mac': macs.get("server", "MISSING"),
                'name': "server",
                'image': params.get("base_os", "slmicro61o")
            },
            'proxy_containerized': {
                'mac': macs.get("proxy", "MISSING"),
                'name': "proxy",
                'image': params.get("base_os", "slmicro61o")
            },
            'product_version': params.get("product_version", "5.1-released"),
            'name_prefix': f"{user}-",
        }

        for param_key, mac_key in slot_mapping.items():
            minion_type = params.get(param_key)
            if minion_type and minion_type.strip() and minion_type != "null":
                mac_addr = macs.get(mac_key, "MISSING_MAC")
                env_config[minion_type] = {'mac': mac_addr, 'name': param_key}

        self.data['ENVIRONMENT_CONFIGURATION'] = env_config
        self.data['LOCATION'] = "nue"

        # BASE CONFIGURATIONS (Separate Block)
        self.data['BASE_CONFIGURATIONS'] = {
            'base_core': {
                'pool': core_info.get("pool", "MISSING"),
                'bridge': core_info.get("bridge", "MISSING"),
                'additional_network': core_info.get("additional_network", "MISSING"),
                'hypervisor': core_info.get("hypervisor", "MISSING"),
            }
        }

    def merge_files(self, file_paths):
        """Merges additional .tfvars files into the data."""
        for file_path in file_paths:
            if not file_path: continue
            logger.info(f"Merging external file: {file_path}")
            try:
                with open(file_path, 'r') as f:
                    content = hcl2.load(f)
                    for key, value in content.items():
                        if isinstance(value, list) and len(value) == 1 and isinstance(value[0], dict):
                            value = value[0]
                        if key == 'ENVIRONMENT_CONFIGURATION' and key in self.data:
                            self.data[key].update(value)
                        else:
                            self.data[key] = value
            except Exception as e:
                logger.error(f"Failed to merge {file_path}: {e}")
                sys.exit(1)

    def inject_variables(self, extra_vars):
        """Injects simple key=value pairs into top-level config."""
        if not extra_vars: return
        logger.info("Injecting variables...")
        for key, value in extra_vars.items():
            if value is not None:
                self.data[key] = value

    # --- CLEANING LOGIC ---
    def clean_resources(self, keep_list, delete_all_unused=False):
        if 'ENVIRONMENT_CONFIGURATION' not in self.data: return
        env_config = self.data['ENVIRONMENT_CONFIGURATION']
        # Base exclusions: Always remove these unless explicitly kept
        exclusions = ['minion', 'client']
        # Extended exclusions: Remove infrastructure if delete_all_unused is True
        if delete_all_unused:
            exclusions.extend(['terminal', 'buildhost', 'proxy', 'dhcp_dns', 'monitoring_server'])
        final_keep_keys = {k for k in env_config.keys() if all(ex not in k for ex in exclusions)}
        requested_keys = set(keep_list)
        available_keys = set(env_config.keys())
        final_keep_keys.update(requested_keys.intersection(available_keys))
        logger.info(f"Retaining resources: {final_keep_keys}")
        cleaned_config = {k: v for k, v in env_config.items() if k in final_keep_keys}
        self.data['ENVIRONMENT_CONFIGURATION'] = cleaned_config

    def save(self, output_path):
        logger.info(f"Saving to {output_path}")
        hcl_content = self.to_hcl(self.data)
        hcl_content = re.sub(r'}\n(\w)', r'}\n\n\1', hcl_content)
        with open(output_path, 'w') as f:
            f.write(hcl_content)
            f.write("\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # Scenario A Args
    parser.add_argument("--env-file", help="Reference env file (Scenario Personal BV)")
    parser.add_argument("--user", help="User identifier (Scenario Personal BV)")
    for i in range(1, 8): parser.add_argument(f"--minion{i}", default="")
    parser.add_argument("--deploy-retail", action='store_true')

    # Common Args
    parser.add_argument("--output", required=True)
    parser.add_argument("--product-version")
    parser.add_argument("--base-os")
    parser.add_argument("--merge-files", nargs='*', default=[], help="Files to merge (Scenario Classic BV)")
    parser.add_argument("--inject", action='append', help="KEY=VALUE")

    # Cleaning Args
    parser.add_argument("--clean", action='store_true', help="Enable resource cleaning")
    parser.add_argument("--keep-resources", nargs='*', default=[], help="List of resources to keep during cleaning")
    parser.add_argument("--delete-all", action='store_true', help="Aggressively clean optional infrastructure (proxy, buildhost, etc) if not in keep-resources")

    args = parser.parse_args()
    j_params = vars(args)
    gen = TfvarsGenerator()

    # RETAIL LOGIC & VALIDATION
    if args.env_file and args.user:
        # Retail Logic
        if args.deploy_retail:
            m1, m2 = j_params.get('minion1', ''), j_params.get('minion2', '')
            if (m1 and m1.strip()) or (m2 and m2.strip()):
                print("\n[ERROR] Retail Conflict: Cannot set minion1/minion2 manually when --deploy-retail is used.")
                sys.exit(1)
            print("[INFO] Deploy Retail enabled. Setting defaults.")
            j_params['minion1'] = 'sles15sp7_minion'
            j_params['minion2'] = 'sles15sp7_buildhost'

        # Duplicate check
        seen = set()
        for i in range(1, 8):
            val = j_params.get(f"minion{i}")
            if val and val.strip() and val != "null":
                if val in seen: print(f"Error: Duplicate {val}"); sys.exit(1)
                seen.add(val)

        macs, core = gen.parse_env_reference_file(args.env_file, args.user)
        gen.generate_base_config(args.user, macs, core, j_params)

    # MERGE FILES (e.g. location.tfvars)
    if args.merge_files:
        gen.merge_files(args.merge_files)

    # INJECT VARIABLES
    vars_to_inject = {}
    if args.inject:
        for item in args.inject:
            if '=' in item:
                k, v = item.split('=', 1)
                vars_to_inject[k] = v
    gen.inject_variables(vars_to_inject)

    # CLEANING
    if args.clean:
        keep_list = [r for r in args.keep_resources if r.strip()]
        gen.clean_resources(keep_list, delete_all_unused=args.delete_all)

    gen.save(args.output)