########################################################################
##                                                                    ##
##   Makefile for NextGenAligner                                      ##
##                                                                    ##
##   Usage:    make       --or--                                      ##
##             make help                                              ##
##                                                                    ##
########################################################################

PKGNAME = NextGenAligner
# make the name of the module all lower-case
MODNAME = $(shell tr 'A-Z ' 'a-z_' <<<"$(PKGNAME)")
SCRIPTNAME = $(PKGNAME)
README = README.txt
# get the package version from the script itself
PKGVER=$(shell sed -n "s/^\(my \$$version  *=  *\)'\(.*\)';/\2/p" $(SCRIPTNAME))
# printed in the 'make help' output
READMEURL=https://github.com/MarioPujato/NextGenAligner\#readme

# this can be overridden by running 'PREFIX=/some/other/dir make'
PREFIX ?= /usr/local
# where "local" modules are installed (modules for software *we* wrote)
MODULEROOT = $(PREFIX)/modules
# "root" dir where MARIO binaries & other supporting files will be installed
MODULEDIR = $(MODULEROOT)/$(MODNAME)/$(PKGVER)
# install these into $(MODULEDIR)/bin
EXECUTABLES = $(SCRIPTNAME)

# where 'modulefile' will be installed to with 'make install-modulefile'
MODULEDESTFILE = $(MODULEROOT)/modulefiles/$(MODNAME)/$(PKGVER)
# the name of the Environment Modules modulefile in the c.w.d.
MODULEFILE = modulefile.tcl
# today's date in MMDDYY format
TODAY = $(shell date +%m%d%y)
# set to 'v' if you want your Git tags to be 'v1.0.0' instead of '1.0.0'
TAGPREFIX = 
# use the Bash shell (always)
SHELL = bash

# ANSI terminal colors (see 'man tput') and
# https://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
#
# Don't set these if there isn't a $TERM environment variable
ifneq ($(strip $(TERM)),)
	BOLD := $(shell tput bold)
	RED := $(shell tput setaf 1)
	GREEN := $(shell tput setaf 2)
	YELLOW := $(shell tput setaf 3)
	BLUE := $(shell tput setaf 4)
	MAGENTA := $(shell tput setaf 5)
	UL := $(shell tput sgr 0 1)
	RESET := $(shell tput sgr0 )
endif

help:
	@echo
	@echo "  $(UL)$(BOLD)$(BLUE)Makefile tasks for $(PKGNAME) v$(PKGVER)$(RESET)"
	@echo
	@echo "  Try one of these:"
	@echo
	@echo "      $(BOLD)make help$(RESET)                   - ($(GREEN)default$(RESET)) you're looking at it ;-)"
	@echo
	@echo "      $(BOLD)make install$(RESET)                - install '$(SCRIPTNAME)' and modulefile"
	@echo
	@echo "      $(BOLD)make install-modulefile$(RESET)     - install Environment Modules modulefile"
	@echo
	@echo "      $(BOLD)make release VERSION=$(MAGENTA)x.y.z$(RESET)  - create release for '$(SCRIPTNAME)' at version $(MAGENTA)x.y.z$(RESET)"
	@echo
	@echo
	@echo "  For more help, see $(READMEURL)"
	@echo

install: install-modulefile
	# install executable scripts / binaries into module dir
	install -d $(MODULEDIR)/bin
	for exe in $(EXECUTABLES); do install -m755 $$exe $(MODULEDIR)/bin; done

install-modulefile:
	# installing modulefile to '$(MODULEDESTFILE)'
	@# -D = create all components of DEST except the last, copy SOURCE to DEST
	install -D $(MODULEFILE) $(MODULEDESTFILE)

# get VERSION from the environment/command line; use it to update the
# '$version' and '$modified' variables in the 'NextGenAligner' Perl script,
# the README, and the modulefile
release: $(EXECUTABLES) $(MODULEFILE) $(README)
ifeq ($(VERSION),)
	@echo >&2
	@echo "  $(UL)$(BOLD)$(RED)OOPS!$(RESET)"
	@echo >&2
	@echo "  Expected a value for VERSION. Try again like this:"
	@echo >&2
	@echo "      $(BOLD)make release VERSION=x.y.z$(RESET)" >&2
	@echo >&2
	@exit 1
endif
	
	@# don't forget that $'s must be doubled in Makefiles to get a literal '$'
	@if ! [[ $(VERSION) =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$$ ]]; then \
		echo "$(BOLD)$(RED)(!!) ERROR$(RESET) - bad version; expected x.y[.z], where x, y, and z are all integers." >&2; \
		exit 1; \
	fi
	
	@# (re)initialize a git repository (it's harmless if one already exists)
	@git init &>/dev/null
	
	@if git status --porcelain | grep -q .; then \
		echo "$(BOLD)$(RED)(!!) ERROR$(RESET) - Git working tree is dirty; commit changes and try again." >&2; \
		echo >&2; \
		echo "     If this is a brand new repository, do this first:" >&2; \
		echo >&2; \
		echo "         $(BOLD)git add . && git commit -m'Initial commit'$(RESET)" >&2; \
		echo >&2; \
		exit 1; \
	fi
	
	@if git tag | grep -q $(TAGPREFIX)$(VERSION); then \
		echo "$(BOLD)$(RED)(!!) ERROR$(RESET) - release $(TAGPREFIX)$(VERSION) already exists." >&2; \
		exit 1; \
	fi
	
	@# replace version string in the Perl script and README
	sed -i "s/^\(my \$$version  *=  *\)'\(.*\)';/\1'$(VERSION)';/" $(SCRIPTNAME)
	sed -i "s/^\(Version:  *\)\(.*\)/\1$(VERSION)/" $(README)
	@# update the modified date in the Perl script and README
	sed -i "s/^\(my \$$modified  *=  *\)'\(.*\)';/\1'$(TODAY)';/" $(SCRIPTNAME)
	sed -i "s/^\(Modified:  *\)\(.*\)/\1$(TODAY)/" $(README)
	@# replace version in the modulefile, too
	sed -i 's/\(set version \)".*"/\1"$(VERSION)"/' $(MODULEFILE)
	
	@# ask the user if the modifications with 'sed' look OK
	@# the Makefile variable '$^' means "all dependencies"
	@git diff --color $^
	@echo
	
	@read -p "Does the above 'git diff' look OK? (y/[n], or Ctrl+C) "; \
	if [[ -z $$REPLY || $$REPLY =~ ^[Nn] ]]; then \
		echo; \
		echo "$(YELLOW)(**) NOTE$(RESET) - reverting changes to: $<" >&2; \
		git checkout $^; \
		exit 1; \
	fi
	
	@echo
	@# create a new commit log entry for the release
	git add $^
	@#      ^^ means "the names of all the prerequisites"
	git commit -m'Release $(TAGPREFIX)$(VERSION)'
	@echo
	
	@# create a new (lightweight) tag for the release; for an explanation of
	@# lightweight v. annotated tags, see https://stackoverflow.com/a/4971817
	@#
	@# FYI: use 'git show <tag>' to see all the details for a tag/release
	git tag $(TAGPREFIX)$(VERSION)
	
	@echo; \
	echo "  $(UL)$(BOLD)$(BLUE)SUPER!$(RESET)"; \
	echo; \
	echo "  Updated '$(PKGNAME)' from $(TAGPREFIX)$(PKGVER) to $(TAGPREFIX)$(VERSION)"; \
	echo; \
	echo "  It would be a good idea now to:"; \
	echo; \
	echo "      $(BOLD)make install$(RESET)"; \
	echo; \
	echo "  to update the installed version of the code."; \
	echo; \
	echo "  Then, push the new tag to your default Git remote, like this:"; \
	echo; \
	echo "      $(BOLD)git push && git push --tags$(RESET)"; \
	echo; \
	echo "  so that the new release shows up on GitLab / GitHub."; \
	echo

# basically just a dummy target for now; this removes editor temp files
# the '-' in front means that make will ignore any error (non-zero exit)
clean:
	-rm *~

# prevent make from getting confused if files w/ these names exist on filesys.
.PHONY: help install release clean

# please leave this intact; prevents Vim from converting spaces to tabs
# vim: noet ft=make
