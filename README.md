# NCAAGameHighlights

# HighlightProcessor
This project uses RapidAPI to obtain NCAA game highlights using a Docker container and uses AWS Media Convert to convert the media file.

# File Overview

The config.py script performs the following actions:
Imports necessary environment variables and assigns them to Python variables, providing default values where appropriate. This approach allows for flexible configuration management, enabling different settings for various environments (e.g., development, staging, production) without modifying the source code.

The fetch.py script performs the following actions:

Establishes the date and league that will be used to find highlights. We are using NCAA in this example because it's included in the free version.
This will fetch the highlights from the API and store them in an S3 bucket as a JSON file (basketball_highlight.json)

process_one_video.py performs the following actions:

Connects to the S3 bucket and retrieves the JSON file.
Extracts the first video URL from within the JSON file.
Downloads the video file the requests library.
Saves the video as a new file in the S3 bucket under a different folder (videos/)
Logs the status of each step

mediaconvert_process.py performs the following actions:

Creates and submits a MediaConvert job
Uses MediaConvert to process a video file - configures the video codec, resolution and bitrate. Also configured the audio settings
Stores the processed video back into an S3 bucket

run_all.py performs the following actions:
Runs the scripts in a chronological order and provides buffer time for the tasks to be created.

.env file stores all over the environment variables, these are variables that we don't want to hardcode into our script.

Dockerfile performs the following actions:
Provides the step by step approach to build the image.

Terraform Scripts:
These scripts are used to created resources in AWS in a scalable and repeatable way. All of the resources we work with like  S3, creating IAM user roles, elastic registry service and elastic container services is built here.

# Prerequisites
Before running the scripts, ensure you have the following:

## **1** Create Rapidapi Account
Rapidapi.com account, will be needed to access highlight images and videos.

For this example we will be using NCAA (USA College Basketball) highlights since it's included for free in the basic plan.

[Sports Highlights API](https://rapidapi.com/highlightly-api-highlightly-api-default/api/sport-highlights-api/playground/apiendpoint_16dd5813-39c6-43f0-aebe-11f891fe5149) is the endpoint we will be using 

## **2** Verify prerequites are installed 

Docker should be pre-installed in most regions docker --version

AWS CloudShell has AWS CLI pre-installed aws --version

Python3 should be pre-installed also python3 --version

## **3** Retrieve AWS Account ID

Copy your AWS Account ID Once logged in to the AWS Management Console Click on your account name in the top right corner You will see your account ID Copy and save this somewhere safe because you will need to update codes in the labs later

## **4** Retrieve Access Keys and Secret Access Keys
You can check to see if you have an access key in the IAM dashboard
Under Users, click on a user and then "Security Credentials"
Scroll down until you see the Access Key section
You will not be able to retrieve your secret access key so if you don't have that somewhere, you need to create an access key.
## **Technical Diagram**
![GameHighlightProcessor](https://github.com/user-attachments/assets/762c3582-c6fe-48b2-b7da-0ff5b86b7970)

## **Project Structure**
```bash
src/
├── Dockerfile
├── config.py
├── fetch.py
├── mediaconvert_process.py
├── process_one_video.py
├── requirements.txt
├── run_all.py
├── .env
├── .gitignore
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── secrets.tf
    ├── iam.tf
    ├── ecr.tf
    ├── ecs.tf
    ├── s3.tf
    ├── container_definitions.tpl
    └── outputs.tf
```

# START HERE - Local
## **Step 1: Clone The Repo**
```bash
git clone https://github.com/Stormz99/NCAAGameHighlights
cd src
```
## **Step 2: Add API Key to AWS Secrets Manager**
```bash
aws secretsmanager create-secret \
    --name my-api-key \
    --description "API key for accessing the Sport Highlights API" \
    --secret-string '{"api_key":"YOUR_ACTUAL_API_KEY"}' \
    --region us-east-1
```

## **Step 3: Create an IAM role or user**

In the search bar type "IAM" 

Click Roles -> Create Role

For the Use Case enter "S3" and click next

Under Add Permission search for AmazonS3FullAccess, MediaConvertFullAccess and AmazonEC2ContainerRegistryFullAccess and click next

Under Role Details, enter "HighlightProcessorRole" as the name

Select Create Role

Find the role in the list and click on it
Under Trust relationships
Edit the trust policy to this:
Edit the Trust Policy and replace it with this:
```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ecs-tasks.amazonaws.com",
          "mediaconvert.amazonaws.com"
        ],
        "AWS": "arn:aws:iam::<"your-account-id">:user/<"your-iam-user">"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
![setting_permissions](./images/python_scripts/setting-permissions-1.png)
![setting_permissions_2](./images/python_scripts/setting-permissions-2.png)
![setting_permission_3](./images/python_scripts/setting-permissions-3.png)
![trustPolicy](./images/python_scripts/trust-policy.png)
![overview](./images/python_scripts/overview.png)


## **Step 4: Update .env file**
1. RapidAPI_KEY: Ensure that you have successfully created the account and select "Subscribe To Test" in the top left of the Sports Highlights API
2. AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
3. AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
4. S3_BUCKET_NAME=your_S3_bucket_name_here
5. MEDIACONVERT_ENDPOINT=https://your_mediaconvert_endpoint_here.amazonaws.com
```bash
aws mediaconvert describe-endpoints
```
7. MEDIACONVERT_ROLE_ARN=arn:aws:iam::your_account_id:role/HighlightProcessorRole

## **Step 5: Secure .env file**
```bash
chmod 600 .env
```
## **Step 6: Locally Buikd & Run The Docker Container**
Run:
```bash
docker build -t highlight-processor .
```
![dockerInstallation](./images/python_scripts/docker-installation.png)
Run the Docker Container Locally:
```bash
docker run --env-file .env highlight-processor
```
![dockerOverview](./images/python_scripts/docker-overview.png)
![dockerInstalled](./images/python_scripts/docker-installed.png)
![dockerImages](.//images/python_scripts/docker-images.png)
[dockerImagesGrep](./images/python_scripts/docker-images-grep.png)
![dockerRun](./images/python_scripts/docker-run.png)

This will run fetch.py, process_one_video.py and mediaconvert_process.py and the following files should be saved in your S3 bucket:

Optional - Confirm there is a video uploaded to s3://<your-bucket-name>/videos/first_video.mp4

![s3Bucket](./images/python_scripts/inside-s3-bucket.png)
![insideHighlight](./images/python_scripts/inside-highlights.png)

Optional - Confirm there is a video uploaded to s3://<your-bucket-name>/processed_videos/

![processedVideos](./images/python_scripts/processed-videos.png)
![watchingVideos](./images/python_scripts/watching-videos.png)
![watchingVideosImage](./images/python_scripts/watching-highlight-2.png)
![emptyingBucket](./images/python_scripts/emptying-bucket.png)
![deletingBucket](./images/python_scripts/deleting-bucket.png)

### **What I Learned**
1. Working with Docker and AWS Services
2. Identity Access Management (IAM) and least privilege
3. How to enhance media quality 

# Part 2 - Terraform Bonus

### **Setup terraform.tfvars File**
1. In the github repo, there is a resources folder and copy the entire contents
2. In the AWS Cloudshell or vs code terminal, create the file vpc_setup.sh and paste the script inside.
3. Run the script
```bash
bash vpc_setup.sh
```
![vpcSetup](./images/terraformImages/startingScripts.png)
)

4. You will see variables in the output, paste these variables into lines 8-13.

5. Store your API key in AWS Secrets Manager
```bash
aws ssm put-parameter \
  --name "/myproject/rapidapi_key" \
  --value "YOUR_SECRET_KEY" \
  --type SecureString
```
![parameterSetup](./images/terraformImages/parameterKey.png)

6.  Run the following script to obtain your mediaconvert_endpoint:
```bash
aws mediaconvert describe-endpoints --query "Endpoints[0].Url" --output text
```
7. Leave the mediaconvert_role_arn string empty

Helpful Tip for Beginners:
1. Use the same region, project, S3 Bucketname and ECR Repo name to make following along easier. Certain steps like pushing the docker image to the ECR repo is easier to copy and paste without remember what you named your repo :)

### **Run The Project**
1.  Navigate to the terraform folder/workspace in VS Code
From the src folder
```bash
cd terraform
```
2. Initialize terraform working directory
```bash
terraform init
```
![terraformInit](./images/terraformImages/terraformInit.png)

3. Check syntax and validity of your Terraform configuration files
```bash
terraform validate
```
![terraformValidate](./images/terraformImages/terraformValidate.png)

4. Display execution plan for the terraform configuration
```bash
terraform plan
```
![teraformPlan](./images/terraformImages/terraformPlan.png)

![terraformPlan2](./images/terraformImages/terraformPlan2.png)

5. Apply changes to the desired state
```bash
terraform apply -var-file="terraform.dev.tfvars"
```
![terraformApply](./images/terraformImages/terraformApply.png)

![terraformApply2](./images/terraformImages/terraformApply2.png)

6. Create an ECR Repo
```bash
aws ecr create-repository --repository-name highlight-pipeline
```
![ecrCreation](./images/terraformImages/ecrCreation.png)

7. Log into ECR
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```
8. Build and Push the Docker Image
```bash
docker build -t highlight-pipeline:latest .
docker tag highlight-pipeline:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/highlight-pipeline:latest
```
![dockerBuild](./images/terraformImages/dockerbuild.png)

![dockerBuild2](./images/terraformImages/dockerBuild2.png)

![dockerDesktop](./images/terraformImages/dockerDesktop.png)

```bash
docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/highlight-pipeline:latest
```
![dockerPush](./images/terraformImages/dockerPush.png)


### **Destroy ECS and ECR resources**
1. In the AWS Cloudshell or vs code terminal, create the file ncaaprojectcleanup.sh and paste the script inside from the resources folder.
3. Run the script
```bash
bash ncaaprojectcleanup.sh
```
![cleanUp](./images/terraformImages/cleanup.png)

### **Review Video Files**
1. Navigate to the S3 Bucket and confirm there is a json video in the highlights folder and a video in the videos folder

![insideS3](./images/terraformImages/insides3.png)

![insideHiglight](./images/terraformImages/inside-highlights.png)

![processedData](./images/terraformImages/processed-videos.png)

![watchingVideos](./images/terraformImages/watching-videos.png)

![watchingVideos2](./images/terraformImages/watching-highlight-2.png)

### **What I Learned**
1. Deploying local docker images to ECR 
2. A high level overview of terraform files
3. Networking - VPCs, Internet Gateways, private subnets and public subnets
4. SSM for saving secrets and pulling into terraform
