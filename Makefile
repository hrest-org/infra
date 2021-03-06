###############################
# Common defaults/definitions #
###############################

# Checks two given strings for equality.
eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)

# Prompts for the user input with a message.
prompt = $(strip $(shell stty -echo; read -p $(1) inp; stty echo; echo $$inp))




######################
# Project parameters #
######################

CLUSTER ?= $(strip \
	$(shell grep -m1 'cluster_name = "' main.tf | cut -d'"' -f2))




##################
# AWS parameters #
##################

ifneq ($(findstring tfstate.s3,$(MAKECMDGOALS)),)
ifeq ($(strip $(AWS_ACCESS_KEY_ID)),)
export AWS_ACCESS_KEY_ID=$(strip \
	$(or $(shell grep -m1 'AWS_ACCESS_KEY_ID=' .my.env | cut -d'=' -f2),\
	     $(call prompt,"AWS_ACCESS_KEY_ID: ")))
endif
ifeq ($(strip $(AWS_SECRET_ACCESS_KEY)),)
export AWS_SECRET_ACCESS_KEY=$(strip \
	$(or $(shell grep -m1 'AWS_SECRET_ACCESS_KEY=' .my.env | cut -d'=' -f2),\
	     $(call prompt,"AWS_SECRET_ACCESS_KEY: ")))
endif
ifeq ($(strip $(AWS_DEFAULT_REGION)),)
export AWS_DEFAULT_REGION=$(strip \
	$(shell grep -m1 'region = "' main.tf | cut -d'"' -f2))
endif
endif




#####################
# System parameters #
#####################

CURRENT_OS = $(strip \
	$(if $(call eq,$(OS),Windows_NT),windows,\
	$(if $(call eq,$(shell uname -s),Darwin),macos,linux)))




############################
# Terraform state commands #
############################

# Bootstraps AWS S3 bucket for storing Terraform state via AWS CloudFormation.
#
# See `provision-tfstate-s3.aws.yml` for the detailed spec.
#
# Usage:
#	make tfstate.s3 [state=(present|view|absent)]
#	                [bucket=<name>]
#	                [dynamodb_table=<name>]

tfstate-s3-bucket = $(strip $(or $(bucket),\
	$(shell grep -m1 'bucket = "' main.tf | cut -d'"' -f2)))
tfstate-s3-dynamodb = $(strip $(or $(dynamodb_table),\
	$(shell grep -m1 'dynamodb_table = "' main.tf | cut -d'"' -f2)))

tfstate.s3:
ifeq ($(strip $(shell which aws)),)
ifeq ($(CURRENT_OS),macos)
	brew install awscli
else
	$(error "`aws` CLI tool must be installed. See: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions")
endif
endif
ifeq ($(or $(state),present),present)
	aws cloudformation create-stack --stack-name tfstate-$(CLUSTER) \
		--template-body file://provision-tfstate-s3.aws.yml \
		--parameters \
			ParameterKey=BucketName,ParameterValue=$(tfstate-s3-bucket) \
			ParameterKey=DynamoDbTable,ParameterValue=$(tfstate-s3-dynamodb)
else
ifeq ($(state),absent)
ifeq ($(call prompt,"Confirm deletion of remote Terraform state (yes/no): "),yes)
	@echo ""
ifneq ($(strip $(shell aws s3api list-object-versions \
                                 --bucket $(tfstate-s3-bucket) \
                                 --output=json --query='*[].{Key:Key}')),[])
	aws s3api delete-objects --bucket $(tfstate-s3-bucket) --delete \
		"$$(aws s3api list-object-versions --bucket $(tfstate-s3-bucket) \
		              --output=json \
		              --query='{Objects: *[].{Key:Key,VersionId:VersionId}}')" \
		--no-paginate
endif
	aws cloudformation delete-stack --stack-name tfstate-$(CLUSTER)
endif
else
	aws cloudformation describe-stack-events --stack-name tfstate-$(CLUSTER)
endif
endif




##################
# .PHONY section #
##################

.PHONY: tfstate.s3
