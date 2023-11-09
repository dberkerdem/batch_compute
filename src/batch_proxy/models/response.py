from pydantic import BaseModel, Field, validator
from typing import Any, Union


class BaseResponseModel(BaseModel):
    statusCode: Union[int, str] = Field(..., description="Status code")
    body: Union[str, dict] = Field(default=None, description="Body of the response")

    @validator("statusCode", pre=True)
    def validate_status(cls, v):
        if isinstance(v, str):
            if not v.isdigit():
                raise ValueError("status must be a number")
            v = int(v)  # Convert string digits to int
        if isinstance(v, int) and (100 <= v <= 599):
            return v
        else:
            raise ValueError("status must be a valid HTTP status code")


class Response2xx(BaseResponseModel):
    @validator("statusCode")
    def specific_status_validation(cls, v):
        if 200 <= v <= 299:
            return v
        raise ValueError("statusCode must be in range 2xx")


class Response4xx(BaseResponseModel):
    @validator("statusCode")
    def specific_status_validation(cls, v):
        if 400 <= v <= 499:
            return v
        raise ValueError("statusCode must be in range 4xx")


class Response5xx(BaseResponseModel):
    @validator("statusCode")
    def specific_status_validation(cls, v):
        if 500 <= v <= 599:
            return v
        raise ValueError("statusCode must be in range 5xx")
