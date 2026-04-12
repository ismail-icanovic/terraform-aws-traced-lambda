def build_http_payload(http_context, request_id):
    return {
        "ok": True,
        "method": http_context["method"],
        "path": http_context["path"],
        "query": http_context["query"],
        "body": http_context["body"],
        "request_id": request_id,
    }
