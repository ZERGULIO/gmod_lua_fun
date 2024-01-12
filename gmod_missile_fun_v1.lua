if SERVER then
    local function GetInterceptDirection(origin, targetPosition, missileSpeed, targetVelocity)
        local los = targetPosition - origin
        local distance = los:Length()
        local alpha = math.acos(los:Dot(targetVelocity) / (distance * targetVelocity:Length()))
        local vt = targetVelocity:Length()
        local vRatio = vt / missileSpeed

        local a = 1 - (vRatio * vRatio)
        local b = 2 * vRatio * distance * math.cos(alpha)
        local c = -distance * distance

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return Vector(0, 0, 0), false
        end

        local root1 = (-b + math.sqrt(discriminant)) / (2 * a)
        local root2 = (-b - math.sqrt(discriminant)) / (2 * a)

        local interceptVectorMagnitude = math.max(root1, root2)
        local time = interceptVectorMagnitude / missileSpeed
        local estimatedPos = targetPosition + targetVelocity * time
        local result = (estimatedPos - origin):GetNormalized()

        return result, true
    end

    local function SpawnRocketEntity(ply)
        if IsValid(ply) then
            local pos = ply:GetPos()
            local ang = ply:EyeAngles()
            local dir = ang:Forward()
            pos = pos + dir * 300
            pos.z = pos.z + 250

            local ent = ents.Create("prop_physics")
            ent:SetModel("models/props_junk/PropaneCanister001a.mdl")
            ent:SetPos(pos)
            ent:Spawn()

            util.SpriteTrail(ent, 0, Color(0, 0, 0), false, 15, 1, 4, 1 / (15 + 1) * 0.5, "trails/smoke.vmt")

            local physObj = ent:GetPhysicsObject()
            if IsValid(physObj) then
                physObj:SetInertia(Vector(0.1, 0.1, 0.1))
            end

            local cone = ents.Create("prop_physics")
            cone:SetModel("models/props_junk/TrafficCone001a.mdl")
            cone:Spawn()
            cone:SetCollisionGroup(COLLISION_GROUP_WORLD)

            local timeCounter = 0
            local lastPos = ent:GetPos()
            local missileSpeeds = {}

            timer.Create("RocketPushTimer" .. tostring(ent:EntIndex()), 0.05, 0, function()
                if IsValid(ent) then
                    if IsValid(physObj) then
                        timeCounter = timeCounter + 50
                        if timeCounter < 3000 then
                            physObj:ApplyForceCenter(Vector(0, 0, 10000))
                        else
                            local currentPos = ent:GetPos()
                            table.insert(missileSpeeds, (currentPos - lastPos):Length() / 0.05)
                            if #missileSpeeds > 20 then -- keep the last 20 speed measurements
                                table.remove(missileSpeeds, 1)
                            end
                            local missileSpeed = 0
                            for _, speed in ipairs(missileSpeeds) do
                                missileSpeed = missileSpeed + speed
                            end
                            missileSpeed = missileSpeed / #missileSpeeds

                            local targetPos = ply:GetPos()
                            local playerVelocity = ply:GetVelocity()
                            local distance = ent:GetPos():Distance(targetPos)

                            local forceDir, interceptPossible = GetInterceptDirection(ent:GetPos(), targetPos, missileSpeed, playerVelocity)

                            if interceptPossible then
                                physObj:ApplyForceCenter(forceDir * 15000)
                            end

                            cone:SetPos(targetPos + Vector(0, 0, 50))

                            if distance < 150 then
                                local effectdata = EffectData()
                                effectdata:SetOrigin(ent:GetPos())
                                util.Effect("Explosion", effectdata)
                                util.Effect("cball_explode", effectdata)
                                ent:EmitSound("ambient/explosions/explode_4.wav")
                                ent:Remove()

                                if IsValid(cone) then
                                    cone:Remove()
                                end
                            end
                        end
                        lastPos = ent:GetPos()
                    end
                else
                    timer.Remove("RocketPushTimer" .. tostring(ent:EntIndex()))
                end
            end)
        end
    end

    local scriptPlayer = Entity(1)
    timer.Create("SpawnRocketTimer", 1, 4, function()
        SpawnRocketEntity(scriptPlayer)
    end)
end
