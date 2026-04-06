import json


def handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "test": "anomaly",
            "ok": True,
            "request_id": request_id,
            "level": (event or {}).get("level", "INFO"),
        }),
    }
