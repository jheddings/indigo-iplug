# common makefile for iplug plugins

# XXX set by parent Makefile
PLUGIN_NAME ?= iPlug

PLUGIN_DIR ?= $(PLUGIN_NAME).indigoPlugin
ZIPFILE ?= $(PLUGIN_NAME).zip
PLUGIN_SRC ?= $(PLUGIN_DIR)/Contents/Server Plugin/

# TODO come up with reasonable defaults for these
DEPLOY_HOST ?= localhost
DEPLOY_PATH ?= dist

EXCLUDE_LIST ?= *.pyc *.swp

PY := PYTHONPATH="$(PLUGIN_SRC)" $(shell which python)

DELETE := rm -vf
RMDIR := rm -vRf

################################################################################
.PHONY: all clean distclean test dist deploy update_iplug

################################################################################
test: clean
	$(PY) -m unittest discover -v ./test/

################################################################################
dist: zipfile

################################################################################
zipfile:
	zip -9r "$(ZIPFILE)" "$(PLUGIN_DIR)" $(foreach patt,$(EXCLUDE_LIST),--exclude \$(patt))

################################################################################
clean:
	find . -name '*.pyc' -exec $(DELETE) {} \;

################################################################################
distclean: clean
	$(DELETE) "$(ZIPFILE)"
	find . -name '*.swp' -exec $(DELETE) {} \;

################################################################################
deploy:
	rsync -avzP $(foreach patt,$(EXCLUDE_LIST),--exclude '$(patt)') "$(PLUGIN_DIR)" "$(DEPLOY_HOST):$(DEPLOY_PATH)"

################################################################################
update_iplug:
	# TODO

################################################################################
all: clean test dist

