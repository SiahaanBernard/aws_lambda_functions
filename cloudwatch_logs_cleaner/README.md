#Description#
This lambda function is used to clean up unused cloudwatch log groups and cloudwatch log streams. It will detect loggroups and logstreams which has 0 zero bytes data store in it, and delete it.

#Deployment#
You can deploy the lambda function using terraform configuration which is provided on deploy dir.
- `cd deploy`
- `terraform plan`
- `terraform apply`

Or you can deploy it using another way.