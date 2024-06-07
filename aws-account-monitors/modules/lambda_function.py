import os
import json
import boto3
import urllib3

http = urllib3.PoolManager()

def lambda_handler(event, context):

    # Retrieve the Teams Webhook URL from the environment variable
    url = os.getenv('TEAMS_WEBHOOK_URL')

    # Lets see if this came from an SNS
    try:
        message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = message.get('AlarmName', None)
        if not alarm_name:
            # lets see if there is a URL passed in for the teams room
            topic_arn = event['Records'][0]['Sns']['TopicArn']
            sns_client = boto3.client('sns')
            response = sns_client.list_tags_for_resource(ResourceArn=topic_arn)
            tags = response['Tags']
            for tag in tags:
                if tag['Key'] == 'teams_url':
                    url = tag['Value']
                    break
    except (KeyError, IndexError, json.JSONDecodeError):
        message = None

    # If it is stillnot set we can use a default value here 
    if not url:
        # raise ValueError('Could not find teams_url tag in SNS topic tags')
        url = "https://compnayname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"

    if not url:
        raise ValueError("The TEAMS_WEBHOOK_URL environment variable is not set")
    
    # Now lets work on the message to send.  We will start blank
    message = None
    
    # Extract the message from the event
    if 'Records' in event and len(event['Records']) > 0:
        # Assume it's an SNS message
        sns_message = event['Records'][0]['Sns']['Message']
        sns_subject = event['Records'][0]['Sns']['Subject']
        if 'AlarmName' in sns_message:
            subject = sns_message['AlarmName']
            message = sns_message['AlarmDescription'] + "\n" + sns_message['NewStateReason'] + "\n"
        else:
            message = sns_message
            subject = sns_subject
    elif 'message' in event and len(event['message']) > 0:
        message = event['message']
    elif len(event) > 0 :
        message = event
    else:
        # Nothing to get so say that
        message = 'No message provided'
    
    # Create the payload for the Teams message
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "0072C6",
        "summary": subject,
        "sections": [{
            "activityTitle": subject,
            "activitySubtitle": "",
            "activityImage": "",
            "text": message
        }]
    }

    # Send the payload to Teams
    encoded_msg = json.dumps(payload).encode("utf-8")
    resp = http.request("POST", url, body=encoded_msg)

    # Uncomment this for debugging :
    #print(
    #    {
    #        "url": url,
    #        "message": message,
    #        "status_code": resp.status,
    #        "response": resp.data,
    #    }
    #)

