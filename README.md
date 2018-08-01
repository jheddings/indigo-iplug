# indigo-iplug

Common functionality used by several of my Indigo plugins.

## Makefile

The `iplug.mk` file provides convenient targets for working with Indigo Plugins.  To use
this file, simply create a file called `Makefile` at the top of your plugin directory and
include the `iplug.mk` file after setting your variables.

### Variables

All plugins should set `PLUGIN_NAME` to an appropriate value before including the `iplug.mk`
file.

### Targets

* test

* clean

* dist

## Classes

### ThreadedPlugin

A standard plugin with a thread loop.
