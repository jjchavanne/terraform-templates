resource "aws_iam_role" "iam_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "iam_profile_for_ec2" {
  name = var.iam_profile_for_ec2
  role = aws_iam_role.iam_role.name
}

resource "aws_iam_role_policy" "iam_policy" {
  name = var.iam_policy
  role = aws_iam_role.iam_role.id

  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}
