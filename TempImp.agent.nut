//=======================Functions======================
function httpPostToThingspeak (data) {
  local thingspeakUrl = "http://api.thingspeak.com/update";
  local headers = {"Content-Type": "application/x-www-form-urlencoded",
                  "X-THINGSPEAKAPIKEY":"[INSERT API KEY]"};
  local request = http.post(thingspeakUrl, headers, data);
  return request.sendsync();
}

function GetDateFormatted(datefirst)
{
  local formatStringDateFirst = "%04d-%02d-%02d %02d:%02d:%02d";
  local formatStringTimeFirst = "%02d:%02d:%02d %02d-%02d-%04d";
  
  if (datefirst)
  {
    return format(formatStringDateFirst, 
    lastTempTimestamp.year,
    lastTempTimestamp.month,
    lastTempTimestamp.day,
    lastTempTimestamp.hour,
    lastTempTimestamp.min,
    lastTempTimestamp.sec);
  }
  else
  {
    return format(formatStringTimeFirst, 
    lastTempTimestamp.hour,
    lastTempTimestamp.min,
    lastTempTimestamp.sec
    lastTempTimestamp.day,
    lastTempTimestamp.month,
    lastTempTimestamp.year);
  }
}

//=======================Global vars======================

lastTemp <- 0;
lastTempTimestamp <- date();

//=======================HTTP Interrupts======================

// Log the URLs we need
server.log("Request Temperature: " + http.agenturl() + "?temp");
 
function requestHandler(request, response) {
  try {
    local temp = 0;
    // check if the user sent temp as a query parameter
    if ("temp" in request.query) {
        response.send(200, 
        "<p>The last logged temperature is: </p></br>" + 
        "<h1>" + lastTemp + "°C </h1></br>" + 
        "<div>" + GetDateFormatted(false) + "</div>" +
        "<div><iframe width='450' height='260' style='border: 1px solid #cccccc;' src='https://api.thingspeak.com/channels/11223/charts/1?width=450&height=260&days=2&dynamic=true&yaxis=Temperature%20(C)&xaxis=Time&title=Current%20Temperature'/></div>"
        );
      }
    else
    {
        // send a response back saying everything was OK.
        response.send(200, "What do you want exactly?");
    }
  } catch (ex) {
    response.send(500, "Darnit, a server error occured: " + ex);
  }
}

// register the HTTP handler
http.onrequest(requestHandler);

//=======================Device Interrupts======================
local field1 = "field1";
local field2 = "field2";

device.on("updateTemp", function(arrTempType) 
  {
    //Set the temperature for 
    lastTemp = arrTempType[0];
    lastTempTimestamp <- date();
    
    local response;
    if (arrTempType[1] == "Current"){
      response = httpPostToThingspeak(field1 + "=" + arrTempType[0]);
    } else if (arrTempType[1] == "Trend") {
      response = httpPostToThingspeak(field2 + "=" + arrTempType[0]);
    }
    
    if (response.body != "0")
    {
      server.log("Datapoint (" + arrTempType[0] +  " °C) for '" + arrTempType[1] +
      "' nr [" + response.body + "] accepted!");
    }
  }
);