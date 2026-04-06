import json
import os


def handler(event, context):
    name = event.get("name") if isinstance(event, dict) else None
    request_id = getattr(context, "aws_request_id", None)
    payload = {
        "message": f"Hello {name or 'world'}",
        "function": os.environ.get("AWS_LAMBDA_FUNCTION_NAME", "hello-world"),
        "request_id": request_id,
        "input_type": type(event).__name__,
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
