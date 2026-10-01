import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(__file__))
target_module_path = os.path.abspath(os.path.join(current_dir, '..', 'tf_vars_generator'))
if target_module_path not in sys.path:
    sys.path.insert(0, target_module_path)

import prepare_tfvars


class TestCustomReposToTfvars(unittest.TestCase):

    def test_flat_keys_only_keep_legacy_behaviour(self):
        repos = {"server": {"a": "u1"}, "proxy": {"b": "u2"}, "sles15sp7_minion": {"c": "u3"}}
        self.assertEqual(
            prepare_tfvars.custom_repos_to_tfvars(repos),
            {"SERVER_ADDITIONAL_REPOS": {"a": "u1"}, "PROXY_ADDITIONAL_REPOS": {"b": "u2"}},
        )

    def test_split_keys_replace_the_flat_key(self):
        repos = {
            "server": {"flat": "x"},
            "server_transactional": {"s_micro": "u1"},
            "server_non_transactional": {"s_sles": "u2"},
            "proxy": {"flat": "y"},
            "proxy_transactional": {"p_micro": "u3"},
            "proxy_non_transactional": {"p_sles": "u4"},
        }
        self.assertEqual(
            prepare_tfvars.custom_repos_to_tfvars(repos),
            {
                "SERVER_ADDITIONAL_REPOS_TRANSACTIONAL": {"s_micro": "u1"},
                "SERVER_ADDITIONAL_REPOS_NON_TRANSACTIONAL": {"s_sles": "u2"},
                "PROXY_ADDITIONAL_REPOS_TRANSACTIONAL": {"p_micro": "u3"},
                "PROXY_ADDITIONAL_REPOS_NON_TRANSACTIONAL": {"p_sles": "u4"},
            },
        )

    def test_split_of_one_kind_does_not_affect_the_other(self):
        repos = {"server": {"a": "u1"}, "proxy": {"flat": "y"}, "proxy_transactional": {"p": "u3"}}
        self.assertEqual(
            prepare_tfvars.custom_repos_to_tfvars(repos),
            {"SERVER_ADDITIONAL_REPOS": {"a": "u1"}, "PROXY_ADDITIONAL_REPOS_TRANSACTIONAL": {"p": "u3"}},
        )

    def test_empty(self):
        self.assertEqual(prepare_tfvars.custom_repos_to_tfvars({}), {})


if __name__ == '__main__':
    unittest.main()
