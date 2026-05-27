fx_version "cerulean"
game "gta5"

title "Laymo - Autonomous Ride Service"
description "A Waymo/Uber style autonomous ride service app for lb-phone or CodeM Phone (QBX, QB, ESX, or ox_core)"
author "Beetle Studios"
version "1.0.0"

lua54 "yes"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
    "locales/init.lua"
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
    "ui/dist/**/*",
    "locales/EN.lua",
    "locales/IT.lua",
    "locales/DE.lua",
    "locales/ES.lua",
    "locales/FR.lua",
    "locales/PT.lua"
}

-- No ui_page: the UI is only shown inside the configured phone when the user opens the Laymo app.
-- The selected phone loads our UI via the URL registered in AddCustomApp (client/main.lua).

dependencies {
    "ox_lib"
}
