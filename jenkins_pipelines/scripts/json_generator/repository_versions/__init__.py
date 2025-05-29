from .v43_nodes import get_v43_nodes_sorted
from .v50_nodes import get_v50_nodes_sorted
from .v51_nodes import get_v51_nodes_sorted

# You can add v51 imports here when ready
# from .v51_nodes import get_v51_nodes_sorted


nodes_by_version: dict[str, dict[str, list[str]]] = {
    "43": get_v43_nodes_sorted,
    "50": get_v50_nodes_sorted(get_v43_nodes_sorted),
    "51": get_v51_nodes_sorted()  # Uncomment when v51 is ready
}