GR = {}
GR.Enabled = false
GR.Player = {}
GR.Utils = {}
GR.CanUse = false

local function Tp(tpCoords)
    local ped, coords = cache.ped, tpCoords
    local oldCoords = GetEntityCoords(ped)

    local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
    local found = false

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()
        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end
        NewLoadSceneStop()
        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end

        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ)
            break
        end
        Wait(0)
    end

    if not found then
        SetPedCoordsKeepVehicle(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0)
    end
    SetPedCoordsKeepVehicle(ped, x, y, groundZ)
end
local function nextCoords(playerPed, distance)
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local radianHeading = math.rad(heading)

    local direction = vector3(
        -math.sin(radianHeading),
        math.cos(radianHeading),
        0.0
    )

    local targetX = playerCoords.x + direction.x * distance
    local targetY = playerCoords.y + direction.y * distance

    local found, groundZ = GetGroundZFor_3dCoord(targetX, targetY, 850.0, false)
    if not found then
        groundZ = playerCoords.z
    end

    local check = groundZ - playerCoords.z

    if check > 2.0 then
        local backStep = playerCoords - (direction * 1.0)
        local foundBack, groundBackZ = GetGroundZFor_3dCoord(backStep.x, backStep.y, backStep.z + 1.0, false)
        if foundBack then
            return vector3(backStep.x, backStep.y, groundBackZ + 0.1)
        else
            return vector3(playerCoords.x, playerCoords.y, playerCoords.z)
        end
    end

    return vector3(targetX, targetY, groundZ + 0.1)
end


CreateThread(function()
    if not Config.EventOnly then
        if Config.DiscordAPI then
            GR.CanUse = lib.callback.await('pz-grapple:perm', false)
            while not GR.CanUse do
                print('[PZ-GRAPPLE] CHECKING DISCORD ROLE...')
                Wait(5000)
                GR.CanUse = lib.callback.await('pz-grapple:perm', false)
            end
            print('[PZ-GRAPPLE] ALLOWED')
        end
        lib.addKeybind({
            name = ('hotkey%s'):format(Config.Key),
            description = 'GR_START',
            defaultKey = tostring(Config.Key),
            onPressed = function()
                if not GR.Enabled then
                    GR.Enabled = true
                    GR.Utils.DisableAA()
                    GR.grapple()
                end
            end
        })
    end
end)

function GR.grapple()
    if GR.Enabled then
        local coordsEscena = GR.Utils.RayTarget()
        if coordsEscena ~= vector3(0, 0, 0) and coordsEscena ~= nil then
            lib.hideTextUI()
            local done = false
            local doing = true
            while doing do
                Wait(0)
                if not done then
                    done = true
                    SetTimeout(200, function()
                        GR.WatchCoords(cache.ped, coordsEscena)
                        TriggerServerEvent('pz-grapple:start:sync', { coords = coordsEscena })
                        doing = false
                    end)
                end
            end
        else
            if coordsEscena == vector3(0, 0, 0) then
                lib.notify({
                    title = 'Out of range',
                    description = 'It is too far away!',
                    type = 'error'
                })
            end
        end
    end
    lib.hideTextUI()
    GR.Enabled = false
end

RegisterNetEvent("pz-grapple:start:syncC")
AddEventHandler("pz-grapple:start:syncC", function(targetSrc, params)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
    local aimPos = params.coords
    local pedPos = GetEntityCoords(playerPed)

    RequestModel("prop_cs_dildo_01")
    while not HasModelLoaded("prop_cs_dildo_01") do
        Wait(1)
    end

    local targetObject = CreateObject(
        joaat("prop_cs_dildo_01"),
        aimPos.x, aimPos.y, aimPos.z + 1.0,
        false, true, false
    )
    PlaceObjectOnGroundProperly(targetObject)
    SetEntityVisible(targetObject, false, 0)
    FreezeEntityPosition(targetObject, true)
    FreezeEntityPosition(playerPed, true)

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
    end

    local length = #(aimPos - pedPos)

    ropeHandle = AddRope(
        pedPos.x, pedPos.y, pedPos.z + 0.5,
        0.0, 0.0, 0.0,
        length,
        5, 5.0, 5.0, 0.0,
        false, false, true,
        5.0,
        false, nil
    )

    if not ropeHandle then
        print("Error creating rope")
        return
    end

    AttachEntitiesToRope(
        ropeHandle,
        playerPed,
        targetObject,
        pedPos.x, pedPos.y, pedPos.z,
        aimPos.x, aimPos.y, aimPos.z,
        length,
        false, false,
        nil, nil
    )

    StopRopeUnwindingFront(ropeHandle)
    StartRopeWinding(ropeHandle)
    RopeForceLength(ropeHandle, length)

    local distance = #(pedPos - aimPos)
    Wait(Config.Delay)

    CreateThread(function()
        LoadAnimDict(Config.Anim.dict)
        TaskPlayAnim(playerPed, Config.Anim.dict, Config.Anim.name, 8.0, -8.0, 100000, 1, 0, false, false, false)
    end)

    local count = 0
    local total = #(GetEntityCoords(playerPed) - aimPos)
    CreateThread(function()
        while distance > 1.0 do
            local playerPos = GetEntityCoords(playerPed)
            distance = #(playerPos - aimPos)

            local direction = (aimPos - pedPos)
            direction = direction / #direction
            local proposedCoords = playerPos + (direction * 1)

            local groundZ = proposedCoords.z
            local foundGround, zPos = GetGroundZFor_3dCoord(proposedCoords.x, proposedCoords.y, proposedCoords.z + 1.0)
            if foundGround then
                groundZ = math.max(proposedCoords.z, zPos + 1.0)
            end

            SetEntityCoordsNoOffset(playerPed, proposedCoords.x, proposedCoords.y, groundZ, true, true, true)

            count = count + 1.0
            if count > total then
                distance = 0
            end
            Wait(20)
        end

        local coordsEscena2 = nextCoords(cache.ped, 3.0)
        local _, ground2 = GetGroundZFor_3dCoord(coordsEscena2.x, coordsEscena2.y, coordsEscena2.z + 2.0)
        SetEntityCoordsNoOffset(playerPed, coordsEscena2.x, coordsEscena2.y, ground2 + 1.0, true, true, true)

        DeleteObject(targetObject)
        FreezeEntityPosition(playerPed, false)
        StopAnimTask(playerPed, Config.Anim.dict, Config.Anim.name, 1.0)

        if DoesRopeExist(ropeHandle) then
            StopRopeUnwindingFront(ropeHandle)
            StopRopeWinding(ropeHandle)
            RopeConvertToSimple(ropeHandle)
        end
        DeleteRope(ropeHandle)
    end)
end)

function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end
end

function GR.WatchCoords(ped, coords2)
    local coords = GetEntityCoords(ped)
    local pcoords = coords2
    local dx = pcoords.x - coords.x
    local dy = pcoords.y - coords.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(ped, heading)
end

GR.Player.Aiming = false
local showCrosshair = true

function GR.Utils.RayTarget()
    local MAX_DISTANCE = Config.MaxDistance or 150
    GR.Player.Aiming = true
    lib.showTextUI('[E] to grappling', Config.TextOpt)
    while GR.Player.Aiming do
        Wait(0)

        if showCrosshair then
            DrawRect(0.5, 0.5, 0.0025, 0.005, 255, 255, 255, 200)
        end

        if IsControlJustReleased(0, 38) then
            local playerPed = PlayerPedId()
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forwardVector = RotAnglesToVec(camRot)
            local rayEnd = camCoords + forwardVector * MAX_DISTANCE

            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, rayEnd.x, rayEnd.y, rayEnd.z, -1,
            playerPed, 0)
            local _, hit, hitCoords, _, entityHit = GetShapeTestResult(rayHandle)

            if hit then
                if Config.Debug then
                    print(string.format("Target: x=%.2f, y=%.2f, z=%.2f", hitCoords.x, hitCoords.y, hitCoords.z))
                end
            else
                hitCoords = rayEnd
                if Config.Debug then
                    print("Missing:", hitCoords)
                end
            end

            if entityHit ~= 0 then
                if Config.Debug then
                    print("Entity ID hitted:", entityHit)
                end
            end
            if IsPlayerFreeAiming(PlayerId()) then
                return hitCoords
            else
                lib.notify({
                    title = 'Aim',
                    description = 'You have to aim with the weapon !',
                    type = 'error'
                })
            end
        elseif IsControlJustReleased(0, 73) or IsControlJustReleased(0, 177) then
            GR.Player.Aiming = false
            GR.Enabled = false
        end
    end
end

function RotAnglesToVec(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

function GR.Utils.DisableAA()
    CreateThread(function()
        while GR.Enabled do
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 80, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 24, true)
            Wait(0)
        end
    end)
end
