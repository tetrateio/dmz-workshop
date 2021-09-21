aws ec2 run-instances --instance-type "t2.micro" \
	              --image-id ami-04eb6e0a0d6bf30e4 \
		      --key-name "abz" --security-group-ids "sg-021866712123fdb1c" \
		      --subnet-id "subnet-0cbbf7aa3f62c6c9a" \
		      --associate-public-ip-address \
                      --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="'workshop-jumpbox-"$PREFIX"'"}]' \
		      --output table
