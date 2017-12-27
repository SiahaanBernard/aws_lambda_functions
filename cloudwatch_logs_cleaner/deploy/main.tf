provider "aws" {
  region = "ap-southeast-1"
}

data "aws_iam_policy_document" "lambda_trust_policy" {
  statement = {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cwlogs_policy" {
  statement = {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DeleteLogGroups",
      "logs:DeleteLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "logs_cleaner_role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_trust_policy.json}"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "cleanup_policy"
  role   = "${aws_iam_role.lambda_role.name}"
  policy = "${data.aws_iam_policy_document.cwlogs_policy.json}"
}

resource "null_resource" "pip" {
  triggers = {
    main = "${base64sha256(file("../lambda_function.py"))}"
  }

  provisioner "local-exec" {
    command = "./deploy.sh"
  }
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "/tmp/function"
  output_path = "/tmp/lambda_function.zip"

  depends_on = ["null_resource.pip"]
}

resource "aws_lambda_function" "logs_cleaner_lambda" {
  filename         = "/tmp/lambda_function.zip"
  function_name    = "logs_cleaner"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${data.archive_file.source.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = 120
}

resource "aws_cloudwatch_event_rule" "logs_cleanup_event" {
  name                = "logs_cleaner"
  description         = "logs_cleaner"
  schedule_expression = "cron(0 11 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "logs_cleanup_event_target" {
  target_id = "logs_cleanup_event_target"
  rule      = "${aws_cloudwatch_event_rule.logs_cleanup_event.name}"
  arn       = "${aws_lambda_function.logs_cleaner_lambda.arn}"
}
