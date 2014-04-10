temp <- hardware.pin1
temp.configure(ANALOG_IN);
led <- hardware.pin2;
led.configure(DIGITAL_OUT);

temperatureSamples <- 10; //number of temperature samples per measurement MAX 10!
periodShort <- 10; //minutes
periodLong <-  3; //Hours
d <- date();

//Get non volatile variables
function loadNonVolatileVariables()
{
  if (!("nv" in getroottable())) {
    nv <- { currentEnabled = true, trendEnabled = false };
  }
}
 
// 1. Load NonVolatileVariables
// 2. Flash the LED
// 3. When the time has come, read the temperature
// 4. Schedule next work appointment
function doWork() {
  //1.
  loadNonVolatileVariables();
  
  //2.
  flashLed();

  //3.
  //TREND Temp: Check if the time is on the 3rd hour (0-3-6...21)
  //and if the temperature for this period has not been send already (trendEnabled)
  if ((d.hour % periodLong) == 0 && nv.trendEnabled == true) 
  {
    nv.trendEnabled = false;
    sendTemperature(true);
  }
  else if (!((d.hour % periodLong) == 0))
  {
    nv.trendEnabled = true;
  }
  
  //CURRENT Temp: Check if the time is on the 10th minute (0-10-20...50)
  //and if the temperature for this period has not been send already (currentEnabled)
  if((d.min % periodShort) == 0 && nv.currentEnabled == true)
  {
    nv.currentEnabled = false;
    sendTemperature(false);
  }
  else if (!((d.min % periodShort) == 0))
  {
    nv.currentEnabled = true;
  }
  
  //4.
  imp.onidle(function() {
    imp.deepsleepfor(10 - (time() % 10)); //Sleep for 60 seconds
  }); 
}

//Send temperature to the agent
function sendTemperature(trend) {
  local temperature = getAverageTemperature();
  local formattedTemperature = format("%.01f", temperature);
  
  if (trend)
  {
    agent.send("updateTemp", [formattedTemperature, "Trend"]);
    imp.sleep(15);
    agent.send("updateTemp", [formattedTemperature, "Current"]);
  }
  else
  {
    agent.send("updateTemp", [formattedTemperature, "Current"]);
  }
  
  server.expectonlinein(periodShort * 60);
}

//Get temperature from sensor, formula: ºC = 100 * V - 50.
function getTemperatureSample()
{
  local supplyVoltage = hardware.voltage();
  local voltageRead =  supplyVoltage * (temp.read() / 65535.0); //Get millivolts reading
  return (voltageRead - 0.5) * 100; //Celcius
}

//Get the average temperature from X samples
function getAverageTemperature()
{
  local sum = 0;
  local temperatureArray = [];
  
  for(local i = 0; i < temperatureSamples; i++)
  {
    temperatureArray.push(getTemperatureSample());
    imp.sleep(0.1);
  }
  
  for(local i = 0; i < temperatureSamples; i++)
  {
    sum = sum + temperatureArray[i];
  }
  
  return (sum / temperatureSamples);
}

function flashLed()
{
  led.write(1);
  imp.sleep(0.1);
  led.write(0);
}

loadNonVolatileVariables();
imp.onidle(doWork);