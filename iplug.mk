# common makefile for iplug plugins

# XXX should set by parent Makefile - we should probably error if this is not set
PLUGIN_NAME ?= iPlug

BASEDIR ?= .
SRCDIR ?= $(BASEDIR)/src

# where iplug is being referenced from...
IPLUG_BASEDIR ?= $(dir $(lastword $(MAKEFILE_LIST)))

ZIPFILE ?= $(BASEDIR)/$(PLUGIN_NAME).zip

# structure of the plugin
PLUGIN_BASEDIR ?= $(BASEDIR)/$(PLUGIN_NAME).indigoPlugin
PLUGIN_CONTENT ?= $(PLUGIN_BASEDIR)/Contents
PLUGIN_SRC ?= $(PLUGIN_CONTENT)/Server Plugin

# path where Indigo keeps application data
INDIGO_SUPPORT_DIR ?= /Library/Application Support/Perceptive Automation/Indigo 7.4

# where to deploy the plugin
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= $(INDIGO_SUPPORT_DIR)/Plugins

# these should be ignored for most operations
EXCLUDE_LIST ?= *.pyc *.swp

# commands used in the makefile
PY := PYTHONPATH="$(PLUGIN_SRC):$(BASEDIR)/test" $(shell which python)
DELETE := rm -vf
RMDIR := rm -Rvf
MKDIR := mkdir -vp
COPY := cp -avf
ZIP := zip -9r
RSYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

# a bit of trickery when performing substitution
comma := ,
empty :=
space := $(empty) $(empty)

src_files = $(wildcard $(SRCDIR)/*)
dest_files = $(patsubst $(SRCDIR)/%,$(PLUGIN_SRC)/%,$(src_files))

################################################################################
get_commit_id = $(shell git -C $(BASEDIR) ls-files -s $(1) | cut -f2 -d\ )
get_commit_status = $(strip $(shell git -C $(BASEDIR) status --short $(1)))

################################################################################
.PHONY: build

build: is_not_iplug_repo
	$(MKDIR) "$(PLUGIN_BASEDIR)"
	$(MKDIR) "$(PLUGIN_CONTENT)"
	$(COPY) $(BASEDIR)/etc/Info.plist "$(PLUGIN_CONTENT)"
	$(MKDIR) "$(PLUGIN_SRC)"
	$(COPY) $(SRCDIR)/* "$(PLUGIN_SRC)"
	$(COPY) $(IPLUG_BASEDIR)/iplug.py "$(PLUGIN_SRC)/iplug.py"

################################################################################
.PHONY: test

test: is_not_iplug_repo build
ifdef TESTMOD
	$(PY) -m unittest -v $(foreach mod,$(subst $(comma),$(space),$(TESTMOD)),test_$(mod))
else
	$(PY) -m unittest discover -v -s ./test
endif

################################################################################
.PHONY: dist

dist: is_not_iplug_repo test zipfile

################################################################################
.PHONY: zipfile

zipfile: is_not_iplug_repo build test
	$(eval exclude_args := $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt)))
	$(ZIP) "$(ZIPFILE)" "$(PLUGIN_BASEDIR)" $(exclude_args)

################################################################################
.PHONY: clean

clean: is_not_iplug_repo
	$(RMDIR) "$(PLUGIN_BASEDIR)"
	find . -name '*.pyc' -exec $(DELETE) {} \;

################################################################################
.PHONY: clobber

clobber: is_not_iplug_repo clean
	$(DELETE) "$(ZIPFILE)"
	find . -name '*.swp' -exec $(DELETE) {} \;

################################################################################
.PHONY: deploy

deploy: is_not_iplug_repo build test
	$(eval dest_path := $(subst $(space),\$(space),$(DEPLOY_PATH)))
	$(RSYNC) "$(PLUGIN_BASEDIR)" "$(DEPLOY_HOST):$(dest_path)"

################################################################################
.PHONY: rebuild

rebuild: is_not_iplug_repo clean build

################################################################################
.PHONY: all

all: is_not_iplug_repo build test dist

################################################################################
.PHONY: is_iplug_repo

is_iplug_repo:
ifneq ($(PLUGIN_NAME), iPlug)
	$(error Must be executed in the iPlug repository)
endif

################################################################################
.PHONY: is_not_iplug_repo

is_not_iplug_repo:
ifeq ($(PLUGIN_NAME), iPlug)
	$(error Cannot be executed in the iPlug repository)
endif

################################################################################
.PHONY: update_iplug

update_iplug: is_not_iplug_repo
	git -C $(IPLUG_BASEDIR) checkout master
	git -C $(IPLUG_BASEDIR) pull

################################################################################
.PHONY: upgrade_iplug

upgrade_iplug: is_not_iplug_repo update_iplug
	$(eval iplug_stat = $(call get_commit_status, $(IPLUG_BASEDIR)))
	$(eval iplug_ver = $(call get_commit_id, $(IPLUG_BASEDIR)))
	if [ -n "$(iplug_stat)" ] ; then \
		git -C $(BASEDIR) add $(IPLUG_BASEDIR) ; \
		git -C $(BASEDIR) commit -m 'Updated iPlug to $(iplug_ver)' $(IPLUG_BASEDIR) ; \
	fi

