-- This script gets triggered when either of the devices listed below changes state.
-- Its purpose is to make sure that if one device changes state, the other device 
-- follows that change. In this case a wall switch "Keuken: S3" (2nd of a 2 button 
-- device) is programmed to control a power plug "Keuken: Aanrecht" and vice versa.
-- 
-- Known issues: 
-- 	- Very rarely switching one of the devices will correctly make the other 
--	  device to follow, but that change will then in turn re-trigger the 1st 
--    device again: both switches start to automatically go on and off. If you 
--    manually operate either of the switches again, the flashing stops. This 
--    should not be possible, because of the use of silent(), yet is does 
--    happen very rarely. I suspect a bug in either dzvents or domoticz to 
--    cause this erratic behavior.


local D1 = 'Keuken: Aanrecht'
local D2 = 'Keuken: S3'

return {
	on = {
		devices = {
			D1,
			D2
		}
	},
    execute = function(domoticz, device, triggerInfo)
        if (domoticz.EVENT_TYPE_TIMER == triggerInfo.type) then
            domoticz.log( 'timer event: '..tostring(triggerInfo.trigger)..'.', domoticz.LOG_INFO)

        elseif (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
            if (device.name == D1) then
                if (device.state ~= domoticz.devices(D2).state) then
                    domoticz.devices(D2).setState(device.state).silent()
                end
            elseif (device.name == D2) then
                if (device.state ~= domoticz.devices(D1).state) then
                    domoticz.devices(D1).setState(device.state).silent()
                end
            end
        end
        
	end
}