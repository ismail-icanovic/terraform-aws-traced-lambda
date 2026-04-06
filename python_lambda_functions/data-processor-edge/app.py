import json


def handler(event, context):
    items = event.get("items", []) if isinstance(event, dict) else []
    operation = event.get("operation", "sum") if isinstance(event, dict) else "sum"

















    }        "body": json.dumps(payload),        "headers": {"Content-Type": "application/json"},        "statusCode": 200,    return {    }        "request_id": request_id,        "result": result,        "numeric_items": len(numbers),        "received_items": len(items),        "operation": operation,    payload = {    request_id = getattr(context, "aws_request_id", None)    result = sum(numbers) if operation == "sum" else len(numbers)    numbers = [x for x in items if isinstance(x, (int, float)) and not isinstance(x, bool)]
