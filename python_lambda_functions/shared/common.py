import os


def build_greeting(name):
    return f"Hello {name or 'world'}"


def runtime_metadata(context):
    return {
        "function": os.environ.get("AWS_LAMBDA_FUNCTION_NAME", "unknown"),
        "request_id": getattr(context, "aws_request_id", None),
    }
