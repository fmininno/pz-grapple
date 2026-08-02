RegisterServerEvent("pz-grapple:start:sync")
AddEventHandler("pz-grapple:start:sync", function(params)
    local src = source
    local players = GetPlayers()
    for _, p in pairs(players) do
        local playerCoords = GetEntityCoords(GetPlayerPed(p))
        local coords = GetEntityCoords(GetPlayerPed(src))
        local distance = #(playerCoords - coords)
        if distance < 100 then
            TriggerClientEvent("pz-grapple:start:syncC", p, src, params)
        end
    end
end)
