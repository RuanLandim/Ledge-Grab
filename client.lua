-- Author: Pedro Ruan Landim (Bartolomeu)
-- EN: Public snippet inspired by the Ledge Grab mechanic from NoPixel V
-- PT-BR: Snippet público inspirado na mecânica de Ledge Grab anunciada pelo NoPixel V

ConfigLedgeGrab = {}

-- EN: Maximum distance the player needs to be from the edge to climb
-- PT-BR: Distância máxima que o jogador precisa estar da borda para escalar
ConfigLedgeGrab.ReachDistance = 1.6          -- Good values / Bons valores: 1.2 ~ 2.0

-- EN: Maximum height the ledge can have relative to the player
-- PT-BR: Altura máxima que a borda pode ter em relação ao jogador
ConfigLedgeGrab.MaxClimbHeight = 2.8         -- Good values / Bons valores: 2.2 ~ 3.5

-- EN: Minimum height (avoids grabbing the floor or very low things)
-- PT-BR: Altura mínima (evita agarrar no chão ou em coisas muito baixas)
ConfigLedgeGrab.MinClimbHeight = 0.6

-- EN: Cooldown between climbs (in ms) - prevents spam
-- PT-BR: Tempo de recarga entre escaladas (em ms) - evita spam
ConfigLedgeGrab.Cooldown = 900

-- EN: Climb key (22 = Space / X on controller)
-- PT-BR: Tecla para escalar (22 = Espaço / X no controle)
ConfigLedgeGrab.ClimbKey = 22

-- EN: Only works if falling / jumping
-- PT-BR: Só funciona se estiver caindo / pulando
ConfigLedgeGrab.OnlyInAir = true

-- EN: Debug (shows in console when a ledge is detected)
-- PT-BR: Debug (mostra no console quando uma borda é detectada)
ConfigLedgeGrab.Debug = false

local LastClimb = 0

function RotationToDirection(Rotation)
    local Z = math.rad(Rotation.z)
    local X = math.rad(Rotation.x)
    local Num = math.abs(math.cos(X))
    return vector3(-math.sin(Z) * Num, math.cos(Z) * Num, math.sin(X))
end

function HasClimbableLedge(Ped)
    local Coords = GetEntityCoords(Ped)
    local Forward = GetEntityForwardVector(Ped)

    -- Main raycast forward (at chest/head height)
    local StartPos = Coords + vector3(0.0, 0.0, 0.7)
    local EndPos = StartPos + (Forward * ConfigLedgeGrab.ReachDistance)

    local Ray = StartShapeTestRay(StartPos.x, StartPos.y, StartPos.z, EndPos.x, EndPos.y, EndPos.z, 17, Ped, 0)
    local _, Hit, HitCoords, SurfaceNormal, EntityHit = GetShapeTestResult(Ray)

    if not Hit then
        -- Second raycast slightly lower (helps on edges)
        StartPos = Coords + vector3(0.0, 0.0, 0.35)
        EndPos = StartPos + (Forward * ConfigLedgeGrab.ReachDistance)
        Ray = StartShapeTestRay(StartPos.x, StartPos.y, StartPos.z, EndPos.x, EndPos.y, EndPos.z, 17, Ped, 0)
        _, Hit, HitCoords, SurfaceNormal, EntityHit = GetShapeTestResult(Ray)
    end

    if Hit then
        local HeightDiff = HitCoords.z - Coords.z

        -- Checks if the height is within the configured range
        if HeightDiff >= ConfigLedgeGrab.MinClimbHeight and HeightDiff <= ConfigLedgeGrab.MaxClimbHeight then
            -- Checks if the surface is more or less vertical (edge)
            local NormalDot = SurfaceNormal.z
            if NormalDot < 0.65 then  -- the smaller, the more vertical the wall is
                if ConfigLedgeGrab.Debug then
                    print(("[Parkour] Ledge detected | Height: %.2f | Distance: %.2f"):format(HeightDiff, #(HitCoords - Coords)))
                end
                return true
            end
        end
    end

    return false
end

Citizen.CreateThread(function()
    while true do
        local Sleep = 250
        local Ped = PlayerPedId()

        if not IsPedInAnyVehicle(Ped, false) and not IsEntityDead(Ped) and not IsPedRagdoll(Ped) then
            local IsInAir = IsPedJumping(Ped) or IsPedFalling(Ped) or (GetEntityHeightAboveGround(Ped) > 1.2)

            if not ConfigLedgeGrab.OnlyInAir or IsInAir then
                Sleep = 0

                if IsControlJustPressed(0, ConfigLedgeGrab.ClimbKey) then
                    local Now = GetGameTimer()

                    if Now - LastClimb > ConfigLedgeGrab.Cooldown then
                        if HasClimbableLedge(Ped) then
                            TaskClimb(Ped, true)
                            LastClimb = Now
                        end
                    end
                end
            end
        end

        Citizen.Wait(Sleep)
    end
end)