import json


def handler(event, context):
    method = event.get("httpMethod", "GET") if isinstance(event, dict) else "GET"
    path = event.get("path", "/") if isinstance(event, dict) else "/"
    query = event.get("queryStringParameters") if isinstance(event, dict) else None
    body = event.get("body") if isinstance(event, dict) else None
    request_id = getattr(context, "aws_request_id", None)

    payload = {
        "ok": True,
        "method": method,
        "path": path,
        "query": query,
        "body": body,
        "request_id": request_id,
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
