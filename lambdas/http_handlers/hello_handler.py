import json
def handler(event, ctx):
    return {
        'statusCode': 200,
        'body': json.dumps('Hello World!')
    }
