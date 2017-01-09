
.PHONY: all
all:
	@echo
	@echo Test Summary
	@echo ------------
	@echo "some tests passed; some tests failed"

include gmil

include gmil_shell

include gmil_text

include gmil_aws

$(call shell_assert_commands,$(GMIL_COMMANDS))

ECHO := /bin/echo

start_test = $(if $0,$(shell $(ECHO) -n "Testing '$1': " >&2))$(eval current_test := OK)
stop_test = $(if $0,$(shell $(ECHO) " $(current_test)" >&2))
test_pass = .
test_fail = X$(eval current_test := ERROR '$1' != '$2')
test_assert = $(if $0,\
  $(if $(filter undefined,$(origin 2)),\
    $(eval 2 :=))$(shell $(ECHO) -n $(if $(call eq,$1,$2),$(call test_pass,$1,$2),$(call test_fail,$1,$2)) >&2))

test_json = {"someKey": "someVal", "otherKey": "otherVal"}
test_shell_arg = printf '$(test_json)'

test_handler_stdout = $(1)
test_handler_exit_status = $(2)

$(call start_test,shell_result_stdout)
$(call test_assert,$(call shell_result,$(test_shell_arg),test_handler_stdout),$(test_json))
$(call stop_test)

$(call start_test,shell_result_exit_status)
$(call test_assert,$(call shell_result,$(test_shell_arg),test_handler_exit_status),0)
$(call stop_test)

$(call start_test,text_dashed_to_title_case)
$(call test_assert,$(call text_dashed_to_title_case,env-dev),EnvDev)
$(call stop_test)

$(call start_test,aws_cf_stack_name)
$(call test_assert,$(call aws_cf_stack_name,cfn-template-xyz.yml),Xyz)
$(call stop_test)

$(call start_test,aws_s3_get_content_handler)
$(call test_assert,$(call aws_s3_get_content_handler,$(test_json),0),$(test_json))
$(call stop_test)
