
include $(__gmil_shell_root)gmil

# 1. command to test on path
shell_command? = $(if $(shell command -v $(1) 2> /dev/null),$(1),)

# 1. expected commands to find on path
# 2. actual commands found on path
shell_assert_commands_failure_message = expected commands on PATH '$(1)', actual '$(2)'

# 1. commands to assert on path
define shell_assert_commands
$(call assert_equal,$(sort $(1)),$(strip $(foreach cmd,$(sort $(1)),$(call shell_command?,$(cmd)))),shell_assert_commands_failure_message)
endef

# 1. shell arg
# 2. handler fn (called with 1. stdout from shell 2. exit status from shell)
define shell_result
$(strip $(call shell_result_raw,$(1),$(2)))
endef

# 1. shell arg
# 2. handler fn (called with 1. stdout from shell 2. exit status from shell)
define shell_result_raw
$(eval RESULT := $(shell $(1); printf ' %d' $$?))
$(if $(word 2,$(RESULT)), \
  $(eval RESULT := $(shell _result='$(RESULT)'; printf '%s %s\n' $${_result##* } "$${_result% *}")))
$(call $(2),$(wordlist 2,$(words $(RESULT)),$(RESULT)),$(firstword $(RESULT)))
$(eval undefine RESULT)
endef
