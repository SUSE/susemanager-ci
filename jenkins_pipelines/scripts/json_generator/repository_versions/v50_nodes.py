from typing import Dict, Set, List

# Dictionary for SUMA 5.0 Server and Proxy nodes
v50_nodes: Dict[str,Dict[str, str]] = {
    "server": {
        "/SUSE_Products_SUSE-Manager-Server_5.0_x86_64/",
        "/SUSE_Updates_SUSE-Manager-Server_5.0_x86_64/",
    },
    "proxy": {
        "/SUSE_Products_SUSE-Manager-Proxy_5.0_x86_64/",
        "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/",
        "/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
        "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
        "/SUSE_Updates_SLE-Micro_5.5_x86_64/",
    },
}

def get_v50_nodes_sorted(v43_client_tools: Dict[str,Dict[str, str]]) -> Dict[str, List[str]]:
    """
    Combine v50_nodes (server/proxy) with v43_client_tools (clients),
    returning a dictionary with sorted lists of repository paths.
    """
    combined_nodes: Dict[str,Dict[str, str]] = {}

    # Add v50_nodes entries
    for key, paths in v50_nodes.items():
        combined_nodes[key] = paths.copy()

    # Add v43_client_tools entries (client tools)
    for key, paths in v43_client_tools.items():
        if key in combined_nodes:
            combined_nodes[key].update(paths)
        else:
            combined_nodes[key] = paths.copy()

    # Return sorted lists instead of sets
    return {key: sorted(paths) for key, paths in combined_nodes.items()}
