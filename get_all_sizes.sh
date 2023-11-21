#!/bin/bash

# Path to the get_storage_size.sh script
GET_STORAGE_SIZE_SCRIPT="./get_storage_size.sh"

# Check if the get_storage_size.sh script exists
if [ ! -f "$GET_STORAGE_SIZE_SCRIPT" ]; then
    echo "Script get_storage_size.sh not found in the current directory."
    exit 1
fi

# Initialize totals
total_storage_gb=0
total_disk_gb=0

# Retrieve all enabled subscription IDs and store them in an array
readarray -t subscription_ids < <(az account list --all --query "[?state=='Enabled'].id" -o tsv | tr -d '\r')

# Process each subscription ID
for sub_id in "${subscription_ids[@]}"; do
    
    # Call the get_storage_size.sh script with the subscription ID
    output=$(bash "$GET_STORAGE_SIZE_SCRIPT" -s "$sub_id" -v 0)

    # Print the output
    echo "$output"

    # Extract and accumulate storage and disk totals
    storage_gb=$(echo "$output" | grep "Total Gigabytes Used by Storage Accounts:" | awk '{print $NF}')
    disk_gb=$(echo "$output" | grep "Total Gigabytes Used by Managed Disks:" | awk '{print $NF}')

    total_storage_gb=$(awk -v total="$total_storage_gb" -v new="$storage_gb" 'BEGIN {print total + new}')
    total_disk_gb=$(awk -v total="$total_disk_gb" -v new="$disk_gb" 'BEGIN {print total + new}')

    echo "----------------------------------------"
done

echo "Total Gigabytes Used by All Storage Accounts Across All Subscriptions: $total_storage_gb"
echo "Total Gigabytes Used by All Managed Disks Across All Subscriptions: $total_disk_gb"

# Convert the grand total to terabytes
grand_total_tb=$(awk -v storage_gb="$total_storage_gb" -v disk_gb="$total_disk_gb" 'BEGIN {print (storage_gb + disk_gb)/1024}')
echo "Grand Total Terabytes Used Across All Subscriptions: $grand_total_tb"

echo "Processing completed."
