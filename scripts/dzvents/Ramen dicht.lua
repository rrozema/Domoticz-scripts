local DEVICE_NAME_ACTUATOR_DIMITRI = "Richard: Raam"
local DEVICE_NAME_ACTUATOR_JOERI = "Joeri: Raam"
local DEVICE_NAME_TIMER = "Time for Avond"

local CLOSED_LEVEL = 0

return {
	on = {
		devices = {
			DEVICE_NAME_TIMER
		}
	},
	logging = {
--		level = domoticz.LOG_INFO,
		marker = 'Ramen dicht'
	},
	execute = function(domoticz, device)
        for i,a in ipairs({DEVICE_NAME_ACTUATOR_DIMITRI, DEVICE_NAME_ACTUATOR_JOERI }) do
            local act = domoticz.devices(a)

		    if nil ~= act then
    		    if device.bState == true and act.level > CLOSED_LEVEL then
    		        domoticz.log('Closing '.. tostring(act.name) .. '.', domoticz.LOG_INFO)
    		        act.setLevel( CLOSED_LEVEL )
    		    end
		    else
                domoticz.log('No device by the name ' .. tostring(a) .. ' was found.', domoticz.LOG_ERROR)
		    end
        end
    end
}