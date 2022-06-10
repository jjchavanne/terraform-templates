# Ref: https://aws.amazon.com/premiumsupport/knowledge-center/restrict-launch-tagged-ami/

# Variables
# Placed here only for easy reference

# Ensure to enter YOUR ACCOUNT ID & REGION
variable "account_id" {
  type        = string
  description = "AWS Account ID"
  default     = "111111111111"
}
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
variable "ami_tag_key" {
  type        = string
  description = "Custom AMI tag key"
  default     = "image"
}
variable "ami_tag_value" {
  type        = string
  description = "Custom AMI tag value"
  default     = "defender"
}

# Policy
resource "aws_iam_policy" "ec2-launch-policy" {
  name        = "EC2LaunchwithAMIsAndTags-Policy"
  path        = "/"
  description = "Allow Launch of EC2 Instances with AMIs with required tags"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "EC2Access",
        Effect: "Allow",
        Action: [
          "ec2:Describe*",
          "ec2:GetConsole*",
          "ec2:CreateKeyPair",
          "ec2:AssociateIamInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:PassRole"
        ],
        Resource: "*"
      },
      {
        Sid: "ActionsRequiredtoRunInstancesInVPC",
        Effect: "Allow",
        Action: "ec2:RunInstances",
        Resource: [
          "arn:aws:ec2:${var.region}:${var.account_id}:instance/*",
          "arn:aws:ec2:${var.region}:${var.account_id}:key-pair/*",
          "arn:aws:ec2:${var.region}:${var.account_id}:security-group/*",
          "arn:aws:ec2:${var.region}:${var.account_id}:volume/*",
          "arn:aws:ec2:${var.region}:${var.account_id}:network-interface/*",
          "arn:aws:ec2:${var.region}:${var.account_id}:subnet/*"
        ]
      },
      {
        Sid: "LaunchingEC2withAMIsAndTags",
        Effect: "Allow",
        Action: "ec2:RunInstances",
        Resource: "arn:aws:ec2:${var.region}::image/ami-*",
        Condition: {
          StringEquals: {
            "ec2:ResourceTag/${var.ami_tag_key}": "${var.ami_tag_value}"
          }
        } 
      }
    ]
  })
}

# Role
resource "aws_iam_role" "ec2-access-role" {
  name                = "EC2LaunchwithAMIsAndTags-Role"
  assume_role_policy  = jsonencode({
   Version: "2012-10-17",
   Statement: [
     {
       Action: "sts:AssumeRole",
       Principal: {
         Service: "ec2.amazonaws.com"
       },
       Effect: "Allow",
       Sid: ""
     }
   ]
  })
}

# Attachment Policy
resource "aws_iam_policy_attachment" "ec2-policy-attachment" {
  name       = "EC2LaunchwithAMIsAndTags-PolicyAttachment"
  roles      = ["${aws_iam_role.ec2-access-role.name}"]
  policy_arn = "${aws_iam_policy.ec2-launch-policy.arn}"
}

resource "aws_iam_user" "iam-user" {
  name = "privesc3-ModifiedCreateEC2WithExistingInstanceProfile-user"
  path = "/"
}

resource "aws_iam_access_key" "iam-user" {
  user = aws_iam_user.iam-user.name
}

# This should migrate to a Group and Group policy attachment in future
resource "aws_iam_user_policy_attachment" "user-attach-policy" {
  user       = aws_iam_user.iam-user.name
  policy_arn = aws_iam_policy.ec2-launch-policy.arn
}

resource "aws_iam_role_policy_attachment" "role-attach-policy" {
  role       = aws_iam_role.ec2-access-role.name
  policy_arn = aws_iam_policy.ec2-launch-policy.arn
}

# TODO - this needs testing
#output "iam_access_key_id" {
#  description = "The access key ID"
#  value       = try(aws_iam_access_key.this[0].id, aws_iam_access_key.this_no_pgp[0].id, "")
#}

#output "iam_access_key_secret" {
#  description = "The access key secret"
#  value       = try(aws_iam_access_key.this_no_pgp[0].secret, "")
#  sensitive   = true
#}