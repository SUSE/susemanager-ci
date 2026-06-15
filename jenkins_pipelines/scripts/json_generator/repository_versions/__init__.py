from typing import TypeAlias, TypedDict

from .v43_nodes import (
    get_v43_nodes_sorted,
    v43_client_tools,
    v43_static_slmicro_salt_repositories,
)
from .v50_nodes import get_v50_nodes_sorted
from .v51_nodes import get_v51_static_and_client_tools
from .v52_nodes import get_v52_static_and_client_tools
from .v53_nodes import get_v53_static_and_client_tools

StaticRepos: TypeAlias = dict[str, dict[str, str]]
DynamicRepos: TypeAlias = dict[str, list[str]]


class VersionNodes(TypedDict):
    static: StaticRepos
    dynamic: DynamicRepos

v43_dynamic = get_v43_nodes_sorted()

static_51_micro, dynamic_51_micro = get_v51_static_and_client_tools("micro")
static_51_sles, dynamic_51_sles = get_v51_static_and_client_tools("sles")

# 5.2 (uses 5.1 client tools)
static_52_micro, dynamic_52_micro = get_v52_static_and_client_tools("micro")
static_52_sles, dynamic_52_sles = get_v52_static_and_client_tools("sles")

# 5.3 Beta (PLACEHOLDER - not yet ready for production use)
# TODO: Update URLs in v53_nodes.py when 5.3 beta project is created
static_53_micro_beta, dynamic_53_micro_beta = get_v53_static_and_client_tools("micro", beta=True)
static_53_sles_beta, dynamic_53_sles_beta = get_v53_static_and_client_tools("sles", beta=True)

nodes_by_version: dict[str, VersionNodes] = {
    "43": {"static": v43_static_slmicro_salt_repositories, "dynamic": v43_dynamic},
    "50-micro": {
        "static": v43_static_slmicro_salt_repositories,
        "dynamic": get_v50_nodes_sorted(v43_client_tools, "micro"),
    },
    "50-sles": {
        "static": v43_static_slmicro_salt_repositories,
        "dynamic": get_v50_nodes_sorted(v43_client_tools, "sles"),
    },
    "51-sles": {"static": static_51_sles, "dynamic": dynamic_51_sles},
    "51-micro": {"static": static_51_micro, "dynamic": dynamic_51_micro},
    "52-sles": {"static": static_52_sles, "dynamic": dynamic_52_sles},
    "52-micro": {"static": static_52_micro, "dynamic": dynamic_52_micro},
    # 5.3 Beta - PLACEHOLDER: URLs need to be updated when 5.3 beta project exists
    "53-sles-beta": {"static": static_53_sles_beta, "dynamic": dynamic_53_sles_beta},
    "53-micro-beta": {"static": static_53_micro_beta, "dynamic": dynamic_53_micro_beta},
}
