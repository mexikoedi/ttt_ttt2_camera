if engine.ActiveGamemode() ~= "terrortown" then return end
SWEP.Base = "weapon_tttbase"
SWEP.Author = "mexikoedi"
SWEP.HoldType = "normal"
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/Cardboard_box02.mdl"
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false

SWEP.CanBuy = {ROLE_DETECTIVE}

SWEP.LimitedStock = true
SWEP.AllowDrop = false
