import json

from aws_lambda_powertools import Logger, Tracer
from calculators.operations import aggregate
from validators.payload import extract_numbers

logger = Logger(service="data-processor")
tracer = Tracer(service="data-processor")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    items, numbers, operation = extract_numbers(event)
    result = aggregate(numbers, operation)
    request_id = getattr(context, "aws_request_id", None)

    payload = {
        "operation": operation,
        "received_items": len(items),
        "numeric_items": len(numbers),
        "result": result,
        "request_id": request_id,
    }
    logger.info("Processed payload", extra={"operation": operation, "result": result})
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
