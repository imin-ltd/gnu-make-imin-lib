
# This is the Imin GNU Make Library version number as a list with
# three items: major, minor, revision

gmil_version := 0 1 0

# This results in __gmil_space containing just a space

__gmil_space :=
__gmil_space +=

# 1. first value to compare
# 2. second value to compare
eq = $(strip \
$(if $(or $(1),$(2)), \
$(and $(findstring $(1),$(2)),$(findstring $(2),$(1))), \
true))

# 1. must be true or the assertion will fail
# 2. assertion failure message
assert = $(if $(2),$(if $(1),,$(error Assertion failure: $(2))))

# 1. expected value
# 2. actual value
# 3. assertion failure message fn (optional)
assert_equal = $(call assert,$(call eq,$(1),$(2)),$(if $(3),$(call $(3),$(1),$(2)),expected '$(1)', actual '$(2)'))
