import paramiko
import re
import logging
from urllib.parse import urlparse


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables
username = "root"
password = "linux"
port = "22"

def extract_ip_from_url(url):
    # Parse the URL
    parsed_url = urlparse(url)

    # Extract the hostname (which contains the IP address)
    hostname = parsed_url.hostname

    # Validate and return the IP address
    if hostname:
        # Use a regular expression to validate the IP address format
        ip_pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
        if ip_pattern.match(hostname):
            return hostname
        else:
            return "Invalid IP address format"
    else:
        return "No hostname found in URL"

def run_ssh_command(url, command):
    """
    Connects to a server using SSH and runs a command.

    :param url: The server api url
    :param command: The command to run on the remote server.
    :return: The output of the command.
    """
    try:
#         ip_address = extract_ip_from_url(url)
        logger.info(f"Server address : {url}")
        # Create an SSH client
        client = paramiko.SSHClient()
        # Automatically add the server's host key (use with caution)
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        private_key = paramiko.RSAKey(filename="/home/maxime/github/sumaform/salt/controller/id_rsa")

        # Connect to the server
        client.connect(url, port=port, username=username, pkey=private_key)

        # Run the command
        stdin, stdout, stderr = client.exec_command(command)

        # Read the command output and error (if any)
        output = stdout.read().decode()
        error = stderr.read().decode()

        # Close the connection
        client.close()
        logger.info(f"Command output : {output}")
        if error:
            return f"Error: {error}"
        return output

    except Exception as e:
        return f"Exception: {str(e)}"

def copy_file_over_ssh(url, local_path, remote_path):
    """
    Copy a file to a remote server via SSH.

    :param url: The server API URL.
    :param local_path: The local path of the file to copy.
    :param remote_path: The destination path on the remote server.
    :return: Success message or error details.
    """
    try:
        logger.info(f"Copying file to server at: {url}")
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        private_key = paramiko.RSAKey(filename="/home/maxime/github/sumaform/salt/controller/id_rsa")

        client.connect(url, port=port, username=username, pkey=private_key)

        sftp = client.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()

        client.close()
        logger.info(f"File {local_path} copied to {remote_path} on server {url}")
        return "File copy successful"

    except Exception as e:
        return f"Exception during file copy: {str(e)}"
