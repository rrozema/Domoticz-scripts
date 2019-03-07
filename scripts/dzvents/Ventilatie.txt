local FAN_NAME_HIGH = 'Ventilatie: Hoog'
local FAN_NAME_MIDDLE = 'Ventilatie: Midden'

local KEUKEN_SENSOR_NAME = 'Keuken'
local BADKAMER_SENSOR_NAME = 'Badkamer'
local WASHOK_SENSOR_NAME = 'Washok'
local WOONKAMER_SENSOR_NAME = 'Woonkamer'
local CO_SENSOR_NAME = 'CO Sensor'
local BUITEN_SENSOR_NAME = 'Buiten'

local HUMIDITY_SETTING_DEVICE_NAME = 'Humidity setting'

local QUIET_SWITCH_NAME = 'Slaaptijd'
local WC_AFZUIGING_SWITCH_NAME = 'WC Afzuiging'
local NIEMAND_THUIS_SWITCH_NAME = 'Niemand thuis'

return {
--    active = true ,
    on = {
--        devices = { '*' },
        devices = { 
            BADKAMER_SENSOR_NAME,
            KEUKEN_SENSOR_NAME,
            WASHOK_SENSOR_NAME,
            WOONKAMER_SENSOR_NAME,
            BUITEN_SENSOR_NAME,
            HUMIDITY_SETTING_DEVICE_NAME,
            QUIET_SWITCH_NAME,
            WC_AFZUIGING_SWITCH_NAME,
            NIEMAND_THUIS_SWITCH_NAME,
            CO_SENSOR_NAME
        }
--        variables = { ... },
--        timer = { 'every minute' }
--        security = { ... }
    },
--    logging = {
--        level = domoticz.LOG_INFO
----        level = domoticz.LOG_DEBUG
--    },  
    data = { 
            humidityTarget = {initial = 60},
            humidityBinnen = {initial = 0},
            humidityBuiten = {initial = 0},
            tempBuiten = {initial = 0},
            tempBinnen = {initial = 0},
            manual = {initial = false},
            CODetected = {initial = false},
            quiet_time = {initial = false},
            niemand_thuis = {initial = false},
            wc_afzuiging = {initial = false}
        },
    execute = function(domoticz, device, triggerInfo)
        if (domoticz.EVENT_TYPE_TIMER == triggerInfo.type) then
            domoticz.log( 'timer event: '..tostring(triggerInfo.trigger)..'.')
            
        elseif (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
            domoticz.log( 'device event: '..device.name..', deviceType: '..device.deviceType..'.')
            if (device.name == BUITEN_SENSOR_NAME) then
                if (domoticz.data.humidityBuiten ~= device.humidity) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.humidityBuiten)..' -> '..tostring(device.humidity)..'.', domoticz.LOG_FORCE)
                    domoticz.data.humidityBuiten = device.humidity
                end
                if (domoticz.data.tempBuiten ~= device.temperature) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.tempBuiten)..' -> '..tostring(device.temperature)..'.', domoticz.LOG_FORCE)
                    domoticz.data.tempBuiten = device.temperature
                end
            elseif (device.name == CO_SENSOR_NAME) then
                if ((device.state == 'On' and domoticz.data.CODetected ~= true) or (device.state == 'Off' and domoticz.data.CODetected ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.CODetected)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.CODetected = (device.state == 'On')
                end
            elseif (device.name == QUIET_SWITCH_NAME) then
                if ((device.state == 'On' and domoticz.data.quiet_time ~= true) or (device.state == 'Off' and domoticz.data.quiet_time ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.quiet_time)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.quiet_time = (device.state == 'On')
                end
            elseif (device.name == NIEMAND_THUIS_SWITCH_NAME) then
                if ((device.state == 'On' and domoticz.data.niemand_thuis ~= true) or (device.state == 'Off' and domoticz.data.niemand_thuis ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.niemand_thuis)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.niemand_thuis = (device.state == 'On')
                end
            elseif (device.name == WC_AFZUIGING_SWITCH_NAME) then
                if ((device.state == 'On' and domoticz.data.wc_afzuiging ~= true) or (device.state == 'Off' and domoticz.data.wc_afzuiging ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.wc_afzuiging)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.wc_afzuiging = (device.state == 'On')
                end
            elseif (device.name == HUMIDITY_SETTING_DEVICE_NAME) then
                if (device.level ~= domoticz.data.humidityTarget) then
                    -- My humidity sensors won't indicate higher than 90%, so I don't allow
                    -- a setting higher than 90% either or the fans will never stop.
                    domoticz.data.humidityTarget = math.min(device.level, 90)
                    if (device.level ~= domoticz.data.humidityTarget) then
                        domoticz.log(device.name..': '..tostring(device.level)..' -> '..tostring(domoticz.data.humidityTarget)..'.')
                        device.switchSelector(domoticz.data.humidityTarget)
                    end
                end
                domoticz.log(device.name..': '..tostring(domoticz.data.manual)..' -> '..tostring(device.state == 'On')..'.')
                if ((device.state == 'On' and domoticz.data.manual ~= false) or (device.state == 'Off' and domoticz.data.manual ~= true)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.manual)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.manual = (device.state ~= 'On')
                end
            elseif (device.name == KEUKEN_SENSOR_NAME or device.name == BADKAMER_SENSOR_NAME or device.name == WASHOK_SENSOR_NAME or device.nmae == WOONKAMER_SENSOR_NAME) then
                local sensors = domoticz.devices().filter({ KEUKEN_SENSOR_NAME, BADKAMER_SENSOR_NAME, WASHOK_SENSOR_NAME, WOONKAMER_SENSOR_NAME})
                local max_humidity = sensors.reduce(
                        function(acc, device)
                            if (device.timedOut ~= true) then -- device.lastUpdate.hoursAgo <= 4) then
                                if (acc == nil or device.humidity > acc) then
                                    acc = device.humidity
                                end
                            end
                            return acc -- always return the accumulator
                        end, 
                        nil) -- nil is the initial value for the accumulator
                if (max_humidity ~= nil) then
                    if (domoticz.data.humidityBinnen ~= max_humidity) then
                        domoticz.log(device.name..': max humidity '..tostring(domoticz.data.humidityBinnen)..' -> '..tostring(max_humidity)..'.', domoticz.LOG_INFO)
                        domoticz.data.humidityBinnen = max_humidity
                    end
                end
                local max_temperature = sensors.reduce(
                        function(acc, device)
                            if (device.timedOut ~= true) then --device.lastUpdate.hoursAgo <= 4) then
                                if (acc == nil or (math.floor(device.temperature * 10 + 0.05)) / 10 > acc) then
                                    acc = math.floor(device.temperature * 10 + 0.05) / 10
                                end
                            end
                            return acc -- always return the accumulator
                        end, 
                        nil) -- nil is the initial value for the accumulator
                if (max_temperature ~= nil) then
                    if (domoticz.data.tempBinnen ~= max_temperature) then
                        domoticz.log(device.name..': max temperature '..tostring(domoticz.data.tempBinnen)..' -> '..tostring(max_temperature)..'.', domoticz.LOG_INFO)
                        domoticz.data.tempBinnen = max_temperature
                    end
                end
            end
        
            local measured_humidity = domoticz.data.humidityBinnen
            local target_humidity = math.max(domoticz.data.humidityTarget, domoticz.data.humidityBuiten - 20)

            domoticz.log('Max humidity '..tostring(domoticz.data.humidityBinnen)..', setpoint: '..tostring( domoticz.data.humidityTarget)..', buiten: '..tostring( domoticz.data.humidityBuiten)..', target: '..tostring(target_humidity)..'.', domoticz.LOG_FORCE)


            if (domoticz.data.CODetected == true or domoticz.data.manual ~= true) then
                local fan_middle
                local fan_high
                
                if (domoticz.data.CODetected == true) then
                    domoticz.log('CO detected!', domoticz.LOG_FORCE)
                    fan_middle = 'On'
                    fan_high = 'On'
                elseif (measured_humidity >= 90 and domoticz.data.quiet_time ~= true) then
                    domoticz.log('humidity >= 90%', domoticz.LOG_FORCE)
                    fan_middle = 'On'
                    fan_high = 'On'
                elseif (measured_humidity > target_humidity + 10 
                                                                            -- If the humidity is more than 10% over the target, set 
                                                                            -- ventilation to "high".
                        and domoticz.data.quiet_time ~= true                -- But, during the night I don't want the fans to go
                                                                            -- howling, even if it's wet.
--                        and (math.abs(domoticz.data.tempBinnen - measured_humidity) >= 2
--                            or measured_humidity > domoticz.data.humidityBuiten)) then
--                                                                            -- And, if there is hardly no temperature difference between 
--                                                                            -- inside and outside, my WTW will not have any condensation, 
--                                                                            -- so no water will be extracted from the incoming air. It is 
--                                                                            -- a waste of energy to replace large volumes of inside air 
--                                                                            -- by outside air unless that outside air is dryer than the
--                                                                            -- inside air.
                        ) then
                    domoticz.log('Humidity more than 10% over target', domoticz.LOG_FORCE)
                    fan_middle = 'On'
                    fan_high = 'On'
                elseif (measured_humidity > target_humidity or domoticz.data.wc_afzuiging == true) then
                    domoticz.log('Humidity over target', domoticz.LOG_FORCE)
                    fan_middle = 'On'
--                    if (domoticz.data.niemand_thuis) then
--                        fan_high = 'On'
--                    else
                        fan_high = 'Off'
--                    end
                else
--                    domoticz.log('Humidity at or under target', domoticz.LOG_FORCE)
                    fan_middle = 'Off'
                    fan_high = 'Off'
                end
                
                local device_middle = domoticz.devices(FAN_NAME_MIDDLE)
                if (device_middle.state ~= fan_middle) then
                    domoticz.log('Fan '..device_middle.name..': '..tostring(device_middle.state)..' -> '..tostring(fan_middle)..'.', domoticz.LOG_INFO)
                    if (fan_middle == 'On') then
                        device_middle.switchOn()
                    else
                        device_middle.switchOff()
                    end
                end
                local device_high = domoticz.devices(FAN_NAME_HIGH)
                if (device_high.state ~= fan_high) then
                    domoticz.log('Fan '..device_high.name..': '..tostring(device_high.state)..' -> '..tostring(fan_high)..'.', domoticz.LOG_INFO)
                    if (fan_high == 'On') then
                        device_high.switchOn()
                    else
                        device_high.switchOff()
                    end
                end
--            else
--                domoticz.log('Fans are on manual control.')
            end
        elseif (domoticz.EVENT_TYPE_VARIABLE == triggerInfo.type) then
                domoticz.log( 'variable event: '..tostring(triggerInfo.trigger)..'.')
        elseif (domoticz.EVENT_TYPE_SECURITY == triggerInfo.type) then
            domoticz.log( 'security event: '..tostring(triggerInfo.trigger)..'.')
        end
    end
}