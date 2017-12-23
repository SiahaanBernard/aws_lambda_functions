import boto3
import sys
import time
from retrying import retry


def retry_on_request_limit_exceed(e):
    if "RequestLimitExceeded" in e.message:
        print "RequestLimitExceeded exception occurs, retrying..."
        return True
    else:
        return False


def lambda_handler(event, context):
    logs = boto3.client('logs')
    describe_all_log_groups(logs)
    unused_loggroups, used_loggroups = describe_all_log_groups(logs)
    unused_logstreams = describe_log_streams(logs, used_loggroups)
    unused_loggroups, used_loggroups = describe_all_log_groups(logs)
    for loggroup in unused_loggroups:
        print(loggroup)
    for logstream in unused_logstreams:
        print(logstream)
#    delete_log_group(unused_loggroups)
#    delete_log_stream(unused_logstreams)


def describe_all_log_groups(logs):
    loggroups = []
    unused_loggroups = []
    used_loggroups = []

    try:
        loggroups = logs.describe_log_groups()
    except Exception, e:
        print e

    loggroups = loggroups['logGroups']
    for loggroup in loggroups:
        loggroup_size = loggroup['storedBytes']
        if loggroup_size == 0:
            unused_loggroups.append(loggroup['logGroupName'])
        else:
            used_loggroups.append(loggroup['logGroupName'])

    return unused_loggroups, used_loggroups


@retry(retry_on_exception=retry_on_request_limit_exceed, wait_random_min=4,
       wait_random_max=8, stop_max_attempt_number=5)
def describe_log_streams(logs, loggroups):
    unused_logstreams = []
    logstreams = []
    for loggroupname in loggroups:
        try:
            logstreams = logs.describe_log_streams(
                logGroupName=loggroupname
            )
        except Exception, e:
            print(e)

        logstreams = logstreams['logStreams']
        for logstream in logstreams:
            if logstream['storedBytes'] == 0:
                raw_data = {"logGroupName": loggroupname,
                            "logStreamName": logstream['logStreamName']}
                unused_logstreams.append(raw_data)
    return unused_logstreams


@retry(retry_on_exception=retry_on_request_limit_exceed, wait_random_min=4,
       wait_random_max=8, stop_max_attempt_number=5)
def delete_log_group(logs, loggroups):
    for loggroup in loggroups:
        try:
            logs.delete_log_group(
                logGroupName=loggroup
            )
        except Exception, e:
            print(e)


@retry(retry_on_exception=retry_on_request_limit_exceed, wait_random_min=4,
       wait_random_max=8, stop_max_attempt_number=5)
def delete_log_stream(logs, logstreams):
    for logstream in logstreams:
        try:
            logs.delete_log_stream(
                logGroupName=logstream['logGroupName'],
                logStreamName=logstream['logStreamName']
            )
        except Exception, e:
            print(e)

if __name__ == "__main__":
    lambda_handler("asdf", "asdf")
