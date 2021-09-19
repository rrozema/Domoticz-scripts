local TIMER_EVENT_NAME = 'every 15 minutes'
local OUTSIDE_TEMPERATURE_NAME = 'Buiten: TempHum'
local AVERAGE_TEMPERATURE_NAME = 'Buiten: Gemiddelde temperatuur'
local GAS_USAGE_NAME = 'Gas'
local AVERAGE_USAGE_DHW_NAME = 'Gemiddeld gasverbruik DHW'
local USAGE_PER_DEGREESDAY_NAME = 'Gasverbruik per graaddag'
local DEGREESDAYS_NAME = 'Graaddagen'


-- Standard temperature that people tend to switch their heating on.
local BASETEMP = 18 

-- m3 gas used in the month July divided by 31 to get the usage per 24h.
-- Used to compensate for gas used for DHW (Domestic Hot Water), for 
-- example to shower and other hot water.
local AVERAGE_USAGE_DHW = (14.75 / 31)

return {
	on = {
		timer = {
			TIMER_EVENT_NAME
		}
	},
	logging = {
		level = domoticz.LOG_INFO,
		marker = 'Heating costs',
	},
	data = {
        temperatures = { history = true, maxHours = 24 },
        m3s = { history = true, maxHours = 24 }
    },
	execute = function(domoticz, item)
	    if item.isTimer and TIMER_EVENT_NAME == item.trigger then
		    local outside_temperature_device = domoticz.devices(OUTSIDE_TEMPERATURE_NAME)
		    local average_temperature_device = domoticz.devices(AVERAGE_TEMPERATURE_NAME)
		    local gas_usage_device = domoticz.devices(GAS_USAGE_NAME)
		    local average_usage_DHW_device = domoticz.devices(AVERAGE_USAGE_DHW_NAME)
		    local usage_per_degreesday_device = domoticz.devices(USAGE_PER_DEGREESDAY_NAME)
		    local degreesdays_device = domoticz.devices(DEGREESDAYS_NAME)

		    if nil == outside_temperature_device then
		        domoticz.log( 'Device ' .. OUTSIDE_TEMPERATURE_NAME .. ' not found.', domoticz.LOG_ERROR)
		    elseif nil == average_temperature_device then
		        domoticz.log( 'Device ' .. AVERAGE_TEMPERATURE_NAME .. ' not found.', domoticz.LOG_ERROR)
		    elseif nil == gas_usage_device then
		        domoticz.log( 'Device ' .. GAS_USAGE_NAME .. ' not found.', domoticz.LOG_ERROR)
		    elseif nil == average_usage_DHW_device then
		        domoticz.log( 'Device ' .. AVERAGE_USAGE_DHW_NAME .. ' not found.', domoticz.LOG_ERROR)
		    elseif nil == usage_per_degreesday_device then
		        domoticz.log( 'Device ' .. USAGE_PER_DEGREESDAY_NAME .. ' not found.', domoticz.LOG_ERROR)
		    elseif nil == degreesdays_device then
		        domoticz.log( 'Device ' .. DEGREESDAYS_NAME .. ' not found.', domoticz.LOG_ERROR)
		    else
		        -- Add the current outside temperature to our set of temperatures.
		        domoticz.data.temperatures.add(outside_temperature_device.temperature)
		        
		        -- Calculate the average temperature over the last 24 hours.
		        local average_outside_temperature = domoticz.data.temperatures.avg()
		        average_temperature_device.updateTemperature(average_outside_temperature)

		        -- Add the current gas meter counter value to our set of counter values.
		        domoticz.data.m3s.add(gas_usage_device.counter)
                -- Now get the oldest and lastest counter values.
		        local oldest = domoticz.data.m3s.getOldest()
		        local latest = domoticz.data.m3s.getLatest()

                -- Determine the times these oldest and latest values were added.
		        local tOldest = oldest.time
		        local tLatest = latest.time

		        -- Latest measurement must be after oldest or we can't calculate a valid value for usage.
		        if tOldest.compare(tLatest).compare > 0 then
    		        local usage = latest.data - oldest.data  -- Usage in liters (=1/1000 m3) from the oldest measurement 
	    	                                                 -- in our set to latest entry. Normally this should be 
		                                                     -- roughly 24 hours. But when starting the process or when 
		                                                     -- the previous message was over 24 hours old, it could be
		                                                     -- less or even zero. If the latest measurement is also the
		                                                     -- oldest measurement we can't calculate a usage, in all 
		                                                     -- other cases we're going to extrapolate this usage for
		                                                     -- an exact 24 hour period.

--                    domoticz.log( 'usage = ' .. domoticz.utils.toStr(usage) ..'.', domoticz.LOG_ERROR)

		            -- Get the number of seconds between tOldest and tLatest
		            local seconds = tOldest.compare(tLatest).seconds
		            -- Calculate the usage for a 24 hour period.
		            usage = usage * ((24 * 60 * 60) / seconds)
		            
		            -- Subtract the gas used for other purposes than heating. Determined by
		            -- taking July's usage (assuming you don't use your heating in July 
		            -- because it's summer) and dividing this by the number of days in July 
		            -- to get the average amount used per 24h. If you've been on holidays 
		            -- most of July, just pick another period in summer for which you think 
		            -- the usage is representive for a 'normal day' in your house and the 
		            -- heating was off.
		            average_usage_DHW_device.updateCustomSensor(AVERAGE_USAGE_DHW)
		            if usage > AVERAGE_USAGE_DHW then
		                usage = usage - AVERAGE_USAGE_DHW
		            else
		                usage = 0
		            end

                    domoticz.log( 'seconds = ' .. domoticz.utils.toStr(seconds) ..', usage = ' .. domoticz.utils.toStr(usage) ..'.', domoticz.LOG_ERROR)

		            -- todo: update usage/24h device

                    -- The temperature at which people tend to switch on the heating. (https://nl.wikipedia.org/wiki/Graaddag)
		            local baseTemp = BASETEMP

        		    local degreesdays
        		    local usage_per_degreesday
        		    if baseTemp > average_outside_temperature then
    		            -- A factor to compensate for the time of the year, as taken from ehoco.nl's script.
	    	            local factor
		                if (tLatest.month >= 4 and tLatest.month <= 9) then 
		                    factor = 0.8 
		                elseif (tLatest.month >= 11 or tLatest.month <= 2) then 
		                    factor = 1.1
		                else
		                    factor = 1
		                end

        		        degreesdays = factor * (baseTemp - average_outside_temperature)

            		    usage_per_degreesday = domoticz.utils.round((usage / degreesdays),3)
        		    else
        		        degreesdays = 0
        		        usage_per_degreesday = 0
        		    end

                    degreesdays_device.updateCounter(degreesdays)
        		    usage_per_degreesday_device.updateCustomSensor(usage_per_degreesday)

            		domoticz.log('Gemiddelde temperatuur buiten (laatste 24u): '.. tostring(average_outside_temperature), domoticz.LOG_INFO)
		            domoticz.log('Gasverbruik (laatste 24u): ' .. tostring(usage) .. ' m3', domoticz.LOG_INFO)
		            domoticz.log('Aantal graaddagen: ' .. tostring(degreesdays), domoticz.LOG_INFO)
		            domoticz.log('Gasverbruik: ' .. tostring(usage_per_degreesday) .. ' m3 per graaddag', domoticz.LOG_INFO)
        		else
        		    domoticz.log('Insufficient data available to calculate usage. Please wait until more measurements are available.', domoticz.LOG_WARNING)
        		end
        	end
		end
	end
}
