import logging
import xmlrpc.client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global configuration
username = "admin"
password = "admin"

def get_session_key(manager_url):
    client = xmlrpc.client.ServerProxy(f"http://{manager_url}/rpc/api")

    # Authenticate
    session_key = client.auth.login(username, password)
    logger.info("Session key obtained.")
    return session_key, client

def logout_session(client, session_key):
    client.auth.logout(session_key)
    logger.info("Logged out from session.")

def delete_users(client, session_key):
    users = client.user.listUsers(session_key)
    for user in users:
        if user["login"] != "admin":
            logger.info(f"Delete user: {user['login']}")
            client.user.delete(session_key, user["login"])

def delete_activation_keys(client, session_key):
    activation_keys = client.activationkey.listActivationKeys(session_key)
    for activation_key in activation_keys:
        if "proxy" not in activation_key['key'] and "monitoring" not in activation_key['key']:
            logger.info(f"Delete activation key: {activation_key['key']}")
            client.activationkey.delete(session_key, activation_key['key'])

def delete_config_projects(client, session_key):
    projects = client.contentmanagement.listProjects(session_key)
    for project in projects:
        logger.info(f"Delete project: {project['label']}")
        client.contentmanagement.removeProject(session_key, project['label'])

def delete_software_channels(client, session_key):
    channels = client.channel.listMyChannels(session_key)
    for channel in channels:
        details = client.channel.software.getDetails(session_key, channel['label'])
        if "proxy" not in channel['label'] and "monitoring" not in channel['label'] and "appstream" in channel['label'] and details['parent_channel_label']:
            logger.info(f"Delete sub channel appstream: {channel['label']}")
            client.channel.software.delete(session_key, channel['label'])

    channels = client.channel.listMyChannels(session_key)
    for channel in channels:
        details = client.channel.software.getDetails(session_key, channel['label'])
        if "proxy" not in channel['label'] and "monitoring" not in channel['label'] and "appstream" in channel['label']:
            logger.info(f"Delete parent channel appstream: {channel['label']}")
            client.channel.software.delete(session_key, channel['label'])

    channels = client.channel.listMyChannels(session_key)
    for channel in channels:
        if "proxy" not in channel['label'] and "monitoring" not in channel['label']:
            logger.info(f"Delete common channel: {channel['label']}")
            client.channel.software.delete(session_key, channel['label'])

def delete_systems(client, session_key):
    systems = client.system.listSystems(session_key)
    for system in systems:
        if "pxy" not in system['name'] and "monitoring" not in system['name'] and "build" not in system['name']:
            logger.info(f"Delete system : {system['name']} | id : {system['id']}")
            client.system.deleteSystem(session_key, system['id'])

def delete_channel_repos(client,session_key):
    repositories = client.channel.software.listUserRepos(session_key)
#     logger.info(f"Repositories : {repositories}")
    for repository in repositories:
        logger.info(f"Delete repository : {repository['label']}")
        client.channel.software.removeRepo(session_key, repository['label'])

def delete_salt_keys(client,session_key):
    accepted_salt_keys = client.saltkey.acceptedList(session_key)
#     logger.info(f"Accepted salt keys : {accepted_salt_keys}")
    for accepted_salt_key in accepted_salt_keys:
        if "pxy" not in accepted_salt_key and "monitoring" not in accepted_salt_key and "build" not in accepted_salt_key:
            logger.info(f"Delete remaining accepted key : {accepted_salt_key}")
            client.saltkey.delete(session_key,accepted_salt_key)