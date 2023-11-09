from abc import ABC, abstractmethod
from typing import List, Dict
from os import environ


class AbstractValidator(ABC):
    @abstractmethod
    def validate(self, payload: Dict[str, str]):
        pass

    @abstractmethod
    def _validate(self, payload: Dict[str, str], expected_keys: List[str]):
        pass


class BaseValidator(AbstractValidator):
    def validate(self, payload: Dict[str, str]):
        raise NotImplementedError

    def _validate(self, payload: Dict[str, str], expected_keys: List[str]):
        raise NotImplementedError


class EnvVarValidator(BaseValidator):
    _expected_env_vars = ["JOB_QUEUE", "JOB_DEFINITION"]

    @classmethod
    def validate(cls):
        try:
            for env_var in cls._expected_env_vars:
                environ[env_var]
        except KeyError:
            raise MissingEnvVarError(env_var)


from .exceptions import (
    MissingEnvVarError,
)  # noqa
