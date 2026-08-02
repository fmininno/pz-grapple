lib.callback.register('pz-grapple:perm', function(source)
    local src = source
    local isRole = exports["DiscordAPI"]:isRolePresent(src, Config.DiscordRole)
    if Config.Debug then
        print('[PZ-GRAPPLE] Check user id: ' .. src .. ' role permission', isRole)
    end
    return isRole
end)
