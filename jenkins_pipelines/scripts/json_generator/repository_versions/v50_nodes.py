from typing import Dict, Set, List

# Dictionary for SUMA 5.0 Server and Proxy nodes
v50_nodes: Dict[str, Set[str]] = {
    "server": {
        "/SUSE_Products_SUSE-Manager-Server_5.0_x86_64/",
        "/SUSE_Updates_SUSE-Manager-Server_5.0_x86_64/",
        "/SUSE_Updates_SLE-Module-Web-Scripting_15-SP6_x86_64/",
        "/SUSE_Updates_SLE-Micro_5.5_x86_64/",
    },
    "proxy": {
        "/SUSE_Products_SUSE-Manager-Proxy_5.0_x86_64/",
        "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/",
        "/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
        "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
        "/SUSE_Updates_SLE-Micro_5.5_x86_64/",
    },
}

def get_v50_nodes_sorted(v43_client_tools: Dict[str, Set[str]]) -> Dict[str, List[str]]:
    """
    Combine v50_nodes (server/proxy) with v43_client_tools (clients),
    returning a dictionary with sorted lists of repository paths.

    Notes:
    - v50_nodes: Dict[str, Set[str]] (server/proxy paths)
    - v43_client_tools: Dict[str, Set[str]] (client tool paths)
    - Only adds client tool entries if they are not already defined in v50_nodes
      (server/proxy keys are preserved).
    - The sets are converted into sorted lists for deterministic ordering.

    Args:
        v43_client_tools (Dict[str, Set[str]]): Client tool repository paths to merge.

    Returns:
        Dict[str, List[str]]: Each node type maps to a sorted list of repository paths.
    """
    combined_nodes: Dict[str, Set[str]] = {k: set(v) for k, v in v50_nodes.items()}

    for key, paths in v43_client_tools.items():
        # Only add if not already defined in v50 (avoid overwriting server/proxy)
        if key not in combined_nodes:
            combined_nodes[key] = set(paths)

    return {key: sorted(paths) for key, paths in combined_nodes.items()}
