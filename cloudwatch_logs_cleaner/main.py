import boto3
import sys
import time

def lambda_handler(event, context):
    logs = boto3.client('logs')
    describe_all_log_groups(logs)


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

    describe_log_stream(logs,used_loggroups)

def describe_log_stream(logs,loggroups):
    unused_logstreams = []
    logstreams = []
    for loggroupname in loggroups:
        try:
            logstreams = logs.describe_log_streams(
                logGroupName = loggroupname
            )
        except Exception, e:
            print(e)

        
        logstreams = logstreams['logStreams']
        for logstream in logstreams:
            if logstream['storedBytes'] == 0:
                unused_logstreams.append(logstream['logStreamName'])

    print("unused logstreams")
    for logstream in unused_logstreams:
        print(unused_logstreams)



if __name__ == "__main__":
    lambda_handler("asdf","asdf")