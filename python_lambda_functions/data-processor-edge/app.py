import json

from aws_lambda_powertools import Logger, Tracer

logger = Logger(service="data-processor-edge")
tracer = Tracer(service="data-processor-edge")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    items = event.get("items", []) if isinstance(event, dict) else []
    operation = event.get("operation", "sum") if isinstance(event, dict) else "sum"
    numbers = [x for x in items if isinstance(x, (int, float)) and not isinstance(x, bool)]
    result = sum(numbers) if operation == "sum" else len(numbers)
    request_id = getattr(context, "aws_request_id", None)

    payload = {
        "operation": operation,
        "received_items": len(items),
        "numeric_items": len(numbers),
        "result": result,
        "request_id": request_id,
    }
    logger.info("Processed edge payload", extra={"operation": operation, "result": result})
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
