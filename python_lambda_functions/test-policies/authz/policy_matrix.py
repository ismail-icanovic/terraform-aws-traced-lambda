ALLOWED_ACTIONS = {
    "read": ["viewer", "editor", "admin"],
    "write": ["editor", "admin"],
    "delete": ["admin"],
}


def evaluate(action, role):
    allowed_roles = ALLOWED_ACTIONS.get(action, [])
    return role in allowed_roles, allowed_roles
