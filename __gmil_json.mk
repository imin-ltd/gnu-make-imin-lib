# GNU Make JSON Library

# TODO assert function required commands present (inside individual functions)
# TODO command errors in functions should abort the build?

# 1. json string
json_encode = $(shell jq 'tojson' <<< '$1')
