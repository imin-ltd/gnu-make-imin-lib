
GMIL_COMMANDS += git sed jq

include $(__gmil_git_root)gmil_shell

git_commit = $(if $(GIT_COMMIT),$(GIT_COMMIT),$(shell git rev-parse HEAD))

git_branch = $(if $(GIT_BRANCH),$(GIT_BRANCH),$(shell git rev-parse --abbrev-ref HEAD))

git_status_json = $(shell git status --porcelain $(1) | \
  sed 's/./\t/3' | \
  jq -R -s -c 'split("\n") | del(.[length - 1]) | map(split("\t")) | map({"Status": .[0], "Path": .[1]})')

git_status_json_group_by_status = $(shell git status --porcelain $(1) | \
  sed 's/./\t/3' | \
  jq -R -s -c 'split("\n") | del(.[length - 1]) | map(split("\t")) | map({"Status": .[0], "Path": .[1]}) | group_by(.Status) | map({"Status": .[0].Status, "Paths": map(.Path)})')
