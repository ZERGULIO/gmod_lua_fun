local ply = player.GetAll()[1]
if not IsValid(ply) then return end

-- трассировка
local trace = {}
trace.start = ply:EyePos()
trace.endpos = trace.start + ply:EyeAngles():Forward() * 200
trace.filter = ply

local tr = util.TraceLine(trace)

-- ракета
local ent = ents.Create("prop_physics")
if not IsValid(ent) then return end

ent:SetModel("models/props_phx/amraam.mdl")
ent:SetPos(tr.HitPos + Vector(0, 0, 10))
ent:SetAngles(ply:EyeAngles())
ent:Spawn()

local phys = ent:GetPhysicsObject()
if not IsValid(phys) then return end

phys:Wake()
phys:EnableGravity(false)
phys:SetDragCoefficient(0)
phys:SetAngleVelocity(Vector(0,0,0))

-- настройки
local SPEED = 1200        -- скорость ракеты
local TURN_SPEED = 0.08
local START_TIME = CurTime()

hook.Add("Think", "RocketMove_" .. ent:EntIndex(), function()
    if not IsValid(ent) then return end
    if not IsValid(ply) then return end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end

    local currentTime = CurTime()

    -- первые 2 секунды летим прямо
    if currentTime - START_TIME < 2 then
        phys:SetVelocity(ent:GetForward() * SPEED)
        phys:SetAngleVelocity(Vector(0,0,0))
        return
    end

    -- направление на игрока
    local targetPos = ply:WorldSpaceCenter()
    local dirToTarget = (targetPos - ent:GetPos()):GetNormalized()

    local targetAng = dirToTarget:Angle()

    -- плавный поворот
    local newAng = LerpAngle(TURN_SPEED, ent:GetAngles(), targetAng)

    phys:SetAngles(newAng)
    phys:SetAngleVelocity(Vector(0,0,0))

    -- ❗ теперь скорость всегда фиксированная
    phys:SetVelocity(ent:GetForward() * SPEED)
end)
