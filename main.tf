//The Terraform AWS Cloud Control Provider 
//https://www.hashicorp.com/resources/using-the-terraform-aws-cloud-control-provider

//Using both the Terraform AWS Cloud Control Provider and the Terraform AWS Provider
//https://www.hashicorp.com/blog/announcing-terraform-aws-cloud-control-provider-tech-preview


//See documentation: https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/kendra_index
resource "awscc_kendra_index" "demo-index" {
  description = "Demo index created with the AWS Cloud Control Provider for Terraform"
  edition  = "ENTERPRISE_EDITION"
  name     = "terraform-awscc-demo"
  role_arn = aws_iam_role.kendra_index.arn
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region_name = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

output "region_name" {
  value = local.region_name
}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

#Region IAM 
//Reference role policy: https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html#iam-roles-index
data "aws_iam_policy_document" "kendra_index_cloudwatch_policy" {
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["Kendra"]
    }
  }
  statement {
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/kendra/*"]
  }
  statement {
    actions   = ["logs:DescribeLogStreams","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/kendra/*:log-stream:*"]
  }
}

data "aws_iam_policy_document" "kendra_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    /*
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:kendra:${local.region_name}:${local.account_id}:index/*"]
    }
    */
    principals {
      type        = "Service"
      identifiers = ["kendra.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kendra_index" {
  name               = "kendra_index_instance_role"
  assume_role_policy = data.aws_iam_policy_document.kendra_assume_role_policy.json
  inline_policy {
    name   = "kendra_index_cloudwatch_policy"
    policy = data.aws_iam_policy_document.kendra_index_cloudwatch_policy.json
  }
}
#End Region

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 0.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}