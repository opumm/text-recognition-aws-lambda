# Instruction


1. Time is of the essence, you have 1 hour.
2. You will have to deploy a Text Recognition service to AWS Lambda. To break down the task:
	a. Proxy lambda service: gets triggered via HTTP Request from attached API Gateway with base64 encoded image.
      Does a basic validation like existence check and triggers Text Recognition lambda with given base64 input.
	b. Text recognition lambda service: should have two distinct Text Recognition methods which detects text out of given base64 encoded image.
       Does a confidence comparison on both results and returns most favourable.
		 i. The lambda handler should be able conduct any need of pre-processing.
4. Deploy the Lambda function to AWS using either Terraform/AWS SAM/Serverless.
5.  Any use of material is allowed (official documentations, medium articles, youtube videos etc)





## Checking the Platform Version and Python Version

To check the platform version and Python version used in AWS Lambda, run the following commands:

```sh
aws lambda get-function --function-name TextRecognitionLambda --query 'Configuration.Architectures' --output text --profile opu

docker run --rm --platform=linux/amd64 --entrypoint python3 public.ecr.aws/lambda/python:3.9-x86_64 --version
```

---

## Building Tesseract for Lambda

To build Tesseract for AWS Lambda, execute the following:

```sh
docker build --platform=linux/amd64 -t tesseract .
mkdir build
docker run --rm --platform=linux/amd64 -v $PWD/build:/tmp/build tesseract sh /tmp/build_tesseract.sh
```

---

## Building the Lambda Package

To build the Lambda package inside a clean **Amazon Linux 2** container, use the following command:

```sh
docker run --rm --platform=linux/amd64 --entrypoint /bin/bash -v "$PWD:/lambda-build" -w /lambda-build public.ecr.aws/lambda/python:3.9-x86_64 -c "
    yum install -y gcc zip libjpeg-devel zlib-devel python3-devel &&
    pip3 install --upgrade pip &&
    pip3 install -r requirements.txt --target /lambda-build/package &&
    cd /lambda-build/package &&
    zip -r9 /lambda-build/lambda-package.zip . &&
    cd .. &&
    zip -g /lambda-build/lambda-package.zip proxy.py &&
    zip -g /lambda-build/lambda-package.zip text_recognition.py"
```

---

## Verifying Files in the Package

After building the package, verify the contents using:

```sh
unzip -l lambda-package.zip
```

---

## Deploying with Terraform

Apply Terraform configuration to deploy the Lambda function:

```sh
terraform apply -auto-approve
```


