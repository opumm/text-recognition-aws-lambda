import json
import requests
import base64

# API Gateway Endpoint from Terraform output
API_ENDPOINT = "https://jtn809el91.execute-api.us-east-1.amazonaws.com/recognize"


# Convert an image file to base64
def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")


# Replace with your actual image file
image_base64 = encode_image("hello_world.png")

# Prepare API request payload
payload = {"image": image_base64}

# Send POST request to API Gateway
response = requests.post(
    API_ENDPOINT, headers={"Content-Type": "application/json"}, data=json.dumps(payload)
)

# Print the response
print("Status Code:", response.status_code)
print("Response:", response.json())
