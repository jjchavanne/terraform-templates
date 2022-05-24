# Ref: https://aws.amazon.com/premiumsupport/knowledge-center/restrict-launch-tagged-ami/

# Role
resource "aws_iam_role" "privesc3-CreateEC2WithExistingInstanceProfile-role" {
  name                = "privesc3-CreateEC2WithExistingInstanceProfile-role"
  assume_role_policy  = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": "ec2.amazonaws.com"
       },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
  })
}

# Policy
resource "aws_iam_policy" "LaunchEC2withAMIsAndTags" {
  name        = "LaunchEC2withAMIsAndTags"
  path        = "/"
  description = ""

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "ReadOnlyAccess",
        "Effect": "Allow",
        "Action": [
          "ec2:Describe*",
          "ec2:GetConsole*",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "iam:ListInstanceProfiles"
        ],
        "Resource": "*"
      },
      {
        "Sid": "ActionsRequiredtoRunInstancesInVPC",
        "Effect": "Allow",
        "Action": "ec2:RunInstances",
        "Resource": [
          "arn:aws:ec2:us-east-1:AccountId:instance/*",
          "arn:aws:ec2:us-east-1:AccountId:key-pair/*",
          "arn:aws:ec2:us-east-1:AccountId:security-group/*",
          "arn:aws:ec2:us-east-1:AccountId:volume/*",
          "arn:aws:ec2:us-east-1:AccountId:network-interface/*",
          "arn:aws:ec2:us-east-1:AccountId:subnet/*"
        ]
      },
      {
        "Sid": "LaunchingEC2withAMIsAndTags",
        "Effect": "Allow",
        "Action": "ec2:RunInstances",
        "Resource": "arn:aws:ec2:us-east-1::image/ami-*",
        "Condition": {
          "StringEquals": {
            "ec2:ResourceTag/Environment": "Prod"
          }
        } 
      }
    ]
  })
}

#
