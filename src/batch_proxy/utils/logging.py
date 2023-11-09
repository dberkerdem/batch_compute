import logging
import os


def get_logger(
    name: str, id: str = None, export: bool = False, log_file: str = None
) -> logging.Logger:
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    if not logger.handlers:
        ch = logging.StreamHandler()
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter(
            f"%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        ch.setFormatter(formatter)
        logger.addHandler(ch)

        if export:
            if not id:
                os.makedirs("/app/logs/", exist_ok=True)
            else:
                os.makedirs(f"/app/logs/{id}", exist_ok=True)
                id += "/"
            fh = logging.FileHandler(log_file.format(id))
            fh.setLevel(logging.DEBUG)
            fh.setFormatter(formatter)
            logger.addHandler(fh)

    return logger
