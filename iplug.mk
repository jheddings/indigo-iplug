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
.PHONY: all build rebuild clean distclean test dist deploy

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
rebuild: clean build

################################################################################
all: build test dist

