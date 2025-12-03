import re
import sys
import argparse

# ... [Keep parse_env_tfvars function exactly as it was] ...
def parse_env_tfvars(file_path, user):
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
        if char == '{':
            open_braces += 1
        elif char == '}':
            open_braces -= 1

        if open_braces == 0:
            break
        block_content += char

    macs = {}
    mac_block_match = re.search(r'mac\s*=\s*{(.*?)}', block_content, re.DOTALL)

    if mac_block_match:
        mac_inner_content = mac_block_match.group(1)
        for m in re.finditer(r'([\w-]+)\s*=\s*"([^"]+)"', mac_inner_content):
            key = m.group(1)
            value = m.group(2)
            macs[key] = value

    core_info = {}
    for key in ['hypervisor', 'pool', 'bridge', 'additional_network']:
        m = re.search(fr'{key}\s*=\s*"([^"]+)"', block_content)
        if m:
            core_info[key] = m.group(1)

    return macs, core_info

def generate_bv_tfvars(user, env_data, jenkins_params, output_file):
    macs, core = env_data

    slot_mapping = {
        'minion1': 'suse-client',     # Will host sles15sp7_minion if Retail=True
        'minion2': 'suse-minion',     # Will host sles15sp7_buildhost if Retail=True
        'minion3': 'suse-sshminion',
        'minion4': 'rhlike-minion',
        'minion5': 'deblike-minion',
        'minion6': 'build-host',
        'minion7': 'kvm-host',
    }

    with open(output_file, 'w') as f:
        f.write(f'ENVIRONMENT_CONFIGURATION = {{\n')

        # 1. CORE INFRASTRUCTURE
        f.write(f'  # Core Infrastructure for {user}\n')
        f.write(f'  controller = {{\n')
        f.write(f'    mac  = "{macs.get("controller", "MISSING")}"\n')
        f.write(f'    name = "controller"\n')
        f.write(f'  }}\n')

        f.write(f'  server_containerized = {{\n')
        f.write(f'    mac   = "{macs.get("server", "MISSING")}"\n')
        f.write(f'    name  = "server"\n')
        f.write(f'    image = "{jenkins_params.get("base_os")}"\n')
        f.write(f'  }}\n')

        f.write(f'  proxy_containerized = {{\n')
        f.write(f'    mac   = "{macs.get("proxy", "MISSING")}"\n')
        f.write(f'    name  = "proxy"\n')
        f.write(f'    image = "{jenkins_params.get("base_os")}"\n')
        f.write(f'  }}\n')

        # 2. DYNAMIC MINIONS
        f.write(f'\n  # Dynamic Minions from Jenkins Parameters\n')

        for param_key, mac_key in slot_mapping.items():
            minion_type = jenkins_params.get(param_key)

            if minion_type and minion_type.strip() and minion_type != "null":
                mac_addr = macs.get(mac_key, "MISSING_MAC")
                minion_name = param_key

                f.write(f'  {minion_type} = {{\n')
                f.write(f'    mac  = "{mac_addr}"\n')
                f.write(f'    name = "{minion_name}"\n')
                f.write(f'  }}\n')

        # 3. GLOBAL SETTINGS
        f.write(f'\n  # Global Settings\n')
        f.write(f'  product_version = "{jenkins_params.get("product_version", "5.1-released")}"\n')
        f.write(f'  name_prefix     = "{user}-"\n')
        f.write(f'  base_core = {{\n')
        f.write(f'    pool               = "{core.get("pool", "MISSING")}"\n')
        f.write(f'    bridge             = "{core.get("bridge", "MISSING")}"\n')
        f.write(f'    additional_network = "{core.get("additional_network", "MISSING")}"\n')
        f.write(f'    hypervisor         = "{core.get("hypervisor", "MISSING")}"\n')
        f.write(f'  }}\n')

        f.write(f'}}\n')
        f.write(f'LOCATION = "nue"\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--output", required=True)

    # Jenkins params
    parser.add_argument("--minion1", default="")
    parser.add_argument("--minion2", default="")
    parser.add_argument("--minion3", default="")
    parser.add_argument("--minion4", default="")
    parser.add_argument("--minion5", default="")
    parser.add_argument("--minion6", default="")
    parser.add_argument("--minion7", default="")
    parser.add_argument("--product-version", default="5.1-released")
    parser.add_argument("--base-os", default="slmicro61o")

    # New Retail Argument
    parser.add_argument("--deploy-retail", action='store_true', help="Deploy Retail configuration")

    args = parser.parse_args()
    j_params = vars(args)

    # --- RETAIL LOGIC: Override and Validate ---
    if args.deploy_retail:
        # 1. Validation: Ensure user didn't try to manually set slots 1 or 2
        m1 = j_params.get('minion1', '')
        m2 = j_params.get('minion2', '')

        if (m1 and m1.strip()) or (m2 and m2.strip()):
            print(f"\n[ERROR] Retail Configuration Conflict.")
            print(f"        'deploy_retail' is set to True, but 'minion1' or 'minion2' were also selected.")
            print(f"        Please clear the 'minion1' and 'minion2' dropdowns when deploying retail.")
            sys.exit(1)

        # 2. Override: Force the required types
        print("[INFO] Deploy Retail enabled. Forcing minion1=sles15sp7_minion and minion2=sles15sp7_buildhost")
        j_params['minion1'] = 'sles15sp7_minion'
        j_params['minion2'] = 'sles15sp7_buildhost'

    # --- SECURITY CHECK: Prevent Duplicate Minion Declarations ---
    seen_minions = set()
    minion_slots = ['minion1', 'minion2', 'minion3', 'minion4', 'minion5', 'minion6', 'minion7']

    for slot in minion_slots:
        val = j_params.get(slot)
        if val and val.strip() and val != "null":
            if val in seen_minions:
                print(f"\n[ERROR] Duplicate minion type detected: '{val}'")
                print(f"        You cannot declare the same minion type multiple times.")
                print(f"        Collision detected at {slot}.")
                sys.exit(1)
            seen_minions.add(val)

    try:
        data = parse_env_tfvars(args.env_file, args.user)
        generate_bv_tfvars(args.user, data, j_params, args.output)
        print(f"Successfully generated {args.output}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
