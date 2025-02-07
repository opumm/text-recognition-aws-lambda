1. Time is of the essence, you have 1 hour.
2. You will have to deploy a Text Recognition service to AWS Lambda. To break down the task:
	a. Proxy lambda service: gets triggered via HTTP Request from attached API Gateway with base64 encoded image.
      Does a basic validation like existence check and triggers Text Recognition lambda with given base64 input.
	b. Text recognition lambda service: should have two distinct Text Recognition methods which detects text out of given base64 encoded image.
       Does a confidence comparison on both results and returns most favourable.
		 i. The lambda handler should be able conduct any need of pre-processing.
4. Deploy the Lambda function to AWS using either Terraform/AWS SAM/Serverless.
5.  Any use of material is allowed (official documentations, medium articles, youtube videos etc)
