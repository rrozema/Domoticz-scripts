-- Auto-Or by Richard Rozema. 
--
-- Auto-Or switches On a device if one of the devices listed after it is on. 
-- When the last of the listed devices is switched off, the device is switched 
-- off too.
--

----- edit below here --------

local SETTINGS = {
    ["svt_cv - Thermostat Pause"]  = { "Woonkamer: Achterdeur", "Hal: Voordeur" }
}

----- edit above here --------

local triggers = {}
local devicelist = {}

for k, devices in pairs( SETTINGS ) do

    if type(devices) == "string" then
        devices = { devices }
    end
        
    if type(devices) == "table" then
        for _, name in ipairs( devices ) do
            
            -- Build a table with all unique device names from
            -- any group. This is the list of triggers that we
            -- wait for.
            local j = 1
            while j <= #triggers and name > triggers[j] do
                j = j + 1
            end
            if j > #triggers then
                table.insert( triggers, j, name )
            elseif name ~= triggers[j] then     -- no duplicates
                table.insert( triggers, j, name )
            end
            
            -- When we're triggered, we need to know which devices
            -- to check, plus which device to switch. One device 
            -- can however be in multiple lists. So we need to
            -- build a list per trigger device.
            if nil == devicelist[name] then
                devicelist[name] = {{ ["devices"] = devices, ["switch"] = k }}
            else
                table.insert(devicelist[name], 1, { ["devices"] = devices, ["switch"] = k })
            end
        end
    end
end

return {
	on = {
		devices = triggers
	},
    execute = function(domoticz, device, triggerInfo)
        
        if device.isDevice then
            domoticz.log(device.name..': state '..tostring(device.bState)..'.')
            
            local dl = devicelist[device.name]
            
            -- if the current device is on, we only need to check if the light is not on yet.
            if device.bState == true then
                for _, s in ipairs( dl ) do
                    local switch = domoticz.devices( s.switch)
                    if switch.bState ~= true then
                        switch.switchOn()
                    end
                end
            else 
                -- if the device is off however, we need to check if any other device is stil on.
                -- Only if no other device is on, we switch off the light.
                for _, s in ipairs( dl ) do
                
                    local switch = domoticz.devices( s.switch)
                    local state = domoticz.devices().filter( s.devices ).reduce(
                                function(acc, d)
                                    if d.timedOut ~= true then -- Ignore devices that have timed out, to 
                                                                -- avoid leaving the light on because a sensor that 
                                                                -- has an empty battery isn't updated to 'Off'.
                                        if d.bState then
                                            --domoticz.utils._.print( 'Sensor ' .. md.name .. ' is on')
                                            domoticz.log( 'Device ' .. d.name .. ' is On.', domoticz.LOG_DEBUG)
                                            acc = true
                                        end
                                    else
                                        domoticz.log( 'Device ' .. d.name .. ' ignored because it timed out. Do you need to replace the battery?', domoticz.LOG_WARNING)
                                    end
                                    return acc -- Always return the accumulator.
                                end, false) -- initial value is false for "Off".
                                
                    if state == false and switch.bState ~= false then
                        switch.switchOff()
                    end
                end
            end
        else
            domoticz.log('Trigger is not a device: ' .. device.name .. '.', domoticz.LOG_ERROR)
            domoticz.utils.dumpTable(device)
    	end
	end
}