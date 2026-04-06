import json


















    }        "body": json.dumps(payload),        "headers": {"Content-Type": "application/json"},        "statusCode": 200,    return {    }        "input_type": type(event).__name__,        "request_id": request_id,        "function": os.environ.get("AWS_LAMBDA_FUNCTION_NAME", "hello-world-edge"),        "message": f"Hello {name or 'world'}",    payload = {    request_id = getattr(context, "aws_request_id", None)    name = event.get("name") if isinstance(event, dict) else Nonedef handler(event, context):import os
