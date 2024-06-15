if engine.ActiveGamemode() ~= "terrortown" then return end
include("shared.lua")
SWEP.PrintName = "Camera"
SWEP.Author = "mexikoedi"
SWEP.Contact = "Steam"
SWEP.Instructions = "Left click to place the camera on walls."
SWEP.Purpose = "You can watch the other terrorists."
SWEP.Slot = 7
SWEP.ViewModelFOV = 10
SWEP.ViewModelFlip = false
SWEP.Icon = "vgui/ttt/weapon_camera"
SWEP.EquipMenuData = {
    type = "item_weapon",
    name = "Camera",
    desc = "Use this to watch terrorists get killed live. Left click to place."
}

surface.SetFont("Trebuchet22")
local w = surface.GetTextSize("LEFT CLICK TO PLACE THE CAMERA")
local x = surface.GetTextSize("MOVE THE MOUSE UP AND DOWN TO PITCH THE CAMERA")
function SWEP:DrawHUD()
    local owner = self:GetOwner()
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
        filter = owner
    })

    if tr.HitWorld and not self:CameraPlaced() then
        surface.SetFont("Trebuchet22")
        surface.SetTextColor(Color(50, 60, 200, 255))
        surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 2 + 50)
        surface.DrawText("LEFT CLICK TO PLACE THE CAMERA")
    end

    if self:CameraPlaced() then
        surface.SetFont("Trebuchet22")
        surface.SetTextColor(Color(50, 60, 200, 255))
        surface.SetTextPos(ScrW() / 2 - x / 2, ScrH() / 2 + 50)
        surface.DrawText("MOVE THE MOUSE UP AND DOWN TO PITCH THE CAMERA")
    end
end

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if IsValid(owner) then
        if self:CameraPlaced() then return end
        self:DrawCameraWorldModel()
    else
        self:DrawModel()
    end
end

function SWEP:DrawCameraWorldModel()
    local rightHandBone = self:GetOwner():LookupBone("ValveBiped.Bip01_R_Hand")
    if not rightHandBone then return end
    local rightHandPos, rightHandAngle = self:GetOwner():GetBonePosition(rightHandBone)
    if not rightHandPos or not rightHandAngle then return end
    rightHandPos = rightHandPos + rightHandAngle:Forward() * 6.97 + rightHandAngle:Up() * -4.34 + rightHandAngle:Right() * 2.2
    if not IsValid(self.CustomWorldModel) then
        self.CustomWorldModel = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
        self.CustomWorldModel:SetModelScale(0.7)
    end

    local modelSettings = {
        model = self.WorldModel,
        pos = rightHandPos,
        angle = self:GetOwner():EyeAngles()
    }

    render.Model(modelSettings, self.CustomWorldModel)
end