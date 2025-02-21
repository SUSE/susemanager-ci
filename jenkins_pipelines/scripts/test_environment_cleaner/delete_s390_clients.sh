#!/bin/bash
##### Manually delete the s390 using delete_s390_guest command #####
# Check if the main.tf file is provided as an argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path_to_main.tf>"
  exit 1
fi

# Get the main.tf file from the argument
MAIN_TF_FILE=$1

# Check if the file exists
if [ ! -f "$MAIN_TF_FILE" ]; then
  echo "Error: File $MAIN_TF_FILE does not exist."
  exit 1
fi

# Extract user IDs from the main.tf file
USERIDS=$(grep -A 1 "userid" "$MAIN_TF_FILE" | awk -F'"' '/userid/ {print $2}')

# Iterate through each userid and delete the s390 clients
for USERID in $USERIDS; do
  echo "Deleting client with userid: $USERID"
  delete_s390_guest "$USERID"

done


##### Remove s390 clients from the terraform state file #####

# Check if the Terraform state file exists in the current directory
if [ ! -f "terraform.tfstate" ]; then
  echo "Error: No terraform.tfstate file found in the current directory."
  exit 1
fi

# Get all Terraform state items containing "s390"
MODULES=$(terraform state list | grep "s390")

# Check if any modules containing "s390" were found
if [ -z "$MODULES" ]; then
  echo "No modules containing 's390' found in the Terraform state."
  exit 0
fi

for MODULE in $MODULES; do
  echo "Removing $MODULE..."
  terraform state rm "$MODULE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to remove $MODULE."
    exit 1
  fi
done

echo "All modules containing 's390' have been successfully removed from the Terraform state."
