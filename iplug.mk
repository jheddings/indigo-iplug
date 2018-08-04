# common makefile for iplug plugins

# XXX set by parent Makefile
PLUGIN_NAME ?= iPlug

BASEDIR := .

PLUGIN_DIR ?= $(BASEDIR)/$(PLUGIN_NAME).indigoPlugin
ZIPFILE ?= $(BASEDIR)/$(PLUGIN_NAME).zip
PLUGIN_SRC ?= $(PLUGIN_DIR)/Contents/Server Plugin

IPLUG_REPO ?= https://github.com/jheddings/indigo-iplug
IPLUG_SRC_URL ?= https://raw.githubusercontent.com/jheddings/indigo-iplug/master

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
CURL := curl --silent
SYNC := rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)')

zip_exclude = $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt))

################################################################################
.PHONY: all clean distclean test dist deploy upgrade_iplug

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
upgrade_iplug:
	$(CURL) --output "$(BASEDIR)/iplug.mk" "$(IPLUG_SRC_URL)/iplug.mk"
	$(CURL) --output "$(PLUGIN_SRC)/iplug.py" "$(IPLUG_SRC_URL)/iplug.py"

################################################################################
all: clean test dist

