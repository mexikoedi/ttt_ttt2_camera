if engine.ActiveGamemode() ~= "terrortown" then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("TTTCameraDetach")
util.AddNetworkString("TTTCamera.Instructions")
function ENT:Use(user)
    if user:IsDetective() and user == self:GetPlayer() then
        self:Remove()
        if not self:GetShouldPitch() then
            user:Give("weapon_ttt_ttt2_camera")
        else
            user:GetWeapon("weapon_ttt_ttt2_camera").camera:SetShouldPitch(false)
            user:GetWeapon("weapon_ttt_ttt2_camera").camera:Remove()
            net.Start("TTTCamera.Instructions")
            net.Send(user)
        end
    end
end

function ENT:OnTakeDamage(dmginfo)
    if self:GetShouldPitch() then return end
    if dmginfo:GetDamageType() ~= DMG_BURN then
        if IsValid(self:GetPlayer()) and self:GetWelded() then
            net.Start("TTTCameraDetach")
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