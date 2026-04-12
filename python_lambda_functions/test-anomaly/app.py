import json

from aws_lambda_powertools import Logger, Tracer

logger = Logger(service="test-anomaly")
tracer = Tracer(service="test-anomaly")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
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
