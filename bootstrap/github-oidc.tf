# ---------------------------------------------------------------
# 1. Trust GitHub as an identity provider (one per AWS account)
# ---------------------------------------------------------------


resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------------------------------------------------------------
# 2. Define the three pipeline roles and who may assume each one
# ---------------------------------------------------------------
locals {
  github_roles = {
    plan = {
      subject     = "repo:${local.github_repo}:pull_request"
      description = "Read-only role used by GitHub Actions to run terraform plan on pull requests"
    }
    apply = {
      subject     = "repo:${local.github_repo}:environment:production"
      description = "Role used by GitHub Actions to run terraform apply after manual approval"
    }
    app-deploy = {
      subject     = "repo:${local.github_repo}:ref:refs/heads/main"
      description = "Role used by GitHub Actions to push Docker images and deploy to ECS"
    }
  }
}

data "aws_iam_policy_document" "github_trust" {
  for_each = local.github_roles
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    # Token must be meant for AWS STS
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Token must come from THIS repo in THIS context only
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value.subject]
    }
  }
}

resource "aws_iam_role" "github" {
  for_each             = local.github_roles
  name                 = "${var.project_name}-gha-${each.key}"
  description          = each.value.description
  assume_role_policy   = data.aws_iam_policy_document.github_trust[each.key].json
  max_session_duration = 3600
}

# ---------------------------------------------------------------
# 3. PLAN role: read-only + access to the state file (for locking)
# ---------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.github["plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}


data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }
  statement {
    sid       = "ReadWriteStateAndLockFiles"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github["plan"].id
  policy = data.aws_iam_policy_document.state_access.json
}

# ---------------------------------------------------------------
# 4. APPLY role: PowerUser (no IAM) + IAM limited to app roles only
# ---------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "apply_poweruser" {
  role       = aws_iam_role.github["apply"].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
data "aws_iam_policy_document" "apply_scoped_iam" {
  statement {
    sid = "ManageOnlyProjectAppRolesAndPolicies"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.project_name}-app-*",
      "arn:aws:iam::${local.account_id}:policy/${var.project_name}-app-*",
    ]
  }
  statement {
    sid       = "PassAppRolesToEcsOnly"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project_name}-app-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "apply_scoped_iam" {
  name   = "scoped-iam-for-app-roles"
  role   = aws_iam_role.github["apply"].id
  policy = data.aws_iam_policy_document.apply_scoped_iam.json
}
# ---------------------------------------------------------------
# 5. APP-DEPLOY role: push images to ECR + roll out new ECS tasks
# ---------------------------------------------------------------
data "aws_iam_policy_document" "app_deploy" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "PushImagesToProjectRepositories"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}-*"]
  }
  statement {
    sid = "RegisterNewTaskDefinitions"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "DeployToProjectServices"
    actions   = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = ["arn:aws:ecs:${var.aws_region}:${local.account_id}:service/${var.project_name}-*/*"]
  }
  statement {
    sid       = "PassAppRolesToEcsOnly"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project_name}-app-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "app_deploy" {
  name   = "ecr-push-and-ecs-deploy"
  role   = aws_iam_role.github["app-deploy"].id
  policy = data.aws_iam_policy_document.app_deploy.json
}

  