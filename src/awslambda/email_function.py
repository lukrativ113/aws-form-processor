import boto3
import json
import os
from botocore.exceptions import ClientError

ses = boto3.client('ses')

SENDER_EMAIL = os.getenv('SENDER_EMAIL')
TO_EMAIL = os.getenv('TO_EMAIL')

def _get_payload(body=None, status=200):
    return {
        "isBase64Encoded": False,
        "statusCode": status,
        "headers": {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        "body": json.dumps(body)
    }

def get_success(message):
    body = {'message': message}
    return _get_payload(body=body, status=200)

def get_error(message, status=500):
    body = {'errors': [message]}
    return _get_payload(body=body, status=status)

def create_message(event_body):
    return f"""
    {event_body.get('name')} has requested information about the following services:
    {event_body.get('services')}

    Additional information:
    email: {event_body.get('email')}
    phone: {event_body.get('phone') or 'Not provided'}
    Additional information: {event_body.get('moreinfo') or 'None'}
    """

def send_mail(from_email, message_body, body_charset='utf-8'):
    email_args = {
        'Source': SENDER_EMAIL,
        'Destination': {
            'ToAddresses': [
                TO_EMAIL
            ]
        },
        'Message': {
            'Subject': {
                'Data': 'New request from BattlehornCoach.com',
                'Charset': 'utf-8'
            },
            'Body': {
                'Text': {
                    'Data': message_body,
                    'Charset': body_charset
                }
            }
        },
        'ReplyToAddresses': [
            from_email
        ]

    }
    return ses.send_email(**email_args)

def lambda_handler(event, context):
    print(event)
    if 'body' not in event:
        raise ValueError('event does not contain the correct body')

    event_body = json.loads(event.get('body'))
    from_email = event_body.get('email')
    message = create_message(event_body)

    try:
        ses_response = send_mail(from_email, message)
        message_id = ses_response.get('MessageId')
        response = get_success(f'Message successfully sent!  ID: {message_id}')
    except ClientError as ce:
        print(ce.response)
        response = get_error(ce.response.get('Error'))

    return response

    