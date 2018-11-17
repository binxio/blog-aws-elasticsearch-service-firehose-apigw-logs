.PHONY: help init clean validate mock create delete info deploy
.DEFAULT_GOAL := help
environment = "example"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

create: ## create env
	@sceptre launch-env $(environment)

delete: ## delete env
	@sceptre delete-env $(environment)

info: ## describe resources
	@sceptre describe-stack-outputs $(environment) elasticsearch

merge-lambda: ## merge lambda in api gateway
	aws-cfn-update \
		lambda-inline-code \
		--resource ProcessorFunction \
		--file lambdas/processors/decode_cw_log_processor.py \
		templates/elasticsearch.yaml

	aws-cfn-update \
		lambda-inline-code \
		--resource ErrorFunction \
		--file lambdas/http_handlers/error_handler.py \
		templates/elasticsearch.yaml

	aws-cfn-update \
		lambda-inline-code \
		--resource HelloFunction \
		--file lambdas/http_handlers/hello_handler.py \
		templates/elasticsearch.yaml

merge-swagger: ## merge swagger in api gateway
	@aws-cfn-update \
		rest-api-body  \
		--resource RestAPI \
		--open-api-specification swagger/swagger.yaml \
		--api-gateway-extensions swagger/aws-extensions.yaml \
		--add-new-version \
		templates/elasticsearch.yaml

hello: ## call the hello function
	@curl https://`sceptre --output json describe-stack-resources example elasticsearch | jq -r '.[] | select(.LogicalResourceId=="RestAPIv1") | .PhysicalResourceId'`.execute-api.eu-west-1.amazonaws.com/dev/hello

error: ## call the hello function
	@curl https://`sceptre --output json describe-stack-resources example elasticsearch | jq -r '.[] | select(.LogicalResourceId=="RestAPIv1") | .PhysicalResourceId'`.execute-api.eu-west-1.amazonaws.com/dev/error