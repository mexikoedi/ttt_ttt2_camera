if engine.ActiveGamemode() ~= "terrortown" then return end
include("shared.lua")
function ENT:Draw()
    self:DrawModel()
end

local CAMERA_WINDOW
local CAMERA_NOISE = Material("camera/noise")
local IS_CAMERA_DRAWING = false
local IS_CAMERA_ACTIVE = false
local IS_CAMERA_CONNECTION_LOST = false
local function GetActiveCameraEntity()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:IsActive() then return end
    for _, ent in ipairs(ents.FindByClass("ent_ttt_ttt2_camera")) do
        if IsValid(ent) and ent:GetPlayer() == ply and ent:GetWelded() then return ent end
    end
end

local function RenderWithoutOutlines(fn)
    local oldOutlineAdd = outline and outline.Add
    local oldHaloAdd = halo and halo.Add
    if oldOutlineAdd then outline.Add = function() end end
    if oldHaloAdd then halo.Add = function() end end
    local ok, err = xpcall(fn, debug.traceback)
    if oldOutlineAdd then outline.Add = oldOutlineAdd end
    if oldHaloAdd then halo.Add = oldHaloAdd end
    if not ok then
        IS_CAMERA_DRAWING = false
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
        IS_CAMERA_DRAWING = true
        surface.SetDrawColor(0, 0, 0)
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
        IS_CAMERA_DRAWING = false
        surface.SetDrawColor(255, 255, 255, 3)
        surface.SetMaterial(CAMERA_NOISE)
        surface.DrawTexturedRect(viewX, viewY, viewW, viewH)
    end)

    IS_CAMERA_DRAWING = false
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
        if not ent and not IS_CAMERA_CONNECTION_LOST then return end
        if IS_CAMERA_CONNECTION_LOST then
            local x = 8
            local y = 24
            local vw = w - 16
            local vh = h - 32
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(x, y, vw, vh)
            surface.SetDrawColor(160, 160, 160)
            surface.SetMaterial(CAMERA_NOISE)
            surface.DrawTexturedRect(x + 1, y + 1, vw - 2, vh - 2)
            local text = "CONNECTION LOST"
            local fontSize = math.Clamp(math.floor(math.min(vw * 0.09, vh * 0.4)), 14, 48)
            local fontName = "TTT2CameraStatus_" .. fontSize
            if not _G[fontName] then
                surface.CreateFont(fontName, {
                    font = "Roboto",
                    size = fontSize,
                    weight = 800,
                    antialias = true
                })

                _G[fontName] = true
            end

            surface.SetFont(fontName)
            local tw, th = surface.GetTextSize(text)
            local tx = x + (vw - tw) * 0.5
            local ty = y + (vh - th) * 0.5
            surface.SetTextColor(0, 0, 0)
            surface.SetTextPos(tx - 2, ty - 2)
            surface.DrawText(text)
            surface.SetTextColor(255, 0, 0)
            surface.SetTextPos(tx, ty)
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
    IS_CAMERA_ACTIVE = IsValid(ply) and ply:IsActive() and (IsValid(ent) or IS_CAMERA_CONNECTION_LOST)
    window:SetVisible(IS_CAMERA_ACTIVE)
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

hook.Add("ShouldDrawLocalPlayer", "TTT2CameraDrawLocalPlayer", function(_) return IS_CAMERA_DRAWING end)
hook.Add("TTT2ModifyOverheadIcon", "TTT2CameraHideOverheadIcons", function(_, _) if IS_CAMERA_DRAWING then return false end end)
hook.Add("TTTRenderEntityInfo", "TTT2CameraSuppressTargetID", function(tData) if IS_CAMERA_ACTIVE then tData:EnableOutline(false) end end)
net.Receive("TTT2CameraDetachment", function()
    if IS_CAMERA_CONNECTION_LOST then return end
    surface.PlaySound("ambient/energy/spark5.wav")
    IS_CAMERA_CONNECTION_LOST = true
    timer.Simple(2.5, function() IS_CAMERA_CONNECTION_LOST = false end)
end)

net.Receive("TTT2CameraPickUp", function() IS_CAMERA_CONNECTION_LOST = false end)
do
    local function OverrideDrawBackground()
        if not vguihandler or not vguihandler.DrawBackground then
            timer.Simple(0.1, OverrideDrawBackground)
            return
        end

        local origDrawBg = vguihandler.DrawBackground
        vguihandler.DrawBackground = function()
            if not vguihandler.IsOpen() then return end
            if IS_CAMERA_ACTIVE then
                local oldBlurredBox = draw.BlurredBox
                local oldBox = draw.Box
                draw.BlurredBox = function() end
                draw.Box = function() end
                origDrawBg()
                draw.BlurredBox = oldBlurredBox
                draw.Box = oldBox
            else
                origDrawBg()
            end
        end
    end

    OverrideDrawBackground()
end