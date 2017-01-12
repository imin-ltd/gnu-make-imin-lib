
GMIL_COMMANDS += sed

# 1. text
text_title_case = $(shell printf '%s\n' $(1) | sed -r 's/(^|-|_)([A-Za-z])([A-Za-z]*)/\u\2\L\3/g')
