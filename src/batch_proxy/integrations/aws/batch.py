import boto3


class BatchService:
    _client = boto3.client("batch")

    @classmethod
    def submit(cls, job_name: str, job_queue: str, job_definition: str, environment_variables: dict):
        try:
            resp = cls._client.submit_job(
                jobName=job_name,
                jobQueue=job_queue,
                jobDefinition=job_definition,
                containerOverrides={"environment": [environment_variables]},
            )
            job_id = resp["jobId"]
            
            return job_id
        except Exception as e:
            msg = str(e)
            raise BatchSubmitError(job_name, job_queue, job_definition, msg)

from .exceptions import BatchSubmitError  # noqa
