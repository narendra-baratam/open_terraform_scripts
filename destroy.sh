export AWS_PROFILE=prisma
export AWS_REGION="us-east-2"
dlq_name='AdjustmentHub-batchfiles-queue-DLQ'
main_queue_name='AdjustmentHub-batchfiles-queue'
enable_encryption=true
dlq_retention=14
receive_count=5

terraform init -backend=true -force-copy \
-backend-config="bucket=lean-terraform-sandbox-state" \
-backend-config="key=prisma-test-backup/aws/state.tfstate" \
-backend-config="region=$AWS_REGION"
terraform destroy \
-var="main_queue_name=$main_queue_name" -var="dlq_name=$dlq_name" \
-var="aws_region=$AWS_REGION" -var="profile=$AWS_PROFILE" -var="dlq_retention=$dlq_retention" \
-var="receive_count=$receive_count" -var="enable_encryption=$enable_encryption" -auto-approve
