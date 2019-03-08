TIMED_DEVICE_NAME = 'Time for Avond'
PRESENCE_DEVICE_NAME = 'Iemand thuis'
GROUP_NAMES = {'Woonkamer + Halogeen'}

return {
	on = {
		devices = {
			TIMED_DEVICE_NAME,
			PRESENCE_DEVICE_NAME
		}
	},  
    data = {
        presence = {initial = 'Off'},
        timer = {initial = 'Off'}
    },	
--    logging = {
----        level = domoticz.LOG_INFO
--        level = domoticz.LOG_DEBUG
--    },  
    execute = function(domoticz, device, triggerInfo)
        if (domoticz.EVENT_TYPE_TIMER == triggerInfo.type) then
            domoticz.log( 'timer event: '..tostring(triggerInfo.trigger)..'.', domoticz.LOG_INFO)

        elseif (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
            domoticz.log( 'device event: '..device.name..', deviceType: '..device.deviceType..'.', domoticz.LOG_INFO)
            
            if (device.name == TIMED_DEVICE_NAME) then
                if (device.state ~= domoticz.data.timer) then
                    domoticz.log( 'Timed device : '..device.name..' -> '..tostring(device.state)..'.', domoticz.LOG_INFO)
                    domoticz.data.timer = device.state
                end
            elseif (device.name == PRESENCE_DEVICE_NAME) then
                if (device.state ~= domoticz.data.presence) then
                    domoticz.log( 'Presence device : '..device.name..' -> '..tostring(device.state)..'.', domoticz.LOG_INFO)
                    domoticz.data.presence = device.state
                end
            end
        
            local groups = domoticz.groups().filter(
                    function (item) 
                        if (GROUP_NAMES[item.name] ~= nil) then
                            domoticz.log( 'Found group : '..group.name..'.', domoticz.LOG_INFO)
                            return true
                        else
                            return false
                        end
                    end
                )
            if (groups ~= nil) then
                groups.forEach(
                        function(group)
                            if (group.state ~= 'On' and domoticz.data.presence == 'On' and domoticz.data.timer == 'On') then
                                domoticz.log( 'Switching On group : '..group.name..'.', domoticz.LOG_INFO)
                                group.switchOn()
                            elseif (group.state ~= 'Off' and (domoticz.data.presence ~= 'On' or domoticz.data.timer ~= 'On')) then
                                domoticz.log( 'Switching Off group : '..group.name..'.', domoticz.LOG_INFO)
                                group.switchOff()
                            end
                        end
                    )
            end
        end
	end
}