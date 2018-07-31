# common makefile for iplug plugins

# XXX set by parent Makefile
PLUGIN_NAME ?= iPlug

PLUGIN_DIR ?= $(PLUGIN_NAME).indigoPlugin
ZIPFILE ?= $(PLUGIN_NAME).zip
PLUGIN_SRC ?= $(PLUGIN_DIR)/Contents/Server Plugin/

# TODO come up with reasonable defaults for these
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= ./dist

DELETE_FILE ?= rm -vf
DELETE_DIR ?= rm -vRf

RUN_PY ?= PYTHONPATH="$(PLUGIN_SRC)" $(shell which python)

RSYNC ?= rsync -avzP

################################################################################
.PHONY: all clean distclean test dist deploy update_iplug

################################################################################
test: clean
	$(RUN_PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile:
	zip -9r "$(ZIPFILE)" "$(PLUGIN_DIR)" --exclude \*.swp --exclude \*.pyc

################################################################################
clean:
	find . -name '*.pyc' -exec $(DELETE_FILE) {} \;

################################################################################
distclean: clean
	$(DELETE_FILE) "$(ZIPFILE)"

################################################################################
deploy:
	$(RSYNC) "$(PLUGIN_DIR)" "$(DEPLOY_HOST):$(DEPLOY_PATH)"

################################################################################
update_iplug:
	# TODO

################################################################################
all: clean test dist

