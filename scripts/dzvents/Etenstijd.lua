local DEVICE_NAMES = { 
        'Woonkamer: Plafond',
        'Joeri: Plafond',
        'Mischa: Plafond',
        'Dimitri: Plafond'
    }

return {
	on = {
		scenes = {
			'Etenstijd'
		}
	},
	execute = function(domoticz, scene)
		domoticz.log('Scene ' .. scene.name .. ' was triggered', domoticz.LOG_INFO)
		
		local dev = domoticz.devices().filter(DEVICE_NAMES)
        dev.forEach(
            function(d)
            	if d.state == 'Off' then
            		d.switchOn().forSec(1).repeatAfterSec(1, 2)
            	else
            		d.switchOff().forSec(1).repeatAfterSec(1, 2)
            	end
            end
        )
	end
}