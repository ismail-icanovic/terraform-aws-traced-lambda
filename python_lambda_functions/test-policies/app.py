import json


def handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    action = (event or {}).get("action", "read")
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "test": "policies",
            "ok": True,
            "request_id": request_id,
            "action": action,
        }),
    }
