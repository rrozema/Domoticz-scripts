local SETPOINT_NORMAL_NAME = "svt_cv - Setpoint Normal"
local SETPOINT_ECONOMY_NAME = "svt_cv - Setpoint Economy"
local MODE_NAME = "svt_cv - Thermostat Mode"
local CONTROL_NAME = "svt_cv - Thermostat Control"
--local PAUSE_NAME = "svt_cv - Thermostat Pause"    -- Can't use this, as the pause button only 
                                                    -- indicates the intent to go to pause mode, 
                                                    -- not if the thermostat is actually in pause
                                                    -- mode. I plan on changing the MODE control
                                                    -- to go into "Off" position when paused.
                                                    
local TARGET_NAME = "svt_cv - Target temperature"
                                                    

return {
	on = {
		devices = {
			CONTROL_NAME,
			MODE_NAME,
			PAUSE_NAME,
			SETPOINT_NORMAL_NAME,
			SETPOINT_ECONOMY_NAME
		}
	},
	logging = {
		level = domoticz.LOG_INFO,
		marker = 'template',
	},
	execute = function(domoticz, device)
		domoticz.log('Device ' .. device.name .. ' was changed', domoticz.LOG_INFO)
		if device.isDevice then
		    local temperature
		    
		    local control = domoticz.devices(CONTROL_NAME)
		    local mode = domoticz.devices(MODE_NAME)
		    local setpoint_normal = domoticz.devices(SETPOINT_NORMAL_NAME)
		    local setpoint_economy = domoticz.devices(SETPOINT_ECONOMY_NAME)
		    
		    local target = domoticz.devices(TARGET_NAME)

            if nil == control then
    		    domoticz.log('Device ' .. CONTROL_NAME .. ' not found.', domoticz.LOG_ERROR)
            elseif nil == mode then
    		    domoticz.log('Device ' .. MODE_NAME .. ' not found.', domoticz.LOG_ERROR)
            elseif nil == setpoint_normal then
    		    domoticz.log('Device ' .. SETPOINT_NORMAL_NAME .. ' not found.', domoticz.LOG_ERROR)
            elseif nil == setpoint_economy then
    		    domoticz.log('Device ' .. SETPOINT_ECONOMY_NAME .. ' not found.', domoticz.LOG_ERROR)
            elseif nil == target then
    		    domoticz.log('Device ' .. TARGET_NAME .. ' not found.', domoticz.LOG_ERROR)
            else
                if control.level == 0 then       -- off
                    temperature = nil
                elseif control.level == 20 then  -- forced
                    temperature = nil
                elseif mode.level == 10 then     -- auto - normal
                    temperature = setpoint_normal.setPoint
                elseif mode.level == 20 then     -- auto - economy
                    temperature = setpoint_economy.setPoint
                else
                    temperature = nil
                end
                
                if setPoint ~= target.temperature then
		            domoticz.log('Target temperature changed to ' .. temperature .. '.', domoticz.LOG_INFO)
		            target.updateTemperature(temperature)
                end
            end
		end
	end
}