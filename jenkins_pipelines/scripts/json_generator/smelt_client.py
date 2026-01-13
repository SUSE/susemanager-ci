import logging
from typing import Any
import requests

# an online tool, GraphiQL, is available at the same URL and allows to see the API Schema and
# write, validate and test GraphQL queries
_SMELT_GRAPHQL_API_URL: str = "https://smelt.suse.de/graphql/"

class SmeltGraphQLClient():

    def __init__(self, api_url: str = _SMELT_GRAPHQL_API_URL):
        self._api_url: str = api_url

    def find_products(self, contains: str) -> list[dict[str, Any]]:
        query: str = f'''{{
            products(name_Icontains: "{contains}"){{
                edges {{
                    node {{
                        name
                        friendlyName
                        baseVersion
                    }}
                }}
            }}
        }}
        '''

        res: dict[str, Any] = self._execute_graphql_query(query)
        edges: list[Any] = res['products']['edges']
        if len(edges) == 0:
            logging.error("No products have been found")
        
        products: list[dict[str, Any]] = [ edge['node'] for edge in edges ]
        return products

    def find_incidents(self, **kwargs) -> list[dict[str, Any]]:
        filters: str = ", ".join(f"{k}: {v}" for k, v in kwargs.items())

        query: str = f'''{{
            incidents({filters}) {{
                edges {{
                    node {{
                        incidentId
                        project
                        priority
                        status {{
                            name
                        }}
                        severity {{
                            name
                        }}
                        created
                    }}
                }}
            }}
        }}'''
        
        res: dict[str, Any] = self._execute_graphql_query(query)
        edges: list[Any] = res['incidents']['edges']
        if len(edges) == 0:
            logging.error("No incidents have been found")

        incidents: list[dict[str, Any]] = [ edge['node'] for edge in edges ]
        return incidents

    def _execute_graphql_query(self, query:str) -> dict[str, Any] :
        response = requests.post(self._api_url, json={'query': query})
        if not response.ok:
            response.raise_for_status()

        json_body = response.json()
        if not isinstance(json_body, dict) or "data" not in json_body:
            logging.error("Unexpected GraphQL response format (missing 'data' key): %s", json_body)
            raise KeyError("Missing 'data' key in GraphQL response")
        
        return json_body["data"]
