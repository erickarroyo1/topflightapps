# AWS ECS Deployment with Terraform and Docker

This repository demonstrates the deployment of a simple application using Amazon ECS, Terraform, and Docker. The application consists of a basic Nginx web server container that displays a message. It involves creating a VPC, an RDS database, an ECS cluster, and deploying the application container. Security best practices are followed to ensure proper access control, networking, and endpoint protection.

## Steps

### Docker Image Build and Push

1. Build the Docker image:
    - Dockerfile:
      ```
      FROM nginx:latest
      COPY index.html /usr/share/nginx/html/index.html
      EXPOSE 8080
      ```
    - HTML (`index.html`):
      ```html
      <!DOCTYPE html>
      <html>
      <head>
          <title>topFlightApp</title>
      </head>
      <body>
          <h1>topFlightApp is running on port 8080 using AWS ECS</h1>
      </body>
      </html>
      ```
2. Push the image to Amazon ECR:
    ```bash
        aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/s0p7h2p1
        docker build -t topflightappdemo .
        docker tag topflightappdemo:latest public.ecr.aws/s0p7h2p1/topflightappdemo:latest
        docker push public.ecr.aws/s0p7h2p1/topflightappdemo:latest
    ```

### Infrastructure Setup

1. Build the infrastructure (VPC, networking, subnets, routes, NAT gateways, ECS Cluster) using Terraform or CDK with Python or other programming languages.
2. Configure security groups for ECS service and RDS connection within the same VPC.

### Database Configuration

1. Connect to the RDS database:

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

## ECS Cluster Deployment

1. Create a task definition using the provided JSON configuration.
2. Deploy the task into the ECS cluster using a service and optionally a load balancer.
3. Configure security groups for the ECS service and RDS connection to be within the same VPC.
4. Optionally, configure ECS with variables. You can also consider using secrets from AWS Secrets Manager for added security.

## Application Deployment
    
    The application code should retrieve variables from the OS environment. For testing purposes, use the following command:
    ```bash
        docker run -d -p 8080:8080 --name topflightapp -e DB_USERNAME=admin -e DB_PASSWORD='password' -e DB_HOST=database-topflight-app.cqa8k6awsmjm.us-east-1.rds.amazonaws.com -e DB_PORT=3306 -e DB_NAME=db public.ecr.aws/s0p7h2p1/topflightappdemo:v3
    ```


## Terraform resources to be created:

1. VPC (Subnets, routes, IGW, NAtGw)
2. RDS Database free tier
3. ECS cluster
4. ECS task definition
5. ECR Repository
6. Image creation and pulling to ECR
7. Use terraform.workspaces from beginning and module as possible for repeteability 
8. CI/CD


TSHOOT: Despliegue modular en workspace prod


Manualidades cosas que faltan

Tener en cuenta que no está desplegando automáticamente la configuración de la BD
Tener en cuenta que el repo en ECR está publico y que no se está ejecutando un script automático paara generar la imágen
Tener en cuenta qe no se ha subido el código a algun repositorio
**No se tiene documentación aun
**el  despliegue  es sin balanceador de carga
no se tiene certificado para listener https 
no se tiene CDN ni WAF


Orden de despliegue: 

1. VPC
2. Backend
3. RDS
4. ECS



