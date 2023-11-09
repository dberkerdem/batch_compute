import requests
from requests.exceptions import RequestException 
from json import JSONDecodeError

base_url = "<YOUR-BASE-URL>"
endpoint_url = f"{base_url}/<YOUR-API-ENDPOINT>"

headers = {
    "X-API-Secret": "<YOUR-API-SECRET>"
}

payload = {"key": "value"}

try:
    # Send the request
    response = requests.post(endpoint_url, headers=headers, json=payload)
    print(f"{response.status_code=}")
    response.raise_for_status()
except RequestException as e:
    print(f"An error occurred: {e}")
finally:
    try:
        resp = response.json()
    except JSONDecodeError:
        resp = response.text
    finally:        
        print(resp)
