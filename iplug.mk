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
INDIGO_SUPPORT_DIR ?= /Library/Application Support/Perceptive Automation/Indigo 7

# where to deploy the plugin
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= $(INDIGO_SUPPORT_DIR)/Plugins

# these should be ignored for most operations
EXCLUDE_LIST ?= *.pyc *.swp

# commands used in the makefile
PY := PYTHONPATH="$(PLUGIN_SRC)" $(shell which python)
DELETE := rm -vf
RMDIR := rm -Rvf
MKDIR := mkdir -vp
COPY := cp -avf
ZIP := zip -9r
RSYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

# a bit of trickery to perform substitution on paths
empty :=
space := $(empty) $(empty)

src_files = $(wildcard $(SRCDIR)/*)
dest_files = $(patsubst $(SRCDIR)/%,$(PLUGIN_SRC)/%,$(src_files))

################################################################################
.PHONY: all build rebuild clean distclean test dist deploy update_iplug

################################################################################
get_commit_id = $(shell git -C $(BASEDIR) ls-files -s $(1) | cut -f2 -d\ )

################################################################################
build:
	$(MKDIR) "$(PLUGIN_BASEDIR)"
	$(MKDIR) "$(PLUGIN_CONTENT)"
	$(COPY) $(BASEDIR)/etc/Info.plist "$(PLUGIN_CONTENT)"
	$(MKDIR) "$(PLUGIN_SRC)"
	$(COPY) $(SRCDIR)/* "$(PLUGIN_SRC)"
	$(COPY) $(IPLUG_BASEDIR)/iplug.py "$(PLUGIN_SRC)/iplug.py"

################################################################################
test: build
	$(PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile: build
	$(eval exclude_args := $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt)))
	$(ZIP) "$(ZIPFILE)" "$(PLUGIN_BASEDIR)" $(exclude_args)

################################################################################
clean:
	$(RMDIR) "$(PLUGIN_BASEDIR)"
	find . -name '*.pyc' -exec $(DELETE) {} \;

################################################################################
distclean: clean
	$(DELETE) "$(ZIPFILE)"
	find . -name '*.swp' -exec $(DELETE) {} \;

################################################################################
deploy: build
	$(eval dest_path := $(subst $(space),\$(space),$(DEPLOY_PATH)))
	$(RSYNC) "$(PLUGIN_BASEDIR)" "$(DEPLOY_HOST):$(dest_path)"

################################################################################
update_iplug:
	$(eval iplug_ver_pre = $(call get_commit_id, $(IPLUG_BASEDIR)))
	git -C $(IPLUG_BASEDIR) pull
	$(eval iplug_ver_post = $(call get_commit_id, $(IPLUG_BASEDIR)))

ifneq ($(iplug_ver_pre), $(iplug_ver_post))
	git -C $(BASEDIR) add $(IPLUG_BASEDIR)
	git -C $(BASEDIR) commit -m 'Updated iPlug to $(iplug_ver_post)' $(IPLUG_BASEDIR)
endif

################################################################################
rebuild: clean build

################################################################################
all: build test dist

