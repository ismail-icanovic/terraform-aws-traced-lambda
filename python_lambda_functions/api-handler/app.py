import json

from aws_lambda_powertools import Logger, Tracer
from responses.builders import build_http_payload
from routers.http_context import parse_http_context

logger = Logger(service="api-handler")
tracer = Tracer(service="api-handler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    http_context = parse_http_context(event)
    request_id = getattr(context, "aws_request_id", None)

    payload = build_http_payload(http_context, request_id)
    logger.info(
        "Returning api-handler response",
        extra={"path": http_context["path"], "method": http_context["method"]},
    )
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
