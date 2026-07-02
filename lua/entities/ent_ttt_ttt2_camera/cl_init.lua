if engine.ActiveGamemode() ~= "terrortown" then return end
include("shared.lua")
function ENT:Draw()
    self:DrawModel()
end

surface.CreateFont("DermaExtraLarge", {
    font = "Roboto",
    size = 48,
    weight = 800,
    antialias = true
})

local RENDER_CONNECTION_LOST = false
local NOISE = Material("camera/noise")
local IS_DRAWING_CAMERA = false
local CAMERA_WINDOW
local function GetActiveCameraEntity()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:IsActive() then return end
    for _, ent in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if IsValid(ent) and ent:GetPlayer() == ply and ent:GetWelded() then return ent end
    end
end

local function RenderWithoutOutlines(fn)
    if not outline or not outline.Add then return fn() end
    local oldAdd = outline.Add
    outline.Add = function() end
    local ok, err = xpcall(fn, debug.traceback)
    outline.Add = oldAdd
    if not ok then
        IS_DRAWING_CAMERA = false
        error(err, 0)
    end
end

local function RenderCameraFeed(ent, panel, w, h)
    local viewPadding = 8
    local titleBarHeight = 24
    local viewX = viewPadding
    local viewY = titleBarHeight + viewPadding
    local viewW = math.max(1, w - viewPadding * 2)
    local viewH = math.max(1, h - viewY - viewPadding)
    local screenX, screenY = panel:LocalToScreen(viewX, viewY)
    RenderWithoutOutlines(function()
        IS_DRAWING_CAMERA = true
        LocalPlayer():DrawShadow(false)
        surface.SetDrawColor(Color(0, 0, 0))
        surface.DrawRect(viewX, viewY, viewW, viewH)
        surface.SetDrawColor(color_white)
        local cdata = {}
        cdata.origin = ent:GetPos() + ent:GetAngles():Forward() * 3 + ent:GetAngles():Right() * -1
        cdata.angles = ent:GetAngles()
        cdata.x = screenX
        cdata.y = screenY
        cdata.w = viewW
        cdata.h = viewH
        cdata.fov = 90
        cdata.znear = .1
        cdata.aspect = viewW / viewH
        render.RenderView(cdata)
        IS_DRAWING_CAMERA = false
        surface.SetDrawColor(Color(255, 255, 255, 3))
        surface.SetMaterial(NOISE)
        surface.DrawTexturedRect(viewX, viewY, viewW, viewH)
    end)

    IS_DRAWING_CAMERA = false
end

local function EnsureCameraWindow()
    if IsValid(CAMERA_WINDOW) then return CAMERA_WINDOW end
    CAMERA_WINDOW = vgui.Create("DFrame")
    CAMERA_WINDOW:SetSize(540, 340)
    CAMERA_WINDOW:SetMinWidth(175)
    CAMERA_WINDOW:SetMinHeight(150)
    CAMERA_WINDOW:SetPos(ScrW() - 540, 0)
    CAMERA_WINDOW:SetTitle("Camera")
    CAMERA_WINDOW:SetDraggable(true)
    CAMERA_WINDOW:SetScreenLock(true)
    CAMERA_WINDOW:SetSizable(true)
    CAMERA_WINDOW:ShowCloseButton(false)
    CAMERA_WINDOW:SetMouseInputEnabled(true)
    CAMERA_WINDOW:SetKeyboardInputEnabled(false)
    CAMERA_WINDOW.PaintOver = function(self, w, h)
        local ent = GetActiveCameraEntity()
        if not ent and not RENDER_CONNECTION_LOST then return end
        if RENDER_CONNECTION_LOST then
            surface.SetDrawColor(Color(0, 0, 0))
            surface.DrawRect(8, 24, w - 16, h - 32)
            surface.SetDrawColor(Color(160, 160, 160))
            surface.SetMaterial(NOISE)
            surface.DrawTexturedRect(9, 25, w - 18, h - 34)
            surface.SetFont("DermaExtraLarge")
            local text = "CONNECTION LOST"
            local textW, textH = surface.GetTextSize(text)
            surface.SetTextPos(w / 2 - textW / 2 - 2, h / 2 - textH / 2 - 1)
            surface.SetTextColor(Color(0, 0, 0))
            surface.DrawText(text)
            surface.SetTextPos(w / 2 - textW / 2, h / 2 - textH / 2)
            surface.SetTextColor(Color(255, 0, 0))
            surface.DrawText(text)
            return
        end

        RenderCameraFeed(ent, self, w, h)
    end
    return CAMERA_WINDOW
end

hook.Add("Think", "TTT2CameraWindowState", function()
    local window = EnsureCameraWindow()
    local ply = LocalPlayer()
    local ent = GetActiveCameraEntity()
    local shouldShow = IsValid(ply) and ply:IsActive() and (IsValid(ent) or RENDER_CONNECTION_LOST)
    window:SetVisible(shouldShow)
end)

hook.Add("CreateMove", "TTT2CameraRotate", function(cmd)
    for _, v in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if v.IsReady and IsValid(v:GetPlayer()) and v:GetPlayer() == LocalPlayer() and v:GetShouldPitch() and LocalPlayer():IsActive() then
            local ang = (v:GetPos() - LocalPlayer():EyePos()):Angle()
            local ang2 = Angle(math.NormalizeAngle(ang.p), math.NormalizeAngle(ang.y), math.NormalizeAngle(ang.r))
            cmd:SetViewAngles(ang2)
            cmd:ClearMovement()
        end
    end
end)

hook.Add("ShouldDrawLocalPlayer", "TTT2CameraDrawLocalPlayer", function() return IS_DRAWING_CAMERA end)
net.Receive("TTT2CameraDetachment", function()
    if RENDER_CONNECTION_LOST then return end
    surface.PlaySound("ambient/energy/spark5.wav")
    RENDER_CONNECTION_LOST = true
    timer.Simple(2.5, function() RENDER_CONNECTION_LOST = false end)
end)

net.Receive("TTT2CameraPickUp", function() RENDER_CONNECTION_LOST = false end)