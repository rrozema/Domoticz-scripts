-- Auto-On by Richard Rozema. 
--
-- Auto-On switches On one or more "slave" switches when a "master" 
-- switch is switched On. The "slave" switches do NOT respond to 
-- the "master" switch going back to "Off".
--
-- A single instance of the script can be used to control multiple sets
-- of "master" and "slave" devices. The configuration is done by editing
-- the SETTINGS variable in the top of the script, below this comment.
-- 
-- Auto-On is part 2 of my set of Auto-scripts. I use these 3
-- scripts to control 90% of all automated switches in my house.
-- Part 1 is Auto-Off: switch a device off after a configurabe 
--                     time of inactivity
-- Part 3 is Auto-OnOff: keep a group of switches in sync.
-- 
-- 
-- Examples of use cases are:
--  - Hallway light: The switch for a hallway light is automatically 
--     switched On when a motion sensor detects motion in the hallway.
--     
--  - Ventilation timer: The switch for the ventilation is switched on 
--     when the light in the toilet switches on. 5 minutes after the
--     light is switched off, the ventilation switch switches off (for
--     example using my "Auto Off"-script).
-- 
-- How to use this script in your Domoticz?
-- Create a new dzVents script and copy this code into the script window.
-- Enter the names for your devices into the SETTINGS variable below 
-- and save the script. Check the Domoticz log window for any error 
-- messages during the save of the script. If the script was successfully
-- integrated into your setup, trigger one of the master devices. Again
-- look at the Domoticz log window for any error messages. If you see 
-- any: correct the reported problem. If you don't get an error but
-- the slave switche(s) don't respond, chances are you've not put the 
-- name of either your master or slave device in completely the same
-- as it is in the device properties. Please note that the names are 
-- case-sensitive. If you don't see any difference, try copy-pasting 
-- the name from each switch' properties into the SETTINGS below.
-- 
-- Note: Unlike my Auto Off script, the configuration for this script is
-- done by editing a variable inside the script. This is because I was
-- told by waaren & dannyblu that having an on {device = "*"} device
-- trigger would be bad for the performance of domoticz. My tests did
-- not show a noticable performance degradation, but just to be safe
-- I've decided to go with their advice.
-- 
-- How to configure the script:
-- You write your configuration into the SETTINGS variable below this 
-- comment. The first column has the name of the "master"-switch, the 
-- second column has the name of the "slave"-switch or the names of 
-- the "slave"-switches. Please note that the name of the "master" 
-- device is enclosed first by " and then again by []. It will most 
-- likely work without the [], but depending on the name of your device
-- the script may fail, so this is why I ask to always enclose the 
-- master device name by []. A single slave device can be defined either 
-- by putting the name of the device as a string after the equals 
-- (=)-sign. The script allows also to add multiple "slave" devices to 
-- a single "master", in this case a comma separated list of "slave" 
-- devices must be enclosed by curly braces { and }: a lua table with
-- string values. A comma must be put after each but the last set of 
-- master = slave or master = { slave, slave} combinations.

----- edit below here --------

local SETTINGS = {
    ["Tuin: Motion"] = 'Tuin: Buitenlamp',
    
    ["WC: Motion"] = { 'WC: Plafond', 'WC Afzuiging' },
    
    ["Badkamer: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Badkamer: Illuminance" )
                if nil == lux_device or lux_device.lux < 50 or lux_device.timedOut then
                    return {'Badkamer: Plafond', 'Badkamer Afzuiging'}
                else
                    return 'Badkamer Afzuiging'
                end
            end,

    ["Hal: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Hal: Illuminance" )
                if nil == lux_device or lux_device.lux < 15 or lux_device.timedOut then
                    return 'Hal: Plafond'
                end
            end, 

    ["Keuken: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Keuken: Illuminance" )
                if nil == lux_device or lux_device.lux < 200 or lux_device.timedOut then
                    return 'Keuken: Aanrecht'
                end
            end, 

    ["Kledingkamer: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Kledingkamer: Illuminance" )
                if nil == lux_device or lux_device.lux < 50 or lux_device.timedOut then
                    return 'Kledingkamer: Plafond'
                end
            end,

    ["Overloop 1: Motion"] =
            function( domoticz, device )
                local lux_device = domoticz.devices( "Overloop 1: Illuminance" )
                if nil == lux_device or lux_device.lux < 20 or lux_device.timedOut then
                    return {'Washok: Plafond', 'Overloop 1: Plafond'}
                end
            end,

    ["Trap 2: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Trap 2: Illuminance" )
                if nil == lux_device or lux_device.lux < 50 or lux_device.timedOut then
                    return 'Trap 2: Plafond'
                end
            end,
        
    ["Trap 1: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Trap 1: Illuminance" )
                if nil == lux_device or lux_device.lux < 50 or lux_device.timedOut then
                    return 'Trap 1: Plafond'
                end
            end
}

----- edit above here --------

local triggerdevices = {}
for k, _ in pairs( SETTINGS ) do
    table.insert( triggerdevices, k )
end

return {
	on = {
		devices = triggerdevices
	},
    execute = function(domoticz, device, triggerInfo)
        if device.isDevice then
            domoticz.log(device.name..': state '..tostring(device.bState)..'.')

            local switches = SETTINGS[device.name]
            if nil ~= switches then
                if type(switches) == "function" then
                    switches = switches(domoticz, device)
                end
                
                if type(switches) == "string" then    -- If it's a single name, we can simply put a string
                                                    -- in the settings. For ease of processing further 
                                                    -- down I'll make that single string into a table 
                                                    -- with 1 entry here.
                    switches = { switches }
                end
                
                if type(switches) == "table" then
                    if device.bState then
                        domoticz.devices().filter( switches )
                            .forEach(
                                function( switch )
                                    if switch.bState ~= true then
                                        domoticz.log('switchOn() : ' .. switch.name .. '.')
                                        switch.switchOn()
                                    end
                                end
                            )
                    end
                end
            else
                domoticz.log('Unexpected device: ' .. device.name .. ': state ' .. tostring(device.bState) .. '.', domoticz.LOG_ERROR)
                domoticz.utils.dumpTable(device)
            end
        else
            domoticz.log('Trigger is not a device: ' .. device.name .. '.', domoticz.LOG_ERROR)
            domoticz.utils.dumpTable(device)
    	end
	end
}