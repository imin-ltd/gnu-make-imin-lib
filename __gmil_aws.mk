# GNU Make AWS Library

# TODO assert function required commands present
# TODO command errors in functions should abort the build?

include $(__gmil_aws_root)gmil

include $(__gmil_aws_root)gmil_shell

include $(__gmil_aws_root)gmil_git

aws_iam_user_name = $(shell AWS_DEFAULT_PROFILE=default aws iam get-user | jq -r '.User.UserName')

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
$(strip
  $(if $(call eq,$(2),0),\
    $(1),\
    $(if $(call eq,$(2),1),,$(error aws_s3_get_content_handler: $(2) $(1)))))
endef

# 1. source
aws_s3_get_content = $(call shell_result,aws s3 cp s3://$(1) -,aws_s3_get_content_handler)

# 1. function name
# 2. function description
aws_lambda_publish_version = $(shell aws lambda publish-version --function-name $(1) --description $(2) | \
  jq -r '.Version')

# 1. template (defaulted)
define aws_cf_validate_template
aws cloudformation validate-template --template-body file://$(if $(1),$(1),cf-template.yml) > /dev/null
endef

# 1. stack name
aws_cf_stack_exists? = $(shell aws cloudformation describe-stacks | \
  jq --arg stack $(1) -e '.Stacks[].StackName | select(. == $$stack)')

# 1. stack name
define aws_cf_stack_events_most_recent_create_failed
aws cloudformation describe-stack-events --stack-name $(1) | \
  jq -C '.StackEvents | map(select(.ResourceStatus == "CREATE_FAILED")) | .[0] | del(.ResourceProperties) | objects'
endef

# 1. stack name
define aws_cf_stack_events_most_recent_update_failed
aws cloudformation describe-stack-events --stack-name $(1) | \
  jq -C '.StackEvents | map(select(.ResourceStatus == "UPDATE_FAILED")) | .[0] | del(.ResourceProperties) | objects'
endef

# 1. stack params
define aws_cf_build_params
$(strip \
  $(foreach param,$(1), \
    $(if $($(param)), \
      $(shell printf "ParameterKey=%s,ParameterValue='%s'" $(param) '$($(param))'))))
endef

aws_comma := ,

# 1. stack name
# 2. template
# 3. stack params
# 4. stack caps
define aws_cf_create_stack
$(strip aws cloudformation create-stack \
  --stack-name $(1) \
  --template-body file://$(2) \
  $(if $(3),--parameters $(call aws_cf_build_params,$(3)),) \
  $(if $(4),--capabilities $(4),) \
  --tags \
    Key=GitCommit,Value=$(git_commit) \
    Key=GitBranch,Value=$(git_branch) \
    Key=AwsIamUserName,Value=$(aws_iam_user_name) \
    Key=AwsCliProfile,Value=$(if $(AWS_DEFAULT_PROFILE),$(AWS_DEFAULT_PROFILE),default))
aws cloudformation wait stack-create-complete --stack-name $(1) || { $(call aws_cf_stack_events_most_recent_create_failed,$(1)); exit 1; }
endef

# 1. stack name
# 2. template
# 3. stack params
# 4. stack caps
define aws_cf_update_stack
$(strip aws cloudformation update-stack \
  --stack-name $(1) \
  --template-body file://$(2) \
  $(if $(3),--parameters $(call aws_cf_build_params,$(3)),) \
  $(if $(4),--capabilities $(4),) \
  --tags \
    Key=GitCommit,Value=$(git_commit) \
    Key=GitBranch,Value=$(git_branch) \
    Key=AwsIamUserName,Value=$(aws_iam_user_name) \
    Key=AwsCliProfile,Value=$(if $(AWS_DEFAULT_PROFILE),$(AWS_DEFAULT_PROFILE),default))
aws cloudformation wait stack-update-complete --stack-name $(1) || { $(call aws_cf_stack_events_most_recent_update_failed,$(1)); exit 1; }
endef

# 1. stack name
# 2. template
# 3. stack params
# 4. stack caps
define aws_cf_sync_stack
$(if $(call aws_cf_stack_exists?,$(1)), \
  $(call aws_cf_update_stack,$(1),$(2),$(3),$(4)), \
  $(call aws_cf_create_stack,$(1),$(2),$(3),$(4)))
endef
