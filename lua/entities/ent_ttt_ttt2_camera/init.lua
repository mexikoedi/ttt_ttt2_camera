if engine.ActiveGamemode() ~= "terrortown" then return end
AddCSLuaFile()
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("TTT2CameraDetachment")
util.AddNetworkString("TTT2CameraPickUp")
function ENT:Use(user)
    if self:GetWelded() and user ~= self:GetPlayer() then return end
    self:Remove()
    if not self:GetShouldPitch() then user:Give("weapon_ttt_ttt2_camera") end
    net.Start("TTT2CameraPickUp")
    net.Send(user)
end

function ENT:OnTakeDamage(dmginfo)
    if self:GetShouldPitch() then return end
    if not IsValid(dmginfo:GetAttacker()) then return end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(true) end
    if dmginfo:GetDamageType() ~= DMG_BURN and self:GetWelded() then
        if IsValid(self:GetPlayer()) then
            net.Start("TTT2CameraDetachment")
            net.Send(self:GetPlayer())
        end

        constraint.RemoveAll(self)
        self:SetWelded(false)
        self:TakePhysicsDamage(dmginfo)
    end

    self.HP = self.HP - dmginfo:GetDamage()
    if self.HP <= 0 then
        local ed = EffectData()
        ed:SetStart(self:GetPos())
        ed:SetOrigin(self:GetPos())
        ed:SetScale(0.25)
        util.Effect("HelicopterMegaBomb", ed)
        self:Remove()
    end
end

function CameraCleanup()
    for _, ent in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        ent:Remove()
    end
end

hook.Add("TTTPrepareRound", "TTT2CameraCleanup", CameraCleanup)
hook.Add("SetupPlayerVisibility", "TTT2CameraSetupPlayerVisibility", function()
    for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        AddOriginToPVS(v:GetPos() + v:GetAngles():Forward() * 3)
    end
end)

hook.Add("SetupMove", "TTT2CameraRotating", function(ply)
    for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if v.IsReady and IsValid(v:GetPlayer()) and v:GetPlayer() == ply and v:GetShouldPitch() and ply:IsActive() then
            local ang = v:GetAngles()
            ang:RotateAroundAxis(ang:Right(), ply:GetCurrentCommand():GetMouseY() * -.15)
            ang.p = math.Clamp(ang.p, -75, 75)
            ang.r = 0
            ang.y = v.OriginalY
            v:SetAngles(ang)
        end
    end
end)

hook.Add("PlayerDeath", "TTT2CameraResetOnDeath", function(victim)
    for _, camera in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if camera:GetPlayer() == victim and camera:GetShouldPitch() then camera:SetShouldPitch(false) end
    end
end)