import json
import os

from aws_lambda_powertools import Logger, Tracer
from shared.common import build_greeting  # pyright: ignore[reportMissingImports]

logger = Logger(service="hello-world")
tracer = Tracer(service="hello-world")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    name = event.get("name") if isinstance(event, dict) else None
    request_id = getattr(context, "aws_request_id", None)
    payload = {
        "message": build_greeting(name),
        "function": os.environ.get("AWS_LAMBDA_FUNCTION_NAME", "hello-world"),
        "request_id": request_id,
        "input_type": type(event).__name__,
    }
    logger.info("Returning hello-world response")
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
