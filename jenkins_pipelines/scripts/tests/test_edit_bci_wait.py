# Copyright (c) 2026 SUSE LLC
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'edit_bci_project'))
# edit.py imports requests/bs4 at module level; stub them when absent (unused here)
for _m in ('requests', 'bs4'):
    try:
        __import__(_m)
    except ImportError:
        sys.modules[_m] = mock.MagicMock()
import edit  # noqa: E402


def results(*pkgs):
    body = "".join(
        f'<status package="{p}" code="{c}">' + (f"<details>{d}</details>" if d else "") + "</status>"
        for p, c, d in pkgs)
    return f'<resultlist><result repository="containerfile" arch="x86_64">{body}</result></resultlist>'


class FakeClock:
    def __init__(self):
        self.t = 0

    def sleep(self, s):
        self.t += s

    def now(self):
        return self.t


class WaitForBuildCompletionTest(unittest.TestCase):

    def wait(self, run, **kw):
        c = FakeClock()
        return edit.wait_for_build_completion("url", "prj", sleep=c.sleep, now=c.now, run=run, **kw)

    def test_success(self):
        root = self.wait(lambda cmd, timeout=None: results(("a", "succeeded", ""), ("b", "disabled", "")))
        self.assertEqual(len(root.findall(".//status")), 2)

    def test_unresolvable_past_grace(self):
        xml = results(("server-image", "unresolvable", "nothing provides google-gson"))
        with self.assertLogs(level="ERROR") as cm, self.assertRaises(SystemExit) as e:
            self.wait(lambda cmd, timeout=None: xml, timeout=100000)
        self.assertEqual(e.exception.code, 1)
        self.assertIn("nothing provides google-gson", "\n".join(cm.output))

    def test_failed_and_broken(self):
        for code in ("failed", "broken"):
            with self.subTest(code=code), self.assertLogs(level="ERROR") as cm, self.assertRaises(SystemExit) as e:
                self.wait(lambda cmd, timeout=None: results(("a", code, "x")))
            self.assertEqual(e.exception.code, 1)
            self.assertIn(f"a (x86_64) {code}: x", "\n".join(cm.output))

    def test_deadline(self):
        with self.assertLogs(level="ERROR") as cm, self.assertRaises(SystemExit) as e:
            self.wait(lambda cmd, timeout=None: results(("a", "building", "")), timeout=100)
        self.assertEqual(e.exception.code, 2)
        self.assertIn("a (x86_64) building", "\n".join(cm.output))

    def test_no_success_after_deadline(self):
        # building first, all-final on the next poll: the poll comes after the deadline (5 s < 20 s sleep)
        answers = iter([results(("a", "building", "")), results(("a", "succeeded", ""))])
        with self.assertRaises(SystemExit) as e:
            self.wait(lambda cmd, timeout=None: next(answers), timeout=5)
        self.assertEqual(e.exception.code, 2)

    def test_consecutive_errors(self):
        def boom(cmd, timeout=None):
            raise RuntimeError("osc down")
        with self.assertRaises(SystemExit) as e:
            self.wait(boom)
        self.assertEqual(e.exception.code, 3)

    def test_osc_exit_counts_as_polling_error(self):
        # run_osc_command calls sys.exit(1) on osc failure: a polling error (exit 3), not exit 1
        def failing_run(cmd, timeout=None):
            raise SystemExit(1)
        with self.assertRaises(SystemExit) as e:
            self.wait(failing_run)
        self.assertEqual(e.exception.code, 3)

    def test_hung_osc_hits_deadline(self):
        def hung(cmd, timeout=None):
            raise subprocess.TimeoutExpired(cmd, timeout)
        with self.assertRaises(SystemExit) as e:
            self.wait(hung, timeout=100)
        self.assertEqual(e.exception.code, 2)

    def test_errors_past_deadline_exit_2_not_3(self):
        def boom(cmd, timeout=None):
            raise RuntimeError("osc down")
        with self.assertRaises(SystemExit) as e:
            self.wait(boom, timeout=30)  # 10 s retries: deadline (30 s) comes before the 10th error
        self.assertEqual(e.exception.code, 2)


if __name__ == "__main__":
    unittest.main()

