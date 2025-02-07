import json
import boto3
import base64


def lambda_handler(event, context):
    # Validate the input
    body = json.loads(event["body"])
    if "image_base64" not in body:
        return {"statusCode": 400, "body": json.dumps("Image data not provided")}

    # Get the base64 encoded image
    image_base64 = body["image_base64"]

    # Trigger the Text Recognition Lambda function
    client = boto3.client("lambda")
    response = client.invoke(
        FunctionName="TextRecognitionLambda",
        InvocationType="RequestResponse",
        Payload=json.dumps({"image_base64": image_base64}),
    )

    # Parse the response and return
    result = json.loads(response["Payload"].read().decode("utf-8"))
    return {"statusCode": 200, "body": json.dumps(result)}
