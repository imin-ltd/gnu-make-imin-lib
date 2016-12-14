
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
