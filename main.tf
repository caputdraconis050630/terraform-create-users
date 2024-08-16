# Variables
variable "user_prefix" {
  description = "IAM 사용자 ID의 접두사"
  type        = string
}

variable "user_count" {
  description = "생성할 IAM 사용자 수"
  type        = number
}

variable "password_length" {
  description = "IAM 사용자 비밀번호 길이"
  type        = number
}

# AWS Provider
provider "aws" {
  region = "ap-northeast-2" # Region is irrelevant for IAM
}

# IAM Group
resource "aws_iam_group" "user_group" {
  name = "${var.user_prefix}-group"
}

# Dummy policy attachments
## S3 Full Access
resource "aws_iam_group_policy_attachment" "s3_full_access" {
  group      = aws_iam_group.user_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
## Lambda Full Access
resource "aws_iam_group_policy_attachment" "lambda_full_access" {
  group      = aws_iam_group.user_group.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# IAM Users
resource "aws_iam_user" "users" {
  count = var.user_count
  name  = format("%s-%02d", var.user_prefix, count.index + 1)
}

# Add IAM Users to a group
resource "aws_iam_user_group_membership" "user_group_membership" {
  count  = var.user_count
  user   = aws_iam_user.users[count.index].name
  groups = [aws_iam_group.user_group.name]
}

# IAM User Login Profile
resource "aws_iam_user_login_profile" "user_login_profile" {
  count                   = var.user_count
  user                    = aws_iam_user.users[count.index].name
  password_length         = var.password_length
  password_reset_required = true
}

# OUTPUT: User Credentials
output "user_credentials" {
  value = [for i in range(var.user_count) : {
    username = aws_iam_user.users[i].name
    password = aws_iam_user_login_profile.user_login_profile[i].password
  }]
  sensitive = true
}
