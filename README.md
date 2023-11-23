# Azure Storage and Disk Usage Scripts

This repository contains two scripts to assist in calculating the storage usage in Azure. These scripts are useful for cloud administrators and architects who need to track storage usage across different Azure subscriptions.

## Prerequisites

- **Azure CLI**: The scripts use Azure CLI to interact with Azure resources. Ensure that Azure CLI is installed and configured on your system. Refer to [Azure CLI documentation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for installation instructions.
- **jq**: `jq` is a lightweight and flexible command-line JSON processor. It's used for parsing JSON data returned by Azure CLI commands. Make sure `jq` is installed on your system. Visit [jq's official website](https://stedolan.github.io/jq/) for download and installation instructions.
- **Azure Resource Graph extension for Azure CLI**. This can be installed using the command:
  ```bash
  az extension add --name resource-graph
  ```

## Scripts

### 1. `get_storage_size.sh`

This script calculates the total gigabytes used by storage accounts and managed disks in a specific Azure subscription.

#### Usage

```bash
./get_storage_size.sh [-v verbosity_level] [-s subscription_id]
```

- -v (optional): Sets the verbosity level. Acceptable values are 0, 1, or 2. The default is 0.
- -s (optional): Specifies the subscription ID to process. If not provided, the script uses the current subscription context.


### 2. `get_all_sizes.sh`

This script iterates over all enabled Azure subscriptions, calling `get_storage_size.sh` for each one to calculate and aggregate storage usage.

#### Usage

```bash
./get_all_sizes.sh [-v verbosity_level]
```
- -v (optional): Sets the verbosity level. Acceptable values are 0, 1, or 2. The default is 0.

#### Output

The script provides a summary of total gigabytes used by storage accounts and managed disks for each subscription. It also outputs a grand total across all subscriptions at the end.

## Notes

- Ensure that you have the necessary permissions to access and list resources in the Azure subscriptions you want to analyze.
- The `get_all_sizes.sh` script assumes `get_storage_size.sh` is located in the same directory.

## License

These scripts are provided "as is" without warranty of any kind. You are free to modify and use them in your environment, subject to your organization's policies and applicable laws.
