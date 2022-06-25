Contribution Guide
==================

1. [Prerequisites](#prerequisites)
2. [Operations](#operations)
3. [Code style](#code-style)




## Prerequisites

Before performing any [Terraform] operations or running [`Makefile`] commands, the following credentials should be set in you terminal as environment variables:
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to authorize operations on [AWS].
- `AWS_SSE_CUSTOMER_KEY` to [encrypt Terraform state][1] stored on [S3 bucket][2].
- `HCLOUD_TOKEN` to authorize operations on [Hetzner Cloud].

> __TIP__: For simplicity, to play around, you may define the following `.my.env` file in the project root: 
> ```
> export AWS_ACCESS_KEY_ID=aws-access-key-value
> export AWS_SECRET_ACCESS_KEY=aws-secret-key-value
> export AWS_SSE_CUSTOMER_KEY=base64-encoded-256-bits-key
> export HCLOUD_TOKEN=hcloud-token-value
> ```
> And load the desired environment by simply running `source .my.env`. 
> 
> __WARNING:__ __DON'T do this for production workloads__, instead load these credentials from secure store like an OS keychain or a hardware token. 




## Operations


### Provision [Terraform] state

Before running any [Terraform] operations, you should provision an [S3 bucket][2] for storing its state.

The provisioning is done via [AWS CloudFormation] tool (see the [spec](provision-tfstate-s3.aws.yml)), and the [`Makefile`] provides the `tfstate.s3` command as a shortcut for running it.
```shell
make tfstate.s3               # to provision S3 bucket and DynamoDB table
make tfstate.s3 state=view    # to track the creation process via AWS events
make tfstate.s3 state=absent  # to remove remote Terraform state completely
```




## Code style


### Secrets management

Storing [Terraform] state remotely and encrypted in an [S3 bucket][2] allows to generate infrastructure secrets and credentials on-fly and store them in a [Terraform] state without being exposed.




[`Makefile`]: Makefile
[AWS]: https://aws.amazon.com
[AWS CloudFormation]: https://docs.aws.amazon.com/cloudformation/index.html
[Hetzner Cloud]: https://www.hetzner.com/cloud
[Terraform]: https://www.terraform.io

[1]: https://www.terraform.io/language/settings/backends/s3#sse_customer_key
[2]: https://www.terraform.io/language/settings/backends/s3
