-- Auto-OnOff - Keep any number of groups of switches in sync. 
--
-- This is usefull in many scenarios.
-- For example: you have a switch at the bottom of the stairs that switches a light, but there is
-- no switch at the top of the stairs. Now if you add some wall switch with no wires to the light,
-- in the 2nd floor, you can use this script to make both switches control the light. You can even 
-- add more lights and another switch on for example the 3rd floor.
-- Another example: you have a wall switch next to the door, and you want to have all the lights
-- in the room to go on and off with this one wall switch and you don't feel like having wires to
-- all of these lights. Simply put a smart plug between the lights you want to switch off and on.
-- Then use this script to have the wall switch control all of the smart plugs.


local SETTINGS = {
    { "Angelique: Bedlamp", "Angelique: S2" },
    { "Joeri: S1", "Joeri: Ventilator 1" },
    { "Mischa: Ledstrip", "Mischa: S2" },
    { "Mischa: Plafond", "Mischa: S1" },
--    { "Richard: Plafond", "Richard: S2" },
--    { "Richard: S2", "Thuis werken" },
    { "Berging: Plafond", "Berging: Deur" },
    { "Richard: Scherm Midden", "Richard: Speakers computer"},
    { "Richard: Scherm tv", "Richard: Speakers"} 
}



-- A list of all unique devices mentioned in the settings (exlcuding any that are alone in a group).
local triggers = {}

-- A list of lists, containing all groups any unique device is in.
local groups = {}

for grpidx, grp in ipairs(SETTINGS) do
    if #grp > 1 then    -- If a group has only one device in it
                        -- then there are no other devices that
                        -- we need to switch.
        for _, name in ipairs(grp) do
    
            -- Build a table with all unique device names from
            -- any group. This is the list of triggers that we
            -- wait for.
            local j = 1
            while j <= #triggers and name > triggers[j] do
                j = j + 1
            end
            if j > #triggers then
                table.insert( triggers, j, name )
            elseif name ~= triggers[j] then     -- no duplicates
                table.insert( triggers, j, name )
            end
            
            -- For each unique device we also keep a list of the
            -- groups it is in. This way we can find what other 
            -- devices to switch. We don't want to check the enitre
            -- group twice if someone accidentaly enters the same 
            -- name twice in a group, so we filter out any 
            -- duplicates here.
            if nil == groups[name] then
                groups[name] = { grpidx }
            else
                local j = 1
                while j <= #groups[name] and grpidx > groups[name][j] do
                    j = j + 1
                end
                if j > #groups[name] then
                    table.insert( groups[name], j, grpidx )
                elseif grpidx ~= groups[name][j] then
                    table.insert( groups[name], j, grpidx )
                end
            end
        end
    end
end

return {
	on = {
		devices = triggers
	},
    execute = function(domoticz, device, triggerInfo)
		if domoticz.EVENT_TYPE_DEVICE == triggerInfo.type then
		    if nil ~= groups[device.name] then
		        for _, grpidx in ipairs(groups[device.name]) do
		            domoticz.devices().filter(SETTINGS[grpidx]).forEach(
						function(otherdevice)
						    if otherdevice.name ~= device.name and 
						       otherdevice.bState ~= device.bState then
							    if device.bState then
							        otherdevice.switchOn().silent()
							    else
							        otherdevice.switchOff().silent()
							    end
							end
						end
					)		            
		        end
		    end
        end
    end
}
