def parse_http_context(event):
    if not isinstance(event, dict):
        return {
            "method": "GET",
            "path": "/",
            "query": None,
            "body": None,
        }

    return {
        "method": event.get("httpMethod", "GET"),
        "path": event.get("path", "/"),
        "query": event.get("queryStringParameters"),
        "body": event.get("body"),
    }
