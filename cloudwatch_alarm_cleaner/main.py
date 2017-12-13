import boto3
import sys
import time

def lambda_handler(event, context):
    cw = boto3.client('cloudwatch')
    ec2 = boto3.client('ec2')
    describe_alarms(cw,ec2)

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

def describe_alarms(cw,ec2):
    '''
    This function will describe alarms where the state Value is INSUFFICIENT_DATA
    and delete the alarm if the instance of the alarm is not exist
    '''
    unused_alarms = []
    delete_alarms = []
    try:
        unused_alarms = cw.describe_alarms(
            StateValue='INSUFFICIENT_DATA'
        )
    except Exception, e:
        print("ther is no alarm with state INSUFFICIENT_DATA")

    unused_alarms = unused_alarms['MetricAlarms']
    for alarm in unused_alarms:
        if alarm['Namespace'] == "AWS/EC2":
            instance_id = alarm['Dimensions'][0]['Value']
            if not is_instance_exist(instance_id,ec2):
                alarm_name = alarm['AlarmName']
                delete_alarms.append(alarm_name)
    try:
        cw.delete_alarms(AlarmNames=[delete_alarms])
        print("deleted alarm:")
        for alarm in delete_alarms:
            print(alarm)
    except Exception, e:
        print(e)