## Reusable building blocks for Indigo Plugins

import re

import logging
import indigo

# a basic regex for matching simple hostnames and IP addresses
re_hostname = re.compile('^(\w[\-\.]?)+$')

# a regex for matching MAC addresses of the form MM:MM:MM:SS:SS:SS
# Windows-like MAC addresses are also supported (MM-MM-MM-SS-SS-SS)
re_macaddr = re.compile('^([0-9a-fA-F][0-9a-fA-F][:\-]){5}([0-9a-fA-F][0-9a-fA-F])$')

################################################################################
class PluginBase(indigo.PluginBase):

    # map devices we observe for changes to function handlers
    _deviceWatchList = list()

    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base __init__ if overidden
    def __init__(self, pluginId, pluginDisplayName, pluginVersion, pluginPrefs):
        indigo.PluginBase.__init__(self, pluginId, pluginDisplayName, pluginVersion, pluginPrefs)
        self.loadPluginPrefs(pluginPrefs)

        self.logger = logging.getLogger('Plugin.iplug')

        indigo.devices.subscribeToChanges()

    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base deviceStartComm if overidden
    def deviceStartComm(self, device):
        self.logger.debug(u'Starting device - %s [%s]', device.name, device.deviceTypeId)

    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base deviceStopComm if overidden
    def deviceStopComm(self, device):
        self.logger.debug(u'Stopping device: %s', device.name)

    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base deviceUpdate if overidden
    def deviceUpdated(self, oldDevice, newDevice):
        indigo.PluginBase.deviceUpdated(self, oldDevice, newDevice)

        # since this method recieves all device changes, even debugging is too verbose...
        #self.logger.debug(u'device change: %s -- %s', oldDevice.name, newDevice.name)

        # notify any watchers for the device ID
        for watcher in self._deviceWatchList:
            watchId = watcher['deviceId']

            if newDevice.id == watchId:
                callback = watcher['callback']

                if callback is not None:
                    callback(self, newDevice)

    #---------------------------------------------------------------------------
    # set a callback for a given device ID => func(plugin, device)
    def watchDeviceForChanges(self, deviceId, func):
        self.logger.debug(u'adding watcher for device: %d', deviceId)

        # this works well for monitoring all changes to a given device...  it
        # would be more useful to create specific events for various changes
        # e.g. deviceStateChange -- may require an event framework for Device objects

        # TODO provide a method for watchers to unregister for changes

        watcher = {
            'deviceId' : deviceId,
            'callback' : func
        }

        self._deviceWatchList.append(watcher)

    #---------------------------------------------------------------------------
    # return the value from the dict as a string, optionally providing a default value
    def getPref(self, prefs, name, dfault=None):
        value = prefs.get(name, None)

        if value is None:
            value = dfault

        self.logger.debug(u'prefs{%s} = %s', name, str(value))

        return value

    #---------------------------------------------------------------------------
    # return the value from the dict as an integer, optionally providing a default value
    def getPrefAsInt(self, prefs, name, dfault=None):
        value = self.getPref(prefs, name, dfault)

        if value is not None:
            value = int(value)

        return value

    #---------------------------------------------------------------------------
    # return the value from the dict as a float, optionally providing a default value
    def getPrefAsFloat(self, prefs, name, dfault=None):
        value = self.getPref(prefs, name, dfault)

        if value is not None:
            value = float(value)

        return value


    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base loadPluginPrefs if overidden
    def loadPluginPrefs(self, prefs):
        # setup logging system
        self.logLevel = self.getPrefAsInt(prefs, 'logLevel', 20)
        self.indigo_log_handler.setLevel(self.logLevel)

    #---------------------------------------------------------------------------
    # reload the plugin prefs whenever the config dialog is closed
    def closedPrefsConfigUi(self, prefs, canceled):
        if canceled: return

        self.loadPluginPrefs(prefs)

    #---------------------------------------------------------------------------
    # standard callback for forcing UI reloads on dynamic menus...
    def updateConfigUI(self, valuesDict=None, typeId=None, targetId=0):
        self.logger.debug('refreshing form content: %d', targetId)

################################################################################
class ThreadedPlugin(PluginBase):

    # delay between loop steps, set by plugin config
    threadLoopDelay = None

    #---------------------------------------------------------------------------
    # NOTE: subclasses should invoke the base loadPluginPrefs if overidden
    def loadPluginPrefs(self, prefs):
        PluginBase.loadPluginPrefs(self, prefs)

        # save loop delay
        self.threadLoopDelay = self.getPrefAsInt(prefs, 'threadLoopDelay', 60)

    #---------------------------------------------------------------------------
    # perform the main work in the thread loop for the plugin. the timing of
    # this method is not guaranteed, however it is guaranteed to run once per
    # loop iteration.  it must be overidden by sublcasses.
    def runLoopStep(self): raise NotImplementedError

    #---------------------------------------------------------------------------
    # HOOK - something to do just before the thread loop starts
    def preThreadLoopHook(self): pass

    #---------------------------------------------------------------------------
    # HOOK - something to do just after the thread loop stops
    def postThreadLoopHook(self): pass

    #---------------------------------------------------------------------------
    # HOOK - perform work in the plugin thread before the loop delay
    def preLoopDelayHook(self): pass

    #---------------------------------------------------------------------------
    # HOOK - perform work in the plugin thread after the loop delay
    def postLoopDelayHook(self): pass

    #---------------------------------------------------------------------------
    def runConcurrentThread(self):
        self.logger.debug(u'Thread Started')

        # allow plugins to do work before the thread starts
        self.preThreadLoopHook()

        try:

            while not self.stopThread:
                # perform the main work of the thread
                self.runLoopStep()

                # do plugin work before the loop delay
                self.preLoopDelayHook()

                # sleep for the configured timeout
                self.sleep(self.threadLoopDelay)

                # do plugin work after the loop delay
                self.postLoopDelayHook()

        except self.StopThread:
            pass

        # allow plugins to do work when the thread stops
        self.postThreadLoopHook()

        self.logger.debug(u'Thread Stopped')

################################################################################
def validateConfig_URL(key, values, errors, emptyOk=False):
    # TODO verify correct URL format
    return validateConfig_String(key, values, errors, emptyOk)

################################################################################
def validateConfig_MAC(key, values, errors, emptyOk=False):
    value = values.get(key, None)

    # it must first be a valid string
    if not validateConfig_String(key, values, errors, emptyOk):
        return False

    if re_macaddr.match(value) is None:
        errors[key] = 'invalid MAC address: %s' % value
        return False

    return True

################################################################################
def validateConfig_Hostname(key, values, errors, emptyOk=False):
    value = values.get(key, None)

    # it must first be a valid string
    if not validateConfig_String(key, values, errors, emptyOk):
        return False

    if re_hostname.match(value) is None:
        errors[key] = 'invalid hostname: %s' % value
        return False

    return True

################################################################################
def validateConfig_Path(key, values, errors, emptyOk=False):
    # TODO verify correct file path format
    return validateConfig_String(key, values, errors, emptyOk)

################################################################################
def validateConfig_String(key, values, errors, emptyOk=False):
    value = values.get(key, None)

    if value is None:
        errors[key] = '%s cannot be empty' % key
        return False

    if not emptyOk and len(value) == 0:
        errors[key] = '%s cannot be blank' % key
        return False

    return True

################################################################################
def validateConfig_Int(key, values, errors, min=None, max=None):
    value = values.get(key, None)
    if value is None:
        errors[key] = '%s is required' % key
        return False

    intVal = None

    try:
        intVal = int(value)
    except:
        errors[key] = '%s must be an integer' % key
        return False

    if min is not None and intVal < min:
        errors[key] = '%s must be greater than or equal to %d' % (key, min)
        return False

    if max is not None and intVal > max:
        errors[key] = '%s must be less than or equal to %d' % (key, max)
        return False

    return True

################################################################################
def valueIsTrue(value):
    if value is True: return True
    if value is None: return False

    if type(value) not in (str, unicode):
        return False

    if value.lower() in ('true', 'yes', 'on', 'active'):
        return True

    return False

################################################################################
def valueIsFalse(value):
    if value is False: return True
    if value is None: return False

    if type(value) not in (str, unicode):
        return False

    if value.lower() in ('false', 'no', 'off', 'inactive'):
        return True

    return False

