local FAN_NAME_HIGH = 'Ventilatie: Hoog'
local FAN_NAME_MIDDLE = 'Ventilatie: Midden'

local KEUKEN_SENSOR_NAME = 'Keuken: TempHum'
local BADKAMER_SENSOR_NAME = 'Badkamer: TempHum'
local WASHOK_SENSOR_NAME = 'Washok: TempHum'
local WOONKAMER_SENSOR_NAME = 'Woonkamer: TempHum'
local CO_SENSOR_NAME = 'Washok: CO'
local BUITEN_SENSOR_NAME = 'Buiten: TempHum'

local HUMIDITY_SETTING_DEVICE_NAME = 'Luchtvochtigheid'

local QUIET_SWITCH_NAME = 'Slaaptijd'
local WC_AFZUIGING_SWITCH_NAME = 'WC Afzuiging'
local BADKAMER_AFZUIGING_SWITCH_NAME = 'Badkamer Afzuiging'
local NIEMAND_THUIS_SWITCH_NAME = 'Niemand thuis'

local STATUS_SWITCH_NAME = 'Ventilatie'


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
            BADKAMER_AFZUIGING_SWITCH_NAME,
            NIEMAND_THUIS_SWITCH_NAME,
            CO_SENSOR_NAME,
            STATUS_SWITCH_NAME,
--            FAN_NAME_HIGH,
--            FAN_NAME_MIDDLE
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
            status = {initial = 0},
            CODetected = {initial = false},
            quiet_time = {initial = false},
            niemand_thuis = {initial = false},
            wc_afzuiging = {initial = false},
            badkamer_afzuiging = {initial = false}
        },
    execute = function(domoticz, device, triggerInfo)
        if (domoticz.EVENT_TYPE_TIMER == triggerInfo.type) then
            domoticz.log( 'timer event: '..tostring(triggerInfo.trigger)..'.')
            
        elseif (domoticz.EVENT_TYPE_DEVICE == triggerInfo.type) then
            domoticz.log( 'device event: '..device.name..', deviceType: '..device.deviceType..'.')

            if (BUITEN_SENSOR_NAME == device.name) then
                if (domoticz.data.humidityBuiten ~= device.humidity) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.humidityBuiten)..' -> '..tostring(device.humidity)..'.')
                    domoticz.data.humidityBuiten = device.humidity
                end
                if (domoticz.data.tempBuiten ~= device.temperature) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.tempBuiten)..' -> '..tostring(device.temperature)..'.')
                    domoticz.data.tempBuiten = device.temperature
                end

            elseif (CO_SENSOR_NAME == device.name) then
                if ((device.state == 'On' and domoticz.data.CODetected ~= true) or (device.state == 'Off' and domoticz.data.CODetected ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.CODetected)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.CODetected = (device.state == 'On')
                end

            elseif (QUIET_SWITCH_NAME == device.name) then
                if ((device.state == 'On' and domoticz.data.quiet_time ~= true) or (device.state == 'Off' and domoticz.data.quiet_time ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.quiet_time)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.quiet_time = (device.state == 'On')
                end

            elseif (NIEMAND_THUIS_SWITCH_NAME == device.name) then
                if ((device.state == 'On' and domoticz.data.niemand_thuis ~= true) or (device.state == 'Off' and domoticz.data.niemand_thuis ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.niemand_thuis)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.niemand_thuis = (device.state == 'On')
                end

            elseif (WC_AFZUIGING_SWITCH_NAME == device.name) then
                if ((device.state == 'On' and domoticz.data.wc_afzuiging ~= true) or (device.state == 'Off' and domoticz.data.wc_afzuiging ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.wc_afzuiging)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.wc_afzuiging = (device.state == 'On')
                end

            elseif (BADKAMER_AFZUIGING_SWITCH_NAME == device.name) then
                if ((device.state == 'On' and domoticz.data.badkamer_afzuiging ~= true) or (device.state == 'Off' and domoticz.data.badkamer_afzuiging ~= false)) then
                    domoticz.log(device.name..': '..tostring(domoticz.data.badkamer_afzuiging)..' -> '..tostring(device.state == 'On')..'.')
                    domoticz.data.badkamer_afzuiging = (device.state == 'On')
                end

            elseif (HUMIDITY_SETTING_DEVICE_NAME == device.name) then
                if (device.level ~= domoticz.data.humidityTarget) then
                    -- My humidity sensors won't indicate higher than 90%, so I don't allow
                    -- a setting higher than 90% either or the fans will never stop.
                    domoticz.data.humidityTarget = math.min(device.level, 90)
                    if (device.level ~= domoticz.data.humidityTarget) then
                        domoticz.log(device.name..': '..tostring(device.level)..' -> '..tostring(domoticz.data.humidityTarget)..'.')
                        device.setLevel(domoticz.data.humidityTarget).silent()
                    end
                end
                domoticz.log(device.name..': '..tostring(domoticz.data.status)..' -> '..tostring(device.state == 'On')..'.')
                
                if device.active then
                    if domoticz.data.status ~= 0 then
                        domoticz.data.status = 0    -- "Auto"
                    end
                else
                    local device_high = domoticz.devices( FAN_NAME_HIGH )
                    local device_middle = domoticz.devices( FAN_NAME_MIDDLE )
                    
                    if nil == device_high then
                        domoticz.log( "Device " .. tostring(FAN_NAME_HIGH) .. " is missing.", domoticz.LOG_ERROR)
                    elseif nil == device_middle then
                        domoticz.log( "Device " .. tostring(FAN_NAME_MIDDLE) .. " is missing.", domoticz.LOG_ERROR)
                    elseif device_high.active then
                        domoticz.data.status = 30
                    elseif device_middle.active then
                        domoticz.data.status = 20
                    else
                        domoticz.data.status = 10
                    end
                end

                local status_device = domoticz.devices( STATUS_SWITCH_NAME )
                
                if nil == status_device then
                    domoticz.log( "Device " .. tostring(STATUS_SWITCH_NAME) .. " is missing.", domoticz.LOG_ERROR)
                elseif status_device.level ~= domoticz.data.status then
                    status_device.switchSelector(domoticz.data.status).silent()
                end
            
            elseif (STATUS_SWITCH_NAME == device.name) then
                if domoticz.data.status ~= device.level then
                    domoticz.data.status = device.level
                end
                
                local level_device = domoticz.devices( HUMIDITY_SETTING_DEVICE_NAME )
                
                if nil == level_device then
                    domoticz.log("Device " .. tostring(HUMIDITY_SETTING_DEVICE_NAME) .. " is missing.", domoticz.LOG_ERROR)
                elseif 0 == device.level then
                    if false == level_device.active then
                        level_device.switchOn().silent()
                        --level_device.switchSelector(level_device.level).silent()
                        --level_device.setLevel(level_device.level).silent()
                    end
                else
                    if true == level_device.active then
                        level_device.switchOff().silent()
                    end
                end

            elseif (device.name == KEUKEN_SENSOR_NAME or device.name == BADKAMER_SENSOR_NAME or device.name == WASHOK_SENSOR_NAME or device.name == WOONKAMER_SENSOR_NAME) then
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
                        domoticz.log(device.name..': max humidity '..tostring(domoticz.data.humidityBinnen)..' -> '..tostring(max_humidity)..'.')
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
                        domoticz.log(device.name..': max temperature '..tostring(domoticz.data.tempBinnen)..' -> '..tostring(max_temperature)..'.')
                        domoticz.data.tempBinnen = max_temperature
                    end
                end
            end
        
            local measured_humidity = domoticz.data.humidityBinnen
            local target_humidity = math.max(domoticz.data.humidityTarget, domoticz.data.humidityBuiten - 20)
            
            local switch_device = domoticz.devices( STATUS_SWITCH_NAME )
            local stat
            if nil ~= switch_device then
                --domoticz.utils.dumpTable(switch_device.levelNames)
                --stat = switch_device.levelNames[domoticz.data.status]
                -- todo: find the correct name for the level in domoticz.data.status.
                stat = switch_device.levelName
            else
                stat = tostring(domoticz.data.status)
            end
            domoticz.log('Status: ' .. stat .. 
                    ', setpoint: ' .. tostring(domoticz.data.humidityTarget) ..
                    ', buiten: ' .. tostring(domoticz.data.humidityBuiten) .. 
                    ', max humidity ' .. tostring(domoticz.data.humidityBinnen) .. 
                    ', target: '..tostring(target_humidity)..'.', domoticz.LOG_FORCE)


            local fan_middle
            local fan_high

            if (domoticz.data.CODetected == true) then
                domoticz.log('CO detected!', domoticz.LOG_FORCE)
                
                fan_middle = 'On'
                fan_high = 'On'

            elseif domoticz.data.status == 30 then  -- manual high level
                domoticz.log('Manual override: high')
                
                fan_middle = 'Off'
                fan_high = 'On'
                
            elseif domoticz.data.status == 20 then  -- manual medium level
                domoticz.log('Manual override: medium')
                
                fan_middle = 'On'
                fan_high = 'Off'
                
            elseif domoticz.data.status == 10 then  -- manual low level
                domoticz.log('Manual override: low')
                
                fan_middle = 'Off'
                fan_high = 'Off'
                
            elseif (measured_humidity >= 90 and domoticz.data.quiet_time ~= true) then
                domoticz.log('humidity >= 90%')

                fan_middle = 'Off'
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
                domoticz.log('humidity more than 10% over target')

                fan_middle = 'On'
                fan_high = 'Off'

            elseif (measured_humidity > target_humidity) then
                domoticz.log('Humidity is <= 10% over target')
                
                fan_middle = 'On'
                fan_high = 'Off'

            elseif (domoticz.data.wc_afzuiging == true or domoticz.data.badkamer_afzuiging == true) then
                domoticz.log('timer active')
                
                fan_middle = 'On'
                fan_high = 'Off'

            else
                
                fan_middle = 'Off'
                fan_high = 'Off'

            end
            
            local device_middle = domoticz.devices(FAN_NAME_MIDDLE)
            local device_high = domoticz.devices(FAN_NAME_HIGH)
            
            if nil == device_middle then
                domoticz.log( 'Device '.. tostring(FAN_NAME_MIDDLE)..' is missing.', domoticz.LOG_ERROR)
            elseif nil == device_high then
                domoticz.log( 'Device '.. tostring(FAN_NAME_HIGH)..' is missing.', domoticz.LOG_ERROR)
            else
                if (device_middle.state ~= fan_middle) then
                    if (fan_middle == 'On') then
                        device_middle.switchOn().silent()
                    else
                        device_middle.switchOff().silent()
                    end
                end
                if (device_high.state ~= fan_high) then
                    if (fan_high == 'On') then
                        device_high.switchOn().silent()
                    else
                        device_high.switchOff().silent()
                    end
                end
            end
        elseif (domoticz.EVENT_TYPE_VARIABLE == triggerInfo.type) then
                domoticz.log( 'variable event: '..tostring(triggerInfo.trigger)..'.')
        elseif (domoticz.EVENT_TYPE_SECURITY == triggerInfo.type) then
            domoticz.log( 'security event: '..tostring(triggerInfo.trigger)..'.')
        end
    end
}