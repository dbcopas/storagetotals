#!/bin/bash

# Default verbosity level
verbosity=0
subscription_id=""

# Parse command line arguments
while getopts "v:s:" opt; do
  case $opt in
    v) verbosity=$OPTARG ;;
    s) subscription_id=$OPTARG ;;
  esac
done

# Set the Azure subscription context
if [ -n "$subscription_id" ]; then
    az account set --subscription "$subscription_id"
else
    subscription_id=$(az account show --query "id" -o tsv)
    subscription_id=$(echo "$subscription_id" | tr -d '\r')
    az account set --subscription $subscription_id
fi

subscription_name=$(az account show --subscription "$subscription_id" --query "name" -o tsv)
subscription_name=$(echo "$subscription_name" | tr -d '\r')

echo "Processing subscription: $subscription_name"

# Function to get the previous day in the format YYYY-MM-DD
get_previous_day() {
    date -u -d "yesterday" '+%Y-%m-%dT00:00:00Z'
}

# Function to get the end of the previous day in the format YYYY-MM-DD
get_end_of_previous_day() {
    date -u -d "yesterday 23:59:59" '+%Y-%m-%dT23:59:59Z'
}

# Get start and end times for the previous day
start_time=$(get_previous_day)
end_time=$(get_end_of_previous_day)

# Initialize total gigabytes variable for storage accounts and managed disks
total_storage_gigabytes=0
total_disk_gigabytes=0

# Query to get the list of storage accounts
[ $verbosity -eq 2 ] && echo "Executing storage account query"
storage_accounts=$(az graph query -q "Resources | where type == 'microsoft.storage/storageaccounts' and subscriptionId == '$subscription_id' | project id, name" --output json)

# Process each storage account without a pipeline
while read -r account; do
    account_id=$(echo "$account" | jq -r '.id')
    account_name=$(echo "$account" | jq -r '.name')

    # Command to get metrics for used capacity for the previous day
    metrics_command="az monitor metrics list --resource $account_id --metric UsedCapacity --aggregation Total --interval PT1H --start-time $start_time --end-time $end_time --output json"
    [ $verbosity -eq 2 ] && echo "Executing: $metrics_command"
    metrics_output=$($metrics_command)

    # Extract the used bytes from the metrics output
    used_bytes=$(echo "$metrics_output" | jq -r '.value[0].timeseries[0].data[0].total')

    # If used_bytes is null or empty, set it to 0
    if [ -z "$used_bytes" ] || [ "$used_bytes" == "null" ]; then
        used_bytes=0
    fi

    # Convert bytes to gigabytes using awk with higher precision
    used_gigabytes=$(awk -v bytes="$used_bytes" 'BEGIN {print bytes/1024/1024/1024}')

    # Add to the total storaazge gigabytes
    total_storage_gigabytes=$(awk -v total="$total_storage_gigabytes" -v used="$used_gigabytes" 'BEGIN {print total + used}')

    # Output for individual accounts (medium and high verbosity)
    [ $verbosity -ge 1 ] && echo "Storage Account: $account_name, Total Gigabytes Used: $used_gigabytes"
done < <(echo "$storage_accounts" | jq -c '.data[]') # Process substitution

# Output total for storage accounts (all verbosity levels)
echo "Total Gigabytes Used by Storage Accounts: $total_storage_gigabytes"

# Query to get the list of managed disks
managed_disks_query="Resources | where type == 'microsoft.compute/disks' and subscriptionId == '$subscription_id' | project id, diskSizeGB = properties.diskSizeGB"
[ $verbosity -eq 2 ] && echo "Executing: az graph query -q \"$managed_disks_query\" --output json"
managed_disks=$(az graph query -q "$managed_disks_query" --output json)

# Process each managed disk without a pipeline
while read -r disk; do
    disk_id=$(echo "$disk" | jq -r '.id')
    disk_size_gb=$(echo "$disk" | jq -r '.diskSizeGB')

    # Add to the total disk gigabytes
    total_disk_gigabytes=$(awk -v total="$total_disk_gigabytes" -v size="$disk_size_gb" 'BEGIN {print total + size}')

    # Output for individual disks (high verbosity only)
    [ $verbosity -eq 2 ] && echo "Managed Disk: $disk_id, Size: $disk_size_gb GB"
done < <(echo "$managed_disks" | jq -c '.data[]') 

# Output total for managed disks (medium and high verbosity)
echo "Total Gigabytes Used by Managed Disks: $total_disk_gigabytes"

# Calculate the grand total in gigabytes
grand_total_gigabytes=$(awk -v storage="$total_storage_gigabytes" -v disks="$total_disk_gigabytes" 'BEGIN {print storage + disks}')

# Convert the grand total to terabytes
grand_total_terabytes=$(awk -v total_gb="$grand_total_gigabytes" 'BEGIN {print total_gb/1024}')

# Print the grand total (all verbosity levels)
echo "Grand Total Terabytes Used (Storage + Managed Disks) in Subscription $subscription_name: $grand_total_terabytes"
