mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
DESTDIR ?=
PREFIX ?= ${HOME}/.local
RUNTIME = $(dir $(mkfile_path))
VERSION = $(lastword $(shell ./scripts/nvimpager -v))
BUSTED = busted

%.configured: scripts/%
	sed 's#^RUNTIME=.*$$#RUNTIME='"'$(RUNTIME)'"'#;s#version=.*$$#version=$(VERSION)#' < $< > $@
	chmod +x $@

install: nvimpager.configured
	mkdir -p $(DESTDIR)$(PREFIX)/bin \
	  $(DESTDIR)$(PREFIX)/share/man/man1 \
	  $(DESTDIR)$(PREFIX)/share/zsh/site-functions
	install nvimpager.configured $(DESTDIR)$(PREFIX)/bin/nvimpager
	install -m 644 scripts/_nvimpager $(DESTDIR)$(PREFIX)/share/zsh/site-functions
uninstall:
	$(RM) $(PREFIX)/bin/nvimpager \
      $(PREFIX)/share/zsh/site-functions/_nvimpager

nvimpager.1: SOURCE_DATE_EPOCH = $(shell git log -1 --no-show-signature --pretty="%ct" 2>/dev/null || echo 1636921311)
nvimpager.1: doc/nvimpager.md
	install -m 644 nvimpager.1 $(DESTDIR)$(PREFIX)/share/man/man1
	sed '1s/$$/ "nvimpager $(VERSION)"/' $< | scdoc > $@

TYPE = minor
version:
	[ $(TYPE) = major ] || [ $(TYPE) = minor ] || [ $(TYPE) = patch ]
	sed -i 's/version=.*version=/version=/' nvimpager
	awk -i inplace -F '[v.]' -v type=$(TYPE)\
      -e 'type == "major" && /version=/ { print $$1 "version=v" $$3+1 ".0" }' \
      -e 'type == "minor" && /version=/ { print $$1 "version=v" $$3 "." $$4+1 }' \
      -e 'type == "patch" && /version=/ { print $$1 "version=v" $$3 "." $$4 "." $$5+1 }' \
      -e '/version=/ { next }' \
      -e '{ print $$0 }' nvimpager
	sed -i "/SOURCE_DATE_EPOCH/s/[0-9]\{10,\}/$(shell date +%s)/" $(MAKEFILE_LIST)

clean:
	$(RM) nvimpager.configured nvimpager.1 luacov.*
.PHONY: clean install test uninstall version
