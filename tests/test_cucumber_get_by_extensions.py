import os
import stat
import unittest
from unittest.mock import MagicMock, call, patch


class FakeSFTPAttr:
    """Minimal stand-in for paramiko.SFTPAttributes."""
    def __init__(self, filename, is_dir=False):
        self.filename = filename
        self.st_mode = stat.S_IFDIR if is_dir else stat.S_IFREG


class TestGetByExtensions(unittest.TestCase):

    def _make_cucumber(self):
        """Return a Cucumber instance with a mocked SSH client."""
        import terracumber.cucumber as cu
        with patch('terracumber.cucumber.paramiko.SSHClient') as mock_ssh_cls:
            instance = cu.Cucumber.__new__(cu.Cucumber)
            instance.ssh_client = MagicMock()
        return instance

    # --- happy path ---

    def test_downloads_matching_extensions(self):
        """Files whose extension is in the list are downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [
            FakeSFTPAttr('output_core.html'),
            FakeSFTPAttr('output_core.json'),
            FakeSFTPAttr('notes.txt'),          # excluded
            FakeSFTPAttr('subdir', is_dir=True), # excluded
        ]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_any_call('/remote/results/output_core.html', '/local/out/output_core.html')
        mock_sftp.get.assert_any_call('/remote/results/output_core.json', '/local/out/output_core.json')
        self.assertEqual(mock_sftp.get.call_count, 2)
        self.assertEqual(sorted(result), sorted([
            '/remote/results/output_core.html',
            '/remote/results/output_core.json',
        ]))

    def test_excludes_txt_files(self):
        """txt files are never downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('core_html_path.txt')]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_not_called()
        self.assertEqual(result, [])

    def test_excludes_subdirectories(self):
        """Subdirectories are never downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('cucumber_report', is_dir=True)]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_not_called()
        self.assertEqual(result, [])

    def test_preserves_atime_mtime(self):
        """copy_atime_mtime is called for every downloaded file."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('output_sanity.html')]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime') as mock_cp:
            c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_cp.assert_called_once_with(
            '/remote/results/output_sanity.html',
            '/local/out/output_sanity.html',
        )

    def test_empty_directory_returns_empty_list(self):
        """An empty remote directory returns an empty list without raising."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = []
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        self.assertEqual(result, [])
        mock_sftp.get.assert_not_called()


if __name__ == '__main__':
    unittest.main()
