def run(params) {
    timestamps {
        def awscli = '/usr/local/bin/aws'

        def source_ami = params.ami_id

        stage('AMI lookup') {
            if (source_ami) {
                echo "AMI ID provided: ${source_ami}. Verifying existence..."

                def checkAmi = sh(
                    script: "${awscli} ec2 describe-images --region ${params.aws_region} --image-ids ${params.ami_id} --query 'Images[0].ImageId' --output text",
                    returnStatus: true // 0 if exists, non-zero if it doesn't
                )
            
                if (checkAmi != 0) {
                    error "TERMINATING: The provided AMI ID ${params.ami_id} does not exist or you don't have access to it."
                }
            
                echo "Verification successful. Using ${source_amiD}"
            }
            else {
                echo "No AMI ID provided. Searching for the latest image with name ${params.ami_name_filter}..."

                def result_id = sh(
                    script: """
                        ${awscli} ec2 describe-images \
                            --region ${params.aws_region} \
                            --owners self \
                            --filters "Name=name,Values=${params.ami_name_filter}*" "Name=state,Values=available" \
                            --query "sort_by(Images, &CreationDate)[-1].ImageId" \
                            --output text
                    """,
                    returnStdout: true
                ).trim()

                if (!result_id || result_id == "None" || result_id == "null") {
                    error "TERMINATING: No AMI found with prefix '${params.ami_name_filter}'. Ensure the name is correct and the AMI is in the 'available' state."
                }

                echo "Latest AMI ID for ${params.ami_name_filter}: ${result_id}"
                source_ami = result_id
            }
        }

        stage('AMI Bake') {
            def timestamp = new Date().format("yyyy-MM-dd-HHmm")
            def new_name = "${params.new_ami_name_prefix}-${timestamp}"
            
            // Launch instance with user data to run updates automatically
            def user_data = "#!/bin/bash\nzypper -n ref && zypper -n dup --no-recommends\n"
            def encoded_user_data = sh(
                script: "printf '${user_data}' | base64 -w 0", 
                returnStdout: true
            ).trim()

            echo "Launching temporary builder instance..."
            def instance_id = sh(script: """
                ${awscli} ec2 run-instances \
                    --region ${params.aws_region} \
                    --image-id ${source_ami} \
                    --instance-type t3.medium \
                    --user-data '${encoded_user_data}' \
                    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=${params.builder_instance_name}}]' \
                    --query 'Instances[0].InstanceId' \
                    --output text
            """, returnStdout: true).trim()

            // Wait for the instance to finish its updates
            wait_time = params.updates_wait_time.toInteger()
            echo "Waiting for updates to complete on ${params.builder_instance_name} - ID: ${instance_id} (Sleeping ${wait_time} seconds)..."
            sleep wait_time

            // Create the new AMI
            echo "Creating new AMI: ${new_name}"
            def new_ami_id = sh(script: """
                ${awscli} ec2 create-image \
                    --region ${params.aws_region} \
                    --instance-id ${instance_id} \
                    --name "${new_name}" \
                    --no-reboot \
                    --query 'ImageId' \
                    --output text
            """, returnStdout: true).trim()

            // Cleanup service EC2
            echo "Terminating builder instance ${params.builder_instance_name} - ${instance_id}..."
            sh "${awscli} ec2 terminate-instances --instance-ids ${instance_id}"
            
            echo "Successfully baked new AMI with ID: ${new_ami_id}"
        }

        stage("Cleanup old AMIs") {
            if (!params.cleanup_amis) {
                echo "AMIs cleanup is disabled or a specific AMI ID was provided. Skipping ..."
            }
            else  {
                echo "Cleaning up AMIs matching '${params.cleanup_name_filter}*', keeping the latest ${params.retain_count}..."

                // Get the list of AMIs sorted by date (Oldest first)
                def ami_data = sh(script: """
                    ${awscli} ec2 describe-images \
                        --region ${params.aws_region} \
                        --owners self \
                        --filters "Name=name,Values=${params.cleanup_name_filter}*" \
                        --query "sort_by(Images, &CreationDate)[].{ID:ImageId, Snap:BlockDeviceMappings[0].Ebs.SnapshotId}" \
                        --output json
                """, returnStdout: true).trim()

                def images = readJSON text: ami_data
                def to_retain = params.retain_count.toInteger()

                if (images.size() <= to_retain) {
                    echo "Only ${images.size()} AMIs found. No cleanup needed."
                } else {
                    // Identify images to delete
                    def to_delete = new ArrayList(images.subList(0, images.size() - to_retain))
            
                    echo "Found ${images.size()} total images. Deleting ${to_delete.size()} oldest images..."

                    to_delete.each { ami ->
                        echo "Destroying AMI: ${ami.ID} (Snapshot: ${ami.Snap})"
                        
                        // Deregister the AMI
                        sh "${awscli} ec2 deregister-image --region ${params.aws_region} --image-id ${ami.ID}"
                        
                        // Delete the backing Snapshot
                        if (ami.Snap && ami.Snap != "null") {
                            sh "${awscli} ec2 delete-snapshot --region ${params.aws_region} --snapshot-id ${ami.Snap}"
                        }
                    }
                    echo "Cleanup complete."
                }
            }
        }
    }
}

return this
