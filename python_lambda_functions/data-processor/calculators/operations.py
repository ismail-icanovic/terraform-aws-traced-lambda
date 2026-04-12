def aggregate(numbers, operation):
    if operation == "count":
        return len(numbers)

    if operation == "avg":
        return sum(numbers) / len(numbers) if numbers else 0

    return sum(numbers)
