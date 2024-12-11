import paramiko
import re
import logging
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SSHClientManager:
    def __init__(self, url, username="root", password="linux", port=22):
        self.url = self.extract_ip_from_url(url)
        self.username = username
        self.password = password
        self.port = port
        self._client = None

    def _connect(self):
        """Establishes an SSH connection to the server."""
        if not self._client:
            self._client = paramiko.SSHClient()
            self._client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            try:
                logger.info(f"Connecting to server at: {self.url}:{self.port}")
                self._client.connect(self.url, port=self.port, username=self.username, password=self.password)
                logger.info("Connection successful.")
            except paramiko.AuthenticationException:
                logger.error("Authentication failed while connecting to the server.")
                raise
            except paramiko.SSHException as ssh_exception:
                logger.error(f"SSH connection error: {ssh_exception}")
                raise
            except Exception as e:
                logger.error(f"Unexpected exception during SSH connection: {e}")
                raise

    def _close(self):
        """Closes the SSH connection."""
        if self._client:
            self._client.close()
            self._client = None
            logger.info("SSH connection closed.")

    def _run_command(self, command):
        """
        Runs a command on the remote server.

        :param command: Command to execute on the server.
        :return: Command output or error message.
        """
        self._connect()
        try:
            logger.info(f"Executing command: {command}")
            stdin, stdout, stderr = self._client.exec_command(command)
            output = stdout.read().decode().strip()
            error = stderr.read().decode().strip()

            if error:
                logger.error(f"Command error: {error}")
                return error
            logger.info(f"Command output: {output}")
            return output
        except Exception as e:
            logger.error(f"Error while executing command: {e}")
            raise
        finally:
            stdin.close()

    def _copy_file(self, local_path, remote_path):
        """
        Copies a file to the remote server.

        :param local_path: Path of the local file to copy.
        :param remote_path: Destination path on the remote server.
        :return: Success message or error details.
        """
        try:
            self._connect()
            sftp = self._client.open_sftp()
            sftp.put(local_path, remote_path)
            sftp.close()
            logger.info(f"File {local_path} copied to {remote_path} on server {self.url}")
        except Exception as e:
            logger.error(f"Exception during file copy: {str(e)}")
            raise
        finally:
            self._close()

    def delete_known_hosts(self, version):
        """
        Deletes the known_hosts file based on the product version.

        :param version: Product version to determine file path.
        """
        try:
            self._connect()
            if version == "4.3":
                self._run_command("rm /var/lib/salt/.ssh/known_hosts")
            elif version in ["5.0", "head", "5.1", "uyuni"]:
                logger.info("Checking files before cleanup...")
                self._run_command("rm /var/lib/containers/storage/volumes/var-salt/_data/.ssh/known_hosts")
                logger.info("Known_hosts file cleaned up.")
            else:
                logger.warning(f"Unsupported version for known_hosts deletion: {version}")
        finally:
            self._close()

    def delete_distributions(self, version):
        """
        Deletes distributions directories based on the product version.

        :param version: Product version to determine file paths.
        """
        try:
            self._connect()
            if version == "4.3":
                logger.warning("Distribution deletion for version 4.3 is not implemented.")
            elif version in ["5.0", "head", "5.1"]:
                self._run_command("rm -rf /var/lib/containers/storage/volumes/srv-www/_data/distributions/*")
                self._run_command("rm -rf /var/lib/containers/storage/volumes/srv-www/_data/htdocs/pub/*iso")
                logger.info("Distributions directories deleted.")
            else:
                logger.error(f"Unsupported product version: {version}")
        finally:
            self._close()

    def update_custom_repositories(self):
        """
        Updates custom repositories by copying a configuration file to the server.
        """
        local_path = "./custom_repositories.json"
        remote_path = "/root/spacewalk/testsuite/features/upload_files/custom_repositories.json"
        logger.info(f"Copying file from {local_path} to {remote_path}")
        self._copy_file(local_path, remote_path)
        logger.info("Custom repositories updated successfully.")

    @staticmethod
    def extract_ip_from_url(url):
        """Extracts and validates the IP address from a URL."""
        parsed_url = urlparse(url)
        hostname = parsed_url.hostname

        if not hostname:
            raise ValueError("No hostname found in the provided URL.")

        ip_pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
        if ip_pattern.match(hostname):
            return hostname
        else:
            raise ValueError(f"Invalid IP address format in URL: {hostname}")
