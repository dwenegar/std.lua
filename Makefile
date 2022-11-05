LUA ?= lua

ver = $(LUA) scripts/ver.lua
format = $(LUA) scripts/format.lua
tidy = $(LUA) scripts/tidy.lua
rm =  $(LUA) scripts/rm.lua

rock_name = @ROCK_NAME@
rock_version = $(shell $(ver))
rockspec = rockspecs/$(rock_name)-$(rock_version)-1.rockspec
rockspec_dev = rockspecs/$(rock_name)-dev-1.rockspec

.PHONY: rockspec spec docs

default: help

docs:
	ldoc -c docs/config.ld .

lint: rockspec $(rockspec-dev)
	luarocks lint $(rockspec)
	luarocks lint $(rockspec_dev)
	luacheck --quiet --formatter plain src spec

spec:
	luarocks test

coverage:
	luarocks test -- -c
	luacov -r summary

install: rockspec
	luarocks make --local $(rockspec)

build: $(rockspec-dev)
	luarocks make --local --no-install

publish: rockspec
	luarocks upload --force --temp-key=$(LUAROCKS_KEY) $(rockspec)

changelog:
	git-cliff --output CHANGELOG.md --tag $(rock_version)
	$(tidy) CHANGELOG.md

rockspec: $(rockspec_dev)
	luarocks new_version --dir rockspecs --tag $(rock_version) $(rockspec_dev)
	$(tidy) $(rockspec)
	$(rm) $(rock_name)-dev-1.rockspec

pre-checkin: rockspec

major-version:
	$(ver) new major

minor-version:
	$(ver) new minor

patch-version:
	$(ver) new patch

tag:
	git tag -f $(rock_version)

untag:
	git tag -d $(rock_version)

help:
	@echo "Available targets:"
	@echo "  help                 prints this help"
	@echo "  docs                 regenerates the rock documentation"
	@echo "  lint                 runs the linter on the rockspec and all Lua code"
	@echo "  spec                 runs the test suite"
	@echo "  coverage             calculates the code coverage of the test suite"
	@echo "  install              installs the rocks"
	@echo "  build                builds the rocks"
	@echo "  publish              publishes the rock"
	@echo "  changelog            regenerates CHANGELOG.md"
	@echo "  rockspec             creates the rockspec for the current version"
	@echo "  pre-checkin          runs the pre-checkin tasks"
	@echo "  major-version        increments the major version"
	@echo "  minor-version        increments the minor version"
	@echo "  patch-version        increments the patch version"
	@echo "  tag                  adds a release tag"
	@echo "  untag                removes the release tag"
