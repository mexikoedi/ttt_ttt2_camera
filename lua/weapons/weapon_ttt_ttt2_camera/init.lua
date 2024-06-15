if engine.ActiveGamemode() ~= "terrortown" then return end
AddCSLuaFile()
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
resource.AddFile("materials/vgui/ttt/weapon_camera.vmt")
resource.AddFile("materials/camera/noise.vmt")
function SWEP:OnDrop()
    self:Remove()
end