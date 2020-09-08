## Wordpress with Terraform and Ansible

### Prerequisites

- Make sure you are using a user who has all the required permissions (for example, full access to the EC2 instance and RDS)
- Copy id and secret key for that user and provide this values in appropriate variables in *vars.tf*

https://aws.amazon.com/free/

- Create an ssh key with no passphrase with ssh-keygen -t rsa and use the name terraform (or use existing key if you have such key).

https://learn.hashicorp.com/tutorials/terraform/aws-provision

- All necessary preinstalations

https://learn.hashicorp.com/tutorials/terraform/install-cli
