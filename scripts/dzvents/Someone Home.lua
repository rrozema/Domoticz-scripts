local IEMAND_THUIS_NAME = 'Iemand thuis'

local THERMOSTAT_MODE_NAME = 'svt_cv - Thermostat Mode'
local THERMOSTAT_MODE_LEVEL_NORMAL = 10
local THERMOSTAT_MODE_LEVEL_ECONOMY = 20


return {
	on = {
		devices = {
			IEMAND_THUIS_NAME
		}
	},
    execute = function(domoticz, device)
        domoticz.log('Device ' .. device.name .. ' was changed', domoticz.LOG_INFO)
		
        if device.isDevice then
            if device.name == IEMAND_THUIS_NAME then
                local thermostat_mode = domoticz.devices(THERMOSTAT_MODE_NAME)
                if nil ~= thermostat_mode then
                    if device.active and thermostat_mode.level ~= THERMOSTAT_MODE_LEVEL_NORMAL then
    		            domoticz.log('Switching ' ..tostring(THERMOSTAT_MODE_NAME) .. ' to Normal mode (' .. tostring(THERMOSTAT_MODE_LEVEL_NORMAL) .. '.', domoticz.LOG_INFO)
                        thermostat_mode.switchSelector( THERMOSTAT_MODE_LEVEL_NORMAL )    -- Normal
                    elseif not device.active and thermostat_mode.level ~= THERMOSTAT_MODE_LEVEL_ECONOMY then
    		            domoticz.log('Switching ' ..tostring(THERMOSTAT_MODE_NAME) .. ' to Economy mode (' .. tostring(THERMOSTAT_MODE_LEVEL_ECONOMY) .. '.', domoticz.LOG_INFO)
                        thermostat_mode.switchSelector( THERMOSTAT_MODE_LEVEL_ECONOMY )    -- Economy
                    end
		        else
		            domoticz.log('Device "' .. tostring(THERMOSTAT_MODE_NAME) .. '" not found.', domoticz.LOG_ERROR)
	            end
            end
        end
	end
}