return {
	on = {
		devices = {
			'*'
		}
	},
    execute = function(domoticz, device, triggerInfo)
		if (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
			if device.deviceType == "Light/Switch"
					and device.description ~= nil
					and device.description ~= ""
			then
				local description = device.description
				local state = device.state
				local ok, settings = pcall( domoticz.utils.fromJSON, device.description)
    	        if ok and settings ~= nil then
					local sync_group = settings.sync_group
					if sync_group ~= nil and sync_group ~= "" then
						domoticz.devices().forEach(
							function(otherdevice)
								if otherdevice.deviceType == "Light/Switch"
									and otherdevice.description ~= nil
									and otherdevice.state ~= state
								then
									local ok, othersettings = pcall( domoticz.utils.fromJSON, otherdevice.description)
									if ok and othersettings ~= nil then
										if othersettings.sync_group == sync_group then
											otherdevice.setState(state).silent()
										end
									end
								end
							end
						)
					end
			    end
		    end
        end
    end
}
