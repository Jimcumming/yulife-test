variable "hosted_zone_name" {
  description = "The name of the hosted zone where the domain name record will be created."
}

variable "domain_name" {
  description = "The domain name to assign to the application load balancer"
}

variable "docker_image" {
  description = "The name of the docker image deployed to ECS"
}