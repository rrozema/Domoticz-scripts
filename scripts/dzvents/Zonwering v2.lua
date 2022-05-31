--[[
A dz dzVents Script to close or open blinds or shutters regarding outside information: light, temperature, solar posiiton and time
In this script, it could be vertical shutters or blinds like roller shades (w/o slates) or fix shutters or blinds with slates ("brise-soleil")
For brise-soleil, the slates follow the sun to get just the shade needed
In the following I'm going to use the word blind only for all cases
It is possible to declare several blinds in the same script with a different configuration for each ones

tips to setup the selector (BLIND_ID)
10: &#9650  => UP
20: &#9724  => STOP
30: &#9660  => DOWN
40: A       => Auto

05/04/2020 - new!
07/02/2021 - clarify log if newBlindProgram is empty
04/04/2021 - add new type of device for SUN_CRITERIA (temperature, lux, percentage)
04/06/2021 - round angle in the device name / fix lastSlatAngle init / fix rename conditions
06/07/2021 - logging precision
08/08/2021 - bug fixed, changed lastBlindProgram to newBlindProgram (one occurence forgotten in Auto mode)
11/08/2021 - clarify log
17/08/2021 - the sun radiation (lux or W/m2) is considered on the floor (horizontal projection of the sun radiation or measured on an horizontal surface)
                for a whole house what matter is more the whole radiation than only the horizontal one
                particularly when the sun is low and vertical windows are considéred
                to have a better criteria for the impact of the sun on a house, the whole value is used (projection on the floor removed)

prerequisite: dzVents Version: 3.0.2
3 sensors: 
SOLAR_ALTITUDE  Device that give Solar Altitude see https://www.domoticz.com/wiki/index.php?title=Lua_dzVents_-_Solar_Data:_Azimuth_Altitude_Lux
SOLAR_AZIMUTH   Device that give Solar Azimuth see https://www.domoticz.com/wiki/index.php?title=Lua_dzVents_-_Solar_Data:_Azimuth_Altitude_Lux
OUTSIDE_TEMP    Device that give Outside temperature
SUN_CRITERIA    Device that give the value of the outside criteria to determine if the blind must be closed because it is too sunny
    (lux, temperature, cloud cover for instance)
    
At the first use or after each change of the script name, to click Auto mode to initiate "data"
--]]

local ALL_MAX_SUN_CRITERIA = 500
local ALL_MIN_OUTSIDE_TEMP = 20

local BLINDS = 
    {   [1203] =                            -- Dummy device with Automatics command (to create) (id or 'name')
            {
            ['BLIND_TYPE'] = 'V',           -- "B" Brise Soleil or "V" Vertical
            ['BLIND_NAME'] = 'Store',-- Name of the dummy device
            ['BLIND_ID'] = 953,             -- Device of the BLIND to close or open (id or 'name') 
            ['BLIND_AZIMUTH'] = 199,        -- Angle from North to where the sun is // to the blind (like the Azimuth)
            ['SOLAR_ALTITUDE_MIN'] = 10,    -- Solar Altitude where the sun is hidden by a house, a tree, if nothing 0    
            ['MAX_SUN_CRITERIA'] = ALL_MAX_SUN_CRITERIA,   -- If criteria is more than this max critéria, the blind is closed during the day and according to the sun position (temperature, UV...) (HOT)
            ['MIN_OUTSIDE_TEMP']  = ALL_MIN_OUTSIDE_TEMP,     -- If outside temperature in less than this min temp, the blind is closed night (COLD) 
            ['SLAT_DOWN_ANGLE']  = -90,     -- Angle from the horizontal when the slat is down (<0), -90 for vertical blind
            ['SLAT_UP_ANGLE'] = 90,         -- Angle from the horizontal when the slat is up, 90 for vertical blind
            ['SLAT_LENGHT']  = '',          -- Length of the slate, any unit (cm...), nil for vertical blind
            ['SLAT_DISTANCE']  = '',        -- Distance between slates, any unit (cm...), nil for vertical blind
            ['BLIND_ANGLE']  = 90,          -- Angle of the blind from the horizontal (>0)
            ['TTC_SLAT_SEC'] = 1            -- Time To Close the blind in seconds, to be measured, 1 for vertical blind 
            },
        [1122] =                             -- Dummy device with Automatics command (to create) (id or 'name')
            {
            ['BLIND_TYPE'] = 'B',           -- "B" Brise Soleil or "V" Vertical
            ['BLIND_NAME'] = 'Brise Soleil',-- Name of the dummy device
            ['BLIND_ID'] = 673,             -- Device of the BLIND to close or open (id or 'name') 
            ['BLIND_AZIMUTH'] = 199,        -- Angle from North to where the sun is // to the blind (like the Azimuth)
            ['SOLAR_ALTITUDE_MIN'] = 15,   -- 20 pour relever les lattes -- Solar Altitude where the sun is hidden by a house, a tree, if nothing 0    
            ['MAX_SUN_CRITERIA'] = ALL_MAX_SUN_CRITERIA,   -- If criteria is more than this max critéria, the blind is closed during the day and according to the sun position (temperature, UV...) (HOT)
            ['MIN_OUTSIDE_TEMP']  = ALL_MIN_OUTSIDE_TEMP,     -- If outside temperature in less than this min temp, the blind is closed night (COLD) 
            ['SLAT_DOWN_ANGLE']  = -4,      -- Angle from the horizontal when the slat is down (<0), -90 for vertical blind
            ['SLAT_UP_ANGLE'] = 55,         -- Angle from the horizontal when the slat is up, 90 for vertical blind
            ['SLAT_LENGHT']  = 8,           -- Length of the slate, any unit (cm...), nil for vertical blind
            ['SLAT_DISTANCE']  = 7,         -- Distance between slates, any unit (cm...), nil for vertical blind
            ['BLIND_ANGLE']  = 16,          -- Angle of the blind from the horizontal (>0)
            ['TTC_SLAT_SEC'] = 16           -- Time To Close the blind in seconds, to be measured, 1 for vertical blind 
            }
    }

--local TEST = 203  -- a dummy switch for testing w/o waiting minutes / remove comment to use / comment to ignore

local SOLAR_ALTITUDE = 338      -- Device that give Solar Altitude
local SOLAR_AZIMUTH = 337       -- Device that give Solar Azimuth

local OUTSIDE_TEMP = 272        -- Device that give Outside temperature
local OUTSIDE_TEMP_MARGING = .8 -- Marging to have an hysteresis to change mode or programm to avoid multiple changes when few changes of temp

-- SUN_CRITERIA: 1 or 2 devices to determine if the blind must be closed (according to the sun position) because it is too sunny
-- It could be temperature, solar radiation in lux, or solar radiation in W/m2
-- If solar radiation, there could be 1 or 2 devices
-- If 1 device, it is a total radiation value (usually on the ground)
-- If 2 device, the SUN_CRITERIA1 is the direct radiation and SUN_CRITERIA2 is the scattered (or diffuse) radiation
-- and the total radiation is calculated on the surface of the blind with the angle of this surface and the sun
local SUN_CRITERIA1 = 1914
local SUN_CRITERIA2 = 1915 -- if the first is the direct radiation, this one is the scattered radiation
local SUN_CRITERIA_MARGING = 50 -- Marging to have an hysteresis to change mode or programm to avoid multiple changes when few changes of the value


local DEVICES_TRIGGER = {1203, 1122, OUTSIDE_TEMP, SUN_CRITERIA1, TEST} -- SOLAR_AZIMUTH is updated at the same time as SUN_CRITERIA

--local TIME_INTERVAL = 'every 5 minutes'

return {
    logging =   {   level   =   
                                domoticz.LOG_ERROR, --select one to override system log level normal = LOG_ERROR
                                --domoticz.LOG_WARNING
                                --domoticz.LOG_DEBUG,
                                --domoticz.LOG_INFO,
                                --domoticz.LOG_FORCE -- to get more log
                },
    on      =   {   devices =   DEVICES_TRIGGER,
                    --timer   =   {TIME_INTERVAL} -- trigger to choose
        },
                        
    data    =   {   slatAngle =     { initial = {}},    -- Last angle of the slate
                    blindMode =     { initial = {}},    -- Last mode of the blind Manual, Auto
                    blindProgram =  { initial = {}}     -- Last program of the blind Cold, Warm, Hot
        },
        
	execute = function(dz, item, triggerInfo)
        _G.logMarker =  dz.moduleLabel -- set logmarker to scriptname 
    	local _u =  dz.utils
	    local LOG_LEVEL = dz.LOG_INFO -- normal = LOG_INFO
	    --local LOG_LEVEL = dz.LOG_DEBUG
	    --local LOG_LEVEL = dz.LOG_ERROR
	    --local LOG_LEVEL = dz.LOG_FORCE -- to get more log
        
    -- /// Functions start \\\
    
    local l_logId = 0
 	local l_logIdx 
    local function logWrite(str, level)  -- Support function for shorthand debug log statements
        l_logId = l_logId + 1
        if l_logId < 10 then
            l_logIdx = '0' .. l_logId
        else
            l_logIdx = l_logId         
        end
        if level == nil then
            level = LOG_LEVEL
        end
        dz.log(l_logIdx .. ": " .. tostring(str), level)
    end
    
        
    local function CalculateSunIncidence(P_SolarAzimuth, P_SolarAltitude, P_AreaAzimuth, P_AreaInclination)
        --logWrite('CalculateSunIncidence')
        -- Calculate the sun incidence (the cosinuss) on a tilt surface

        --P_SolarAzimuth: azimuth of the sun in degrees (from the Noth)
        --P_SolarAltitude: elevation of the sun or altitude in degrees
        --P_AreaAzimuth: azimuth of the normale surface in degrees (from the Noth)
        --P_AreaInclination: inclination of the surface (from the horizontal)
            
        --logWrite('P_SolarAltitude: ' .. P_SolarAltitude)
        --logWrite('P_SolarAzimuth: ' .. P_SolarAzimuth)
        --logWrite('P_AreaInclination: ' .. P_AreaInclination)
        --logWrite('P_AreaAzimuth: ' .. P_AreaAzimuth)
            
        local F_CosIncidence
            
        F_CosIncidence = math.cos(math.rad(P_SolarAltitude)) * math.sin(math.rad(P_AreaInclination)) * math.cos(math.rad(P_AreaAzimuth - P_SolarAzimuth))
                    + math.sin(math.rad(P_SolarAltitude)) * math.cos(math.rad(P_AreaInclination))
        F_CosIncidence = _u.round(F_CosIncidence, 3)

        --logWrite('F_CosIncidence: ' .. F_CosIncidence)
        local F_Incidence = math.deg(math.acos(F_CosIncidence))
        --logWrite('F_Incidence: ' .. F_Incidence)
        
        logWrite('SolarAltitude: ' .. P_SolarAltitude .. ' SolarAzimuth: ' .. P_SolarAzimuth
            .. ' AreaInclination: ' .. P_AreaInclination .. ' AreaAzimuth: ' .. P_AreaAzimuth
            .. ' CosIncidence: ' .. F_CosIncidence .. ' ' .. ' Incidence: ' .. _u.round(F_Incidence,0) .. '°')
        return F_CosIncidence
    end
    

    local function GetSunCriteria(P_SolarAzimuth, P_SolarAltitude, P_AreaAzimuth, P_AreaInclination)
        -- Get the sun criteria values
        local F_dev_sunCriteria = dz.devices(SUN_CRITERIA1)
        local F_sunCriteriaValue
        --logWrite('sunCriteriaValue ' .. F_dev_sunCriteria.name .. ' type ' .. F_dev_sunCriteria.deviceType .. ' s/type ' .. F_dev_sunCriteria.deviceSubType)
   
        if F_dev_sunCriteria.deviceType == 'Temp' then
            F_sunCriteriaValue = F_dev_sunCriteria.temperature
            
        elseif F_dev_sunCriteria.deviceSubType == 'Lux' then
            F_sunCriteriaValue = F_dev_sunCriteria.lux
            
        elseif F_dev_sunCriteria.deviceSubType == 'Solar Radiation' then    
            local F_solarRadiation = F_dev_sunCriteria.radiation
            if SUN_CRITERIA2 ~= nil then -- it is the scattered radiation and the previous was the direct
                local F_solarRadiationScattered = dz.devices(SUN_CRITERIA2).radiation
                -- the total radation on the blind depends on the incidence of the sun
                local F_cosIncidence = CalculateSunIncidence(P_SolarAzimuth, P_SolarAltitude, P_AreaAzimuth, P_AreaInclination)
                -- the direct radiation is projected on the incidence, the scattered (diffused) is in all directions
                F_sunCriteriaValue = math.max(_u.round(F_solarRadiation * F_cosIncidence + F_solarRadiationScattered, 0), 0) -- <0, sun behind
            
            else -- it is the total radiation
                F_sunCriteriaValue = F_solarRadiation
            end
            
        else
            logWrite(F_dev_sunCriteria.id .. ' ' .. F_dev_sunCriteria.name .. ' device Type not supported ' .. F_dev_sunCriteria.deviceType, dz.LOG_ERROR)
        end

        logWrite('sunCriteria ' .. F_sunCriteriaValue, dz.LOG_DEBUG)
    
    return F_sunCriteriaValue
    end
 
    local function InitPosition(P_devBlind, P_SLAT_UP_ANGLE)
        P_devBlind.open().silent()
        return P_SLAT_UP_ANGLE
    end
    
    
    local function CalculateSlatAngle(P_SolarAzimuth, P_SolarAltitude, P_BlindAzimuth, P_SlatDownAngle, P_SlatUpAngle, P_SolarAltitudeMin, P_SLAT_LENGHT, P_SLAT_DISTANCE, P_BLIND_ANGLE, P_BLIND_TYPE)
        -- calculate the angle the slat need to have to be against the sun
        -- normal to the projection of the sun ray on a plan perpendicular at the blind azimuth
        --[[
        logWrite('CalculateSlatAngle')
        logWrite('P_BLIND_TYPE ' .. P_BLIND_TYPE)
        logWrite('P_SolarAzimuth ' .. P_SolarAzimuth)
        logWrite('P_SolarAltitude ' .. P_SolarAltitude)
        logWrite('P_BlindAzimuth ' .. P_BlindAzimuth)
        logWrite('P_SolarAltitudeMin ' .. P_SolarAltitudeMin)
        --]]
        local F_SunInTheFront = false
        local F_SlatAngle
        if P_SolarAltitude < P_SolarAltitudeMin then -- if the sun is low, open the slates
            F_SlatAngle = P_SlatUpAngle
            logWrite('F_SlatAnglee open when the sun is low :' .. F_SlatAngle)
        else
            if P_SolarAzimuth >= P_BlindAzimuth and P_SolarAzimuth <= P_BlindAzimuth + 180 then
                F_SunInTheFront = true -- the sun is in the front = where the blind is)
                logWrite('Sun in the front')
            else
                logWrite('Sun in the back')            
            end
            local F_IncidenceSunBlind = 90 - P_SolarAzimuth + P_BlindAzimuth -- angle of the sun on the front of the blind
            local F_ProjectedSolarAltitude = math.deg(math.atan
        		                            (
    		                                math.tan(math.rad(P_SolarAltitude))
    		                                /math.cos(math.rad(F_IncidenceSunBlind))
    	                                    )
                                                    )
                                                    
            logWrite('F_ProjectedSolarAltitude: ' .. F_ProjectedSolarAltitude)
            
            if P_BLIND_TYPE == "V" then -- vertical blind: open or closed
                if F_SunInTheFront then -- the slate should be closed enough not to let the sun shine in
                   F_SlatAngle = P_SlatDownAngle
                   logWrite('Blind closed: ' .. F_SlatAngle)
                else
                    F_SlatAngle = P_SlatUpAngle
                    logWrite('Blind open: ' .. F_SlatAngle)
                end

            elseif P_BLIND_TYPE == "B" then -- brise-soleil, the angle of slates is calculated to follow the sun
                logWrite('P_SlatDownAngle ' .. P_SlatDownAngle .. ' / P_SlatUpAngle ' .. P_SlatUpAngle)
                local q =  math.tan(math.rad(F_ProjectedSolarAltitude + P_BLIND_ANGLE))
                --print('q ' .. q)
                local a = (P_SLAT_DISTANCE / P_SLAT_LENGHT) + 1
                --print('a '  .. a)
                local b = 2 / q
                --print('b ' .. b)
                local c = (P_SLAT_DISTANCE / P_SLAT_LENGHT) - 1
                --print('c ' .. c)
                local d = b*b - 4*a*c
                --print('d ' .. d)
                local rac2d = math.sqrt(d)
                --print('rac2d ' .. rac2d)
                local t = (rac2d - b) / (2*a)
                --print('t ' .. t)
                local i =  2*math.deg(math.atan(t)) -- angle between the slat and the blind (roof)
                --print('i ' .. i)
                F_SlatAngle = i - P_BLIND_ANGLE
                logWrite('F_SlatAngle therorical: ' .. F_SlatAngle)

                -- the slate angle should be inside the capability of the blind
                if F_SlatAngle > P_SlatUpAngle then
                    F_SlatAngle = P_SlatUpAngle
                elseif F_SlatAngle < P_SlatDownAngle then
                    F_SlatAngle = P_SlatDownAngle
                end
                logWrite('Slat angle target: ' .. F_SlatAngle .. '° / Inclination from horizontal: ' .. (F_SlatAngle - P_BLIND_ANGLE) .. '°')
            else
                logWrite("BLIND_TYPE unknown " .. P_BLIND_TYPE, dz.LOG_ERROR)
                return(0)
            end
        end
        return(_u.round(F_SlatAngle,0))
    end
    
    
    local function CalculateSlatMvt(P_SlatAngleTarget, P_LastSlatAngle, P_SLAT_UP_ANGLE, P_SLAT_DOWN_ANGLE, P_SLAT_MARGING, P_TTC_SLAT_SEC)
    -- calculte the time is seconds to move the slates and the direction
        --[[
        logWrite('CalculateSlatMvt')
        logWrite('P_SlatAngleTarget '.. P_SlatAngleTarget )
        logWrite('P_LastSlatAngle ' .. P_LastSlatAngle )
        --]]
        -- if the slat target is near an edge it is moving to this edge
        local F_SlatMvt
        local F_SlatAngleDelta
        if P_SlatAngleTarget == P_SLAT_UP_ANGLE and P_LastSlatAngle == P_SLAT_UP_ANGLE then -- already up
            F_SlatMvt = 0
            F_SlatAngleDelta = 0
            logWrite('P_SlatAngleTarget already to the max => F_SlatMvt ' .. F_SlatMvt)
        elseif P_SlatAngleTarget + P_SLAT_MARGING > P_SLAT_UP_ANGLE then -- up edge
            F_SlatMvt = 999
            F_SlatAngleDelta = 999
            logWrite('P_SlatAngleTarget near the up edge ' .. F_SlatMvt)
        elseif P_SlatAngleTarget == P_SLAT_DOWN_ANGLE and P_LastSlatAngle == P_SLAT_DOWN_ANGLE then -- already down
            F_SlatMvt = 0
            F_SlatAngleDelta = 0
            logWrite('P_SlatAngleTarget already to the min ' .. F_SlatMvt)
        elseif P_SlatAngleTarget - P_SLAT_MARGING < P_SLAT_DOWN_ANGLE then -- down edge
            F_SlatMvt = -999
            F_SlatAngleDelta = -999
            logWrite('P_SlatAngleTarget near the down edge ' .. F_SlatMvt)
        else
            F_SlatAngleDelta = P_SlatAngleTarget - P_LastSlatAngle
            logWrite('F_SlatAngleDelta ' .. F_SlatAngleDelta)
            F_SlatMvt = P_TTC_SLAT_SEC * F_SlatAngleDelta / (P_SLAT_UP_ANGLE - P_SLAT_DOWN_ANGLE)
            -- rounded toward the next move
            if F_SlatMvt < 0 then
                F_SlatMvt = math.floor(F_SlatMvt)
            else
                F_SlatMvt = math.ceil(F_SlatMvt)
            end
            F_SlatAngleDelta = F_SlatMvt * (P_SLAT_UP_ANGLE - P_SLAT_DOWN_ANGLE) / P_TTC_SLAT_SEC -- the "real" move
        end
    
        logWrite('F_SlatMvt ' .. F_SlatMvt)

        logWrite('F_SlatAngleDelta ' .. F_SlatAngleDelta )
        return F_SlatMvt, F_SlatAngleDelta
    end
    
    
    local function MoveSlat(P_SlatMvt, P_devBlind)
    -- move the slat the number of seconds in parameter, if > 0 to the open direction , if < 0 to the close direction
        logWrite('MoveSlate ' .. P_SlatMvt .. ' ' .. P_devBlind.name)
        if P_SlatMvt == 0 then
            logWrite('No need to move the blind ' .. P_SlatMvt .. ' sec')
        else
            if P_SlatMvt > 0 then
                --if P_SlatMvt < 999 then
                    --P_devBlind.open().forSec(P_SlatMvt).silent()
                    logWrite('Blind opens for ' .. P_SlatMvt .. ' seconds')
                --else
                    P_devBlind.open().silent()
                    --logWrite('Blind opens to the max')
                --end
            else
                --if P_SlatMvt > -999 then
                    logWrite('Blind closes for ' .. P_SlatMvt .. ' seconds')
                --else
                    P_devBlind.close().silent()
                    --logWrite('Blind closes ')
                --end
                P_SlatMvt = - P_SlatMvt 
                logWrite('Blind closes ' .. P_SlatMvt .. ' seconds')
            end
            
            if math.abs(P_SlatMvt) ~= 999 then -- it is not an edge position
                P_devBlind.stop().afterSec(P_SlatMvt).silent()
            end
        end
        return
    end
    
    
    local function Calibration(P_timeSec, P_devBlind)
        logWrite('CALIBRATION ' .. P_timeSec, dz.LOG_FORCE)
        MoveSlat(P_timeSec, P_devBlind)
        currentBlindMode = 'CALIBRATION'
        return
    end
    
	-- \\\ Functions end ///

        if item.isDevice then -- selector by sbdy or change is temp or sun criteria or sun position
            logWrite('==>> triggered by device ' ..  item.id .. ' ' .. item.name .. ' ' .. item.state, dz.LOG_FORCE)
        elseif item.isTimer then -- Timer trigger
            logWrite('==>> triggered by timer', dz.LOG_FORCE)
        else -- Impossible error!
            logWrite('==>> triggered by ?????', dz.LOG_ERROR)
            return
        end

    
        for blindId, blinfInfo in pairs(BLINDS) do
            local devDummyBlind = dz.devices(blindId)               -- Switch dummy device with commands 
            local devBlind = dz.devices(BLINDS[blindId].BLIND_ID)   -- Device of the BLIND to close or open

            logWrite('-->> ' .. devDummyBlind.name .. ' ' .. blindId)
            logWrite(devBlind.name .. ' ' .. devBlind.id)
            
            local lastSlatAngle = dz.data.slatAngle[blindId]
            local currentBlindMode = dz.data.blindMode[blindId]
            local lastBlindProgram = dz.data.blindProgram[blindId]
                
            if currentBlindMode == nil then currentBlindMode = 'INITIAL' end
            if lastBlindProgram == nil then lastBlindProgram = 'INITIAL' end
            
            if lastSlatAngle == nil then
                if currentBlindMode == 'Auto' then -- 01/06/2021
                    logWrite('Start ' .. currentBlindMode .. ' lastSlatAngle null !!!', dz.LOG_ERROR)
                else
                    logWrite('Start ' .. currentBlindMode .. ' slat angle null')
                end
            else
                logWrite('Start ' .. currentBlindMode .. ' slat angle ' .. lastSlatAngle)
            end
                
            local BLIND_TYPE = BLINDS[blindId].BLIND_TYPE
            local BLIND_NAME = BLINDS[blindId].BLIND_NAME
            local BLIND_AZIMUTH = BLINDS[blindId].BLIND_AZIMUTH
            local SOLAR_ALTITUDE_MIN = BLINDS[blindId].SOLAR_ALTITUDE_MIN
            local SLAT_DOWN_ANGLE = BLINDS[blindId].SLAT_DOWN_ANGLE
            local SLAT_UP_ANGLE = BLINDS[blindId].SLAT_UP_ANGLE
            local SLAT_LENGHT = BLINDS[blindId].SLAT_LENGHT
            local SLAT_DISTANCE = BLINDS[blindId].SLAT_DISTANCE
            local BLIND_ANGLE = BLINDS[blindId].BLIND_ANGLE


            -- < Device trigger
            if item.isDevice then -- selector by sbdy or change is temp or sun criteria or sun position
                if item == devDummyBlind then -- sbdy used the dummy selector
                    if devDummyBlind.level == 10 then -- up
                        if CALIBRATION ~= nil then -- move the slate up to count the times to open
                            Calibration(CALIBRATION, devBlind)
                            return
                        else
                            devBlind.open().silent()
                            lastSlatAngle =  SLAT_UP_ANGLE
                            currentBlindMode = 'Manual'
                            dz.log('devDummyBlind level: ' .. devDummyBlind.level .. ' open', LOG_LEVEL)
                        end
                    elseif devDummyBlind.level == 20 then -- stop
                        devBlind.stop().silent()
                        lastSlatAngle =  nil
                        currentBlindMode = 'Manual'
                        logWrite('devDummyBlind level: ' .. devDummyBlind.level .. ' stop')
                    elseif devDummyBlind.level == 30 then -- down                    
                        if CALIBRATION ~= nil then -- move the slate up to count the times to close
                            Calibration(-CALIBRATION, devBlind)
                            return
                        else
                            devBlind.close().silent()
                            devBlind.close().afterSec(3).silent() -- twice in case of loss of message (12/11/2020)
                            lastSlatAngle =  SLAT_DOWN_ANGLE
                            currentBlindMode = 'Manual'
                            logWrite('devDummyBlind level: ' .. devDummyBlind.level .. ' close')
                        end
                    elseif devDummyBlind.level == 40 then -- automatic
                        if currentBlindMode ~= 'Auto' then
                            lastSlatAngle = nil -- to force an init in Auto mode
                            logWrite('devDummyBlind level: ' .. devDummyBlind.level .. ' init auto mode')
                        else
                            logWrite('devDummyBlind level: ' .. devDummyBlind.level .. ' go on auto mode')
                        end
                        currentBlindMode = 'Auto'
                    else
                        logWrite('devDummyBlind level unknown: ' .. devDummyBlind.state, dz.LOG_ERROR)
                    end
                end
            end
       
            
            -- < Auto mode
            local MAX_SUN_CRITERIA = BLINDS[blindId].MAX_SUN_CRITERIA
            logWrite('MAX_SUN_CRITERIA: ' .. MAX_SUN_CRITERIA, dz.LOG_DEBUG)
            local MIN_OUTSIDE_TEMP =  BLINDS[blindId].MIN_OUTSIDE_TEMP
            logWrite('MIN_OUTSIDE_TEMP: ' .. MIN_OUTSIDE_TEMP, dz.LOG_DEBUG)
            logWrite('SLAT_UP_ANGLE: ' .. BLINDS[blindId].SLAT_UP_ANGLE, dz.LOG_DEBUG)
            logWrite('SLAT_DOWN_ANGLE: ' .. BLINDS[blindId].SLAT_DOWN_ANGLE, dz.LOG_DEBUG)
            local TTC_SLAT_SEC = BLINDS[blindId].TTC_SLAT_SEC
            local SLAT_MARGING = (BLINDS[blindId].SLAT_UP_ANGLE - BLINDS[blindId].SLAT_DOWN_ANGLE) / BLINDS[blindId].TTC_SLAT_SEC  -- choice: it is 1 second = 1 move
            
            local outsideTemp = dz.devices(OUTSIDE_TEMP).temperature
            local sunAzimuth = tonumber(dz.devices(SOLAR_AZIMUTH).sValue)
            logWrite('sunAzimuth: ' .. sunAzimuth, dz.LOG_DEBUG)
            local sunAltitude = tonumber(dz.devices(SOLAR_ALTITUDE).sValue)
            logWrite('sunAltitude: ' .. sunAltitude, dz.LOG_DEBUG)
            local sunCriteriaValue = GetSunCriteria(sunAzimuth, sunAltitude, BLIND_AZIMUTH + 90, BLIND_ANGLE)          
                
            local newBlindProgram
            local wCold = false
            local wHot = false
            if currentBlindMode == 'Auto' then
                logWrite('Auto mode execution')
                if (lastBlindProgram == "Cold" and outsideTemp < MIN_OUTSIDE_TEMP + OUTSIDE_TEMP_MARGING) then
                    newBlindProgram = "Cold"
                    logWrite('newBlindProgram stay Cold', dz.LOG_DEBUG)
                    wCold = true -- 01/06/2021
                elseif (lastBlindProgram ~= "Cold" and outsideTemp < MIN_OUTSIDE_TEMP - OUTSIDE_TEMP_MARGING) then
                    newBlindProgram = "Cold"
                    logWrite('newBlindProgram go Cold', dz.LOG_DEBUG)
                    wCold = true -- 01/06/2021
                end
                if (lastBlindProgram == "Hot" and sunCriteriaValue > MAX_SUN_CRITERIA - SUN_CRITERIA_MARGING) then
                    newBlindProgram = "Hot"
                    logWrite('newBlindProgram stay Hot', dz.LOG_DEBUG)
                    wHot = true -- 01/06/2021
                elseif (lastBlindProgram ~= "Hot" and sunCriteriaValue > MAX_SUN_CRITERIA + SUN_CRITERIA_MARGING) then
                    newBlindProgram = "Hot"
                    logWrite('newBlindProgram go Hot', dz.LOG_DEBUG)
                    wHot = true -- 01/06/2021
                end
                if (wCold and wHot) or (not wCold and not wHot) then
                    newBlindProgram = "Warm"
                    logWrite('newBlindProgram Warm', dz.LOG_DEBUG)
                end
        
                local blindProgramChanged = false
                local logAction = '?' -- 06/07/2021
                if newBlindProgram ~= lastBlindProgram then
                    blindProgramChanged = true
                    logAction = 'changed to '
                else
                    logAction = 'remains on '
                end
                -- 11/08/2021
                logWrite(blindId .. ' ' .. currentBlindMode .. ': ' .. logAction .. newBlindProgram .. ' / Outside Temp: ' .. _u.round(outsideTemp,1) .. '/' .. MIN_OUTSIDE_TEMP .. ' ; Sun criteria: ' .. sunCriteriaValue .. '/' .. MAX_SUN_CRITERIA, dz.LOG_FORCE)

                if lastSlatAngle == nil then -- on Auto mode, if initial position is unknown, the blind is open to get the zero -- move up 01/06/2021
                    logWrite('lastSlatAngle to init') 
                    lastSlatAngle = InitPosition(devBlind, SLAT_UP_ANGLE)
                end
                
                if newBlindProgram == "Hot" then
                    -- -- comment 01/06/2021
                    --if lastSlatAngle == nil then -- on Auto mode, if initial position is unknown, the blind is open to get the zero
                      --  logWrite('lastSlatAngle to init') 
                        --lastSlatAngle = InitPosition(devBlind)
                    --else
                        logWrite('Auto Program: ' .. newBlindProgram .. ' / Last Slat Angle '.. lastSlatAngle)            
                        local slatAngleTarget = CalculateSlatAngle(sunAzimuth, sunAltitude, BLIND_AZIMUTH, SLAT_DOWN_ANGLE, SLAT_UP_ANGLE, SOLAR_ALTITUDE_MIN, SLAT_LENGHT, SLAT_DISTANCE, BLIND_ANGLE, BLIND_TYPE)
                        local slateMvt = 0
                        local lastSlatAngleDelta
                        slateMvt, lastSlatAngleDelta = CalculateSlatMvt(slatAngleTarget, lastSlatAngle, SLAT_UP_ANGLE, SLAT_DOWN_ANGLE, SLAT_MARGING, TTC_SLAT_SEC) -- mouvement to make to the slates in seconds
                        MoveSlat(slateMvt, devBlind)
                        if lastSlatAngleDelta == 999 then       -- it is the up position
                            lastSlatAngle = SLAT_UP_ANGLE
                        elseif lastSlatAngleDelta == -999 then  -- it is the down position 
                            lastSlatAngle = SLAT_DOWN_ANGLE
                        else
                            lastSlatAngle = lastSlatAngle + lastSlatAngleDelta
                        end
                    --end
                elseif newBlindProgram == "Cold" then -- 08/08/2021 - bug! lastBlindProgram changed to newBlindProgram
                    --local solarAltitude = tonumber(devAltitude.state)
                    --logWrite("Solar Altitude=" .. tostring(solarAltitude))

                    if dz.time.matchesRule('at 17:00-00:30') then -- !!! -> to put in parameters...
                        logWrite("timeConditionsClose OK")
                        if sunAltitude < -6 then
                            if devBlind.state ~= "Closed" then
                                devBlind.close()
                                devBlind.close().afterSec(5).silent() -- twice in case of loss of message
                                logWrite('Auto Program: ' .. newBlindProgram .. ' / ' .. devBlind.name .. " closing")
                            end
                            lastSlatAngle =  SLAT_DOWN_ANGLE
                        end
                    elseif dz.time.matchesRule('at 6:00-12:00') then-- !!! -> to put in parameter 
                        logWrite("timeConditionsOpen OK")
                        if sunAltitude > -8 then
                            if devBlind.state ~= "Open" then
                                devBlind.open().silent()
                                devBlind.open().afterSec(5).silent()
                                logWrite('Auto Program: ' .. newBlindProgram .. ' / ' .. devBlind.name .. " opening")
                            end
                            lastSlatAngle =  SLAT_UP_ANGLE
                        end
                    end
                else -- Warm
                    if dz.time.matchesRule('at 6:00-10:00') or blindProgramChanged then
                        logWrite("Time to check if it is open")
                        --local solarAltitude = tonumber(devAltitude.state)
                        --logWrite("Solar Altitude=" .. tostring(solarAltitude))
                        if sunAltitude >=  -7 then
                            if devBlind.state ~= "Open" then
                                devBlind.open()
                                logWrite('Auto Program: ' .. newBlindProgram .. ' / ' .. devBlind.name .. " opening")
                            end
                            lastSlatAngle =  SLAT_UP_ANGLE
                        end
                    end
                end
    
            else   
                newBlindProgram = ''
            end
                
        
            -- < Update global variables if changed
            local renameFlag = false
            if dz.data.blindMode[blindId] ~= currentBlindMode then
                renameFlag = true
                logWrite('currentBlindMode changed to ' .. currentBlindMode, dz.LOG_FORCE)
                dz.data.blindMode[blindId] = currentBlindMode
            else
                logWrite('currentBlindMode NOT changed: ' .. currentBlindMode)
            end
            
            if dz.data.blindProgram[blindId] ~= newBlindProgram then
                renameFlag = true
                if newBlindProgram == '' then -- 07/02/2021 clarify log if newBlindProgram is empty
                    logWrite('newBlindProgram changed to NONE', dz.LOG_FORCE)                
                else
                    logWrite('newBlindProgram changed to ' .. newBlindProgram, dz.LOG_FORCE)
                 end
                dz.data.blindProgram[blindId] = newBlindProgram
            else
                logWrite('newBlindProgram NOT changed: ' .. newBlindProgram)
            end

            if (dz.data.slatAngle[blindId] ~= lastSlatAngle) then -- 16/08/2021
                renameFlag = true
                if lastSlatAngle == nil then
                    logWrite('SlatAngle changed to nul')
                else
                    if lastSlatAngle == SLAT_DOWN_ANGLE then
                        logWrite(devBlind.name ..  ' closes ', dz.LOG_FORCE)
                    elseif lastSlatAngle == SLAT_UP_ANGLE then
                        logWrite(devBlind.name ..  ' opens ', dz.LOG_FORCE)
                    else
                        local newSlatAngle = _u.round(lastSlatAngle,0)
                        logWrite('Slates of ' .. devBlind.name .. ' move to ' .. newSlatAngle .. '° - ' .. newBlindProgram, dz.LOG_FORCE)
                    end
                end
                dz.data.slatAngle[blindId] = lastSlatAngle
            else    
                if lastSlatAngle == nil then
                    logWrite('SlatAngle NOT changed: nul')
                else
                    if lastSlatAngle == SLAT_DOWN_ANGLE then
                        logWrite(devBlind.name ..  ' remains closed ')
                    elseif lastSlatAngle == SLAT_UP_ANGLE then
                        logWrite(devBlind.name ..  ' remains open ')
                    else
                        logWrite('Slates of ' .. devBlind.name .. ' remains on ' .. lastSlatAngle .. ' °')
                    end
                end
            end
        
            if renameFlag then -- 16/08/2021
                local blindRename = BLIND_NAME
                if lastSlatAngle == nil then
                    blindRename = blindRename .. ' (' .. devBlind.state .. ') - '  .. currentBlindMode
                else
                    if lastSlatAngle == SLAT_DOWN_ANGLE then
                        blindRename = blindRename .. ' (Closed) - ' .. currentBlindMode
                    elseif lastSlatAngle == SLAT_UP_ANGLE then
                        blindRename = blindRename .. ' (Open) - ' .. currentBlindMode
                    else
                        local newSlatAngle = _u.round(lastSlatAngle,0)
                        blindRename = blindRename .. ' (' .. newSlatAngle .. '°) - ' .. currentBlindMode
                    end
                end
                blindRename = blindRename .. ' ' .. newBlindProgram
                devDummyBlind.rename(blindRename)
                devDummyBlind.switchSelector(devDummyBlind.level).silent()
            end
        end

    end
}