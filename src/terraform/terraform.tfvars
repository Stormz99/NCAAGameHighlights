# terraform.tfvars

aws_region                = "us-east-1"
project_name             = "highlight-pipeline-final"
s3_bucket_name           = "ijiolausman-ncaaa-highlights-final"
ecr_repository_name      = "highlight-pipeline2-final"

vpc_id                   = "vpc-049de302d9103816a"
public_subnets           = ["subnet-056ee35e49e202a23"]
private_subnets          = ["subnet-00bcdcb444f80fb88"]
igw_id                   = "igw-050c4befb1a364adf"
public_route_table_id    = "rtb-04dd1e338ee844ff9"
private_route_table_id   = "rtb-06b9b479fb5287079"

rapidapi_ssm_parameter_arn = "arn:aws:ssm:us-east-1:982081058848:parameter/myproject/rapidapi_key"

mediaconvert_endpoint     = "https://vasjpylpa.mediaconvert.us-east-1.amazonaws.com"
mediaconvert_role_arn     = "" # Leaving the string empty will use the role that is created

retry_count                = 5
retry_delay                = 60
