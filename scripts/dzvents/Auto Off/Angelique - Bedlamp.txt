-- This script gets triggered when either of the devices listed below changes state.
-- Its purpose is to make sure that if one device changes state, the other device 
-- follows that change. In this case a wall switch "Angelique: S3" (2nd of a 2 button 
-- device) is programmed to control a power plug "Angelique: Bedlamp" and vice versa.
-- 
-- Known issues: 
-- 	- Very rarely switching one of the devices will correctly make the other 
--	  device to follow, but that change will then in turn re-trigger the 1st 
--    device again: both switches start to automatically go on and off. If you 
--    manually operate either of the switches again, the flashing stops. This 
--    should not be possible, because of the use of silent(), yet is does 
--    happen very rarely. I suspect a bug in either dzvents or domoticz to 
--    cause this erratic behavior.

local MASTER = 'Angelique: Bedlamp'
local SLAVE = 'Angelique: S3'

return {
	on = {
		devices = {
			MASTER,
			SLAVE
		}
	},
    execute = function(domoticz, device, triggerInfo)
        if (domoticz.EVENT_TYPE_TIMER == triggerInfo.type) then
            domoticz.log( 'timer event: '..tostring(triggerInfo.trigger)..'.', domoticz.LOG_INFO)

        elseif (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
            if (device.name == MASTER) then
                if (device.state ~= domoticz.devices(SLAVE).state) then
                    domoticz.devices(SLAVE).setState(device.state).silent()
                end
            elseif (device.name == SLAVE) then
                if (device.state ~= domoticz.devices(MASTER).state) then
                    domoticz.devices(MASTER).setState(device.state).silent()
                end
            end
        end
        
	end
}