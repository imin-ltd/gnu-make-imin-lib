
# 1. commands to assert on path
define shell_assert_commands
$(foreach cmd,$(1),\
  $(if $(shell command -v $(cmd) 2> /dev/null),,$(error Command '$(cmd)' not found in PATH)))
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
