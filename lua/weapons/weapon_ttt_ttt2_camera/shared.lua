if engine.ActiveGamemode() ~= "terrortown" then return end
SWEP.Base = "weapon_tttbase"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/dav0r/camera.mdl"
SWEP.Kind = WEAPON_EQUIP2
SWEP.Spawnable = false
SWEP.AutoSpawnable = false
SWEP.AdminOnly = false
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = true
SWEP.AllowDrop = false
function SWEP:Initialize()
    self:SetModelScale(0.7)
    self:SetHoldType("camera")
end

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "Camera")
end

function SWEP:CameraPlaced()
    return IsValid(self:GetCamera())
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then self:GetOwner():DrawViewModel(false) end
    return true
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    if SERVER then
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:LagCompensation(true)
        if not self:CameraPlaced() then
            local tr = util.TraceLine({
                start = owner:GetShootPos(),
                endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
                filter = owner
            })

            if tr.HitWorld then
                local camera = ents.Create("ent_ttt_ttt2_camera")
                camera:SetPlayer(owner)
                camera:SetPos(tr.HitPos - owner:EyeAngles():Forward())
                camera:SetAngles((owner:EyeAngles():Forward() * -1):Angle())
                camera:SetWelded(true)
                camera:Spawn()
                camera:Activate()
                camera:SetPos(tr.HitPos - owner:EyeAngles():Forward())
                camera:SetAngles((owner:EyeAngles():Forward() * -1):Angle())
                timer.Simple(0, function() constraint.Weld(camera, tr.Entity, 0, 0, 0, true) end)
                camera:SetShouldPitch(true)
                self:SetCamera(camera)
                self:SetHoldType("magic")
            end
        else
            local camera = self:GetCamera()
            if camera:GetShouldPitch() then
                camera:SetShouldPitch(false)
                timer.Simple(0.1, function() self:Remove() end)
            end
        end

        for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
            if v:GetPlayer() == owner and v ~= self:GetCamera() then v:Remove() end
        end

        self:SetNextPrimaryFire(CurTime() + 1)
        owner:LagCompensation(false)
    end
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():IsActive() then self:GetOwner():ConCommand("lastinv") end
end