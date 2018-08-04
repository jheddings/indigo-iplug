# common makefile for iplug plugins

# XXX set by parent Makefile
PLUGIN_NAME ?= iPlug

BASEDIR := .
SRCDIR := $(BASEDIR)/src

ZIPFILE ?= $(BASEDIR)/$(PLUGIN_NAME).zip
PLUGIN_DIR ?= $(BASEDIR)/$(PLUGIN_NAME).indigoPlugin
PLUGIN_SRC ?= $(PLUGIN_DIR)/Contents/Server Plugin

INDIGO_SUPPORT_DIR ?= /Library/Application Support/Perceptive Automation/Indigo 7

# a bit of trickery to perform substitution on paths
empty :=
space := $(empty) $(empty)

# rsync paths require a bit of extra escaping for some reason...
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= $(subst $(space),\$(space),$(INDIGO_SUPPORT_DIR))/Plugins

EXCLUDE_LIST ?= *.pyc *.swp

PY := PYTHONPATH="$(PLUGIN_SRC)" $(shell which python)

DELETE := rm -vf
RMDIR := rm -vRf
MKDIR := mkdir -vp
COPY := cp -fv
SYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

zip_exclude = $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt))

################################################################################
.PHONY: all build rebuild clean distclean test dist deploy

################################################################################
build:
	$(MKDIR) "$(PLUGIN_DIR)/Contents"
	$(COPY) Info.plist "$(PLUGIN_DIR)/Contents"
	$(MKDIR) "$(PLUGIN_SRC)"
	$(COPY) src/* "$(PLUGIN_SRC)"
	$(COPY) iplug/*.py "$(PLUGIN_SRC)"

################################################################################
test: clean build
	$(PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile: build
	zip -9r "$(ZIPFILE)" "$(PLUGIN_DIR)" $(zip_exclude)

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
	$(SYNC) "$(PLUGIN_DIR)" "$(DEPLOY_HOST):$(DEPLOY_PATH)"

################################################################################
rebuild: clean build

################################################################################
all: build test

