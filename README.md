# Domoticz-scripts

These are the scripts I use in my Domoticz installation. Many of them are of my own writing, others are borrowed, then modified. Where possible I will try to link to the original author.

The scripts are mostly written in DzVents, a domoticz specific framework based on lua.

Most notable scripts are:
 - Ventilatie : a script that controls my home's forced ventilation unit, based on various sensors throughout my house: 4 humidity sensors, a co sensor plus some dummy switches to control system states like a silent period during the night and extra ventilation after toilet usage.
 - Auto Off : a script that scans all devices in my domoticz configuration looking for those that have specific settings. If it finds the settings it checks if the device needs to be switched off. This makes for a very generic and easily configurable way of automatically switching off lights etc after they have been switched on by what ever means. It also incorporates the possibility to configure one or more motion detectors to make sure a light is not switched off until after everyone has left a room.
 - Several copies of Sync scripts: these scripts combine 2 devices to follow each other's state: if either of the devices is switched on, the other will automatically switch on too, and the other way around, if one goes off, the other follows. These scripts I mostly use where I have a 2 channel wall switch, 1 channel controls the ceiling light, the other has no wiring to it. This 2nd channel is -via these scripts- used to control for example a plug in the room. Theoreticaly the script can be extended to control more than 2 switches too. I just haven't needed it yet. I think I will try -at some point in the future- to make this more generic too, so I need only one script instead of several copies, just like the Auto Off script.
