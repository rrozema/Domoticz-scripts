--alle Formeln nach http://www.wettermail.de/wetter/feuchte.html
--
--Taupunktberechnung in °C
--function Taupunkt($temperatur,$relfeuchte)
--{
--    $val = (234.67*0.434292289*log(6.1*exp((7.45*$temperatur)
--            /(234.67+$temperatur)*2.3025851)*$relfeuchte/100/6.1))
--            /(7.45-0.434292289*log(6.1*exp((7.45*$temperatur)
--            /(234.67+$temperatur)*2.3025851)*$relfeuchte/100/6.1) );
--    return $val;
--}
--//Sättigungsdampfdruck in hPa
--function SaettigungsDampfDruck($temperatur)
--{
--    if ($temperatur >= 0)
--    {
--        $a = 7.5;
--        $b = 237.3;
--    }
--    elseif ($temperatur < 0)
--    {
--        $a = 7.6;
--        $b = 240.7;
--    }
--    $val = (6.1078 * exp( log(10) * (($a * $temperatur) / ($b + $temperatur)) ) );
--    return $val;
--}
--//Dampfdruck in hPa
--function DampfDruck($temperatur,$relfeuchte)
--{
--    $val = $relfeuchte/100 * SaettigungsDampfDruck($temperatur);
--    return $val;
--}
--//absolute Feuchte in g/m³
--function AbsoluteFeuchte($temperatur,$relfeuchte)
--{
--    $tk = ($temperatur + 273.15);
--    $val  = (exp(log(10) * 5) * 18.016/8314.3 * DampfDruck($temperatur,$relfeuchte)/$tk);
--    return $val;
--}
--
--$taupunkt = Taupunkt($temperatur,$relfeuchte);
--$sattdampfdruck = SaettigungsDampfDruck($temperatur);
--$dampfdruck = DampfDruck($temperatur,$relfeuchte);
--$absfeuchte = AbsoluteFeuchte($temperatur,$relfeuchte);
--
--

local TEMPHUM_DEVICE_NAME = '*: TempHum'

return {
	on = {
		devices = {
			TEMPHUM_DEVICE_NAME
		}
	},
	execute = function(domoticz, device)
		local device_name = string.sub( device.name, 1, string.len(device.name) - 9) .. ': Humidity'
		local hum_device = domoticz.devices(device_name)

		if nil ~= hum_device then
    	    local dampDruk
    	    if device.temperature >= 0 then
    	        dampDruk = (6.1078 * math.exp( math.log(10) * ((7.5 * device.temperature) / (237.3 + device.temperature)) ) );
    	    else
    	        dampDruk = (6.1078 * math.exp( math.log(10) * ((7.6 * device.temperature) / (240.7 + device.temperature)) ) );
    	    end
    	    
    		local absolute_humidity = math.floor(1000.0 * math.exp(math.log(10) * 5) * 18.016 / 8314.3 * (device.humidity / 100.0 * dampDruk) / (device.temperature + 273.15) + 0.5) / 1000.0
    		
    		hum_device.updateCustomSensor(tostring(absolute_humidity))
    	end
	end
}