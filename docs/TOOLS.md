# Official tools

From `oracle.oci-cloud-mcp-server` (SDK wrapper, not `oci` CLI subprocess).

Think: `client class → method → kwargs`.

| Tool | Args (main) | Notes |
|---|---|---|
| `list_oci_clients` | none | capability dump |
| `find_oci_api` | `query`, optional `client_fqn`, `limit` (3–5 first) | short phrases: `list instances`, `create vcn` |
| `list_client_operations` | `client_fqn`, optional `query`, `limit` | e.g. `oci.core.ComputeClient` |
| `describe_oci_operation` | `client_fqn`, `operation` | required vs optional params |
| `invoke_oci_api` | `client_fqn`, `operation`, `params` | optional `fields`, `max_results`, `result_mode` |

Example invoke:

```json
{
  "client_fqn": "oci.core.ComputeClient",
  "operation": "list_instances",
  "params": { "compartment_id": "ocid1.compartment.oc1.." },
  "fields": ["id", "display_name", "lifecycle_state"],
  "max_results": 10
}
```

Prefer describe → invoke. Use `find_oci_api` only as fallback.
