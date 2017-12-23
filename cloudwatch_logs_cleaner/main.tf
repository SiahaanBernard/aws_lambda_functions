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
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_trust_policy.json}"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "cleanup_policy"
  role   = "${aws_iam_role.lambda_role.name}"
  policy = "${data.aws_iam_policy_document.cwlogs_policy.json}"
}

resource "null_resource" "pip" {
  triggers = {
    main = "${base64sha256(file("function/main.py"))}"
  }
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "function"
  output_path = "/tmp/logs_cleaner.zip"

  depends_on = ["null_resource.pip"]
}

resource "aws_lambda_function" "logs_cleaner_lambda" {
  filename         = "/tmp/logs_cleaner.zip"
  function_name    = "logs_cleaner"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "logs_cleaner.lambda_handler"
  source_code_hash = "${data.archive_file.source.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = 120
}

resource "aws_cloudwatch_event_rule" "logs_cleanup_event" {
  name                = "logs_cleaner"
  description         = "logs_cleaner"
  schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "logs_cleanup_event_target" {
  target_id = "logs_cleanup_event_target"
  rule      = "${aws_cloudwatch_event_rule.logs_cleanup_event.name}"
  arn       = "${aws_lambda_function.logs_cleaner_lambda.arn}"
}
