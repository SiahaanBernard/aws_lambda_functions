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

    resource = "*"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_trust_policy.json}"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "CleanupPolicy"
  role   = "${aws_iam_role.lambda_role.json}"
  policy = "${data.aws_iam_policy_document.cwlogs_policy.json}"
}

resource "aws_lambda_function" "logs_cleaner_lambda" {
  filename         = "logs_cleaner.zip"
  function_name    = "logs_cleaner"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "logs_cleaner.lambda_handler"
  source_code_hash = "${base64sha256(file("logs_cleaner.zip"))}"
  runtime          = "python2.7"
}

resource "aws_cloudwatch_event_rule" "logs_cleanup_event" {
  name                = "logs_cleaner"
  description         = "time to clean up logs"
  schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "logs_cleanup_event_target" {
  target_id = "logs_cleanup_event_target"
  rule      = "${aws_cloudwatch_event_rule.logs_cleanup_event.arn}"
  arn       = "${aws_lambda_function.logs_cleaner_lambda.arn}"
}
