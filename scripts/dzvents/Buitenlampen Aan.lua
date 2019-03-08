-- Check the wiki for dzVents
-- remove what you don't need
return {

	-- optional active section,
	-- when left out the script is active
	-- note that you still have to check this script
	-- as active in the side panel
	active = {

		true,  -- either true or false, or you can specify a function

--		function(domoticz)
--		    return domoticz.time.matchesRule('15 minutes before sunset before 21:00')
--			-- return true/false
--		end
	},
	-- trigger
	-- can be a combination:
	on = {

		-- timer triggers
		timer = {
			-- timer triggers.. if one matches with the current time then the script is executed
    		function(domoticz)
	    	    return (domoticz.time.matchesRule('before sunrise') and domoticz.time.matchesRule('at 07:00'))
	    	        or (domoticz.time.matchesRule('before 22:30') and domoticz.time.matchesRule('at sunset'))
--	    	    domoticz.time.matchesRule('15 minutes before sunset before 21:00')
--	    	        or domoticz.time.matchesRule('at sunset before 21:00') 
----	    	        or domoticz.time.matchesRule('15 minutes after sunrise between 00:00-07:00')
--	    	        or domoticz.time.matchesRule('at 07:00 before sunrise')
		    end
		}
	},

--	-- custom logging level for this script
--	logging = {
--        level = domoticz.LOG_DEBUG,
--        marker = "Buitenlampen"
--    },

	-- actual event code
	-- the second parameter is depending on the trigger
	-- when it is a device change, the second parameter is the device object
	-- similar for variables, scenes and groups and httpResponses
	-- inspect the type like: triggeredItem.isDevice
	execute = function(domoticz, triggeredItem, info)
	    domoticz.log( tostring(info.trigger)..'.', domoticz.LOG_INFO)
		local d = domoticz.devices('Tuin: Buitenlamp')
		if (d.state ~= 'On') then
		    d.switchOn()
		end
	end
}
