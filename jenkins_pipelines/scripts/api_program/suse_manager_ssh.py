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

    :param url: The server API URL.
    :param command: The command to run on the remote server.
    :return: The output of the command or an error message if connection fails.
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    private_key = paramiko.RSAKey(filename="/home/maxime/github/sumaform/salt/controller/id_rsa")

    try:
        logger.info(f"Connecting to server at: {url}")
        # Attempt to connect to the server
        client.connect(url, port=port, username=username, pkey=private_key)
        logger.info("Connection successful.")

        # Run the command
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode()
        error = stderr.read().decode()

        # Log and return the output or error
        if error:
            logger.error(f"Command error: {error}")
            return f"Error: {error}"

        logger.info(f"Command output: {output}")
        return output

    except paramiko.AuthenticationException:
        logger.error("Authentication failed while connecting to the server.")
        return "Authentication failed."

    except paramiko.SSHException as ssh_exception:
        logger.error(f"SSH connection error: {str(ssh_exception)}")
        return f"SSH connection error: {str(ssh_exception)}"

    except Exception as e:
        logger.error(f"Exception: {str(e)}")
        return f"Exception: {str(e)}"

    finally:
        client.close()

def copy_file_over_ssh(url, local_path, remote_path):
    """
    Copy a file to a remote server via SSH.

    :param url: The server API URL.
    :param local_path: The local path of the file to copy.
    :param remote_path: The destination path on the remote server.
    :return: Success message or error details.
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    private_key = paramiko.RSAKey(filename="/home/maxime/github/sumaform/salt/controller/id_rsa")

    try:
        logger.info(f"Connecting to server at: {url} to copy file.")
        # Attempt to connect to the server
        client.connect(url, port=port, username=username, pkey=private_key)
        logger.info("Connection successful for file transfer.")

        # Open SFTP session and transfer the file
        sftp = client.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()
        logger.info(f"File {local_path} copied to {remote_path} on server {url}")
        return "File copy successful"

    except paramiko.AuthenticationException:
        logger.error("Authentication failed during file copy.")
        return "Authentication failed during file copy."

    except paramiko.SSHException as ssh_exception:
        logger.error(f"SSH error during file copy: {str(ssh_exception)}")
        return f"SSH error during file copy: {str(ssh_exception)}"

    except Exception as e:
        logger.error(f"Exception during file copy: {str(e)}")
        return f"Exception during file copy: {str(e)}"

    finally:
        client.close()
