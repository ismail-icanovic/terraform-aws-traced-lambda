import json

from aws_lambda_powertools import Logger, Tracer
from authz.policy_matrix import evaluate

logger = Logger(service="test-policies")
tracer = Tracer(service="test-policies")


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    action = (event or {}).get("action", "read")
    role = (event or {}).get("role", "viewer")
    allowed, allowed_roles = evaluate(action, role)
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "test": "policies",
            "ok": True,
            "request_id": request_id,
            "action": action,
            "role": role,
            "authorized": allowed,
            "allowed_roles": allowed_roles,
        }),
    }
