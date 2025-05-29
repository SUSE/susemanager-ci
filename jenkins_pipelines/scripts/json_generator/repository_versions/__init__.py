from .v43_nodes import get_v43_nodes_sorted
from .v50_nodes import get_v50_nodes_sorted
from .v51_nodes import get_v51_static_and_client_tools

static, dynamic = get_v51_static_and_client_tools()

nodes_by_version: dict[str, dict[str, dict[str, list[str]]]] = {
    "43": {"dynamic": get_v43_nodes_sorted()},
    "50": {"dynamic": get_v50_nodes_sorted(get_v43_nodes_sorted())},
    "51": {"static": static, "dynamic": dynamic},
}