# AWS AMI Lifecycle Management Pipeline

This Jenkins pipeline automates the creation of updated Amazon Machine Images (AMIs).
It launches a temporary EC2 instance, runs system updates, creates a new AMI from that instance, and manages the retention of older images.

New AMIs created with this procedure can then be retrieved by other pipelines through the Terraform AWS provider filtering between the ones owned by `self`.

### ⚠️ Important Considerations

> **OS Compatibility**: This script is configured for **SUSE Linux** (using `zypper`). To use with RHEL, Amazon Linux, or Ubuntu, the `user_data` variable in the `AMI Bake` stage must be updated to use `yum` or `apt`.

> **Snapshot Deletion**: This pipeline explicitly deletes the EBS snapshot associated with the Root device when deregistering old AMIs. Ensure no other resources are relying on these snapshots before enabling `cleanup_amis`.

### Workflow

1) AMI Lookup: Validates a provided AMI ID or searches for the latest AMI based on a name filter.

2) AMI Bake

    - Launches a temporary t3.medium instance.

    - Executes system updates via User Data (zypper -n ref && zypper -n dup).

    - Creates a new AMI from the updated instance.

    - Terminates the temporary instance.

3) Cleanup: Identifies older AMIs matching a specific prefix and deletes them (including snapshots) based on a defined retention count.


### Pipeline Parameters

The defaults for each parameter are currently matching the openSUSE Tumbleweed AMI we use in Uyuni AWS CI.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `aws_region` | String | The AWS region (e.g., `us-east-1`) to perform operations. |
| `ami_id` | String | (Optional) Specific AMI ID to use. Overrides the search filter. |
| `ami_name_filter` | String | Prefix to find the latest base AMI if `ami_id` is null. |
| `new_ami_name_prefix` | String | The name prefix for the newly generated AMI. |
| `builder_instance_name`| String | Tag applied to the temporary EC2 builder instance. |
| `updates_wait_time` | Integer| Seconds to wait for updates to finish before creating the image. |
| `cleanup_amis` | Boolean| Enables/Disables the deletion of old AMI versions. |
| `cleanup_name_filter` | String | Prefix used to identify which AMIs are eligible for deletion. |
| `retain_count` | Integer| Number of most recent AMIs to keep during cleanup. |