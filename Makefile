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
	$(or $(shell grep -m1 'aws_access_key = "' my.auto.tfvars | cut -d'"' -f2),\
	     $(shell stty -echo; read -p "AWS_ACCESS_KEY_ID: " input; \
	             stty echo; echo $$input)))
endif
ifeq ($(strip $(AWS_SECRET_ACCESS_KEY)),)
export AWS_SECRET_ACCESS_KEY=$(strip \
	$(or $(shell grep -m1 'aws_secret_key = "' my.auto.tfvars | cut -d'"' -f2),\
	     $(shell stty -echo; read -p "AWS_SECRET_ACCESS_KEY: " input; \
	             stty echo; echo $$input)))
endif
ifeq ($(strip $(AWS_DEFAULT_REGION)),)
export AWS_DEFAULT_REGION=$(strip \
	$(shell grep -m1 'region = "' main.tf | cut -d'"' -f2))
endif
endif




############################
# Terraform state commands #
############################

# Bootstraps AWS S3 bucket for storing Terraform state via AWS CloudFormation.
#
# See `provision-tfstate-s3.aws.yml` for the detailed spec.
#
# Usage:
#	make tfstate.s3 [state=(present|view|absent)] [bucket=<name>]

tfstate.s3:
ifeq ($(or $(state),present),present)
	aws cloudformation create-stack --stack-name tfstate-$(CLUSTER) \
		--template-body file://provision-tfstate-s3.aws.yml \
		--parameters ParameterKey=BucketName,ParameterValue=$(strip \
			$(or $(bucket),\
			     $(shell grep -m1 'bucket = "' main.tf | cut -d'"' -f2)))
else
ifeq ($(state),absent)
	aws cloudformation delete-stack --stack-name tfstate-$(CLUSTER)
else
	aws cloudformation describe-stack-events --stack-name tfstate-$(CLUSTER)
endif
endif




##################
# .PHONY section #
##################

.PHONY: tfstate.s3
