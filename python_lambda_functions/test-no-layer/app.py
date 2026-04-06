import json


def handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    event_type = type(event).__name__
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "test": "no-layer",
            "ok": True,
            "request_id": request_id,
            "event_type": event_type,
        }),
    }
