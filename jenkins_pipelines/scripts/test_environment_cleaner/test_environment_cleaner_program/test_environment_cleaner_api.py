import logging
import xmlrpc.client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global configuration
username = "admin"
password = "admin"

class ResourceManager:
    def __init__(self, manager_url, resources_to_delete):
        self.resources_to_keep = {"proxy", "monitoring", "build"} - set(resources_to_delete)
        self.session_key = None
        self.client = xmlrpc.client.ServerProxy(f"http://{manager_url}/rpc/api")

    def get_session_key(self):
        self.session_key = self.client.auth.login(username, password)
        logger.info("Session key obtained.")

    def logout_session(self):
        self.client.auth.logout(self.session_key)
        logger.info("Logged out from session.")

    def delete_users(self):
        users = self.client.user.listUsers(self.session_key)
        for user in users:
            if user["login"] != "admin":
                logger.info(f"Delete user: {user['login']}")
                self.client.user.delete(self.session_key, user["login"])

    def delete_activation_keys(self):
        activation_keys = self.client.activationkey.listActivationKeys(self.session_key)
        for activation_key in activation_keys:
            if not any(protected in activation_key['key'] for protected in self.resources_to_keep):
                logger.info(f"Delete activation key: {activation_key['key']}")
                self.client.activationkey.delete(self.session_key, activation_key['key'])

    def delete_config_projects(self):
        projects = self.client.contentmanagement.listProjects(self.session_key)
        for project in projects:
            logger.info(f"Delete project: {project['label']}")
            self.client.contentmanagement.removeProject(self.session_key, project['label'])

    def delete_software_channels(self):
        channels = self.client.channel.listMyChannels(self.session_key)
        product_version = self.get_product_version()


        if all(version not in product_version for version in ["5.0", "4.3", "5.1"]):
            for channel in channels:
                if "custom" in channel['label'] and not any(protected in channel['label'] for protected in self.resources_to_keep):
                    logger.info(f"Delete custom channel: {channel['label']}")
                    self.client.channel.software.delete(self.session_key, channel['label'])
            logging.warning("Delete only custom channels for uyuni")
            return

        for channel in channels:
            details = self.client.channel.software.getDetails(self.session_key, channel['label'])
            if "appstream" in channel['label'] and details['parent_channel_label']:
                if not any(protected in channel['label'] for protected in self.resources_to_keep):
                    logger.info(f"Delete sub channel appstream: {channel['label']}")
                    self.client.channel.software.delete(self.session_key, channel['label'])

        channels = self.client.channel.listMyChannels(self.session_key)
        for channel in channels:
            if "appstream" in channel['label'] and not any(protected in channel['label'] for protected in self.resources_to_keep):
                logger.info(f"Delete parent channel appstream: {channel['label']}")
                self.client.channel.software.delete(self.session_key, channel['label'])

        channels = self.client.channel.listMyChannels(self.session_key)
        for channel in channels:
            if not any(protected in channel['label'] for protected in self.resources_to_keep):
                logger.info(f"Delete common channel: {channel['label']}")
                self.client.channel.software.delete(self.session_key, channel['label'])

    def delete_systems(self):
        systems = self.client.system.listSystems(self.session_key)
        for system in systems:
            if not any(protected in system['name'] for protected in self.resources_to_keep):
                logger.info(f"Delete system : {system['name']} | id : {system['id']}")
                self.client.system.deleteSystem(self.session_key, system['id'])

    def delete_channel_repos(self):
        repositories = self.client.channel.software.listUserRepos(self.session_key)
        for repository in repositories:
            logger.info(f"Delete repository : {repository['label']}")
            self.client.channel.software.removeRepo(self.session_key, repository['label'])

    def delete_salt_keys(self):
        accepted_salt_keys = self.client.saltkey.acceptedList(self.session_key)
        for accepted_salt_key in accepted_salt_keys:
            if not any(protected in accepted_salt_key for protected in self.resources_to_keep):
                logger.info(f"Delete remaining accepted key : {accepted_salt_key}")
                self.client.saltkey.delete(self.session_key, accepted_salt_key)

    def get_product_version(self):
        product_version = self.client.api.systemVersion()
        logger.info(f"Product version is {product_version}")
        return product_version

    def run(self):
            self.delete_users()
            self.delete_activation_keys()
            self.delete_config_projects()
            self.delete_software_channels()
            self.delete_systems()
            self.delete_channel_repos()
            self.delete_salt_keys()
