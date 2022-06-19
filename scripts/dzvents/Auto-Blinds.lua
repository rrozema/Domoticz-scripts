--[[
This script can be used to automatically open and close different types of 
blinds and/or turn slates to or away from the sun in order to keep the room 
behind the binds cool during summer and help keeping heat inside the room 
during winter time. Behavior of and features of the blinds can be configured
individually independent of each other.
Many ideas used in this script are based on a cool script created by hestia 
over at the Domoticz forum.
hestia : https://www.domoticz.com/forum/memberlist.php?mode=viewprofile&u=17872)
his script : https://www.domoticz.com/forum/viewtopic.php?t=36640


tips to setup the selector for a Roller, Vertical or Zebra blind (blindId)
10: &#9650  => UP
20: &#9724  => STOP
30: &#9660  => DOWN
40: A       => Auto

An alternative for horizontal blinds can be:
10: &#x25C0     => LEFT
20: &#9724      => STOP
30: &#x25B6     => RIGHT
40: A           => Auto

Or for curtains that open to both sides:
10: &#x25C0&#x25B6  => OPEN
20: &#x3C           => STOP
30: &#x25B6&#x25C0  => CLOSE
40: A               => Auto

This script can control different types of blinds:
    'R' - Roller blinds
        Roller blinds can move up (open) and down (close).
    'H' - Horizontal blinds
        Horizontal blinds have slats that can be tilted horizontally to 
        block sunlight.
    'V' - Vertical blinds
        Vertical blinds have slats that can be tilted vertically to
        block sunlight.
    'Z' - Zebra shades
        Zebra shades can move up (open) and down (close) like roller blinds
        but have specific zones in which sunlight can pass through them.


 Configuration
For the script to work some global properties must be set up first, then
individual blinds can be configured.

Global properties to set up
TODO

Setting up individual blinds
For each blind controlled by this script a dummy device must created to set 
the mode for this blind. Furthermore an entry must be created in the blinds
table below for each dummy device, to define the features and behavior
of the blind.

The dummy device
TODO

The BLINDS entry
TODO


prerequisites: dzVents Version: 3.0.2
3 sensors: 
SOLAR_ALTITUDE  Device that give Solar Altitude see https://www.domoticz.com/wiki/index.php?title=Lua_dzVents_-_Solar_Data:_Azimuth_Altitude_Lux
SOLAR_AZIMUTH   Device that give Solar Azimuth see https://www.domoticz.com/wiki/index.php?title=Lua_dzVents_-_Solar_Data:_Azimuth_Altitude_Lux
OUTSIDE_TEMP    Device that give Outside temperature
SUN_CRITERIA    Device that give the value of the outside criteria to determine if the blind must be closed because it is too sunny
    (lux, temperature, cloud cover for instance)

--]]


------------------------------> Start of configuration section <----------------


local SOLAR_ALTITUDE_IDX = 1197     -- Device that gives Solar Altitude.
local SOLAR_AZIMUTH_IDX = 1198      -- Device that gives Solar Azimuth.

local OUTSIDE_TEMP_IDX = 1033       -- Device that gives Outside temperature
local OUTSIDE_TEMP_MARGIN = .8      -- Margin to have an hysteresis to change 
                                    -- mode or programm to avoid multiple 
                                    -- changes when few changes of temp.

-- SUN_CRITERIA: 1 or 2 devices to determine if the blind must be closed 
-- (according to the sun position) because it is too sunny. It can be 
-- temperature, solar radiation in lux, or solar radiation in W/m2.
-- If solar radiation, there can be 1 or 2 devices
-- If 1 device, it is a total radiation value (usually on the ground).
-- If 2 device, the SUN_CRITERIA1 is the direct radiation and SUN_CRITERIA2 is 
-- the scattered (or diffuse) radiation and the total radiation is calculated 
-- on the surface of the blind with the angle of this surface and the sun.
local SUN_CRITERIA1_IDX = 1201
local SUN_CRITERIA2_IDX = nil       -- If the first is the direct radiation, 
                                    -- this one is the scattered radiation.
local SUN_CRITERIA_MARGIN = 50      -- Marging to have an hysteresis to change 
                                    -- mode or programm to avoid multiple 
                                    -- changes when few changes of the value.


-- Level values for the Dummy switches
local DUMMY_LEVEL_OPEN  = 10
local DUMMY_LEVEL_STOP  = 20
local DUMMY_LEVEL_CLOSE = 30
local DUMMY_LEVEL_AUTO  = 40


-- Defaults to use when no value is specified for a specific blind.
local ALL_MAX_SUN_CRITERIA = 200
local ALL_MIN_OUTSIDE_TEMP = 20


-- Definition of the blinds that this script should control.
local BLINDS = {

    ['Richard: Rolluik Mode'] = {           -- The dummy device used to set the 
                                            -- mode of the blind. Can be device
                                            -- id or 'name'.
                                            
        ['blindId'] = 'Richard: Rolluik',   -- The switch to control. Can be 
                                            -- device id or 'name'. No default.

        ['blindType'] = 'R',                -- Roller blind. No default.

--        ['blindAzimuth'] = 234,             -- Angle from North to where the sun
        ['blindAzimuth'] = 254,             -- Angle from North to where the sun
                                            -- is perpendicular to the blind 
                                            -- (like the Azimuth). No default.

        ['SOLAR_ALTITUDE_MIN'] = 2,         -- Solar Altitude from where the sun
                                            -- is hidden behind a house, a tree,
                                            -- etc.. Default is 0.

        ['MAX_SUN_CRITERIA'] = ALL_MAX_SUN_CRITERIA,
                                            -- If sun criteria is more than this
                                            -- value, the blind is closed during
                                            -- the day and according to the sun 
                                            -- position. Value depends on the 
                                            -- type sensor is specified for 
                                            -- SUN_CRITERIA1. i.e. it can 
                                            -- temperature, UV, Lux or W/m2.
                                            -- Default is nil, which disables
                                            -- the HOT program for this blind.

        ['MIN_OUTSIDE_TEMP']  = ALL_MIN_OUTSIDE_TEMP,  -- If outside 
                                            -- temperature is less than this 
                                            -- temp, the blind is closed at 
                                            -- night (COLD program). Default is
                                            -- nil, which disables the COLD
                                            -- program for this blind.
                                            

        --['SLAT_DOWN_ANGLE']  = -90,       -- Angle from the horizontal when the slat is down (<0), -90 for vertical blind

        --['SLAT_UP_ANGLE'] = 90,           -- Angle from the horizontal when the slat is up, 90 for vertical blind

        --['SLAT_LENGHT']  = nil,           -- Length of the slate, any unit (cm...), nil for vertical blind

        --['SLAT_DISTANCE']  = nil,         -- Distance between slates, any unit (cm...), nil for vertical blind

        --['blindAngle']  = 90,             -- Angle of the blind from the horizontal (>0, 90 for blinds that hang vertically)

        --['TTC_SLAT_SEC'] = 1,             -- Time To Close the blind in seconds, to be measured, 1 for vertical blind

        ['LEVEL_OPEN'] = 100,               -- The level at which this blind is fully opened.

        ['LEVEL_CLOSED'] = 0                -- The level at which this blind is fully closed.
    },

    [1205] = {                              -- The dummy device used to control the 
                                            -- mode of the blind.
        ['blindId'] = 'test blind',         -- The switch to control (can be id or 'name').
        ['blindType'] = 'R',                -- Roller blind
--        ['blindAzimuth'] = 54,             -- Angle from North to where the sun is perpendicular to the blind (like the Azimuth)
        ['blindAzimuth'] = 74,             -- Angle from North to where the sun is perpendicular to the blind (like the Azimuth)
--        ['blindAzimuth'] = 164,             -- Angle from North to where the sun is perpendicular to the blind (like the Azimuth)
        --['SOLAR_ALTITUDE_MIN'] = 0,       -- Solar Altitude where the sun is hidden by a house, a tree, etc.. Default is 0.
        ['MAX_SUN_CRITERIA'] = ALL_MAX_SUN_CRITERIA,
                                            -- If criteria is more than this max critéria, the blind is closed during the day and according to the sun position (temperature, UV...) (HOT)
        ['MIN_OUTSIDE_TEMP']  = ALL_MIN_OUTSIDE_TEMP,  -- If outside temperature in less than this min temp, the blind is closed night (COLD) 

        --['SLAT_DOWN_ANGLE']  = -90,       -- Angle from the horizontal when the slat is down (<0), -90 for vertical blind
        --['SLAT_UP_ANGLE'] = 90,           -- Angle from the horizontal when the slat is up, 90 for vertical blind
        --['SLAT_LENGHT']  = nil,           -- Length of the slate, any unit (cm...), nil for vertical blind
        --['SLAT_DISTANCE']  = nil,         -- Distance between slates, any unit (cm...), nil for vertical blind
        --['blindAngle']  = 90,             -- Angle of the blind from the horizontal (>0, 90 for blinds that hang vertically)
        --['TTC_SLAT_SEC'] = 1,             -- Time To Close the blind in seconds, to be measured, 1 for vertical blind
        ['LEVEL_OPEN'] = 100,               -- The level at which this blind is fully opened.
        ['LEVEL_CLOSED'] = 0                -- The level at which this blind is fully closed.
    }
}


------------------------------> End of configuration section <------------------
--
-- No changes should be needed below this point for normal users of the script.
--
-- When a new version of the script is released you can simply copy the settings 
-- of your existing script over those in the newly released script.
--
------------------------- Start of code section <------------------------------


-- Devices that will cause positions for all blinds to be re-calculated.
local global_devices = {
    SOLAR_ALTITUDE_IDX,
    SOLAR_AZIMUTH_IDX,
    OUTSIDE_TEMP_IDX,
    SUN_CRITERIA1_IDX
}

-- If a device for sun criteria2 was specified, add this to the set of 
-- global devices.
if SUN_CRITERIA2_IDX ~= nil then
    table.insert( global_devices, SUN_CRITERIA2_IDX)
end



-- Devices that will trigger execution of this script.
-- First add all global devices.
local trigger_devices = global_devices

-- Now add to those each of the dummy devices defined in 
-- the BLINDS configuration set.
for dummyId, _ in pairs(BLINDS) do
    table.insert( trigger_devices, dummyId)
end




local SCRIPT_NAME = 'Auto-Blinds'
local SCRIPT_VERSION = '0.01'

return {
	on = {
--	    timer = {
--	        'every minute'
--	    },
		devices = trigger_devices
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
    	local _u = domoticz.utils
    	
    	
    	local function CalculateSlatAngles(domoticz, blindInfo, solarAltitude, solarAzimuth)
	    end

	    
        local function CalculateSunIncidence(domoticz, solarAzimuth, solarAltitude, areaAzimuth, areaInclination)
            --logWrite('CalculateSunIncidence')
            -- Calculate the sun incidence (the cosinus) on a tilt surface
    
            --solarAzimuth: azimuth of the sun in degrees (from the North)
            --solarAltitude: elevation of the sun or altitude in degrees
            --areaAzimuth: azimuth of the normale surface in degrees (from the North)
            --areaInclination: inclination of the surface (from the horizontal)
                
            --logWrite('solarAltitude: ' .. solarAltitude)
            --logWrite('solarAzimuth: ' .. solarAzimuth)
            --logWrite('areaInclination: ' .. areaInclination)
            --logWrite('areaAzimuth: ' .. areaAzimuth)
                
            local cosIncidence
                
            cosIncidence = _u.round(
                            math.cos(math.rad(solarAltitude)) 
                            * math.sin(math.rad(areaInclination)) 
                            * math.cos(math.rad(areaAzimuth - solarAzimuth))
                            + math.sin(math.rad(solarAltitude)) * math.cos(math.rad(areaInclination))
                        , 3)
            cosIncidence = _u.round(cosIncidence, 3)
    
            --logWrite('cosIncidence: ' .. cosIncidence)
--            local incidence = math.deg(math.acos(cosIncidence))
            --logWrite('incidence: ' .. incidence)
            
--            domoticz.log('SolarAltitude: ' .. solarAltitude .. ', SolarAzimuth: ' .. solarAzimuth .. '°'
--                .. ', AreaInclination: ' .. areaInclination .. '°, AreaAzimuth: ' .. areaAzimuth .. '°'
--                .. ', CosIncidence: ' .. cosIncidence .. ' ' .. ', Incidence: ' .. _u.round(incidence,0) .. '°', domoticz.LOG_DEBUG)
            return cosIncidence
        end
    


        local function GetSunCriteria(domoticz, sunCriteria1Dev, sunCriteria2Dev, solarAzimuth, solarAltitude, areaAzimuth, areaInclination)
            local criteriaFunction = {
                ['Temp'] =
                    function (domoticz, temperatureDevice)
                        return temperatureDevice.temperature, temperatureDevice.temperature, '°'
                    end,
                    
                ['Lux'] =
                    function (domoticz, luxDevice)
                        return luxDevice.lux, luxDevice.lux, 'Lux'
                    end,
                    
                ['Solar Radiation'] =
                    function (domoticz, solarRadiationDevice, scatteredRadiationDevice, solarAzimuth, areaAzimuth, areaInclination)
                        local solarRaditionScattered = nil ~= scatteredRadiationDevice and scatteredRadiationDevice.radiation or 0
                        
                        local cosIncidence = CalculateSunIncidence(domoticz, solarAzimuth, solarAltitude, areaAzimuth, areaInclination)
                        
--                        return math.max(_u.round(solarRadiationDevice.radiation * cosIncidence + solarRaditionScattered, 0), 0), -- <0, sun behind
--                            solarRadiationDevice.radiation,
--                            'W/m2'
                        return math.max(_u.round(solarRadiationDevice.radiation + solarRaditionScattered, 0), 0), -- <0, sun behind
                            solarRadiationDevice.radiation + solarRaditionScattered,
                            'W/m2'
                    end
            }

            local sunCriteriaCorrectedValue
            local sunCriteriaValue
            local sunCriteriaUnit
            if nil ~= sunCriteria1Dev then
                local f = criteriaFunction[sunCriteria1Dev.deviceSubType]
                if type(f) == "function" then
                    sunCriteriaCorrectedValue, sunCriteriaValue, sunCriteriaUnit = f(domoticz, sunCriteria1Dev, sunCriteria2Dev, solarAzimuth, areaAzimuth, areaInclination)
                else
                    domoticz.log(tostring(sunCriteria1Dev.id) .. ' ' .. tostring(sunCriteria1Dev.name) .. ' device type ' .. tostring(sunCriteria1Dev.deviceType) .. ' not supported.', domoticz.LOG_ERROR)
                end
            else
                domoticz.log('Sun Criteria device 1 not found.', domoticz.LOG_ERROR)
            end
            
            --domoticz.log('sunCriteria ' .. tostring(sunCriteriaValue), domoticz.LOG_DEBUG)
            return sunCriteriaCorrectedValue, sunCriteriaValue, sunCriteriaUnit
        end
	    

	    
        _G.logMarker =  domoticz.moduleLabel -- Set logmarker to scriptname.
        
        domoticz.log( SCRIPT_NAME .. ' v' .. SCRIPT_VERSION .. ', Domoticz v' .. domoticz.settings.domoticzVersion .. ', Dzvents v' .. domoticz.settings.dzVentsVersion .. '.', domoticz.LOG_DEBUG)
        
        if item.isDevice then
		    domoticz.log('Device ' .. tostring(item.name) .. ' was changed', domoticz.LOG_DEBUG)
		    
		else
		    domoticz.log( 'Unexpected trigger type for this script.', domoticz.LOG_ERROR)
		end
		
        -- Every time we get called we will re-calculate the proper positions
        -- for all blinds. But first let's get the information we will need for 
        -- all blinds.

        local devOutsideTemp = domoticz.devices(OUTSIDE_TEMP_IDX)
        local devSolarAzimuth = domoticz.devices(SOLAR_AZIMUTH_IDX)
        local devSolarAltitude = domoticz.devices(SOLAR_ALTITUDE_IDX)
        local devSolarCriteria1 = domoticz.devices(SUN_CRITERIA1_IDX)
        local devSolarCriteria2 = domoticz.devices(SUN_CRITERIA2_IDX)
        
        if nil == devOutsideTemp then
            domoticz.log( 'Outside temperature device ' .. tostring(OUTSIDE_TEMP_IDX) .. ' not found.', domoticz.LOG_ERROR)
        elseif nil == devSolarAzimuth then
            domoticz.log( 'Solar azimuth device ' .. tostring(SOLAR_AZIMUTH_IDX) .. ' not found.', domoticz.LOG_ERROR)
        elseif nil == devSolarAltitude then
            domoticz.log( 'Solar altitude device ' .. tostring(SOLAR_ALTITUDE_IDX) .. ' not found.', domoticz.LOG_ERROR)
        elseif nil == devSolarCriteria1 then
            domoticz.log( 'Solar criteria1 device ' .. tostring(SUN_CRITERIA1_IDX) .. ' not found.', domoticz.LOG_ERROR)
        else
            local outsideTemp = devOutsideTemp.temperature
            local solarAzimuth = tonumber(devSolarAzimuth.sValue)
            local solarAltitude = tonumber(devSolarAltitude.sValue)

            domoticz.log('solarAzimuth: ' .. tostring(solarAzimuth) .. '°'
                .. ', solarAltitude: ' .. tostring(solarAltitude) .. '°'
                .. ', outsideTemp: ' .. tostring(outsideTemp) .. '°'
                .. '.', domoticz.LOG_DEBUG)
            
            -- Now that we have all information we need for all blinds, we process 
            -- each individual blind from the BLINDS collection.
                        
	        for dummyId, blindInfo in pairs(BLINDS) do
	            local blindType = blindInfo.blindType
	            local blindId = blindInfo.blindId
                --local blind_name = blindInfo.BLIND_NAME
                local blindAzimuth = blindInfo.blindAzimuth ~= nil and blindInfo.blindAzimuth or 0
                local blindAngle = blindInfo.blindAngle ~= nil and blindInfo.blindAngle or 90
                local blindLevelOpen = blindInfo.LEVEL_OPEN ~= nil and math.min(math.max(blindInfo.LEVEL_OPEN, 0), 100) or 100
                local blindLevelClosed = blindInfo.LEVEL_CLOSED ~= nil and math.min(math.max(blindInfo.LEVEL_CLOSED, 0), 100) or 0
                local solarAltitudeMin = blindInfo.SOLAR_ALTITUDE_MIN ~= nil and blindInfo.SOLAR_ALTITUDE_MIN or 0
                local slat_down_angle = blindInfo.SLAT_DOWN_ANGLE
                local slat_up_angle = blindInfo.SLAT_UP_ANGLE
                local slat_length = blindInfo.SLAT_LENGHT
                local slat_distance = blindInfo.SLAT_DISTANCE
	            
                local solarCriteriaMax = blindInfo.MAX_SUN_CRITERIA ~= nil and blindInfo.MAX_SUN_CRITERIA or ALL_MAX_SUN_CRITERIA
                local outsideTemperatureMin =  blindInfo.MIN_OUTSIDE_TEMP
                local ttc_slat_sec = blindInfo.TTC_SLAT_SEC
                --local slat_margin = (blindInfo.SLAT_UP_ANGLE - blindInfo.SLAT_DOWN_ANGLE) / blindInfo.TTC_SLAT_SEC  -- choice: it is 1 second = 1 move

                --local sunCriteriaValue = GetSunCriteria(solarAzimuth, solarAltitude, blindAzimuth + 90, blindAngle)          
--                local sunCriteriaValue, sunCriteriaOriginalValue, sunCriteriaUnit = GetSunCriteria( domoticz, devSolarCriteria1, devSolarCriteria2, solarAzimuth, solarAltitude, (blindAzimuth + 90) % 360, blindAngle)
                local sunCriteriaValue, sunCriteriaOriginalValue, sunCriteriaUnit = GetSunCriteria( domoticz, devSolarCriteria1, devSolarCriteria2, solarAzimuth, solarAltitude, blindAzimuth, blindAngle)
                
--                domoticz.log( '"' .. tostring(dummyId) .. '" : blindType ' .. tostring(blindType)
--                                                            .. ', blindId '.. tostring(type(blindId) == 'string' and '"' .. blindId .. '"' or blindId)
--                                                            .. ', blindAzimuth ' .. tostring(blindAzimuth) .. '°'
--                                                            .. ', blindAngle ' .. tostring(blindAngle) .. '°'
--                                                            .. ', solarAltitudeMin ' .. tostring(solarAltitudeMin)
--                                                            .. ', solarCriteriaMax ' .. tostring(solarCriteriaMax)
--                                                            .. ', outsideTemperatureMin ' .. tostring(outsideTemperatureMin) .. '°'
--                                                            .. '.', domoticz.LOG_DEBUG)
                                                        
	            local dummyDev = domoticz.devices(dummyId)
	            local blindDev = domoticz.devices(blindId)
	            
                if nil == dummyDev then
                    domoticz.log( 'Mode device ' .. tostring(dummyId) .. ' not found.', domoticz.LOG_ERROR)
                elseif nil == blindDev then
                    domoticz.log( 'Blind device ' .. tostring(blindId) .. ' not found.', domoticz.LOG_ERROR)
                else
                    
                    domoticz.log(tostring(type(dummyId) == 'string' and '"' .. dummyId .. '"' or dummyId) .. ': Sun is '
                        .. tostring( solarAltitude >= 0 and 'up' or 'down' ) .. ' and '
--                        .. tostring( solarAltitude >= solarAltitudeMin and 'up' or 'down' ) .. ' '
                        .. tostring( (math.cos(math.rad(blindAzimuth - solarAzimuth )) >= 0) and 'in front of ' or 'behind' ) .. ' this blind.'
                        .. ' mode ' .. tostring(dummyDev.level)
                        .. ', blindType ' .. tostring(blindType)
                        .. ', blindId ' .. tostring(type(blindId) == 'string' and '"' .. blindId .. '"' or blindId)
                        .. ', blindLevelOpen ' .. tostring(blindLevelOpen)
                        .. ', blindLevelClosed ' .. tostring(blindLevelClosed)
                        .. ', solarAltitude ' .. tostring(solarAltitude)
                        .. ', solarAltitudeMin ' .. tostring(solarAltitudeMin) 
                        .. ', solarAzimuth ' .. tostring(solarAzimuth) .. '°'
                        .. ', blindAzimuth ' .. tostring(blindAzimuth) .. '°'
                        .. ', blindAngle ' .. tostring(blindAngle) .. '°'
                        .. ', sunCriteriaValue ' .. tostring(sunCriteriaValue) 
                        .. ', solarCriteriaMax ' .. tostring(solarCriteriaMax)
                        .. ', sunCriteriaOriginalValue ' .. tostring(sunCriteriaOriginalValue) 
                        .. ', sunCriteriaUnit ' .. tostring(sunCriteriaUnit) 
                        .. ', outsideTemp ' .. tostring(outsideTemp) .. '°'
                        .. ', outsideTemperatureMin ' .. tostring(outsideTemperatureMin) .. '°'
                        .. '.', domoticz.LOG_DEBUG)

                    
                    if item == dummyDev then -- sbdy used the dummy selector
                        if dummyDev.level == DUMMY_LEVEL_OPEN then -- up
                            if blindDev.level ~= blindLevelOpen then
                                blindDev.setLevel(blindLevelOpen)
                            end

                        elseif dummyDev.level == DUMMY_LEVEL_STOP then -- stop
                            -- Todo: remove this level as there is no stop 
                            -- possible if you just set the new level and the 
                            -- device runs to this new position autonomously.

                        elseif dummyDev.level == DUMMY_LEVEL_CLOSE then -- down
                            if blindDev.level ~= blindLevelClosed then
                                blindDev.setLevel(blindLevelClosed)
                            end

                        elseif dummyDev.level == DUMMY_LEVEL_AUTO then -- automatic
                        
                            -- Do nothing
                        else
                            domoticz.log('dummyDev level unknown: ' .. dummyDev.state, domoticz.LOG_ERROR)
                        end
                    end
                
                    if dummyDev.level == DUMMY_LEVEL_AUTO then
                        
                        -- No solar radiation when the sun is below the horizon or coming from 'behind'.
                        if nil ~= solarAltitudeMin and solarAltitude >= solarAltitudeMin then
                            local sunInTheFront = math.cos(math.rad(blindAzimuth - solarAzimuth )) >= 0

                            if sunInTheFront then
                                if sunCriteriaValue >= solarCriteriaMax + SUN_CRITERIA_MARGIN then
                                    if blindDev.level ~= blindLevelClosed then
                                        blindDev.setLevel(blindLevelClosed)
                                        domoticz.log('Closing because there is too much sun.', domoticz.LOG_DEBUG)
                                    end
                                elseif sunCriteriaValue < solarCriteriaMax - SUN_CRITERIA_MARGIN then
                                    if blindDev.level ~= blindLevelOpen then
                                        blindDev.setLevel(blindLevelOpen)
                                        domoticz.log('Opening because too much sun condition is gone.', domoticz.LOG_DEBUG)
                                    end
                                end
                            else
                                if blindDev.level ~= blindLevelOpen then
                                    blindDev.setLevel(blindLevelOpen)
                                    domoticz.log('Opening to default daytime position.', domoticz.LOG_DEBUG)
                                    -- .. tostring(solarAltitude >= solarAltitudeMin and sunInTheFront and sunCriteriaValue >= solarCriteriaMax + SUN_CRITERIA_MARGIN)
                                end
                            end
                        elseif nil ~= outsideTemperatureMin and solarAltitude < -6 then    -- below civil twilight
                            if outsideTemp < outsideTemperatureMin - OUTSIDE_TEMP_MARGIN then
                                if blindDev.level ~= blindLevelClosed then
                                    blindDev.setLevel(blindLevelClosed)
                                    domoticz.log('Closing to keep the warmth in on a cold night.', domoticz.LOG_DEBUG)
                                end
                            elseif outsideTemp >= outsideTemperatureMin + OUTSIDE_TEMP_MARGIN then
                                if blindDev.level ~= blindLevelOpen then
                                    blindDev.setLevel(blindLevelOpen)
                                    domoticz.log('Opening on a hot night.', domoticz.LOG_DEBUG)
                                end
                            end
                        else
                            if blindDev.level ~= blindLevelOpen then
                                blindDev.setLevel(blindLevelOpen)
                                domoticz.log('Opening to default position.', domoticz.LOG_DEBUG)
                                -- .. tostring(solarAltitude) .. ' ' >= solarAltitudeMin and sunInTheFront and sunCriteriaValue >= solarCriteriaMax + SUN_CRITERIA_MARGIN)
                            end
                        end

--                        if solarAltitude >= solarAltitudeMin then
--                            domoticz.log('Sun is up.', domoticz.LOG_DEBUG)
--                        else
--                            domoticz.log('Sun is down.', domoticz.LOG_DEBUG)
--                        end
--                        if blindAzimuth - solarAzimuth > 0 and blindAzimuth + 180 - solarAzimuth > 0 then
--                            domoticz.log('Sun is at ' .. tostring(blindAzimuth - solarAzimuth) .. '° in front of this blind.', domoticz.LOG_DEBUG)
--                        else
--                            domoticz.log('Sun is behind this blind.', domoticz.LOG_DEBUG)
--                        end

                        if 'R' == blindType then

                        elseif 'V' == blindType then
                            
                        elseif 'H' == blindType then
                            
                        elseif 'Z' == blindType then
                            
                        else
                            domoticz.log( 'Unexpected blind type ' .. tostring(blindtype) .. ' for ' .. tostring(dummyId) .. '.', domoticz.LOG_ERROR)
                        end
                    end
                end
                
--              domoticz.log('solarCriteriaMax: ' .. tostring(solarCriteriaMax) .. ', sunCriteriaValue: ' .. tostring(sunCriteriaValue), domoticz.LOG_DEBUG)
--              domoticz.log('MIN_OUTSIDE_TEMP: ' .. tostring(MIN_OUTSIDE_TEMP) .. ', outsideTemp: ' .. tostring(outsideTemp), domoticz.LOG_DEBUG)
--              domoticz.log('SLAT_UP_ANGLE: ' .. tostring(BLINDS[blindId].SLAT_UP_ANGLE) ..'°', domoticz.LOG_DEBUG)
--              domoticz.log('SLAT_DOWN_ANGLE: ' .. tostring(BLINDS[blindId].SLAT_DOWN_ANGLE) ..'°', domoticz.LOG_DEBUG)
            end
        end
	end
}