class BatchSubmitError(Exception):
    def __init__(self, job_name: str, job_queue: str, job_definition: str, msg: str):
        self.msg = msg
        self.job_name = job_name
        self.job_queue = job_queue
        self.job_definition = job_definition

    def __str__(self):
        return f"Unable to submit JobName={self.job_name}, JobQueue={self.job_queue}, JobDefinition={self.job_definition}. {self.msg}"
