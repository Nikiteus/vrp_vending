fx_version 'adamant'
games { 'gta5' }

name 'vrp_vending'
author 'smallo92'
contact 'https://github.com/smallo92/'
download 'https://github.com/smallo92/xnVending'
description 'Allows players to use vending machines'

server_scripts {
	"@vrp/lib/utils.lua",
	"server_load.lua"
}

client_scripts {
	"@vrp/lib/utils.lua",
	"client_load.lua"
}

files {
	"client.lua",
	"config.lua"
}
