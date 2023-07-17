--[[
This script calculate in real-time some usefull solar data without any hardware sensor :
·  Azimuth : Angle between the Sun and the north, in degree. (north vector and the perpendicular projection of the sun down onto the horizon)
·  Altitude : Angle of the Sun with the horizon, in degree.
·  Lux : The illuminance, equal to one lumen per square metre. Taking account of the real time cloud layer.

-- Installation & Documentation -----------------------------------------------------------
https://www.domoticz.com/wiki/index.php?title=Lua_dzVents_-_Solar_Data:_Azimuth_Altitude_Lux

-- Prerequisits  -----------------------------------------------------------
	2 sensors with Cloud Cover and Pressure updated
	Requires Domoticz v3.8551 or later.   
	Work with lua 5.3 too.
	No Platform dependent; Linux & Windows


-- Contributors  ----------------------------------------------------------------
	V1.0  - Sébastien Joly - Great original work
	V1.1  - Neutrino - Adaptation to Domoticz
	V1.2  - Jmleglise - An acceptable approximation of the lux below 1° altitude for Dawn and dusk + translation + several changes to be more userfriendly.
	V1.3  - Jmleglise - No update of the Lux data when <=0 to get the sunset and sunrise with lastUpdate
	V1.4  - Jmleglise - use the API instead of updateDevice to update the data of the virtual sensor to be able of using devicechanged['Lux'] in our scripts. (Due to a bug in Domoticz that doesn't catch the devicechanged event of the virtual sensor)
	V1.5  - xces - UTC time calculation.
	      - waaren - pow function for lua 5.3 compatibility
	V2.4  - BakSeeDaa - Converted to dzVents and changed quite many things.
	V2.41 - Oredin - Use Dark Sky API instead of WU API
	V3.0  - Bram Vreugdenhil/Hestia - Weather Api independent. Use OpenWeathermaps devices or your own sensors
	V3.1  - Jmleglise - Merge the different fork. Some clean Up, comment and wiki.
]]--

local scriptName = 'solarData'
local scriptVersion = '3.1'

-- Variables to customize ------------------------------------------------

-- Devices for Input Data
local idxCloudCover = 347       -- device holding cloudcoverage in percentage. Ex : 60%  (for E.g. a device from Openweathermap or darksky)
local idxBarometer  = 1033      -- Barometer device. E.g. a device from Openweathermap that contains value in hPa: like a Temp+Humidity+Baro device with : -0.5 C, 59 %, 1023.0 hPa  (for E.g. a device from Openweathermap or your own hardware sensor)

-- Devices for Output Data  (can be nil if you dont want some data)------------------------------------------
local idxSolarAzimuth  = 1198    -- Your device. A Virtual customer sensor for Solar Azimuth 
local idxSolarAltitude = 1197    -- Your device. A Virtual customer sensor for Solar Altitude
local idxRadiation     = 1201    -- Your device. A Virtual customer sensor for Solar Radiation  (in Watt/m2)
local idxLux           = 1196    -- Your device. A Virtual lux sensor for Solar Lux

-- Other parameters -----------------------------------------------------
local intervalMins = 3	        -- The interval of running this script. No need to be faster than the data source. (For example it is 10 min)
local altitude  = 8             -- Meters above sea level of your location. (Integer)  Can be found from coordinates on https://www.advancedconverter.com/map-tools/find-altitude-by-coordinates
local latitude  = nil 		    -- Keep nil if you have defined your lat. and long. in the settings. Otherwise you can overwrite it here. E.g. something like 51.748485
local longitude = nil 		    -- idem. E.g.something like 5.629728.
local logToFile = false		  			-- Set to true if you also want to log to a file. It might get big by time. 
local tmpLogFile = '/tmp/logSun.txt'	-- Logging to a file if specified 


-- Don't make any changes below this line (Except for setting logging level) ----------------------------------------------------------------------


return {
	active = true,
	logging = {
--		 level = domoticz.LOG_DEBUG,                                     -- Uncomment to override the dzVents global logging setting
		marker = scriptName..' '..scriptVersion
	},
	on = {
--		devices = {'testSwitch'},                                       -- a switch for testing w/o waiting minutes
        devices = {
                idxCloudCover,
                idxBarometer
            },
		timer = {'every '..tostring(intervalMins)..' minutes'}       -- There is no more limit to worry about as there is no API called
	},

	execute = function(domoticz, device)

		local function leapYear(year)   
			return year%4==0 and (year%100~=0 or year%400==0)
		end

		function math.pow(x, y)                                         -- Function math.pow(x, y) has been deprecated in Lua 5.3. 
			return x^y 
		end		
		
        if latitude == nil then
            latitude = domoticz.settings.location.latitude
        end
    
        if longitude == nil then
            longitude = domoticz.settings.location.longitude
        end		
		
		local arbitraryTwilightLux = 6.32                               -- W/m² egal 800 Lux (the theoritical value is 4.74 but I have more accurate result with 6.32...)
		local constantSolarRadiation = 1361                             -- Solar Constant W/m²

		local relativePressure = domoticz.devices(idxBarometer).barometer

		local year = os.date('%Y')
		local numOfDay = os.date('%j')
		local nbDaysInYear = (leapYear(year) and 366 or 365)

		local angularSpeed = 360/365.25
		local declination = math.deg(math.asin(0.3978 * math.sin(math.rad(angularSpeed) *(numOfDay - (81 - 2 * math.sin((math.rad(angularSpeed) * (numOfDay - 2))))))))
		local timeDecimal = (os.date('!%H') + os.date('!%M') / 60)      -- Coordinated Universal Time  (UTC)
		local solarHour = timeDecimal + (4 * longitude / 60 )           -- The solar Hour
		local hourlyAngle = 15 * ( 12 - solarHour )                     -- hourly Angle of the sun
		local sunAltitude = math.deg(math.asin(math.sin(math.rad(latitude))* math.sin(math.rad(declination)) + math.cos(math.rad(latitude)) * math.cos(math.rad(declination)) * math.cos(math.rad(hourlyAngle))))-- the height of the sun in degree, compared with the horizon

		local sunAzimuth = math.acos((math.sin(math.rad(declination)) - math.sin(math.rad(latitude)) * math.sin(math.rad(sunAltitude))) / (math.cos(math.rad(latitude)) * math.cos(math.rad(sunAltitude) ))) * 180 / math.pi -- deviation of the sun from the North, in degree
		local sinAzimuth = (math.cos(math.rad(declination)) * math.sin(math.rad(hourlyAngle))) / math.cos(math.rad(sunAltitude))
		if(sinAzimuth<0) then sunAzimuth=360-sunAzimuth end
		local sunstrokeDuration = math.deg(2/15 * math.acos(- math.tan(math.rad(latitude)) * math.tan(math.rad(declination))))  -- duration of sunstroke in the day . Not used in this calculation.
		local RadiationAtm = constantSolarRadiation * (1 +0.034 * math.cos( math.rad( 360 * numOfDay / nbDaysInYear )))         -- Sun radiation  (in W/m²) in the entrance of atmosphere.

		-- Coefficient of mitigation M
		local absolutePressure = relativePressure - domoticz.utils.round((altitude/ 8.3),1) -- hPa
		local sinusSunAltitude = math.sin(math.rad(sunAltitude))
		local M0 = math.sqrt(1229 + math.pow(614 * sinusSunAltitude,2)) - 614 * sinusSunAltitude
		local M = M0 * relativePressure/absolutePressure

		domoticz.log('', domoticz.LOG_INFO)
		domoticz.log('==================   '..scriptName..' V'..scriptVersion..'   ==================', domoticz.LOG_INFO)
		domoticz.log('Altitude:'..tostring(altitude)..', latitude: ' .. latitude .. ', longitude: ' .. longitude, domoticz.LOG_INFO)
		domoticz.log('Angular Speed = ' .. angularSpeed .. ' per day', domoticz.LOG_DEBUG)
		domoticz.log('Declination = ' .. declination .. '°', domoticz.LOG_DEBUG)
		domoticz.log('Universal Coordinated Time (UTC) '.. timeDecimal ..' H.dd', domoticz.LOG_DEBUG)
		domoticz.log('Solar Hour '.. solarHour ..' H.dd', domoticz.LOG_DEBUG)
		domoticz.log('Altitude of the sun = ' .. sunAltitude .. '°', domoticz.LOG_INFO)
		domoticz.log('Angular hourly = '.. hourlyAngle .. '°', domoticz.LOG_DEBUG)
		domoticz.log('Azimuth of the sun = ' .. sunAzimuth .. '°', domoticz.LOG_INFO)
		domoticz.log('Duration of the sun stroke of the day = ' .. domoticz.utils.round(sunstrokeDuration,2) ..' H.dd', domoticz.LOG_DEBUG)
		domoticz.log('Radiation max in atmosphere = ' .. domoticz.utils.round(RadiationAtm,2) .. ' W/m²', domoticz.LOG_DEBUG)
		domoticz.log('Local relative pressure = ' .. relativePressure .. ' hPa', domoticz.LOG_DEBUG)
		domoticz.log('Absolute pressure in atmosphere = ' .. absolutePressure .. ' hPa', domoticz.LOG_DEBUG)
		domoticz.log('Coefficient of mitigation M = ' .. M ..' M0 = '..M0, domoticz.LOG_DEBUG)
		domoticz.log('', domoticz.LOG_INFO)
		
		-- In meteorology, an okta is a unit of measurement used to describe the amount of cloud cover
		-- at any given location such as a weather station. Sky conditions are estimated in terms of how many
		-- eighths of the sky are covered in cloud, ranging from 0 oktas (completely clear sky) through to 8 oktas
		-- (completely overcast). In addition, in the synop code there is an extra cloud cover indicator '9'
		-- indicating that the sky is totally obscured (i.e. hidden from view),
		-- usually due to dense fog or heavy snow.

        Cloudpercentage = domoticz.devices(idxCloudCover).percentage
		
		okta = Cloudpercentage/12.5
		
		local Kc = 1-0.75*math.pow(okta/8,3.4)      -- Factor of mitigation for the cloud layer

		local directRadiation, scatteredRadiation, totalRadiation, Lux, weightedLux
		if sunAltitude > 1 then                     -- Below 1° of Altitude , the formulae reach their limit of precision.
			directRadiation = RadiationAtm * math.pow(0.6,M) * sinusSunAltitude
			scatteredRadiation = RadiationAtm * (0.271 - 0.294 * math.pow(0.6,M)) * sinusSunAltitude
			totalRadiation = scatteredRadiation + directRadiation
			Lux = totalRadiation / 0.0079           -- Radiation in Lux. 1 Lux = 0,0079 W/m²
			weightedLux = Lux * Kc                  -- radiation of the Sun with the cloud layer
		elseif sunAltitude <= 1 and sunAltitude >= -7  then -- apply theoretical Lux of twilight
			directRadiation = 0
			scatteredRadiation = 0
			arbitraryTwilightLux=arbitraryTwilightLux-(1-sunAltitude)/8*arbitraryTwilightLux
			totalRadiation = scatteredRadiation + directRadiation + arbitraryTwilightLux 
			Lux = totalRadiation / 0.0079           -- Radiation in Lux. 1 Lux = 0,0079 W/m²
			weightedLux = Lux * Kc                  -- radiation of the Sun with the cloud layer
		elseif sunAltitude < -7 then                -- no management of nautical and astronomical twilight...
			directRadiation = 0
			scatteredRadiation = 0
			totalRadiation = 0
			Lux = 0
			weightedLux = 0                         --  Lux for the nautic twilight should be around 3,2. I prefer to get 0.
		end

        totalRadiation=totalRadiation*Kc
        
		domoticz.log('Okta = '..okta.. ' Cloud coverage = ' ..Cloudpercentage .. '%', domoticz.LOG_INFO)
		domoticz.log('Kc = ' .. Kc, domoticz.LOG_DEBUG)
		domoticz.log('Direct Radiation = '.. domoticz.utils.round(directRadiation,2) ..' W/m²', domoticz.LOG_INFO)
		domoticz.log('Scattered Radiation = '.. domoticz.utils.round(scatteredRadiation,2) ..' W/m²', domoticz.LOG_DEBUG)
		domoticz.log('Total radiation = ' .. domoticz.utils.round(totalRadiation,2) ..' W/m²', domoticz.LOG_INFO)
		domoticz.log('Total Radiation in lux = '.. domoticz.utils.round(Lux,2)..' Lux', domoticz.LOG_DEBUG)
		domoticz.log('Total weighted lux  = '.. domoticz.utils.round(weightedLux,2)..' Lux', domoticz.LOG_INFO)

		-- No update if Lux is already 0. So lastUpdate of the Lux sensor will keep the time when Lux has reached 0.
		-- (Kind of timeofday['SunsetInMinutes'])
		if idxLux and domoticz.devices(idxLux).lux + domoticz.utils.round(weightedLux, 0) > 0 then
			domoticz.devices(idxLux).updateLux(domoticz.utils.round(weightedLux,0))
		end
		if idxSolarAzimuth then
		   domoticz.devices(idxSolarAzimuth).updateCustomSensor(domoticz.utils.round(sunAzimuth,0))
		end   
		if idxSolarAltitude then
		   domoticz.devices(idxSolarAltitude).updateCustomSensor(domoticz.utils.round(sunAltitude,1))
		end
		-- No update if radiation is already 0. See LUX
		if idxRadiation and (domoticz.devices(idxRadiation).rawData[1] + domoticz.utils.round(totalRadiation, 2) > 0) then
            local d = domoticz.devices(idxRadiation)
            if nil == d then
        		domoticz.log('Device '..idxRadiation.. ' was not found.', domoticz.LOG_ERROR)
            elseif type(d.updateRadiation) == "function" then
    		    d.updateRadiation(domoticz.utils.round(totalRadiation,2))
            elseif type(d.updateCustomSensor) == "function" then
                d.updateCustomSensor(domoticz.utils.round(totalRadiation,2))
            else
        		domoticz.log('Device '..idxRadiation.. ' does not have a updateRadiation() nor updateCustomSensor() function.', domoticz.LOG_ERROR)
            end
		end
		if logToFile then
			local logDebug = os.date('%Y-%m-%d %H:%M:%S',os.time())
			logDebug=logDebug..' Azimuth:' .. sunAzimuth .. ' Altitude:' .. sunAltitude
			logDebug=logDebug..' Okta:' .. okta..'  KC:'.. Kc
			logDebug=logDebug..' Direct:'..directRadiation..' inDirect:'..scatteredRadiation..' TotalRadiation:'..totalRadiation..' LuxCloud:'.. domoticz.utils.round(weightedLux,2)
			os.execute('echo '..logDebug..' >>'..tmpLogFile)  -- compatible Linux & Windows
		end
	end
}
