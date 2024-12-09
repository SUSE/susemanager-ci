import paramiko
import re
import logging
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SSHClientManager:
    def __init__(self, url, username="root", password="linux", port=22):
        self.url = url
        self.username = username
        self.password = password
        self.port = port
        self.client = None

    def connect(self):
        """Establishes an SSH connection to the server."""
        if not self.client:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            try:
                logger.info(f"Connecting to server at: {self.url}")
                self.client.connect(self.url, port=self.port, username=self.username, password=self.password)
                logger.info("Connection successful.")
            except paramiko.AuthenticationException:
                logger.error("Authentication failed while connecting to the server.")
                raise
            except paramiko.SSHException as ssh_exception:
                logger.error(f"SSH connection error: {str(ssh_exception)}")
                raise
            except Exception as e:
                logger.error(f"Exception: {str(e)}")
                raise

    def close(self):
        """Closes the SSH connection."""
        if self.client:
            self.client.close()
            self.client = None
            logger.info("Connection closed.")

    def run_command(self, command):
        """
        Runs a command on the remote server.

        :param command: Command to execute on the server.
        :return: Command output or error message.
        """
        try:
            self.connect()
            stdin, stdout, stderr = self.client.exec_command(command)
            output = stdout.read().decode()
            error = stderr.read().decode()

            if error:
                logger.error(f"Command error: {error}")
                return f"Error: {error}"
            logger.info(f"Command output: {output}")
            return output
        except Exception as e:
            logger.error(f"Exception: {str(e)}")
            return f"Exception: {str(e)}"

    def copy_file(self, local_path, remote_path):
        """
        Copies a file to the remote server.

        :param local_path: Path of the local file to copy.
        :param remote_path: Destination path on the remote server.
        :return: Success message or error details.
        """
        try:
            self.connect()
            sftp = self.client.open_sftp()
            sftp.put(local_path, remote_path)
            sftp.close()
            logger.info(f"File {local_path} copied to {remote_path} on server {self.url}")
            return "File copy successful"
        except Exception as e:
            logger.error(f"Exception during file copy: {str(e)}")
            return f"Exception during file copy: {str(e)}"

    @staticmethod
    def extract_ip_from_url(url):
        """Extracts and validates the IP address from a URL."""
        parsed_url = urlparse(url)
        hostname = parsed_url.hostname

        if hostname:
            ip_pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
            if ip_pattern.match(hostname):
                return hostname
            else:
                return "Invalid IP address format"
        else:
            return "No hostname found in URL"
