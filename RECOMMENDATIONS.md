# YuLife DevOps Tech Test

## Jim Cumming 11th Feb 2023

## Changes I have made
I fixed more than one item as I wanted to get it running properly on my aws account. Demo is now running on https://yulife.jimc.co.uk

Pleae let me know once you've reviewed so I can remove. 

Tasks completed

* Upgraded Terraform to 1.3.8
* Updated security groups to more secure settings
* Moved ECS to private subnet and added nat gateway
* Created an SSL certificate
* Attached SSL cert to LB
* Applied a secure SSL policy to the Load Balancer
* Redirected http traffic to https
* Setup logging

## Additional Recommendations

### App folder
Nginx config could be expanded to include security headers and content security policy
Enable gzip compression in Nginx config

### CICD
Copy only build folder to nginx container, not whole application.

Had to add `docker build --platform amd64` to build-container.sh script to allow for M1 mac compatibility

Build container script should ideally use --frozen-lockfile to ensure build is deterministic
`yarn install --frozen-lockfile --cwd app`

Should export the docker iamage name and tag for use by terraform. 

If this was a complete pipeline, you would probably want to do the following

* lint typescript
* run some unit tests
* generate unique tag name
* build image and push to ecr
* export image name and tag
* validate terraform files
* create terraform plan
* have a validation step for plan approval
* apply terraform changes
* rollback if error detected.

### Infrastructure
Ideally build process should make use of immutable tags. Makes it easier to roll back to specific versions if image tags are immutable. If tags can be overwritten you can't trust previous tags to have not changed. 

EC2 Execution role doesn't really need `AmazonEC2ContainerRegistryFullAccess` it's only pulling images, so `AmazonEC2ContainerRegistryReadOnly` should do

For a more complex application you might consider using a different execution and task role for the container. 

ECS cluster is running in a public subnet and has a public ip assigned. Only load balancer should be in public subnet, ecs should be in private subnet. 

Nat gateway should be enabled in private subnets so ECS can pull ECR images.

Security groups are wide open, they allow traffic from aywhere on the internet to all ports and protocols.
Should be set to load balaner ip -> tcp port 80 for ecs_service security group. 
Load balancer SG should only allow incoming on port 443 and port 80 from internet on tcp. 

If a bastion server is to be used, you should also allow access from the bastion IP for SSH and HTTP for debugging purposes. 

Traffic should be served over https not http, so you would want to add an SSL certificate to the load balancer and set a redirect action to https for http traffic.

You will need to add a certificate to the load balancer listener. This could either be created in Terrform earlier in the script or could be a pre-created certificate. 

You then need to add arn of the cert to the aws_lb_listener.

If this application was to get any more complex I would be tempted to move each item into a seperate module files.

ECS task definition refers to nginx image rather than the one built in CI/CD steps. I've moved this to a tfvars file for now. Ideally build script should output the image name and tag which is then picked up by the tf scripts. 

There are no health checks configured for the container in ECS. 

Only a single container is created for this service. For reliability and performance at least 2 containers should be created. 
Autoscaling should also be enable to allow it to scale to additional containers is required. 
A capacity provider that uses Fargate Spot could be used to control costs of auto scaling. 

No logging is enabled. Had to setup aws log driver to debug issue with ARM image on ECS. Would ideally split application and access logs into 2 different log streams. 

