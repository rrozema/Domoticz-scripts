local DEVICE_NAME_ACTUATOR_RICHARD = "Richard: Raam"
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
	    if device.bState == true then
    	    domoticz.devices({DEVICE_NAME_ACTUATOR_RICHARD, DEVICE_NAME_ACTUATOR_JOERI }).forEach(
                function(act)
    	    	    if act.level > CLOSED_LEVEL then
    		            domoticz.log('Closing '.. tostring(act.name) .. '.', domoticz.LOG_INFO)
    		            act.setLevel( CLOSED_LEVEL )
    		        end
                end
            )
        end
    end
}