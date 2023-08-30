# AWS ECS Deployment with Terraform and Docker

This repository demonstrates the deployment of a simple application using Amazon ECS, RDS, Terraform, and Docker. The application consists of a basic flask app using python. It is deployed into a container that displays a message and retrieve the current value of the database. The RDS Data is inserted at the 1st called to a microservice and is ony one execution. It involves creating a VPC, an RDS database, an ECS cluster, and deploying the application container. Security best practices are followed to ensure proper access control, networking, and endpoint protection.

For security Best Practices purposes, i use a .gitignore file that avoid the upload of *.tfvars files. Additionally, in order to not to manage static credentials, the provider is confiured with alias and I use sso authentication from aws CLIv2

Note:
- The certificate is not deployed using terraform, i pass the arn of the cert with a tfvars file.
- The public access for this solution is: https://topflight.devsecopsapp.com/ using route53 alias pointing to alb.

## Steps

### Docker Image Build and Push

1. Build the Docker image:
    - Dockerfile:
      ```
        FROM python:3.9
        RUN apt update && apt install -y python3-mysqldb
        ENV PYTHONUNBUFFERED True
        ENV APP_HOME /app
        WORKDIR $APP_HOME
        COPY . ./
        RUN pip install --no-cache-dir -r requirements.txt
        CMD ["python3", "app.py"]

      ```

2. Push the image to Amazon ECR:
      ```bash
                aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/s0p7h2p1
                docker build -t topflightappdemo .
                docker tag topflightappdemo:latest public.ecr.aws/s0p7h2p1/topflightappdemo:latest
                docker push public.ecr.aws/s0p7h2p1/topflightappdemo:latest
       ```

## ECS Cluster Deployment Definitions

1. Create a task definition using the provided JSON configuration.
2. Deploy the task into the ECS cluster using a service and optionally a load balancer.
3. Configure security groups for the ECS service and RDS connection to be within the same VPC.
4. Optionally, configure ECS with variables. 
5. You can also consider using secrets from AWS Secrets Manager for added security.

## Application Deployment (Local Testing)
    
    The application code should retrieve variables from the OS environment. For testing purposes, use the following command:

        ```bash
            docker run -d -p 8080:8080 --name topflightapp -e DB_USERNAME=admin -e DB_PASSWORD='password' -e DB_HOST=database-topflight-app.cqa8k6awsmjm.us-east-1.rds.amazonaws.com -e DB_PORT=3306 -e DB_NAME=db public.ecr.aws/s0p7h2p1/topflightappdemo:v3
        ```


## Terraform resources to be created (Definition)

1. VPC (Subnets, routes, IGW, NAtGw)
2. RDS Database free tier
3. Secret Manager
4. Policies
5. Roles
6. ECS cluster
7. ECS task definition
8. ECR Repository
9. Image creation and pulling to ECR
10. Use terraform.workspaces from beginning and module as possible for repeteability (needed)
11. CI/CD (optional)

### Database Configuration form a host within vpc

1. Connect to the RDS database using bastion host deployed into the same RDS's VPC

    ```bash
        mysql -h database-topflight-app.cqa8k6awsmjm.us-east-1.rds.amazonaws.com -u admin -p
    
    ```

2. Create the database and table:
    ```sql
    CREATE DATABASE db;
    USE db;
    CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    salary DECIMAL(10, 2)
    );
    ```
# Missing Items and improvements

1. Please ensure that the database configuration is not auto-deploying.
2. Take into consideration that the ECR repository is public, and there is no automatic script running to generate the image.
3. The deployment lacks a load balancer.
4. An HTTPS listener certificate is missing.
5. There is no CDN or WAF in place.
6. CI/CD is a good solution to solve manual steps like configuration of the RDS and employee table, deploy terraform, build and push docker image 

