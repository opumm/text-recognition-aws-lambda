import json
import base64
import boto3
import pytesseract
from PIL import Image
from io import BytesIO

import os

# Detect if running in AWS Lambda
if os.getenv("AWS_EXECUTION_ENV"):
    BASE_DIR = "/var/task"
else:
    BASE_DIR = os.getcwd()  # Use current working directory for local testing

# Set Tesseract Paths
os.environ["LD_LIBRARY_PATH"] = f"{BASE_DIR}/lib"
os.environ["TESSDATA_PREFIX"] = f"{BASE_DIR}/tessdata"
pytesseract.pytesseract.tesseract_cmd = f"{BASE_DIR}/tesseract"


def decode_image(base64_string):
    image_data = base64.b64decode(base64_string)
    return Image.open(BytesIO(image_data))


def ocr_tesseract(image):
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)

    text = " ".join(data["text"]).strip()

    confidence_values = [float(conf) for conf in data["conf"] if conf != "-1"]
    confidence = (
        sum(confidence_values) / max(len(confidence_values), 1)
        if confidence_values
        else 0.0
    )

    return {"text": text, "model": "Tesseract OCR", "confidence": confidence}


def ocr_textract(image_bytes):
    client = boto3.client("textract")
    response = client.detect_document_text(Document={"Bytes": image_bytes})

    text = " ".join(
        [
            item.get("Text", "")
            for item in response.get("Blocks", [])
            if item.get("BlockType") == "LINE"
        ]
    )

    confidence_values = [
        item.get("Confidence", 0)
        for item in response.get("Blocks", [])
        if item.get("BlockType") == "LINE"
    ]

    confidence = sum(confidence_values) / max(len(confidence_values), 1)

    return {"text": text, "model": "AWS Textract", "confidence": confidence}


def lambda_handler(event, context):
    body = json.loads(event["body"])
    base64_image = body.get("image_base64")

    if not base64_image:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No image provided from text-recognition"}),
        }

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
            {
                "model": best_result["model"],
                "text": best_result["text"],
                "confidence": best_result["confidence"],
            }
        ),
    }
