local EAST_FACING_PANEL_NAME = 'Paneel 11'
local WEST_FACING_PANEL_NAME = 'Paneel 16'

local SWITCH_NAME = 'Stand van de zon'

local NONE_LEVEL = 0
local EAST_LEVEL = 10
local MIDDLE_LEVEL = 20
local WEST_LEVEL = 30

local HYSTERESIS = 4

return {
	on = {
		devices = {
			EAST_FACING_PANEL_NAME,
			WEST_FACING_PANEL_NAME
		}
	},
--	logging = {
--		level = domoticz.LOG_INFO,
--		marker = 'Zonneschermen',
--	},
	execute = function(domoticz, device)
		local east_device = domoticz.devices(EAST_FACING_PANEL_NAME)
		local west_device = domoticz.devices(WEST_FACING_PANEL_NAME)
		local switch_device = domoticz.devices(SWITCH_NAME)
		
		if nil ~= east_device and nil ~= west_device and nil ~= switch_device then
		    local east_power = east_device.actualWatt
	        local west_power = west_device.actualWatt
            
            if east_power < 10 and west_power < 10 then
                if switch_device.level ~= NONE_LEVEL then
                    switch_device.setLevel( NONE_LEVEL)
                end
            elseif east_power > west_power + HYSTERESIS then
                if switch_device.level ~= EAST_LEVEL then
                    switch_device.setLevel( EAST_LEVEL)
                end
		    elseif west_power > east_power + HYSTERESIS then
		        if switch_device.level ~= WEST_LEVEL then
		            switch_device.setLevel( WEST_LEVEL)
		        end
		    else
		        if switch_device.level ~= MIDDLE_LEVEL then
		            switch_device.setLevel( MIDDLE_LEVEL)
		        end
		    end
		else
		    domoticz.log('One or more required devices were not found, skipping this change.', domoticz.LOG_ERROR)
		end
	end
}