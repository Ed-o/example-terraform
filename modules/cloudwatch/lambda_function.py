import urllib3
import json
import boto3

http = urllib3.PoolManager()

def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])

    # Uncomment this for debugging :
    # print(
    #    {
    #        "message": message,
    #    }
    #)

    subject = message['AlarmName']
    body = message['AlarmDescription'] + "\n" + message['NewStateReason'] + "\n"

    # Extract the Teams webhook URL from the SNS topic tags
    topic_arn = event['Records'][0]['Sns']['TopicArn']
    sns_client = boto3.client('sns')
    response = sns_client.list_tags_for_resource(ResourceArn=topic_arn)
    tags = response['Tags']
    url = None
    for tag in tags:
        if tag['Key'] == 'teams_url':
            url = tag['Value']
            break
    if url is None:
        # raise ValueError('Could not find teams_url tag in SNS topic tags')
        url = "https://compnayname.webhook.office.com/webhookb2/987654321/IncomingWebhook/987654321"

    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "0072C6",
        "summary": subject,
        "sections": [{
            "activityTitle": subject,
            "activitySubtitle": "",
            "activityImage": "",
            "text": body
        }]
    }

    # Send the payload to Teams
    encoded_msg = json.dumps(payload).encode("utf-8")
    resp = http.request("POST", url, body=encoded_msg)

    # Uncomment this for debugging :
    #print(
    #    {
    #        "url": url,
    #        "message": event["Records"][0]["Sns"]["Message"],
    #        "status_code": resp.status,
    #        "response": resp.data,
    #    }
    #)

