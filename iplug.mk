# common makefile for iplug plugins

# XXX set by parent Makefile
PLUGIN_NAME ?= iPlug

BASEDIR := .

PLUGIN_DIR ?= $(BASEDIR)/$(PLUGIN_NAME).indigoPlugin
ZIPFILE ?= $(BASEDIR)/$(PLUGIN_NAME).zip
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
COPY := cp -fv
SYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

zip_exclude = $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt))

################################################################################
.PHONY: all clean distclean test dist deploy

################################################################################
test: clean
	$(PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile:
	zip -9r "$(ZIPFILE)" "$(PLUGIN_DIR)" $(zip_exclude)

################################################################################
clean:
	find . -name '*.pyc' -exec $(DELETE) {} \;

################################################################################
distclean: clean
	$(DELETE) "$(ZIPFILE)"
	find . -name '*.swp' -exec $(DELETE) {} \;

################################################################################
deploy:
	$(SYNC) "$(PLUGIN_DIR)" "$(DEPLOY_HOST):$(DEPLOY_PATH)"

################################################################################
all: clean test dist

