import boto3
import sys
import time

def lambda_handler(event, context):
    cw = boto3.client('cloudwatch')
    ec2 = boto3.client('ec2')
    describe_cloudwatch_alarms(cw,ec2)

def is_instance_exist(instance_id,ec2):
    '''
    this function will check existance of an instance
    '''
    try:
        instance = ec2.describe_instances(
            InstanceIds = [instance_id]
        )
        return True
    except Exception, e:
        return False

def describe_cloudwatch_alarms(cw,ec2):
    '''
    This function will describe alarms where the state Value is INSUFFICIENT_DATA
    and delete the alarm if the instance of the alarm is not exist
    '''
    unused_alarms = []
    insufficient_alarms = []
    try:
        insufficient_alarms = cw.describe_alarms(
            StateValue='INSUFFICIENT_DATA'
        )
    except Exception, e:
        print("there is no alarm with state INSUFFICIENT_DATA")

    insufficient_alarms = insufficient_alarms['MetricAlarms']
    for alarm in insufficient_alarms:
        if alarm['Namespace'] == "AWS/EC2":
            instance_id = alarm['Dimensions'][0]['Value']
            if not is_instance_exist(instance_id,ec2):
                alarm_name = alarm['AlarmName']
                unused_alarms.append(alarm_name)

    delete_cloudwatch_alarms(unused_alarms)

def delete_cloudwatch_alarms(cw,alarms):
    try:
        cw.delete_alarms(AlarmNames=[alarms])
        print("deleted alarm:")
        for alarm in alarms:
            print(alarm)
    except Exception, e:
        print(e)