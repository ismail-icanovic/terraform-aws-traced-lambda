import json

from aws_lambda_powertools import Logger, Tracer

logger = Logger(service="test-basic")
tracer = Tracer(service="test-basic")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    event_type = type(event).__name__
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "test": "basic",
            "ok": True,
            "request_id": request_id,
            "event_type": event_type,
        }),
    }
