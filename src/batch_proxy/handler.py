import json
from os import environ
from utils import EnvVarValidator, get_logger, MissingEnvVarError
from models import Response2xx, Response4xx, Response5xx
from integrations.aws import BatchService, BatchSubmitError

def handler(event, context):
    logger = get_logger(__name__)
    try:
        payload = json.loads(event["body"])
        # Validate Environment
        EnvVarValidator.validate()
        logger.info("Successfully validated environment variables.")

        # Submit job to AWS Batch
        data = {
            "job_name": "batch-job",
            "job_queue": environ["JOB_QUEUE"],
            "job_definition": environ["JOB_DEFINITION"],
            "environment_variables": {"name": "JOB_INPUT", "value": str(payload)},
        }

        job_id = BatchService.submit(**data)
        logger.info("Successfully submitted job to AWS Batch.")

        response = Response2xx(statusCode=200, body=json.dumps({"job_id": job_id}))
        return response.dict()
    except (json.JSONDecodeError, TypeError, KeyError) as e:
        logger.exception("Invalid payload.")

        response = Response5xx(statusCode=400, body=f"Invalid payload.")
        return response.dict()
    except BatchSubmitError as e:
        logger.exception("Unable to submit job.")

        response = Response5xx(statusCode=500, body=f"Internal Server Error.")
        return response.dict()
    except MissingEnvVarError as e:
        logger.exception("Missing environment variable.")

        response = Response5xx(statusCode=500, body=f"Internal Server Error.")
        return response.dict()
    except Exception as e:
        logger.exception("Something went wrong.")

        response = Response4xx(statusCode=400, body=f"Invalid Payload.")
        return response.dict()
