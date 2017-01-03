
GMIL_COMMANDS += jq

# 1. json string
json_encode = $(shell jq 'tojson' <<< '$1')
