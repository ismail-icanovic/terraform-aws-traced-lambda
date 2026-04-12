import json

from aws_lambda_powertools import Logger, Tracer

logger = Logger(service="api-handler-edge")
tracer = Tracer(service="api-handler-edge")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
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
    logger.info("Returning api-handler-edge response", extra={"path": path, "method": method})
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
