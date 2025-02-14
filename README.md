# my-first-terraform

## Purpose: 
- Taking advantage of IaC to create a simple but secured virtual network infrastructure on AWS that managable via Terraform cli.

## Infrastruture contains:
- 1 VPC in us-west-1, CIDR 10.0.0.0/16
- 1 Public Subnet, CIDR 10.0.1.0/24 with Internet Gateway that allow all trafic from Public Subnet to internet with no restriction using a Public Route Table
- 1 Private Subnet, CIDR 10.0.2.0/24 with no internet access
- 1 NAT Gateway that placed in Public Subnet, attached with an Elastic IP address that allow instances from Private Subnet securely connect to internet without the risk on a connection invokes from the external, using a Private Route Table

## Testing:
- Launch a t3.micro linux instance on Public Subnet and another on Private Subnet
- SSH into Public Instance using its public IP address
- SSH into Private Instance using its private IP address
- Check internet connection from this instance (yum update or ping google.com)

## Keypairs and security concerns:
- I created a public and private key on my local computer using PowerShell
``` <bash>
ssh-keygen -t rsa -b 2048 -f C:\path\to\your\keyfile
```
- I only used this keypair to create both Public Instance and Private Instance
- When SHH from Public Instance, I create new private key on Public Instance and paste the value in, then use it to SSH into the Private Instance. I'm aware this is not a secure way to store secret but also tried to keep it simple. 

## Improvement:
- Use AWS Secrets Manager to quickly store and summons it
![alt text](<images/my-first-terraform.drawio.png>)