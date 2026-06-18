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
        self.resources_to_keep = {"proxy", "monitoring", "build", "terminal"} - set(resources_to_delete)
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
        """Delete only custom child channels (keeps all parent channels and vendor child channels)."""
        # Specific child channels to delete by exact label match (use set for O(1) lookup)
        specific_channels_to_delete = {
            "ubuntu-2404-noble-amd64"
        }

        # No need to differentiate between versions (SUMA 4.3, 5.0, 5.1, 5.2 vs Uyuni)
        # Uyuni BV is now gone, and the behavior should be the same across all versions and products
        channels = self.client.channel.listMyChannels(self.session_key)

        for channel in channels:
            channel_label = channel['label']

            # Skip protected channels early to avoid unnecessary API calls
            if any(protected in channel_label for protected in self.resources_to_keep):
                continue

            # Pre-filter: only check details for potential deletion candidates
            # (channels with "custom" in label or in specific list)
            is_candidate = (
                "custom" in channel_label.lower() or
                channel_label in specific_channels_to_delete
            )

            if not is_candidate:
                continue

            # Get channel details to check if it's a child channel
            # (only called for deletion candidates, avoiding N+1 query waste)
            details = self.client.channel.software.getDetails(self.session_key, channel_label)

            # Only delete child channels (those with a parent)
            if details.get('parent_channel_label'):
                logger.info(f"Delete child channel: {channel_label} (parent: {details['parent_channel_label']})")
                self.client.channel.software.delete(self.session_key, channel_label)

    def delete_systems(self):
        systems = self.client.system.listSystems(self.session_key)
        for system in systems:
            if not any(protected in system['name'] for protected in self.resources_to_keep):
                logger.info(f"Delete system : {system['name']} | id : {system['id']}")
                self.client.system.deleteSystem(self.session_key, system['id'])

    def delete_system(self, system_name):
        systems = self.client.system.listSystems(self.session_key)
        for system in systems:
            if system['name'] == system_name :
                logger.info(f"Delete system : {system['name']} | id : {system['id']}")
                self.client.system.deleteSystem(self.session_key, system['id'])

    def delete_system_groups(self):
        groups = self.client.systemgroup.listAllGroups(self.session_key)
        for group in groups:
            logger.info(f"Delete system group : {group['name']}")
            self.client.systemgroup.delete(self.session_key, group['name'])

    def delete_images(self):
        images = self.client.image.listImages(self.session_key)
        for image in images:
            logger.info(f"Delete image : {image['name']}")
            self.client.image.delete(self.session_key, image['id'])

    def delete_channel_repos(self):
        repositories = self.client.channel.software.listUserRepos(self.session_key)
        for repository in repositories:
            logger.info(f"Delete repository : {repository['label']}")
            self.client.channel.software.removeRepo(self.session_key, repository['label'])

    def delete_salt_keys(self):
        accepted_salt_keys = self.client.saltkey.acceptedList(self.session_key)
        pending_salt_keys = self.client.saltkey.pendingList(self.session_key)
        salt_keys = accepted_salt_keys + pending_salt_keys
        for salt_key in salt_keys:
            if not any(protected in salt_key for protected in self.resources_to_keep):
                logger.info(f"Delete remaining accepted key : {salt_key}")
                self.client.saltkey.delete(self.session_key, salt_key)

    def delete_salt_key(self, system_name):
        self.client.saltkey.delete(self.session_key, system_name)

    def delete_image_profiles(self):
        try:
            profiles = self.client.image.profile.listImageProfiles(self.session_key)
        except xmlrpc.client.Fault as e:
            logger.warning(f"Failed to list image profiles (fault {e.faultCode}): {e.faultString}")
            return
        except Exception:
            logger.exception("Unexpected error listing image profiles")
            raise

        for profile in profiles:
            try:
                logger.info(f"Delete image profile: {profile['label']}")
                self.client.image.profile.delete(self.session_key, profile['label'])
            except xmlrpc.client.Fault as e:
                logger.warning(f"Failed to delete profile {profile['label']} (fault {e.faultCode}): {e.faultString}")
                # Continue with other profiles
                continue

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
