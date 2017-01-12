include gmil

GMIL_VERSION := $(subst $(__gmil_space),.,$(gmil_version))
DIST := gnu-make-imin-lib-$(GMIL_VERSION)
TAR := $(DIST).tar.gz

PREFIX = $(DESTDIR)/usr/local
INCLUDEDIR = $(PREFIX)/include

.PHONY: dist
dist: $(TAR)

define SOURCES
gmil
__gmil.mk
gmil_shell
__gmil_shell.mk
gmil_aws
__gmil_aws.mk
gmil_json
__gmil_json.mk
gmil_git
__gmil_git.mk
gmil_text
__gmil_text.mk
gmil_kong
__gmil_kong.mk
endef

$(TAR): $(strip $(SOURCES))
	@echo Making $@
	@rm -rf $(DIST)
	@mkdir $(DIST)
	@cp $^ $(DIST)
	@tar -c -z -f $@ $(DIST)
	@rm -rf $(DIST)

.PHONY: test
test:
	@$(MAKE) --no-print-directory -f gmil_test.mk

.PHONY: install
install: $(strip $(SOURCES))
	install -D $^ $(INCLUDEDIR)/

.PHONY: uninstall
uninstall: $(strip $(SOURCES))
	rm -f $(addprefix $(INCLUDEDIR)/,$(strip $(SOURCES)))
