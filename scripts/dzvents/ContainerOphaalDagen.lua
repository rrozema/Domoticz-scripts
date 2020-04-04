--[[ getGarbageDates.lua for [ dzVents >= 2.4 ]

This script is only useful in those areas of the Netherlands where the HVC group collects household garbage

Enter your zipcode and housenumber in the appropriate place between the lines starting with --++++
Next is to set your virtual text and or virtual alert device.

the text device will contain the most nearby collectdates for the four types of household garbage
the alert device will contain the date and type for the garbagecollecion that will arrive first

Ga naar de volgende url in de browser, waarbij je de juiste url voor jouw afvalverwerker kiest, en postcode en huisnummer wijzigd.
https://apps.hvcgroep.nl/rest/adressen/3328LN-35
de output die je krijgt te zien bevat een bagId wat je later nodig hebt.

Dit bagId wordt gebruikt in de volgende URLs:
Ophaaldagen: https://apps.hvcgroep.nl/rest/adressen/bagId/kalender/2018 <<replace bagId
De ophaaldagen gebruiken ID's om aan te geven welk afvaltype het betreft.
Informatie over deze afvaltypes kan opgehaald worden via:
https://apps.hvcgroep.nl/rest/adressen/bagId/afvalstromen <<replace bagId

]]--

--++++--------------------- Mandatory: Set your values and device names below this Line -------------------------------------

local ZIPCODE = "2622LH"        -- postcode, no space between 4 digits and 2 letters!
local NUMBER = "87"             -- huisnummer

--local ZIPCODE = "5654LN"
--local NUMBER = "11"

--local ZIPCODE = "3121AR"
--local NUMBER = "15"

local TEXT_DEVICE_NAME = "Garbage"
local ALERT_DEVICE_NAME = "GarbageAlert"

--++++---------------------------- Set your values and device names above this Line -----------------------------------------

local GETBAGID = "getBagId_Response"
local GETTYPES = "getTypes_Response"
local GETDATES = "getGarbage_Response"

local provider_list = {
        ["Cyclus NV"] = "https://afvalkalender.cyclusnv.nl",
        ["HVC"] = "https://apps.hvcgroep.nl",
        ["Dar"] = "https://afvalkalender.dar.nl",
        ["Afvalvrij"] = "https://afvalkalender.circulus-berkel.nl",
        ["Meerlanden"] = "https://afvalkalender.meerlanden.nl",
        ["Cure"] = "https://afvalkalender.cure-afvalbeheer.nl", 
        ["Avalex"] = "https://www.avalex.nl",
        ["RMN"] = "https://inzamelschema.rmn.nl",
        ["Venray"] = "https://afvalkalender.venray.nl",
        ["Den Haag"] = "https://huisvuilkalender.denhaag.nl",
        ["Berkelland"] = "https://afvalkalender.gemeenteberkelland.nl",
        ["Alphen aan den Rijn"] = "https://afvalkalender.alphenaandenrijn.nl",
        ["Waalre"] = "http://afvalkalender.waalre.nl",
        ["ZRD"] = "https://afvalkalender.zrd.nl",
        ["Spaarnelanden"] = "https://afvalwijzer.spaarnelanden.nl",
        --["Montfoort"] = "https://afvalkalender.montfoort.nl",     -- url no longer available?
        ["GAD"] = "https://inzamelkalender.gad.nl",
        ["Cranendonck"] = "https://afvalkalender.cranendonck.nl"
        --["irado"] = "https://www.irado.nl/bewoners/afvalkalender"
    }

return {
    on = {
        timer = {
          "at 00:01",
          "at 05:00"
          --'every 1 minutes'
        },
        httpResponses = { 
            GETDATES,  -- Trigger reading garbage collection schema
            GETTYPES,  -- Trigger reading afvalstromen
            GETBAGID
        } 
    },

--    logging = {
--        level = domoticz.LOG_INFO, -- Remove the "-- at the beginning of this and next line for debugging the script
--        marker = "collectGarbage"
--    },

    data = { 
        code = {initial = nil},
        bagId = {initial = nil},
        types = {initial = nil},
        garbage = {initial = {}},
        provider = {initial = nil}
    }, -- Keep a copy of last json just in case

    execute = function(dz, triggerObject)

        local myCode = ZIPCODE .. "-" .. NUMBER

        -- Build a get request for a specified trigger type
        -- and send it after secondsFromNow.
        local function request_Response( triggerName, secondsFromNow)
            local url = nil

            if GETDATES == triggerName then
                local myYear = os.date("%Y")
                url = provider_list[dz.data.provider] .. "/rest/adressen/" .. dz.data.bagId .. "/kalender/" .. myYear
                --dz.log( "request dates from " .. dz.data.provider .. ". url = " .. url .. ".", dz.LOG_INFO )
            elseif GETTYPES == triggerName then
                url = provider_list[dz.data.provider] .. "/rest/adressen/" .. dz.data.bagId .. "/afvalstromen"
                --dz.log( "request types from " .. dz.data.provider .. ". url = " .. url .. ".", dz.LOG_INFO )
            elseif GETBAGID == triggerName then
                url = provider_list[dz.data.provider] .. "/rest/adressen/" .. myCode
                --dz.log( "request bagid from " .. dz.data.provider .. ". url = " .. url .. ".", dz.LOG_INFO )
            else
                dz.log( "Unknown trigger " .. triggerName .. " in request_Response.", dz.LOG_ERROR)
            end
            
            if nil ~= url then
                dz.openURL (
                        {
                            url = url,
                            method = "GET",
                            callback = triggerName
                        }
                    ).afterSec(secondsFromNow)
            end
        end
    
        -- Response to a types request
        local function handleTypesJSON( rt )
            if nil ~= rt and #rt > 0 then
                local types = {}
                
                for j = 1, #rt do
                    types[tostring(rt[j].id)] = rt[j].title
                end
                
                dz.data.types = types
            else
                dz.log( "No types list received from " .. dz.data.provider .. ".", dz.LOG_WARNING )
                dz.data.types = nil
            end
            return (nil ~= dz.data.types)
        end
        
        -- Response to a bagid request
        local function handleBagIdJSON( rt )
            if nil ~= rt and #rt > 0 then
                dz.data.bagId = tostring(rt[1].bagId)
                dz.data.code = myCode

                dz.log( "Got bagId " .. dz.data.bagId .. " for your address from provider " .. dz.data.provider .. ".", dz.LOG_ERROR )
            else
                dz.log( "No bagId received from " .. dz.data.provider .. ".", dz.LOG_ERROR )
                dz.data.bagId = nil
            end
            return (nil ~= dz.data.bagId)
        end
    
        local function string2Epoch(dateString) -- seconds from epoch based on stringdate (used by string2Date)
            -- Assuming a date pattern like: yyyy-mm-dd
            local pattern = "(%d+)-(%d+)-(%d+)"
            local runyear, runmonth, runday= dateString:match(pattern)
            local convertedTimestamp = os.time({year = runyear, month = runmonth, day = runday})
            return convertedTimestamp
        end
        
        local function string2Date(str,fmt) -- convert string from json into datevalue
            if fmt then
                return os.date(fmt,string2Epoch(str)) 
            end
            return os.date(" %A %d %B, %Y",string2Epoch(str))
        end
        
        local function alertLevel(delta)
            if delta < 1 then return dz.ALERTLEVEL_RED end
            if delta < 2 then return dz.ALERTLEVEL_GREEN end
            return dz.ALERTLEVEL_GREY
        end
        
        local function setGarbageAlertDevice(alertDeviceName,alertText,alertDate)
            local delta = tonumber(string2Date(alertDate,"%d")) - tonumber(os.date("%d")) -- delta in days between today and first garbage collection date
            local alert_device = dz.devices( alertDeviceName )
            if nil ~= alert_device then
                if nil == alertText then
                    alertText = "<no information available>"
                end
                local color = alertLevel(delta)
                if alertText ~= alert_device.text or color ~= alert_device.color then
                    alert_device.updateAlertSensor( color, alertText )
                end
            end
            return (delta == 0)
        end

        -- Handle response to dates request.
        local function handleGarbageJSON( rt )
            if nil ~= rt and #rt > 0 then
                dz.data.garbage = rt
            elseif nil ~= dz.data.garbage and #dz.data.garbage > 0 then
                rt = dz.data.garbage
                dz.log("Problem with received response (no data). Re-using data from previous run.", dz.LOG_WARNING)
            else
                dz.log("Problem with received response (no data) and no previous data is available.", dz.LOG_ERROR)
                return false
            end
            
            local garbageLines
            local typeEarliestDate
            local overallEarliestDate = nil -- Hopefully we will have a different garbage collection system by then
            local garbageToday = false
            local today = os.date("%Y-%m-%d")
            
            local results = {}
            local unknown = {}
            
            -- Find the first date for each type.
            for j = 1, #rt do
                if dz.data.types[tostring(rt[j].afvalstroom_id)] and rt[j].ophaaldatum >= today then
                    local r = results[tostring(rt[j].afvalstroom_id)]
                    if r == nil or rt[j].ophaaldatum < r then
                        results[tostring(rt[j].afvalstroom_id)] = rt[j].ophaaldatum
                    end
                    if overallEarliestDate == nil or overallEarliestDate > rt[j].ophaaldatum then
                        overallEarliestDate = rt[j].ophaaldatum
                        overallEarliestType = tostring(rt[j].afvalstroom_id)
                    end
                else
                    unknown[tostring(rt[j].afvalstroom_id)] = true
                end
            end
        
            -- if we've found at least one value ...
            if overallEarliestDate then
                -- ... build the lines for the text device...
                local ordered = {}
                local j
                -- first convert the dates and their descriptions in an ordered list ...
                for i, v in pairs(dz.data.types) do
                    if results[i] then
                        j = 1
                        while j <= #ordered and results[i] > ordered[j].date do
                            j = j + 1
                        end
                        table.insert(ordered, j, { ["date"] = results[i], ["description"] = dz.data.types[i] } )
                    end
                        
                end
                -- then build a string from that list.
                garbageLines = ""
                for i, v in ipairs(ordered) do
                    garbageLines = garbageLines .. string2Date(ordered[i].date,"%a %e %b" ) .. " : " .. ordered[i].description .. "\n"
                end
            else
                garbageLines = "<No information available>"
            end

            -- Plus, update the Alert device with the first upcoming collection date.
            if overallEarliestDate then -- Update AlertDevice with nearest date and its type.
                garbageToday = setGarbageAlertDevice( 
                                    ALERT_DEVICE_NAME,
                                    dz.data.types[overallEarliestType] .. "\n" .. string2Date(overallEarliestDate),
                                    overallEarliestDate
                                )
            else
                garbageToday = false
            end
        
            local text_device = dz.devices(TEXT_DEVICE_NAME)
            if text_device then -- Update defined virtual text device with dates / types
                if garbageLines ~= text_device.text then
                    text_device.updateText(garbageLines)
                end
            end
        
            if dz.time.matchesRule("at 05:00-10:00") and garbageToday then
                if overallEarliestType and dz.data.types[overallEarliestType] then
                    dz.notify(dz.data.types[overallEarliestType] .. " will be collected today")
                end
            end
            
            return true
        end
        

        
        -- Main
        if triggerObject.isTimer then

            -- If we have a nil bagId, a nil provider or the address has changed,
            -- get the first provider from our list and call it's url to see if we
            -- get a bagid for our zipcode + number.
            if nil == dz.data.bagId or nil == dz.data.provider or nil == dz.data.types or dz.data.code ~= myCode then
                -- Get the first provider from the provider_list.
                dz.data.provider, _ = next( provider_list, nil )
                if nil ~= dz.data.provider then
                    request_Response( GETBAGID, 1)
                else
                    dz.log( "Sorry, we can't get your garbage collection dates, the provider list seems to be empty.", dz.LOG_ERROR )
                end
            
            -- If we have everything we need, get the dates.
            else
                request_Response( GETDATES, 1 )
            end

        elseif triggerObject.isHTTPResponse then
            
            if triggerObject.ok then
                if GETDATES == triggerObject.trigger then
                    if handleGarbageJSON( triggerObject.json ) then
                        dz.log( "Done collecting dates for your address from " .. dz.data.provider .. ".", dz.LOG_ERROR )
                        return
                    else
                        -- Try again with the next provider from the provider_list.
                        dz.data.provider, _ = next( provider_list, dz.data.provider )
                        if nil ~= dz.data.provider then
                            request_Response( GETBAGID, 1)
                        else
                            dz.log( "Sorry, none of the providers in our list has dates for your address.", dz.LOG_ERROR )
                        end
                    end

                elseif GETTYPES == triggerObject.trigger then
                    if handleTypesJSON( triggerObject.json ) then
                        -- Now that we have a types list, get the dates.
                        request_Response( GETDATES, 1 )
                    else
                        -- Try again with the next provider from the provider_list.
                        dz.data.provider, _ = next( provider_list, dz.data.provider )
                        if nil ~= dz.data.provider then
                            request_Response( GETBAGID, 1)
                        else
                            dz.log( "Sorry, none of the providers in our list has dates for your address.", dz.LOG_ERROR )
                        end
                    end

                elseif GETBAGID == triggerObject.trigger then
                    if handleBagIdJSON( triggerObject.json ) then
                        -- Now that we have a bagid, get the types list.
                        request_Response( GETTYPES, 1 )
                    else
                        dz.log( "No bagid json from ".. dz.data.provider .. ".", dz.LOG_ERROR )
                            
                        -- Try again with the next provider from the provider_list.
                        dz.data.provider, _ = next( provider_list, dz.data.provider )
                        if nil ~= dz.data.provider then
                            request_Response( GETBAGID, 1)
                        else
                            dz.log( "Sorry, none of the providers in our list has dates for your address.", dz.LOG_ERROR )
                        end
                    end

                else
                    dz.log( "Unknown trigger " .. triggerObject.trigger .. " in handle_Response.", dz.LOG_ERROR)
                end
            else
                dz.log( "Not ok response for " .. triggerObject.trigger .. " from " .. dz.data.provider .. ".", dz.LOG_ERROR)
                -- Try again with the next provider from the provider_list.
                dz.data.provider, _ = next( provider_list, dz.data.provider )
                if nil ~= dz.data.provider then
                    request_Response( GETBAGID, 1)
                else
                    dz.log( "Sorry, none of the providers in our list has dates for your address.", dz.LOG_ERROR )
                end
            end
        end
    end
}
