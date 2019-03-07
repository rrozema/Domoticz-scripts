local MASTER = 'Dimitri: Wandlamp'
local SLAVE = 'Dimitri: S2'

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