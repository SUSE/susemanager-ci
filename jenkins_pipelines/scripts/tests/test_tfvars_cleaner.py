import unittest
from unittest.mock import patch, mock_open
import sys
import os


current_dir = os.path.dirname(os.path.abspath(__file__))

target_module_path = os.path.abspath(os.path.join(current_dir, '..', 'tf_vars_generator'))

# Add it to the system path so Python can find prepare_tfvars.py
if target_module_path not in sys.path:
    sys.path.insert(0, target_module_path)

import prepare_tfvars

class TestTfvarsGenerator(unittest.TestCase):

    def setUp(self):
        self.generator = prepare_tfvars.TfvarsGenerator()

    # --- HCL Formatting Tests ---

    def test_to_hcl_simple_types(self):
        """Test HCL conversion for simple data types."""
        self.assertEqual(self.generator.to_hcl("string_value"), '"string_value"')
        self.assertEqual(self.generator.to_hcl(123), '123')
        self.assertEqual(self.generator.to_hcl(True), 'true')
        self.assertEqual(self.generator.to_hcl(False), 'false')
        self.assertEqual(self.generator.to_hcl(None), 'null')

    def test_to_hcl_list(self):
        """Test HCL conversion for lists."""
        data = ["a", "b", 10]
        expected = '["a", "b", 10]'
        self.assertEqual(self.generator.to_hcl(data), expected)

    def test_to_hcl_dict_nested(self):
        """Test HCL conversion for nested dictionaries."""
        data = {
            "parent": {
                "child": "value"
            }
        }
        # Note: Exact whitespace matching depends on the indent logic
        expected_fragment = 'parent = {\n  child = "value"\n}'
        self.assertEqual(self.generator.to_hcl(data).strip(), expected_fragment)

    # --- Generation Logic Tests ---

    @patch('builtins.open', new_callable=mock_open, read_data='test_user = {\n  mac = {\n    controller = "aa:bb:cc"\n  }\n  pool = "default"\n}')
    def test_parse_env_reference_file(self, mock_file):
        """Test parsing of the legacy environment reference file."""
        macs, core = self.generator.parse_env_reference_file("dummy_path", "test_user")

        self.assertEqual(macs.get('controller'), "aa:bb:cc")
        self.assertEqual(core.get('pool'), "default")

    def test_generate_base_config(self):
        """Test the generation of the initial ENVIRONMENT_CONFIGURATION structure."""
        user = "testuser"
        macs = {'controller': '11:22:33', 'suse-client': '44:55:66'}
        core_info = {'pool': 'ssd'}
        params = {'minion1': 'sles15sp4_minion', 'base_os': 'slmicro60o'}

        self.generator.generate_base_config(user, macs, core_info, params)

        config = self.generator.data.get('ENVIRONMENT_CONFIGURATION', {})

        # Check Core
        self.assertEqual(config['controller']['mac'], '11:22:33')
        self.assertEqual(config['server_containerized']['image'], 'slmicro60o')

        # Check Dynamic Minion
        self.assertIn('sles15sp4_minion', config)
        self.assertEqual(config['sles15sp4_minion']['mac'], '44:55:66')

        # Check Global
        self.assertEqual(self.generator.data['LOCATION'], 'nue')

    # --- Merging & Injection Tests ---

    @patch('prepare_tfvars.hcl2.load')
    @patch('builtins.open', new_callable=mock_open)
    def test_merge_files(self, mock_file, mock_hcl_load):
        """Test merging external tfvars files."""
        # Setup initial data
        self.generator.data = {'ENVIRONMENT_CONFIGURATION': {'key1': 'val1'}}

        # Mock file content
        mock_hcl_load.return_value = {
            'ENVIRONMENT_CONFIGURATION': {'key2': 'val2'},
            'OTHER_CONFIG': 'val3'
        }

        self.generator.merge_files(['dummy.tfvars'])

        env_config = self.generator.data['ENVIRONMENT_CONFIGURATION']
        self.assertEqual(env_config['key1'], 'val1') # Preserved
        self.assertEqual(env_config['key2'], 'val2') # Added
        self.assertEqual(self.generator.data['OTHER_CONFIG'], 'val3') # Top-level added

    def test_inject_variables(self):
        """Test variable injection."""
        self.generator.data = {}
        extras = {'NEW_VAR': 'new_value', 'EXISTING': 'override'}

        self.generator.inject_variables(extras)
        self.assertEqual(self.generator.data['NEW_VAR'], 'new_value')

    # --- Cleaning Logic Tests ---

    def test_clean_resources(self):
        """Test removal of unselected resources."""
        self.generator.data = {
            'ENVIRONMENT_CONFIGURATION': {
                'controller': {},       # Should keep (infrastructure)
                'server': {},           # Should keep (infrastructure)
                'sles15_minion': {},    # Should remove (minion)
                'rocky_minion': {},     # Should keep (explicitly requested)
                'ubuntu_client': {}     # Should remove (client)
            }
        }

        keep_list = ['rocky_minion']
        # This call was failing because the method was missing or unattached
        self.generator.clean_resources(keep_list)

        env_config = self.generator.data['ENVIRONMENT_CONFIGURATION']

        self.assertIn('controller', env_config)
        self.assertIn('rocky_minion', env_config)
        self.assertNotIn('sles15_minion', env_config)
        self.assertNotIn('ubuntu_client', env_config)

if __name__ == '__main__':
    unittest.main()