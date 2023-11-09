import sys
import json
import time
import os

def main():
    # Read the payload from the standard input (stdin)
    try:
        payload = sys.stdin.read()
        print("Received Payload:", payload)
        time.sleep(10)
        print("Completed Sleeping for 10 sec")
        data = json.loads(payload)
        print("Parsed Payload:", json.dumps(data, indent=4))
    except Exception as e:
        print(e)
    finally:
        print("Completed")
        for k,v in os.environ.items():
            print(f"{k}:{v}")

if __name__ == '__main__':
    main()
