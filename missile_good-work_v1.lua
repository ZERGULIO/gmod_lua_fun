local function FindFastObjects(origin, radius)
    local entities = ents.FindInSphere(origin, radius)
    local fastObjects = {}

    for _, entity in ipairs(entities) do
        if entity:GetNWBool("IsCopy") then
            continue
        end

        local entityPhysObj = entity:GetPhysicsObject()
        if IsValid(entityPhysObj) and entityPhysObj:GetVelocity():Length() > 500 then
            if CurTime() - entity:GetCreationTime() >= 3 then
                table.insert(fastObjects, entity)
            end
        end
    end

    return fastObjects
end

local function delCopyObj(copy)
    if IsValid(copy) then
        copy:Remove()
    end
end

local function SpawnRedSphere(ply)
    if IsValid(ply) then
        local pos = ply:GetPos()
        local ang = ply:EyeAngles()
        local dir = ang:Forward()
        dir.z = 0
        dir:Normalize()
        pos = pos + dir * 200
        pos.z = pos.z + 30

        local ent = ents.Create("prop_physics")
        ent:SetModel("models/hunter/misc/sphere025x025.mdl")
        ent:SetPos(pos)
        ent:SetColor(Color(255, 0, 0))
        ent:Spawn()

        local physObj = ent:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        local targets = {}
        local targetTimers = {}

        timer.Create("FastObjectCheckTimer" .. tostring(ent:EntIndex()), 0.01, 0, function()
            if IsValid(ent) then
                local fastObjects = FindFastObjects(ent:GetPos(), 60000)
                for _, target in ipairs(fastObjects) do
                    if not table.HasValue(targets, target) then
                        table.insert(targets, target)

                        if (CurTime() - target:GetCreationTime()) >= 3 then
                            local copy = ents.Create("prop_physics")
                            copy:SetModel(ent:GetModel())
                            copy:SetPos(ent:GetPos())
                            copy:SetColor(ent:GetColor())
                            copy:Spawn()
                            copy:SetNWBool("IsCopy", true)

                            util.SpriteTrail(copy, 0, Color(0, 0, 0), false, 15, 1, 4, 1 / (15 + 1) * 0.5, "trails/smoke.vmt")

                            local copyPhysObj = copy:GetPhysicsObject()
                            if IsValid(copyPhysObj) then
                                local targetTimerName = "ApplyForceTimer" .. tostring(copy:EntIndex())
                                table.insert(targetTimers, targetTimerName)
                                timer.Create(targetTimerName, 0.01, 0, function()
                                    if IsValid(copy) and IsValid(target) then
                                        -- Calculate intercept vector
                                        local direction = (target:GetPos() - copy:GetPos()):GetNormalized()
                                        local navigationTime = (target:GetPos() - copy:GetPos()):Length() / 500
                                        local targetRelativeInterceptPosition = (target:GetPos() + target:GetPhysicsObject():GetVelocity() * navigationTime) - copy:GetPos()
                                        
                                        -- Apply force with lead
                                        copyPhysObj:ApplyForceCenter(targetRelativeInterceptPosition:GetNormalized() * 5000)

                                        if copy:GetPos():Distance(target:GetPos()) < 100 or (CurTime() - copy:GetCreationTime()) > 30 then
                                            delCopyObj(copy)
                                            timer.Remove(targetTimerName)
                                            table.RemoveByValue(targets, target)
                                            table.RemoveByValue(targetTimers, targetTimerName)
                                        end
                                    else
                                        timer.Remove(targetTimerName)
                                        table.RemoveByValue(targets, target)
                                        table.RemoveByValue(targetTimers, targetTimerName)
                                    end
                                end)
                            end
                        end
                    end
                end
            else
                timer.Remove("FastObjectCheckTimer" .. tostring(ent:EntIndex()))
                for _, targetTimerName in ipairs(targetTimers) do
                    timer.Remove(targetTimerName)
                end
            end
        end)
    end
end

local scriptPlayer = Entity(1)
SpawnRedSphere(scriptPlayer)
