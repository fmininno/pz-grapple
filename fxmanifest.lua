fx_version 'cerulean'

game 'gta5'

description 'PZFX - GRAPPLE'
lua54 'yes'
version '1.0'
author 'PZ-DEV'

shared_scripts {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'cfg_grapple.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/grapple.lua'
}

escrow_ignore {
    'server/perm.lua',
    'cfg_grapple.lua',
}
