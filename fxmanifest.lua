fx_version 'cerulean'
game 'gta5'

name "old_ring"
description "ring for job"
author "OldMoney"
version "1.0.0"

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	"rageUI/RMenu.lua",
	"rageUI/menu/RageUI.lua",
	"rageUI/menu/Menu.lua",
	"rageUI/menu/MenuController.lua",
	"rageUI/components/*.lua",
	"rageUI/menu/elements/*.lua",
	"rageUI/menu/items/*.lua",
	"rageUI/menu/panels/*.lua",
	"rageUI/menu/panels/*.lua",
	"rageUI/menu/windows/*.lua",
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}




files {
	'data/*.json',
	'web/dist/index.html',
	'web/dist/assets/**/*'
}

ui_page 'web/dist/index.html'
