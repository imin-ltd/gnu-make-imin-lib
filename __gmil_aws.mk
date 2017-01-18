
GMIL_COMMANDS += aws jq date chmod

include $(__gmil_aws_root)gmil

include $(__gmil_aws_root)gmil_shell

include $(__gmil_aws_root)gmil_text

aws_iam_user_name := $(shell AWS_DEFAULT_PROFILE=default aws iam get-user | jq -r '.User.UserName')

# 1. input
# 2. bucket
# TODO assert single result
aws_s3_key_contains = $(shell aws s3api list-objects --bucket $(2) | \
  jq -r --arg input $(1) '.Contents[].Key | select(. | contains($$input))')

# 1. source
# 2. destination
define aws_s3_cp
aws s3 cp $(1) s3://$(2)
endef

# 1. content
# 2. destination
define aws_s3_put_content
aws s3 cp - s3://$(strip $(2)) <<< '$(strip $(1))'
endef

define aws_s3_get_content_handler
$(if $(call eq,$(2),0),$(1),$(if $(call eq,$(2),1),,$(error aws_s3_get_content_handler: $(2) $(1))))
endef

# 1. source
aws_s3_get_content = $(call shell_result,aws s3 cp s3://$(1) -,aws_s3_get_content_handler)

# 1. function name
# 2. function description
aws_lambda_publish_version = $(shell aws lambda publish-version --function-name $(1) --description $(2) | \
  jq -r '.Version')

# 1. key pair name
aws_ec2_key_pair_exists? = $(shell aws ec2 describe-key-pairs | \
  jq -r '.KeyPairs[].KeyName | select(. == "$(1)")')

define aws_ec2_create_key_pair_if_not_exists
result=$$(aws ec2 create-key-pair --key-name $(1)) && \
  { printf '%s' "$$result" | jq '.'; \
    printf '%s' "$$result" | jq -r '.KeyMaterial' > $(1).pem; \
    chmod 600 $(1).pem }
endef

# 1. key pair name
define aws_ec2_create_key_pair
$(if $(call aws_ec2_key_pair_exists?,$(1)), \
  , \
  $(call aws_ec2_create_key_pair_if_not_exists,$(1)))
endef

# 1. key pair name
define aws_ec2_delete_key_pair
$(if $(call aws_ec2_key_pair_exists?,$(1)), \
  aws ec2 delete-key-pair --key-name $(1))
endef

# 1. group id
# 2. protocol; currently ignored
# 3. port
# 4. cidr; currently ignored
define aws_ec2_security_group_ingress_exists?
$(shell aws ec2 describe-security-groups --group-ids $(1) | \
  jq -r --argjson port $(3) '.SecurityGroups[] | select(.IpPermissions[] | .FromPort == $$port and .ToPort == $$port) | .GroupId')
endef

# 1. group id
# 2. protocol (default tcp)
# 3. port
# 4. cidr (default 0.0.0.0/0)
define aws_ec2_authorize_security_group_ingress
$(if $(call aws_ec2_security_group_ingress_exists?,$(1),$(2),$(3),$(4)), \
  , \
  aws ec2 authorize-security-group-ingress --group-id $(1) --protocol $(if $(2),$(2),tcp) --port $(3) --cidr $(if $(4),$(4),0.0.0.0/0))
endef

# 1. group id
# 2. protocol (default tcp)
# 3. port
# 4. cidr (default 0.0.0.0/0)
define aws_ec2_revoke_security_group_ingress
$(if $(call aws_ec2_security_group_ingress_exists?,$(1),$(2),$(3),$(4)), \
  aws ec2 revoke-security-group-ingress --group-id $(1) --protocol $(if $(2),$(2),tcp) --port $(3) --cidr $(if $(4),$(4),0.0.0.0/0))
endef

# 1. template
define aws_cfn_stack_name
$(call text_title_case,$(subst cfn-template-,,$(basename $(1))))
endef

# 1. template (defaulted)
define aws_cfn_validate_template
aws cloudformation validate-template --template-body file://$(if $(1),$(1),cf-template.yml) > /dev/null
endef

# 1. stack name
aws_cfn_stack_exists? = $(shell aws cloudformation describe-stacks | \
  jq --arg stack $(1) -e '.Stacks[].StackName | select(. == $$stack)')

__gmil_now := $(shell date -Iseconds)

# 1. stack name
# 2. since
define aws_cfn_stack_events
aws cloudformation describe-stack-events --stack-name $(1) | \
  jq --arg since $(__gmil_now) '.StackEvents |= map(select(.Timestamp >= $$since) | del(.ResourceProperties))'
endef

# 1. stack name
define aws_cfn_stack_exports
aws cloudformation list-exports | \
  jq -S --arg stack $(1) '.Exports |= map(select(.ExportingStackId | contains("/" + $$stack + "/")) | del(.ExportingStackId))'
endef

# 1. export name
define aws_cfn_stack_export_value
$(shell aws cloudformation list-exports | \
  jq -r -e --arg name $(1) '.Exports[] | select(.Name == $$name) | .Value')
endef

# 1. stack param names
define aws_cfn_build_params
$(strip \
  $(foreach param_name,$(1), \
    $(if $($(param_name)), \
      ParameterKey=$(param_name)$(__gmil_comma)ParameterValue='$(subst $(__gmil_comma),\$(__gmil_comma),$($(param_name)))')))
endef

# 1. stack name
# 2. template
# 3. stack param names
# 4. stack param file
# 5. stack caps
define aws_cfn_create_stack
$(strip aws cloudformation create-stack \
  --stack-name $(1) \
  --template-body file://$(2) \
  $(if $(4),--parameters file://$(4),$(if $(3),--parameters $(call aws_cfn_build_params,$(3)))) \
  $(if $(5),--capabilities $(5)) \
  --tags \
    Key=GitCommit,Value=$(GIT_COMMIT) \
    Key=GitBranch,Value=$(GIT_BRANCH) \
    $(if $(aws_iam_user_name),Key=AwsIamUserName$(__gmil_comma)Value=$(aws_iam_user_name)) \
    Key=AwsCliProfile,Value=$(if $(AWS_DEFAULT_PROFILE),$(AWS_DEFAULT_PROFILE),default))
{ aws cloudformation wait stack-create-complete --stack-name $(1) && \
  { $(call aws_cfn_stack_events,$(1)); $(call aws_cfn_stack_exports,$(1)); exit 0; } } || \
  { $(call aws_cfn_stack_events,$(1)); exit 1; }
endef

# 1. stack name
# 2. template
# 3. stack param names
# 4. stack param file
# 5. stack caps
define aws_cfn_update_stack
$(strip aws cloudformation update-stack \
  --stack-name $(1) \
  --template-body file://$(2) \
  $(if $(4),--parameters file://$(4),$(if $(3),--parameters $(call aws_cfn_build_params,$(3)))) \
  $(if $(5),--capabilities $(5)) \
  --tags \
    Key=GitCommit,Value=$(GIT_COMMIT) \
    Key=GitBranch,Value=$(GIT_BRANCH) \
    $(if $(aws_iam_user_name),Key=AwsIamUserName$(__gmil_comma)Value=$(aws_iam_user_name)) \
    Key=AwsCliProfile,Value=$(if $(AWS_DEFAULT_PROFILE),$(AWS_DEFAULT_PROFILE),default))
{ aws cloudformation wait stack-update-complete --stack-name $(1) && \
  { $(call aws_cfn_stack_events,$(1)); $(call aws_cfn_stack_exports,$(1)); exit 0; } } || \
  { $(call aws_cfn_stack_events,$(1)); exit 1; }
endef

# 1. stack name
# 2. template
# 3. stack param names
# 4. stack param file
# 5. stack caps
define aws_cfn_sync_stack
$(if $(call aws_cfn_stack_exists?,$(1)), \
  $(call aws_cfn_update_stack,$(1),$(2),$(3),$(4),$(5)), \
  $(call aws_cfn_create_stack,$(1),$(2),$(3),$(4),$(5)))
endef

# 1. stack name
define aws_cfn_delete_stack_and_wait
aws cloudformation delete-stack --stack-name $(1)
aws cloudformation wait stack-delete-complete --stack-name $(1) || \
  { $(call aws_cfn_stack_events,$(1)); exit 1; }
endef

# 1. stack name
define aws_cfn_delete_stack
$(if $(call aws_cfn_stack_exists?,$(1)),$(call aws_cfn_delete_stack_and_wait,$(1)))
endef
