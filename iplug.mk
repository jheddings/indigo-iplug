# common makefile for iplug plugins

# XXX should set by parent Makefile - we should probably error if this is not set
PLUGIN_NAME ?= iPlug

BASEDIR ?= .
SRCDIR ?= $(BASEDIR)/src

ZIPFILE ?= $(BASEDIR)/$(PLUGIN_NAME).zip
PLUGIN_DIR ?= $(BASEDIR)/$(PLUGIN_NAME).indigoPlugin
PLUGIN_SRC ?= $(PLUGIN_DIR)/Contents/Server Plugin

INDIGO_SUPPORT_DIR ?= /Library/Application Support/Perceptive Automation/Indigo 7

# rsync paths require a bit of extra escaping for some reason...
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= $(INDIGO_SUPPORT_DIR)/Plugins

EXCLUDE_LIST ?= *.pyc *.swp

# commands used in the makefile
PY := PYTHONPATH="$(PLUGIN_SRC)" $(shell which python)
DELETE := rm -vf
RMDIR := rm -vRf
MKDIR := mkdir -vp
COPY := cp -afv
ZIP := zip -9r
RSYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

# a bit of trickery to perform substitution on paths
empty :=
space := $(empty) $(empty)

################################################################################
.PHONY: all build rebuild clean distclean test dist deploy

################################################################################
build:
	$(MKDIR) "$(PLUGIN_SRC)"
	$(COPY) $(BASEDIR)/icon.png "$(PLUGIN_DIR)"
	$(COPY) $(BASEDIR)/Info.plist "$(PLUGIN_DIR)/Contents"
	$(COPY) $(SRCDIR)/* "$(PLUGIN_SRC)"
	$(COPY) $(BASEDIR)/iplug/iplug.py "$(PLUGIN_SRC)"

################################################################################
test: build
	$(PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile: build
	$(eval exclude_args := $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt)))
	$(ZIP) "$(ZIPFILE)" "$(PLUGIN_DIR)" $(exclude_args)

################################################################################
clean:
	$(RMDIR) "$(PLUGIN_DIR)"
	find . -name '*.pyc' -exec $(DELETE) {} \;

################################################################################
distclean: clean
	$(DELETE) "$(ZIPFILE)"
	find . -name '*.swp' -exec $(DELETE) {} \;

################################################################################
deploy: build
	$(eval dest_path := $(subst $(space),\$(space),$(DEPLOY_PATH)))
	$(RSYNC) "$(PLUGIN_DIR)" "$(DEPLOY_HOST):$(dest_path)"

################################################################################
rebuild: clean build

################################################################################
all: build test dist

