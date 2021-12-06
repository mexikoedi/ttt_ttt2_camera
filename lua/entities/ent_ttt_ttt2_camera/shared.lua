if engine.ActiveGamemode() ~= "terrortown" then return end
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Camera"
ENT.Author = "mexikoedi"
ENT.Contact = "Steam"
ENT.Instructions = "Is only used for the camera item."
ENT.Purpose = "Camera entity for the camera item."
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Welded")
    self:NetworkVar("Entity", 0, "Player")
    self:NetworkVar("Bool", 1, "ShouldPitch")
end

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

    timer.Simple(0, function()
        self:GetPhysicsObject():SetMass(25)
    end)

    if SERVER then
        self:SetUseType(SIMPLE_USE)
        self.HP = 80 -- you can change the health of the camera to your likings
    end
end

function ENT:Think()
end

if SERVER then
    hook.Add("SetupPlayerVisibility", "TTTCamera.VISLEAF", function()
        for k, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
            AddOriginToPVS(v:GetPos() + v:GetAngles():Forward() * 3)
        end
    end)

    hook.Add("SetupMove", "TTTCamera.Rotate", function(ply, mv)
        for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
            if v.GetPlayer and v.GetShouldPitch and IsValid(v:GetPlayer()) and v:GetPlayer() == ply and v:GetShouldPitch() and ply:Alive() then
                local ang = v:GetAngles()
                ang:RotateAroundAxis(ang:Right(), ply:GetCurrentCommand():GetMouseY() * -.15)
                ang.p = math.Clamp(ang.p, -75, 75)
                ang.r = 0
                ang.y = v.OriginalY
                v:SetAngles(ang)
            end
        end
    end)
end

hook.Add("PlayerSwitchWeapon", "TTTCamera.RotateNoSwitch", function(ply)
    for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if v.GetPlayer and v.GetShouldPitch and IsValid(v:GetPlayer()) and v:GetPlayer() == ply and v:GetShouldPitch() and ply:Alive() then return true end
    end
end)

if CLIENT then
    hook.Add("CreateMove", "TTTCamera.Rotate", function(cmd)
        for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
            if v.GetPlayer and IsValid(v:GetPlayer()) and v:GetPlayer() == LocalPlayer() and v:GetShouldPitch() and LocalPlayer():Alive() then
                local ang = (v:GetPos() - LocalPlayer():EyePos()):Angle()
                local ang2 = Angle(math.NormalizeAngle(ang.p), math.NormalizeAngle(ang.y), math.NormalizeAngle(ang.r))
                cmd:SetViewAngles(ang2)
                cmd:ClearMovement()
            end
        end
    end)
end

hook.Add("ShouldCollide", "TTTCamera.Collide", function(e1, e2)
    if e1:IsPlayer() and e2:GetClass() == "ent_ttt_ttt2_camera" then return true end
    if e2:IsPlayer() and e1:GetClass() == "ent_ttt_ttt2_camera" then return true end
end)