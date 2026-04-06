import json


def handler(event, context):
    method = event.get("httpMethod", "GET") if isinstance(event, dict) else "GET"
    path = event.get("path", "/") if isinstance(event, dict) else "/"


















    }        "body": json.dumps(payload),        "headers": {"Content-Type": "application/json"},        "statusCode": 200,    return {    }        "request_id": request_id,        "body": body,        "query": query,        "path": path,        "method": method,        "ok": True,    payload = {    request_id = getattr(context, "aws_request_id", None)    body = event.get("body") if isinstance(event, dict) else None    query = event.get("queryStringParameters") if isinstance(event, dict) else None
