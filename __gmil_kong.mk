
GMIL_COMMANDS += curl

GMIL_HTTP_INSECURE = -k

GMIL_HTTP_OPT_NAMES = GMIL_HTTP_INSECURE

# 1. http opts
define kong_http_opts
$(strip \
  $(foreach opt,$(sort $(1)), \
    $(foreach opt_name,$(GMIL_HTTP_OPT_NAMES), \
      $(if $(filter $(opt_name),$(opt)),\
        $($(opt_name)), \
        $(error Unknown http opt $(opt))))))
endef

# 1. kong admin url
# 2. api name
# 3. http opts
kong_api_exists? = $(shell curl $(call kong_http_opts,$(3)) -sS -f $(1)/apis/$(2) 2> /dev/null)

# 1. kong admin url
# 2. api name
# 3. upstream url
# 4. request host
# 5. http opts
define kong_api
$(if $(call kong_api_exists?,$(1),$(2),$(5)), \
  $(strip curl $(call kong_http_opts,$(5)) -sS -f -X PATCH -d 'upstream_url=$(3)' -d 'request_host=$(4)' $(1)/apis/$(2)), \
  $(strip curl $(call kong_http_opts,$(5)) -sS -f -d 'name=$(2)' -d 'upstream_url=$(3)' -d 'request_host=$(4)' $(1)/apis))
endef

# 1. kong admin url
# 2. api name
# 3. plugin name
# 4. http opts
define kong_api_plugin_exists?
$(shell curl $(call kong_http_opts,$(4)) -sS $(1)/apis/$(2)/plugins | \
  jq -r --arg name $(3) '.data[].name | select(. == $$name)')
endef

#define kong_api_plugin_id
#jq -r --arg name basic-auth '.data[] | select(.name == $name) | .id
#endef

# 1. kong admin url
# 2. api name
# 3. plugin name
# 4. plugin opts
# 5. http opts
define kong_api_plugin
$(if $(call kong_api_plugin_exists?,$(1),$(2),$(3),$(5)), \
  , \
  $(strip curl $(call kong_http_opts,$(5)) -sS -f -d 'name=$(3)' $(patsubst %,-d '%',$(4)) $(1)/apis/$(2)/plugins))
endef

# printf '{"name":"already exists with value 'kong'"}' |
# jq -e -s '(first | objects),(first | type == "object" and ((.id and .name == "kong") or .name))'; echo $?
