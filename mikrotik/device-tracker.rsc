:local bridgeUrl "http://webhook4mqtt.local:5000/publish"
:local mqttTopicPrefix "my/binary_sensor"
:local unknownDeviceName "presence_guest"
:local commonAttrs "\"zone\":\"home\",\"source_type\":\"router\""

:local knownMacs {
    "AA:BB:CC:DD:EE:FF"="presence_myphone";
    "AA:BB:CC:DD:EE:F0"="donttrack_mylaptop";
}

:local seenList ""
:local unknownList ""
:local unknownNames ""
:local unknownPresent false

:local post do={
    /tool fetch url=$1 http-method=post keep-result=no \
        http-header-field="Content-Type: application/json" \
        http-data=("{\"topic\":\"" . $2 . "\",\"message\":" . $3 . ",\"retain\":true}")
}

:foreach reg in=[/interface wireless registration-table find] do={
    :local mac [/interface wireless registration-table get $reg mac-address]
    :if ([:typeof ($knownMacs->$mac)] != "nothing") do={
        :local name ($knownMacs->$mac)
        :if ((!($name ~ "^donttrack")) && ([:find $seenList ("," . $name . ",")] < 0)) do={
            :set seenList ($seenList . "," . $name . ",")
        }
    } else={
        :set unknownPresent true
        :local hostName [/ip dhcp-server lease get [find mac-address=$mac] host-name]
        :if ([:len $hostName] = 0) do={ :set hostName "unknown" }
        :set unknownList ($unknownList . $mac . ",")
        :set unknownNames ($unknownNames . $hostName . ",")
    }
}

:foreach mac,alias in=$knownMacs do={
    :if (!($alias ~ "^donttrack")) do={
        :local state "OFF"
        :if ([:find $seenList ("," . $alias . ",")] >= 0) do={
            :set state "ON"
        }
        $post ($bridgeUrl) ($mqttTopicPrefix . "/" . $alias . "/state") ("\"" . $state . "\"")
        $post ($bridgeUrl) ($mqttTopicPrefix . "/" . $alias . "/attributes") ("{" . $commonAttrs . "}")
    }
}

:local unknownState "OFF"
:if ($unknownPresent) do={ :set unknownState "ON" }

:local guestAttrs ("{\"macs\":\"" . $unknownList . "\",\"names\":\"" . $unknownNames . "\", " . $commonAttrs . "}")

$post ($bridgeUrl) ($mqttTopicPrefix . "/" . $unknownDeviceName . "/state") ("\"" . $unknownState . "\"")
$post ($bridgeUrl) ($mqttTopicPrefix . "/" . $unknownDeviceName . "/attributes") ($guestAttrs)
