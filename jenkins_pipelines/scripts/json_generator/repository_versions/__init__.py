from .v43_nodes import get_v43_nodes_sorted
from .v50_nodes import get_v50_nodes_sorted
from .v51_nodes import get_v51_static_and_client_tools

static_51_micro, dynamic_51_micro = get_v51_static_and_client_tools("micro")
static_51_sles, dynamic_51_sles = get_v51_static_and_client_tools("sles")

nodes_by_version: dict[str, dict[str, dict[str, list[str]]]] = {
    "43": {"dynamic": get_v43_nodes_sorted()},
    "50-micro": {"dynamic": get_v50_nodes_sorted(get_v43_nodes_sorted(), "micro")},
    "50-sles": {"dynamic": get_v50_nodes_sorted(get_v43_nodes_sorted(), "sles")},
    "51-sles": {"static": static_51_sles, "dynamic": dynamic_51_sles},
    "51-micro": {"static": static_51_micro, "dynamic": dynamic_51_micro}
}
