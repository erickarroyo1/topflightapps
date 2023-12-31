# DevSecOps Project - AWS ECS Deployment with Terraform and Docker

This repository demonstrates the deployment of a simple application using Amazon ECS, RDS, Terraform, and Docker. The application consists of a basic flask app using python. It is deployed into a container that displays a message and retrieve the current value of the database. The RDS Data is inserted at the 1st called to a microservice and is ony one execution. It involves creating a VPC, an RDS database, an ECS cluster, and deploying the application container. Security best practices are followed to ensure proper access control, networking, and endpoint protection.

For security Best Practices purposes, i use a .gitignore file that avoid the upload of *.tfvars files. Additionally, in order to not to manage static credentials, the provider is confiured with alias and I use sso authentication from aws CLIv2

Note:
- The certificate is not deployed using terraform, i pass the arn of the cert with a tfvars file.
- The public access for this solution is: https://topflight.devsecopsapp.com/ using route53 alias pointing to alb.

## Working Evidence: 

  ![TopflightAPP running](./resources/TopflightAPP-Running.png " TopflightAPP - done")

## Steps to deploy

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
10. Use terraform.workspaces from beginning and module as possible for repeteability (needed), I use workspace prod for all project modules separated by folders.
11. CI/CD (optional)

### Database Configuration form a host within vpc

1. Connect to the RDS database using bastion host deployed into the same RDS's VPC

    ```bash
        mysql -h topflightapps-database.cqa8k6awsmjm.us-east-1.rds.amazonaws.com -u admin -p
    
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

1. The database configuration is not auto-deploying. Is needed a bastion host to make the first connection to the DB and create the table employees.
2. Take into consideration that the ECR repository is public for testing purposes. 
3. There is no automatic script running to generate the DOcker image. I will push an script to do it. Maybe with a null resource local-exec from terraform that call an script.
3. There is no CDN or WAF in place to protect against attacks (due the time of this project). This is consider a must.
4. CI/CD is a good solution to solve manual steps like configuration of the RDS and employee table, deploy terraform, build and push docker image. (Due the objective and time, is not completed yet)

# Evidences of resources and deployment:


  
  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-2.png " TopflightAPP - 2")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-3.png " TopflightAPP - 3")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-4.png " TopflightAPP - 4")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-5.png " TopflightAPP - 5")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-6.png " TopflightAPP - 6")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-7.png " TopflightAPP - 7")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-8.png " TopflightAPP - 8")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-9.png " TopflightAPP - 9")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-10.png " TopflightAPP - 10")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-11.png " TopflightAPP - 11")

  ![TopflightAPP running](./resources/Captura%20desde%202023-08-30-12.png " TopflightAPP - 12")

  ![TopflightAPP running](./resources/DeploymentTFErick.png " TopflightAPP - deployment Erick")


# Author: Erick Arroyo