import json
import base64
import boto3
import pytesseract
from PIL import Image
from io import BytesIO


def decode_image(base64_string):
    image_data = base64.b64decode(base64_string)
    return Image.open(BytesIO(image_data))


def ocr_tesseract(image):
    text = pytesseract.image_to_string(image)
    confidence = 0.9  # Tesseract does not return confidence directly
    return {"text": text, "confidence": confidence}


def ocr_textract(image_bytes):
    client = boto3.client("textract")
    response = client.detect_document_text(Document={"Bytes": image_bytes})
    text = " ".join(
        [
            item["DetectedText"]
            for item in response["Blocks"]
            if item["BlockType"] == "LINE"
        ]
    )
    confidence = sum(
        [
            item["Confidence"]
            for item in response["Blocks"]
            if item["BlockType"] == "LINE"
        ]
    ) / max(len(response["Blocks"]), 1)
    return {"text": text, "confidence": confidence}


def lambda_handler(event, context):
    body = json.loads(event["body"])
    base64_image = body.get("image")

    if not base64_image:
        return {"statusCode": 400, "body": json.dumps({"error": "No image provided"})}

    image = decode_image(base64_image)
    image_bytes = base64.b64decode(base64_image)

    result_tesseract = ocr_tesseract(image)
    result_textract = ocr_textract(image_bytes)

    best_result = (
        result_tesseract
        if result_tesseract["confidence"] > result_textract["confidence"]
        else result_textract
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"text": best_result["text"], "confidence": best_result["confidence"]}
        ),
    }
