def extract_numbers(event):
    items = event.get("items", []) if isinstance(event, dict) else []
    operation = event.get("operation", "sum") if isinstance(event, dict) else "sum"
    numbers = [x for x in items if isinstance(x, (int, float)) and not isinstance(x, bool)]
    return items, numbers, operation
