
GMIL_COMMANDS += tee sed

# 1. dashed text
text_dashed_to_title_case = $(shell printf '%s\n' $(1) | tee -a text_dashed_to_title_case.log | sed -r 's/(^|-)([a-z])/\u\2/g')
