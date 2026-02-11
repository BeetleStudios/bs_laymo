fx_version "cerulean"
game "gta5"

title "Laymo - Autonomous Ride Service"
description "A Waymo/Uber style autonomous ride service app for lb-phone (QBX Core)"
author "BS Scripts"
version "1.0.0"

lua54 "yes"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}

client_scripts {
    "client/main.lua",
    "client/autopilot.lua",
    "client/nui.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua"
}

files {
    "icon.png",
    "ui/dist/**/*"
}

-- No ui_page: the UI is only shown inside lb-phone when the user opens the Laymo app.
-- lb-phone loads our UI via the URL registered in AddCustomApp (client/main.lua).

dependencies {
    "qbx_core",
    "lb-phone",
    "ox_lib"
}
