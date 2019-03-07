local DARK_TIMER_NAME = 'Time for Avond'
local SLEEP_TIMER_NAME = 'Slaaptijd'
local BUITENLAMP_NAME = 'Hal: Buitenlamp'

return {
	on = {
		devices = {
			DARK_TIMER_NAME,
			SLEEP_TIMER_NAME
		}
	},
	execute = function(domoticz, device)
	    domoticz.log('Device ' .. device.name .. ' was changed', domoticz.LOG_INFO)
		
        if (device.name == DARK_TIMER_NAME or device.name == SLEEP_TIMER_NAME) then
            local dark = domoticz.devices(DARK_TIMER_NAME)
            local sleep = domoticz.devices(SLEEP_TIMER_NAME)
    	    local buitenlamp = domoticz.devices(BUITENLAMP_NAME)
            
		    if (dark.state == 'On' and sleep.state == 'Off') then
		        if (buitenlamp.state ~= 'On') then
		            buitenlamp.switchOn()
		        end
	        end
            else
                if (buitenlamp.state ~= 'Off') then
		            buitenlamp.switchOff()
		        end
		    end
		end
}