local DROGER_WATT_DEVICE_NAME = '$Washok: Droger: Vermogen'
local DROGER_SELECTOR_DEVICE_NAME = 'Droger: Status'

local WASMACHINE_WATT_DEVICE_NAME = '$Washok: Wasmachine: Vermogen'
local WASMACHINE_SELECTOR_DEVICE_NAME = 'Wasmachine: Status'

local QUOOKER_WATT_DEVICE_NAME = '$Keuken: Quooker: Vermogen'
local QUOOKER_SELECTOR_DEVICE_NAME = 'Quooker: Status'

return {
	on = {
		devices = {
		    DROGER_WATT_DEVICE_NAME,
			QUOOKER_WATT_DEVICE_NAME,
			WASMACHINE_WATT_DEVICE_NAME
		}
	},
	logging = {
--		level = domoticz.LOG_INFO,
		marker = 'template',
	},
	execute = function(domoticz, device)
	    if (WASMACHINE_WATT_DEVICE_NAME == device.name) then
    	    local power_device = domoticz.devices(WASMACHINE_WATT_DEVICE_NAME)
    	    local selector_device = domoticz.devices(WASMACHINE_SELECTOR_DEVICE_NAME)
    	    
    	    if (nil ~= power_device and nil ~= selector_device) then
                local power = power_device.actualWatt
    
                if (power >= 1 and selector_device.level ~= 10) then
    	            selector_device.setLevel(10)
    	        elseif (power < 1 and selector_device.level ~= 0) then
    	            selector_device.setLevel(0)
    	        end
	        end
        elseif (QUOOKER_WATT_DEVICE_NAME == device.name) then
    	    local power_device = domoticz.devices(QUOOKER_WATT_DEVICE_NAME)
    	    local selector_device = domoticz.devices(QUOOKER_SELECTOR_DEVICE_NAME)
    	    
    	    if (nil ~= power_device and nil ~= selector_device) then
                local power = power_device.actualWatt
    
                if (power >= 1 and selector_device.level ~= 10) then
    	            selector_device.setLevel(10)
    	        elseif (power < 1 and selector_device.level ~= 0) then
    	            selector_device.setLevel(0)
    	        end
	        end
        elseif (DROGER_WATT_DEVICE_NAME == device.name) then
    	    local power_device = domoticz.devices(DROGER_WATT_DEVICE_NAME)
    	    local selector_device = domoticz.devices(DROGER_SELECTOR_DEVICE_NAME)
    	    
    	    if (nil ~= power_device and nil ~= selector_device) then
                local power = power_device.actualWatt
    
                if (power >= 1 and selector_device.level ~= 10) then
    	            selector_device.setLevel(10)
    	        elseif (power < 1 and selector_device.level ~= 0) then
    	            selector_device.setLevel(0)
    	        end
	        end
	    end

	end
}