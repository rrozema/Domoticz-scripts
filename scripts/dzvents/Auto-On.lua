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

-- New feature: Initial dimmer level. Auto-On can set the level of a 
-- dimmer device to a specific level whenever it activates a device.
-- The device and when to activate it is exactly like it was before;
-- to make sure a device is always started at some specific level,
-- include in the device's description field json text specifing the
-- attribute "auto_on_level" followed a level from 1 to 100 to set 
-- the dimmer to when the device is activated by auto-on. For example:
-- {
--  "auto_on_level": "50"
-- }
-- this will set the dimmer to 50% whenever it gets activated by 
-- auto-on.

----- edit below here --------

local SETTINGS = {
    ["Tuin: Motion"] = --'Tuin: Buitenlamp',
            function ( domoticz, device )
                local switch_device = domoticz.devices( "Time for Avond" )
                if nil == switch_device or switch_device.bState or switch_device.timedOut then
                    return 'Tuin: Buitenlamp'
                end
            end, 
        
    ["WC: Motion"] = { 'WC: Plafond', 'WC Afzuiging' },
    
    ["Badkamer: Motion"] =
            function ( domoticz, device )
                --delayedOn(domoticz, device, 'Badkamer Afzuiging', 30)
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
                if nil == lux_device or lux_device.lux < 150 or lux_device.timedOut then
                    return {'Keuken: Spots', 'Keuken: kastverlichting'}
                else
                    return {'Keuken: kastverlichting'}
                end
            end, 

    ["Kledingkamer: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Kledingkamer: Illuminance" )
                if nil == lux_device or lux_device.lux < 10 or lux_device.timedOut then
                    return 'Kledingkamer: Plafond'
                end
            end,

    ["Overloop 1: Motion"] =
            function( domoticz, device )
                local lux_device = domoticz.devices( "Overloop 1: Illuminance" )
                if nil == lux_device or lux_device.lux < 10 or lux_device.timedOut then
                    return {'Overloop 1: Plafond', 'Washok: Plafond'}
--                    return {'Overloop 1: Plafond'}
                else
                    return {'Washok: Plafond'}
                end
            end,

    ["Trap 2: Motion"] =
            function ( domoticz, device )
                local lux_device = domoticz.devices( "Trap 2: Illuminance" )
                if nil == lux_device or lux_device.lux < 30 or lux_device.timedOut then
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

 --   ["Woonkamer: Motion 2"] =
 --           function ( domoticz, device )
 --               return {"Woonkamer: Scherm Links", "Woonkamer: Scherm Rechts", "Woonkamer: Speakers"}
 --           end
}

----- edit above here --------

-- Version history:
-- 2021-09-10
--  - Added regular expression to filter out descriptions that can't be json. Thanks EddyG!
--  - Fixed some inconsistent coding when retrieving the auto_on_level setting.

local triggerdevices = {}
for k, _ in pairs( SETTINGS ) do
    table.insert( triggerdevices, k )
end

local function delayedOn(domoticz, triggerDevice, toSwitch, seconds)
    if nil ~= domoticz and nil ~= triggerDevice and nil ~= toSwitch then
        -- ... and there is a delay > 0 seconds defined for this device...
        if seconds ~= nil and seconds > 0 then
            local Time = require('Time')
            local thisUpdate = Time(os.date("%Y-%m-%d %H:%M:%S", os.time(triggerDevice.lastUpdate.current)))
    
            local name = '__Auto_On-' .. tostring(triggerDevice.idx) .. '-' .. thisUpdate.raw
            local extraData = { ["idx"] = triggerDevice.idx, ["bState"] = triggerDevice.bState,  ["thisUpdate"] = thisUpdate, ["toSwitch"] = toSwitch }
    
            -- ... emit a customEvent after the delay.
            domoticz.emitEvent(name,  extraData).afterSec(seconds)
        else
            -- No delay, activate the action right now.
            domoticz.log( 'Triggering switch(es) without delay', domotiz.LOG_INFO)
            switchOn(domoticz, toSwitch)
        end
    end
end

local function switchOn( domoticz, switches )
    if nil ~= domoticz and nil ~= switches then
        if type(switches) == "string" then  -- If it's a single name, we can simply put a string
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
                            local level = nil
                            domoticz.log('Checking ' .. switch.name .. '.')
                            
                            local description = string.match(switch.description, '^[^{]*({.*})[^}]*$')
                            if nil ~= description and description ~= '' then
                                local ok, settings = pcall( domoticz.utils.fromJSON, description)
                                if ok and nil ~= settings then
                                    if nil ~= settings.auto_on_level then
                                        level = settings.auto_on_level;
                                        domoticz.log('Found auto_on_level of ' .. tostring(level) .. ' for ' .. switch.name .. '.')
                                    end
                                end
                            end
                        
                            if nil ~= level and switch.level < tonumber(level) then
                                domoticz.log('setLevel(' .. tostring(level) .. ') : ' .. switch.name .. '.')
                                switch.setLevel(tonumber(level))
                            elseif switch.bState ~= true then
                                domoticz.log('switchOn() : ' .. switch.name .. '.')
                                switch.switchOn()
                            end
                        end
                    )
            end
        end
    end
end


return {
    on = {
        devices = triggerdevices,
        customEvents = {"__Auto_On-*"}
    },
    execute = function(domoticz, trigger, triggerInfo)
        if trigger.isDevice then
            local device = trigger
            domoticz.log(device.name..': state '..tostring(device.bState)..'.')
            
            local switches = SETTINGS[device.name]
            if nil ~= switches then
                if type(switches) == "function" then
                    switches = switches(domoticz, device)
                end
                
                if type(switches) == "string" then  -- If it's a single name, we can simply put a string
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
                                    local level = nil
                                    domoticz.log('Checking ' .. switch.name .. '.')
                            
                                    local description = string.match(switch.description, '^[^{]*({.*})[^}]*$')
                                    if nil ~= description and description ~= '' then
                                        local ok, settings = pcall( domoticz.utils.fromJSON, description)
                                        if ok and nil ~= settings then
                                            if nil ~= settings.auto_on_level then
                                                level = settings.auto_on_level;
                                                domoticz.log('Found auto_on_level of ' .. tostring(level) .. ' for ' .. switch.name .. '.')
                                            end
                                        end
                                    end
                                
                                    if nil ~= level and switch.level < tonumber(level) then
                                        domoticz.log('setLevel(' .. tostring(level) .. ') : ' .. switch.name .. '.')
                                        switch.setLevel(tonumber(level))
                                    elseif true ~= switch.bState then
                                        domoticz.log('switchOn() : ' .. switch.name .. '.')
                                        switch.switchOn()
                                    end                                    
                                    
                                    
--                                    if switch.bState ~= true then
--                                        domoticz.log('switchOn() : ' .. switch.name .. '.')
--                                        switch.switchOn()
--                                    end
                                end
                            )
                    end
                end
            else
                domoticz.log('Unexpected device: ' .. device.name .. ': state ' .. tostring(device.bState) .. '.', domoticz.LOG_ERROR)
                domoticz.utils.dumpTable(device)
            end
        elseif item.isCustomEvent then
            local event = trigger
            -- If we get here, the customEvent has been triggered after the delay period. We will 
            -- test that:
            -- 1 : bState on the device equals that which we stored in the [extra data], and
            -- 2 : lastUpdate on the device equals that which we stored in [extra data].
            -- If both conditions are met we know the device is still unchanged after the delay
            -- and we can then start the delayed action.

            if event.json == nil then
                domoticz.log( 'json is missing', domoticz.LOG_ERROR)
            elseif event.json.idx == nil then
                domoticz.log( 'idx is missing', domoticz.LOG_ERROR)
            elseif event.json.bState == nil then
                domoticz.log( 'bstate is missing', domoticz.LOG_ERROR)
            elseif event.json.thisUpdate == nil then  
                domoticz.log( 'thisUpdate is missing', domoticz.LOG_ERROR)
            else
                local device = domoticz.devices(event.json.idx)
                if device == nil then
                    domoticz.log( 'device('..tostring(event.json.idx)..') not found', domoticz.LOG_ERROR)
                else
                    local Time = require('Time')
                    local thisUpdate = Time(os.date("%Y-%m-%d %H:%M:%S", os.time(event.json.thisUpdate)))
                    
                    if device.bState == event.json.bState and device.lastUpdate.compare(thisUpdate).compare == 0 then
                        domoticz.log( 'Triggering switch(es) after delay', domoticz.LOG_FORCE)
                        switchOn( domoticz, event.json.toSwitch)
                    end 
                end
            end
        else  
            domoticz.log('Trigger is not a device nor a custom event:', domoticz.LOG_ERROR)
            domoticz.utils.dumpTable(trigger)
        end
    end
}