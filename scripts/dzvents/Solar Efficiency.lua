local SOLAR_POWER_NAME = 'BR: Sun Power'

local PRODUCTION_ALL_NAME = 'Zonnepanelen Productie'
local EFFICIENCY_ALL_NAME = 'Efficientie Zonnepanelen'

local PRODUCTION_EAST_NAMES = {'Paneel 02', 'Paneel 06', 'Paneel 07', 'Paneel 08', 'Paneel 10', 'Paneel 11', 'Paneel 14', 'Paneel 15'}
local EFFICIENCY_EAST_NAME = 'Efficientie Zonnepanelen Oost'

local PRODUCTION_WEST_NAMES = {'Paneel 01', 'Paneel 03', 'Paneel 04', 'Paneel 05', 'Paneel 09', 'Paneel 12', 'Paneel 13', 'Paneel 16'}
local EFFICIENCY_WEST_NAME = 'Efficientie Zonnepanelen West'

local PANEL_M2 = 1.6
local NUM_PANELS = 16

return {
	on = {
		devices = {
			PRODUCTION_ALL_NAME,
			SOLAR_POWER_NAME
		}
	},
	logging = {
--		level = domoticz.LOG_INFO,
		marker = 'Solar Efficiency',
	},
	execute = function(domoticz, device)
	    local solar_power_device = domoticz.devices(SOLAR_POWER_NAME)
	    local production_all_device = domoticz.devices(PRODUCTION_ALL_NAME)
	    local efficiency_all_device = domoticz.devices(EFFICIENCY_ALL_NAME)
	    
	    if nil == solar_power_device then
	        domoticz.log( 'Device ' .. SOLAR_POWER_NAME .. ' not found.', domoticz.LOG_ERROR)
	    elseif nil == production_all_device then
	        domoticz.log( 'Device ' .. PRODUCTION_ALL_NAME .. ' not found.', domoticz.LOG_ERROR)
	    elseif nil == efficiency_all_device then
	        domoticz.log( 'Device ' .. EFFICIENCY_ALL_NAME .. ' not found.', domoticz.LOG_ERROR)
	    else
	        local efficiency
	        if solar_power_device.sensorValue > 0 then
	            efficiency = 100.0 * ((production_all_device.actualWatt / (NUM_PANELS * PANEL_M2)) / solar_power_device.sensorValue)
	        else
	            efficiency = nil
	        end
		    domoticz.log('Efficiency ALL = ' .. tostring(efficiency) .. '.', domoticz.LOG_INFO)
		    efficiency_all_device.updatePercentage(efficiency)
	    end
	    
	    local east_device = domoticz.devices(EFFICIENCY_EAST_NAME)
	    if nil == east_device then
	        domoticz.log( 'Device ' .. EFFICIENCY_EAST_NAME .. ' not found.', domoticz.LOG_ERROR)
	    else
	        local power = 0
	        local m2 = 0
	        for _, name in ipairs(PRODUCTION_EAST_NAMES) do
	            local d = domoticz.devices(name)
	            if nil == d then
	                domoticz.log( 'Device ' .. d .. ' not found.', domoticz.LOG_ERROR)
	            else
	                power = power + d.actualWatt
	                m2 = m2 + 1.65
	            end
            end
	        local efficiency
	        if solar_power_device.sensorValue > 0 then
	            efficiency = 100.0 * ((power / m2) / solar_power_device.sensorValue)
	        else
	            efficiency = nil
	        end
		    domoticz.log('Efficiency EAST = ' .. tostring(efficiency) .. '.', domoticz.LOG_INFO)
		    east_device.updatePercentage(efficiency)
        end
	        
	    
	    local west_device = domoticz.devices(EFFICIENCY_WEST_NAME)
	    if nil == west_device then
	        domoticz.log( 'Device ' .. EFFICIENCY_WEST_NAME .. ' not found.', domoticz.LOG_ERROR)
	    else
	        local power = 0
	        local m2 = 0
	        for _, name in ipairs(PRODUCTION_WEST_NAMES) do
	            local d = domoticz.devices(name)
	            if nil == d then
	                domoticz.log( 'Device ' .. d .. ' not found.', domoticz.LOG_ERROR)
	            else
	                power = power + d.actualWatt
	                m2 = m2 + 1.65
	            end
            end
	        local efficiency
	        if solar_power_device.sensorValue > 0 then
	            efficiency = 100.0 * ((power / m2) / solar_power_device.sensorValue)
	        else
	            efficiency = nil
	        end
		    domoticz.log('Efficiency WEST = ' .. tostring(efficiency) .. '.', domoticz.LOG_INFO)
		    west_device.updatePercentage(efficiency)
        end

	end
}