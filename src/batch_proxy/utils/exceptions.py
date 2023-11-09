class MissingKeyError(Exception):
    def __init__(self, key: str):
        self.key = key

    def __str__(self):
        return f"Missing key='{self.key}'."


class InvalidKeyError(Exception):
    def __init__(self, key: str):
        self.key = key

    def __str__(self):
        return f"Invalid key='{self.key}'."


class MissingValueError(Exception):
    def __init__(self, key: str):
        self.key = key

    def __str__(self):
        return f"Value corresponds to key='{self.key}' cannot be empty."


class InvalidValueError(Exception):
    def __init__(self, key: str, value: str, msg: str = ""):
        self.key = key
        self.value = value
        self.msg = msg

    def __str__(self):
        return f"Invalid in value='{self.value}' in key={self.key}. {self.msg}"


class MissingEnvVarError(Exception):
    def __init__(self, var_name: str):
        self.var_name = var_name

    def __str__(self):
        return f"Missing environment variable. Name={self.var_name}"
