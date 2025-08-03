if engine.ActiveGamemode() ~= "terrortown" then return end
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Camera"
ENT.Author = "mexikoedi"
ENT.Contact = "Steam"
ENT.Instructions = "Only used for the camera item."
ENT.Purpose = "Camera entity for the camera item."
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AdminSpawnable = false
ENT.IsReady = false
function ENT:Initialize()
    self.CanPickup = false
    self:SetModel("models/dav0r/camera.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:DrawShadow(false)
    self:SetModelScale(.33, 0)
    self:Activate()
    self.OriginalY = self:GetAngles().y
    self:SetupPhysics()
    if SERVER then
        self:SetUseType(SIMPLE_USE)
        self.HP = 100
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Welded")
    self:NetworkVar("Entity", 0, "Player")
    self:NetworkVar("Bool", 1, "ShouldPitch")
    self.IsReady = true
end

function ENT:SetupPhysics()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:SetMass(25)
    else
        timer.Simple(0.1, function()
            if IsValid(self) and IsValid(self:GetPhysicsObject()) then
                self:GetPhysicsObject():EnableMotion(false)
                self:GetPhysicsObject():SetMass(25)
            end
        end)
    end
end

hook.Add("PlayerSwitchWeapon", "TTT2CameraRotateNoSwitch", function(ply)
    for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if v.IsReady and IsValid(v:GetPlayer()) and v:GetPlayer() == ply and v:GetShouldPitch() and ply:IsActive() then return true end
    end
end)

hook.Add("ShouldCollide", "TTT2CameraCollide", function(e1, e2)
    if e1:IsPlayer() and e2:GetClass() == "ent_ttt_ttt2_camera" then return true end
    if e2:IsPlayer() and e1:GetClass() == "ent_ttt_ttt2_camera" then return true end
end)