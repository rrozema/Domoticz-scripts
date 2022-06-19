local SETTINGS = {
    
    ['Timer voor buitenlampen'] = 
        function ( domoticz, device, lux )
            if lux <= 100 then
                if not device.active then
                    device.switchOn()
                end
            else
                if device.active then
                    device.switchOff()
                end
            end
        end
    
}


local SCRIPT_NAME = 'Auto-Lux'
local SCRIPT_VERSION = '0.01'

return {
	on = {
		devices = {
			'Solar Lux'
		}
	},
	logging = {
	    level   =   
            --domoticz.LOG_ERROR --select one to override system log level, default = LOG_ERROR
            --domoticz.LOG_WARNING
            domoticz.LOG_DEBUG
            --domoticz.LOG_INFO
            --domoticz.LOG_FORCE -- to get more log
	},
	execute = function(domoticz, item)
        _G.logMarker =  domoticz.moduleLabel -- Set logmarker to scriptname.
        
        domoticz.log( SCRIPT_NAME .. ' v' .. SCRIPT_VERSION .. ', Domoticz v' .. domoticz.settings.domoticzVersion .. ', Dzvents v' .. domoticz.settings.dzVentsVersion .. '.', domoticz.LOG_DEBUG)
        
        for idx, f in pairs(SETTINGS) do
            local device = domoticz.devices(idx)
            if nil ~= device then
                if type(f) == "function" then
                    f( domoticz, device, item.lux)
                end
            end
        end
	end
}