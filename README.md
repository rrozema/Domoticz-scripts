# Domoticz-scripts

These are the scripts I use in my Domoticz installation. Many of them are of my own writing, others are borrowed, then modified. Where possible I will try to link to the original author.

The scripts are mostly written in DzVents, a domoticz specific framework based on lua.

Most notable scripts are:
 - Ventilatie Main : a script that controls my home's forced ventilation unit, based on various sensors throughout my house: 4 humidity sensors, a co sensor plus some dummy switches to control system states like a silent period during the night and extra ventilation after toilet usage.
 - Auto-Off : a script that scans all devices in my domoticz configuration looking for those that have specific settings. If it finds the settings it checks if the device needs to be switched off. This makes for a very generic and easily configurable way of automatically switching off lights etc after they have been switched on by what ever means. It also incorporates the possibility to configure one or more motion detectors to make sure a light is not switched off until after everyone has left a room.
 - Auto-On : Make one or more devices switch on when a master switch switches on.
 - Auto-OnOff : Make a group of devices all switch on and off together: if one goes on, the rest follows and vice versa.
 - ContainerOphaalDagen : A rewrite of GarbageCollect: collects every day the next time my garbage containers will be collected.
 - Etenstijd : A script to attach to an event. When activated it will flash a group of lights 3 times. This way I can call my kids to come down for dinner without having to stand shouting at the bottom of the stairs :-).
