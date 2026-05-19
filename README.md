-- ============================================
--   Nycluu Script | Delta Executor
--   Blox Fruits | Segundo Mar
--   Tabs: ESP · FARM · MISC · FPS
-- ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================
-- CONFIGURACIÓN CENTRAL
-- ============================================
local Config = {
    -- ESP Jugadores
    ESP_Jugadores    = true,
    ESP_Cajas        = true,
    ESP_Nombres      = true,
    ESP_HP           = true,
    ESP_Distancia    = true,
    ESP_Nivel        = true,
    ESP_Tracers      = false,
    -- ESP Frutas
    ESP_Frutas       = true,
    ESP_FrutasTracer = false,
    -- ESP Mobs
    ESP_Mobs         = true,
    ESP_MobNombre    = true,
    ESP_MobHP        = true,
    ESP_MobTracer    = false,
    -- Rango general
    ESP_MaxDist      = 1500,

    -- FARM
    Farm_Auto        = false,
    Farm_TpMob       = true,
    Farm_AutoAttack  = true,
    Farm_AutoCollect = true,

    -- MISC
    Misc_NoClip      = false,
    Misc_InfJump     = false,
    Misc_Speed       = false,
    Misc_SpeedVal    = 32,
    Misc_AutoStats   = false,
    Misc_StatFocus   = "Melee",

    -- FPS
    FPS_Boost        = true,
    FPS_Sombras      = true,
    FPS_Particulas   = true,
    FPS_Texturas     = true,
    FPS_Niebla       = true,
}

-- ============================================
-- UTILS DRAWING
-- ============================================
local function NTexto(col, sz)
    local t = Drawing.new("Text")
    t.Color        = col or Color3.fromRGB(255,255,255)
    t.Size         = sz  or 13
    t.Center       = true
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Visible      = false
    t.Font         = Drawing.Fonts.UI
    return t
end
local function NCaja(col)
    local c = Drawing.new("Square")
    c.Color     = col or Color3.fromRGB(255,255,255)
    c.Thickness = 1.5
    c.Filled    = false
    c.Visible   = false
    return c
end
local function NLinea(col)
    local l = Drawing.new("Line")
    l.Color     = col or Color3.fromRGB(255,255,255)
    l.Thickness = 1
    l.Visible   = false
    return l
end
local function W2S(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on
end
local function DistLocal(pos)
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    return r and (pos - r.Position).Magnitude or 9999
end

-- ============================================
-- FPS BOOST
-- ============================================
local function AplicarFPS()
    if Config.FPS_Texturas  then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end
    if Config.FPS_Sombras   then Lighting.GlobalShadows = false; Lighting.ShadowSoftness = 0 end
    if Config.FPS_Niebla    then Lighting.FogEnd = 100000; Lighting.FogStart = 99999 end
    if Config.FPS_Particulas then
        local function killFX(o)
            if o:IsA("ParticleEmitter") or o:IsA("Trail") or
               o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
                o.Enabled = false
            end
        end
        for _, o in ipairs(Workspace:GetDescendants()) do killFX(o) end
        Workspace.DescendantAdded:Connect(killFX)
    end
    if syn and syn.set_fps_cap then syn.set_fps_cap(60) end
end
if Config.FPS_Boost then AplicarFPS() end

-- ============================================
-- ESP — JUGADORES
-- ============================================
local ESPJ = {}

local function LimpiarJ(p)
    if ESPJ[p] then
        for _, o in pairs(ESPJ[p]) do pcall(function() o:Remove() end) end
        ESPJ[p] = nil
    end
end

local function IniciarESPJ(player)
    if player == LocalPlayer then return end
    local d = {
        Caja   = NCaja(Color3.fromRGB(255,60,60)),
        Nombre = NTexto(Color3.fromRGB(255,255,255), 13),
        HP     = NTexto(Color3.fromRGB(80,255,80), 11),
        Dist   = NTexto(Color3.fromRGB(190,190,190), 10),
        Nivel  = NTexto(Color3.fromRGB(255,215,60), 10),
        Tracer = NLinea(Color3.fromRGB(255,60,60)),
    }
    ESPJ[player] = d

    local con
    con = RunService.RenderStepped:Connect(function()
        local function hide() for _, o in pairs(d) do o.Visible = false end end

        if not player or not player.Parent then
            hide(); LimpiarJ(player); con:Disconnect(); return
        end
        local char = player.Character
        if not char then hide(); return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then hide(); return end

        local dist = DistLocal(root.Position)
        if dist > Config.ESP_MaxDist then hide(); return end
        local sp, on = W2S(root.Position)
        if not on then hide(); return end

        local spT = W2S(root.Position + Vector3.new(0,3.2,0))
        local spB = W2S(root.Position - Vector3.new(0,3.2,0))
        local alt  = math.abs(spT.Y - spB.Y)
        local ancho = alt * 0.55
        local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)

        d.Caja.Visible = Config.ESP_Jugadores and Config.ESP_Cajas
        if d.Caja.Visible then
            d.Caja.Size     = Vector2.new(ancho, alt)
            d.Caja.Position = sp - Vector2.new(ancho/2, alt/2)
        end

        d.Nombre.Visible = Config.ESP_Jugadores and Config.ESP_Nombres
        if d.Nombre.Visible then
            d.Nombre.Text     = player.Name
            d.Nombre.Position = sp - Vector2.new(0, alt/2 + 14)
        end

        d.HP.Visible = Config.ESP_Jugadores and Config.ESP_HP
        if d.HP.Visible then
            d.HP.Color    = Color3.fromRGB(math.floor(255-hpPct*255), math.floor(hpPct*255), 0)
            d.HP.Text     = "HP " .. math.floor(hpPct*100) .. "%"
            d.HP.Position = sp - Vector2.new(0, alt/2 + 26)
        end

        d.Dist.Visible = Config.ESP_Jugadores and Config.ESP_Distancia
        if d.Dist.Visible then
            d.Dist.Text     = math.floor(dist) .. "m"
            d.Dist.Position = sp + Vector2.new(0, alt/2 + 4)
        end

        d.Nivel.Visible = Config.ESP_Jugadores and Config.ESP_Nivel
        if d.Nivel.Visible then
            local lvl = "?"
            pcall(function()
                lvl = tostring(player.leaderstats.Level.Value)
            end)
            d.Nivel.Text     = "Lv " .. lvl
            d.Nivel.Position = sp + Vector2.new(0, alt/2 + 16)
        end

        d.Tracer.Visible = Config.ESP_Jugadores and Config.ESP_Tracers
        if d.Tracer.Visible then
            local vp = Camera.ViewportSize
            d.Tracer.From = Vector2.new(vp.X/2, vp.Y)
            d.Tracer.To   = sp
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do task.spawn(IniciarESPJ, p) end
Players.PlayerAdded:Connect(IniciarESPJ)
Players.PlayerRemoving:Connect(LimpiarJ)

-- ============================================
-- ESP — FRUTAS
-- ============================================
local ESPF = {}

local function EsFruta(o)
    return o:IsA("Model") and (
        o.Name:find("Fruit") or o.Name:find("fruit") or
        o.Name:find("Logia") or o.Name:find("Zoan") or o.Name:find("Paramecia")
    )
end

local function AgregarFruta(o)
    if not EsFruta(o) or ESPF[o] then return end
    local d = {
        Label  = NTexto(Color3.fromRGB(255,215,0), 13),
        Tracer = NLinea(Color3.fromRGB(255,215,0)),
    }
    ESPF[o] = d
    local con
    con = RunService.RenderStepped:Connect(function()
        local function hide() d.Label.Visible=false; d.Tracer.Visible=false end
        if not Config.ESP_Frutas then hide(); return end
        if not o or not o.Parent then
            hide()
            pcall(function() d.Label:Remove(); d.Tracer:Remove() end)
            ESPF[o]=nil; con:Disconnect(); return
        end
        local part = o:FindFirstChild("Handle") or o.PrimaryPart or o:FindFirstChildOfClass("BasePart")
        if not part then hide(); return end
        local dist = DistLocal(part.Position)
        if dist > Config.ESP_MaxDist then hide(); return end
        local sp, on = W2S(part.Position + Vector3.new(0,2,0))
        if on then
            d.Label.Text     = o.Name .. "  [" .. math.floor(dist) .. "m]"
            d.Label.Position = sp
            d.Label.Visible  = true
            d.Tracer.Visible = Config.ESP_FrutasTracer
            if d.Tracer.Visible then
                local vp = Camera.ViewportSize
                d.Tracer.From = Vector2.new(vp.X/2, vp.Y); d.Tracer.To = sp
            end
        else hide() end
    end)
end

for _, o in ipairs(Workspace:GetDescendants()) do task.spawn(AgregarFruta, o) end
Workspace.DescendantAdded:Connect(function(o) task.wait(0.1); AgregarFruta(o) end)
Workspace.DescendantRemoving:Connect(function(o)
    if ESPF[o] then
        pcall(function() ESPF[o].Label:Remove(); ESPF[o].Tracer:Remove() end)
        ESPF[o]=nil
    end
end)

-- ============================================
-- ESP — MOBS
-- ============================================
local ESPM = {}

local MobNames = {
    "Swan Pirate","Fishman Warrior","Fishman Lord","Fishman Raider",
    "Fishman Captain","Tide Keeper","Ship Deckhand","Ship Engineer",
    "Ship Steward","Ship Officer","Snowman Minion","Snowflake Warrior",
    "Arctic Warrior","Mammoth","Yeti","Zombie","Vampire","Snow Lurker",
}

local function EsMob(name)
    for _, n in ipairs(MobNames) do if name:find(n) then return true end end
    return false
end

local function AgregarMob(o)
    if not o:IsA("Model") or not EsMob(o.Name) or ESPM[o] then return end
    local hum = o:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local d = {
        Nombre = NTexto(Color3.fromRGB(50,200,255), 12),
        HP     = NTexto(Color3.fromRGB(80,255,80),  10),
        Tracer = NLinea(Color3.fromRGB(50,200,255)),
    }
    ESPM[o] = d
    local con
    con = RunService.RenderStepped:Connect(function()
        local function hide() d.Nombre.Visible=false; d.HP.Visible=false; d.Tracer.Visible=false end
        if not Config.ESP_Mobs then hide(); return end
        if not o or not o.Parent then
            hide(); pcall(function() d.Nombre:Remove(); d.HP:Remove(); d.Tracer:Remove() end)
            ESPM[o]=nil; con:Disconnect(); return
        end
        if hum.Health <= 0 then hide(); return end
        local root = o:FindFirstChild("HumanoidRootPart")
        if not root then hide(); return end
        local dist = DistLocal(root.Position)
        if dist > Config.ESP_MaxDist then hide(); return end
        local sp, on = W2S(root.Position + Vector3.new(0,2,0))
        if on then
            local hpPct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
            d.Nombre.Visible  = Config.ESP_MobNombre
            d.Nombre.Text     = o.Name
            d.Nombre.Position = sp - Vector2.new(0,14)
            d.HP.Visible      = Config.ESP_MobHP
            d.HP.Color        = Color3.fromRGB(math.floor(255-hpPct*255), math.floor(hpPct*255), 0)
            d.HP.Text         = math.floor(hpPct*100) .. "%"
            d.HP.Position     = sp + Vector2.new(0,4)
            d.Tracer.Visible  = Config.ESP_MobTracer
            if d.Tracer.Visible then
                local vp = Camera.ViewportSize
                d.Tracer.From = Vector2.new(vp.X/2, vp.Y); d.Tracer.To = sp
            end
        else hide() end
    end)
end

for _, o in ipairs(Workspace:GetDescendants()) do task.spawn(AgregarMob, o) end
Workspace.DescendantAdded:Connect(function(o) task.wait(0.1); AgregarMob(o) end)

-- ============================================
-- AUTO FARM
-- ============================================
local function MobCercano()
    local best, bd = nil, 9999
    for o in pairs(ESPM) do
        if o and o.Parent then
            local h = o:FindFirstChildOfClass("Humanoid")
            local r = o:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r then
                local d = DistLocal(r.Position)
                if d < bd then bd=d; best=o end
            end
        end
    end
    return best
end

RunService.Heartbeat:Connect(function()
    if not Config.Farm_Auto then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if Config.Farm_AutoCollect then
        for o in pairs(ESPF) do
            if o and o.Parent then
                local p = o:FindFirstChild("Handle") or o.PrimaryPart or o:FindFirstChildOfClass("BasePart")
                if p and DistLocal(p.Position) < 8 then
                    root.CFrame = CFrame.new(p.Position)
                end
            end
        end
    end

    if Config.Farm_AutoAttack then
        local mob = MobCercano()
        if mob then
            local mr = mob:FindFirstChild("HumanoidRootPart")
            if mr then
                if Config.Farm_TpMob then
                    root.CFrame = CFrame.new(mr.Position - (mr.Position - root.Position).Unit * 5)
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local re = tool:FindFirstChild("RemoteEvent")
                    if re then pcall(function() re:FireServer() end) end
                end
            end
        end
    end
end)

-- ============================================
-- MISC — NoClip
-- ============================================
RunService.Stepped:Connect(function()
    if not Config.Misc_NoClip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ============================================
-- MISC — Infinite Jump
-- ============================================
UserInputService.JumpRequest:Connect(function()
    if not Config.Misc_InfJump then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ============================================
-- MISC — Velocidad
-- ============================================
RunService.Heartbeat:Connect(function()
    if not Config.Misc_Speed then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.Misc_SpeedVal end
end)

-- ============================================
-- MISC — Auto Stats
-- ============================================
RunService.Heartbeat:Connect(function()
    if not Config.Misc_AutoStats then return end
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remote = rs:FindFirstChild("AddStat", true)
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(Config.Misc_StatFocus)
        end
    end)
end)

-- ============================================
-- GUI — NYCLUU SCRIPT
-- ============================================
local SG = Instance.new("ScreenGui")
SG.Name           = "NycluuScript"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = LocalPlayer.PlayerGui

-- Ventana
local Win = Instance.new("Frame", SG)
Win.Size             = UDim2.new(0, 224, 0, 38)
Win.Position         = UDim2.new(0, 14, 0.24, 0)
Win.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Win.BorderSizePixel  = 0
Win.Active           = true
Win.Draggable        = true
Win.ClipsDescendants = true
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 5)
local WS = Instance.new("UIStroke", Win)
WS.Color = Color3.fromRGB(255,255,255); WS.Thickness = 0.7; WS.Transparency = 0.82

-- Header blanco
local Hdr = Instance.new("Frame", Win)
Hdr.Size             = UDim2.new(1,0,0,38)
Hdr.BackgroundColor3 = Color3.fromRGB(255,255,255)
Hdr.BorderSizePixel  = 0
Instance.new("UICorner", Hdr).CornerRadius = UDim.new(0,5)
local HFix = Instance.new("Frame", Hdr)
HFix.Size=UDim2.new(1,0,0,8); HFix.Position=UDim2.new(0,0,1,-8)
HFix.BackgroundColor3=Color3.fromRGB(255,255,255); HFix.BorderSizePixel=0

local HTitle = Instance.new("TextLabel", Hdr)
HTitle.Size=UDim2.new(1,-42,0,18); HTitle.Position=UDim2.new(0,12,0,5)
HTitle.BackgroundTransparency=1; HTitle.Text="NYCLUU SCRIPT"
HTitle.TextColor3=Color3.fromRGB(8,8,8); HTitle.Font=Enum.Font.GothamBold
HTitle.TextSize=13; HTitle.TextXAlignment=Enum.TextXAlignment.Left

local HSub = Instance.new("TextLabel", Hdr)
HSub.Size=UDim2.new(1,-12,0,10); HSub.Position=UDim2.new(0,12,0,22)
HSub.BackgroundTransparency=1; HSub.Text="DELTA  ·  2° MAR"
HSub.TextColor3=Color3.fromRGB(110,110,110); HSub.Font=Enum.Font.Gotham
HSub.TextSize=9; HSub.TextXAlignment=Enum.TextXAlignment.Left

local BMin = Instance.new("TextButton", Hdr)
BMin.Size=UDim2.new(0,24,0,24); BMin.Position=UDim2.new(1,-30,0,7)
BMin.BackgroundColor3=Color3.fromRGB(20,20,20); BMin.Text="—"
BMin.TextColor3=Color3.fromRGB(180,180,180); BMin.Font=Enum.Font.GothamBold
BMin.TextSize=11; BMin.BorderSizePixel=0
Instance.new("UICorner", BMin).CornerRadius=UDim.new(0,3)

-- Barra de tabs
local TBar = Instance.new("Frame", Win)
TBar.Size=UDim2.new(1,0,0,26); TBar.Position=UDim2.new(0,0,0,38)
TBar.BackgroundColor3=Color3.fromRGB(13,13,13); TBar.BorderSizePixel=0
local TBL = Instance.new("UIListLayout", TBar)
TBL.FillDirection=Enum.FillDirection.Horizontal
TBL.HorizontalAlignment=Enum.HorizontalAlignment.Center
TBL.Padding=UDim.new(0,3)
local TBP = Instance.new("UIPadding", TBar)
TBP.PaddingLeft=UDim.new(0,4); TBP.PaddingRight=UDim.new(0,4); TBP.PaddingTop=UDim.new(0,4)

-- Separador
local TSep = Instance.new("Frame", Win)
TSep.Size=UDim2.new(1,0,0,1); TSep.Position=UDim2.new(0,0,0,64)
TSep.BackgroundColor3=Color3.fromRGB(255,255,255); TSep.BackgroundTransparency=0.88; TSep.BorderSizePixel=0

-- ScrollFrame cuerpo
local Body = Instance.new("ScrollingFrame", Win)
Body.Size=UDim2.new(1,0,1,-66); Body.Position=UDim2.new(0,0,0,66)
Body.BackgroundTransparency=1; Body.BorderSizePixel=0
Body.ScrollBarThickness=3
Body.ScrollBarImageColor3=Color3.fromRGB(255,255,255)
Body.ScrollBarImageTransparency=0.75
Body.CanvasSize=UDim2.new(0,0,0,0)
local BL = Instance.new("UIListLayout", Body)
BL.Padding=UDim.new(0,5); BL.HorizontalAlignment=Enum.HorizontalAlignment.Center
local BP = Instance.new("UIPadding", Body)
BP.PaddingLeft=UDim.new(0,10); BP.PaddingRight=UDim.new(0,10)
BP.PaddingTop=UDim.new(0,7); BP.PaddingBottom=UDim.new(0,10)

-- ============================================
-- HELPERS GUI
-- ============================================
BL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Body.CanvasSize = UDim2.new(0,0,0, BL.AbsoluteContentSize.Y + 20)
end)

local function MkSeccion(txt)
    local f = Instance.new("Frame", Body)
    f.Size=UDim2.new(1,0,0,20); f.BackgroundTransparency=1
    local l = Instance.new("TextLabel", f)
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="— " .. txt .. " —"; l.TextColor3=Color3.fromRGB(120,120,120)
    l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left
    return f
end

local TInfo = TweenInfo.new(0.17, Enum.EasingStyle.Quad)

local function MkToggle(txt, init, cb)
    local Row = Instance.new("Frame", Body)
    Row.Size=UDim2.new(1,0,0,34); Row.BackgroundColor3=Color3.fromRGB(14,14,14); Row.BorderSizePixel=0
    Instance.new("UICorner", Row).CornerRadius=UDim.new(0,4)
    local RS=Instance.new("UIStroke",Row); RS.Color=Color3.fromRGB(255,255,255); RS.Thickness=0.5; RS.Transparency=0.88

    local Dot=Instance.new("Frame",Row)
    Dot.Size=UDim2.new(0,4,0,4); Dot.Position=UDim2.new(0,10,0.5,-2)
    Dot.BackgroundColor3=init and Color3.fromRGB(255,255,255) or Color3.fromRGB(50,50,50); Dot.BorderSizePixel=0
    Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)

    local Lbl=Instance.new("TextLabel",Row)
    Lbl.Size=UDim2.new(1,-54,1,0); Lbl.Position=UDim2.new(0,20,0,0)
    Lbl.BackgroundTransparency=1; Lbl.Text=txt
    Lbl.TextColor3=Color3.fromRGB(210,210,210); Lbl.Font=Enum.Font.Gotham
    Lbl.TextSize=11; Lbl.TextXAlignment=Enum.TextXAlignment.Left

    local Pill=Instance.new("Frame",Row)
    Pill.Size=UDim2.new(0,34,0,17); Pill.Position=UDim2.new(1,-44,0.5,-8)
    Pill.BackgroundColor3=init and Color3.fromRGB(255,255,255) or Color3.fromRGB(36,36,36); Pill.BorderSizePixel=0
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(1,0)
    local PS=Instance.new("UIStroke",Pill); PS.Color=Color3.fromRGB(255,255,255); PS.Thickness=0.7; PS.Transparency=init and 1 or 0.6

    local Knob=Instance.new("Frame",Pill)
    Knob.Size=UDim2.new(0,11,0,11)
    Knob.Position=init and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)
    Knob.BackgroundColor3=init and Color3.fromRGB(8,8,8) or Color3.fromRGB(155,155,155); Knob.BorderSizePixel=0
    Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0)

    local state = init
    Row.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        state = not state
        TweenService:Create(Pill,  TInfo, {BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(36,36,36)}):Play()
        TweenService:Create(Knob,  TInfo, {Position = state and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5), BackgroundColor3 = state and Color3.fromRGB(8,8,8) or Color3.fromRGB(155,155,155)}):Play()
        TweenService:Create(Dot,   TInfo, {BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(50,50,50)}):Play()
        PS.Transparency = state and 1 or 0.6
        cb(state)
    end)
    return Row
end

-- ============================================
-- SISTEMA DE TABS
-- ============================================
local TabBtns    = {}
local TabItems   = {}   -- [tabName] = { elem, elem, ... }
local TabActivo  = nil
local TABS       = {"ESP","FARM","MISC","FPS"}

for _, n in ipairs(TABS) do
    TabItems[n] = {}
    local btn = Instance.new("TextButton", TBar)
    btn.Size=UDim2.new(0,44,0,18); btn.BackgroundColor3=Color3.fromRGB(20,20,20)
    btn.Text=n; btn.TextColor3=Color3.fromRGB(120,120,120)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,3)
    TabBtns[n] = btn
end

local function AbrirTab(nombre)
    for _, n in ipairs(TABS) do
        local activo = (n == nombre)
        TabBtns[n].BackgroundColor3 = activo and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,20,20)
        TabBtns[n].TextColor3       = activo and Color3.fromRGB(8,8,8)       or Color3.fromRGB(120,120,120)
        for _, elem in ipairs(TabItems[n]) do
            elem.Visible = activo
        end
    end
    TabActivo = nombre
end

local function Reg(tab, elem)
    table.insert(TabItems[tab], elem)
    elem.Visible = false
end

for _, n in ipairs(TABS) do
    TabBtns[n].MouseButton1Click:Connect(function() AbrirTab(n) end)
end

-- ============================================
-- POBLAR TAB: ESP
-- ============================================
Reg("ESP", MkSeccion("JUGADORES"))
Reg("ESP", MkToggle("ESP Jugadores",     Config.ESP_Jugadores,    function(v) Config.ESP_Jugadores    = v end))
Reg("ESP", MkToggle("Cajas",             Config.ESP_Cajas,        function(v) Config.ESP_Cajas        = v end))
Reg("ESP", MkToggle("Nombres",           Config.ESP_Nombres,      function(v) Config.ESP_Nombres      = v end))
Reg("ESP", MkToggle("HP",                Config.ESP_HP,           function(v) Config.ESP_HP           = v end))
Reg("ESP", MkToggle("Distancia",         Config.ESP_Distancia,    function(v) Config.ESP_Distancia    = v end))
Reg("ESP", MkToggle("Nivel",             Config.ESP_Nivel,        function(v) Config.ESP_Nivel        = v end))
Reg("ESP", MkToggle("Tracers jugadores", Config.ESP_Tracers,      function(v) Config.ESP_Tracers      = v end))
Reg("ESP", MkSeccion("FRUTAS"))
Reg("ESP", MkToggle("ESP Frutas",        Config.ESP_Frutas,       function(v) Config.ESP_Frutas       = v end))
Reg("ESP", MkToggle("Tracers frutas",    Config.ESP_FrutasTracer, function(v) Config.ESP_FrutasTracer = v end))
Reg("ESP", MkSeccion("MOBS / NPCs"))
Reg("ESP", MkToggle("ESP Mobs",          Config.ESP_Mobs,         function(v) Config.ESP_Mobs         = v end))
Reg("ESP", MkToggle("Nombre mob",        Config.ESP_MobNombre,    function(v) Config.ESP_MobNombre    = v end))
Reg("ESP", MkToggle("HP mob",            Config.ESP_MobHP,        function(v) Config.ESP_MobHP        = v end))
Reg("ESP", MkToggle("Tracers mobs",      Config.ESP_MobTracer,    function(v) Config.ESP_MobTracer    = v end))

-- ============================================
-- POBLAR TAB: FARM
-- ============================================
Reg("FARM", MkSeccion("AUTO FARM"))
Reg("FARM", MkToggle("Auto Farm",        Config.Farm_Auto,        function(v) Config.Farm_Auto        = v end))
Reg("FARM", MkToggle("TP a mobs",        Config.Farm_TpMob,       function(v) Config.Farm_TpMob       = v end))
Reg("FARM", MkToggle("Auto Attack",      Config.Farm_AutoAttack,  function(v) Config.Farm_AutoAttack  = v end))
Reg("FARM", MkSeccion("FRUTAS"))
Reg("FARM", MkToggle("Auto Collect",     Config.Farm_AutoCollect, function(v) Config.Farm_AutoCollect = v end))

-- ============================================
-- POBLAR TAB: MISC
-- ============================================
Reg("MISC", MkSeccion("MOVIMIENTO"))
Reg("MISC", MkToggle("NoClip",           Config.Misc_NoClip,      function(v) Config.Misc_NoClip      = v end))
Reg("MISC", MkToggle("Infinite Jump",    Config.Misc_InfJump,     function(v) Config.Misc_InfJump     = v end))
Reg("MISC", MkToggle("Alta Velocidad",   Config.Misc_Speed,       function(v) Config.Misc_Speed       = v end))
Reg("MISC", MkSeccion("STATS"))
Reg("MISC", MkToggle("Auto Stats",       Config.Misc_AutoStats,   function(v) Config.Misc_AutoStats   = v end))

-- ============================================
-- POBLAR TAB: FPS
-- ============================================
Reg("FPS", MkSeccion("RENDIMIENTO"))
Reg("FPS", MkToggle("FPS Boost (todo)",  Config.FPS_Boost,       function(v)
    Config.FPS_Boost = v
    if v then AplicarFPS() else
        Lighting.GlobalShadows = true
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end))
Reg("FPS", MkToggle("Sin sombras",       Config.FPS_Sombras,     function(v)
    Config.FPS_Sombras = v; Lighting.GlobalShadows = not v
end))
Reg("FPS", MkToggle("Sin partículas",    Config.FPS_Particulas,  function(v) Config.FPS_Particulas = v end))
Reg("FPS", MkToggle("Sin niebla",        Config.FPS_Niebla,      function(v)
    Config.FPS_Niebla = v
    if v then Lighting.FogEnd=100000; Lighting.FogStart=99999
    else Lighting.FogEnd=1000; Lighting.FogStart=0 end
end))
Reg("FPS", MkToggle("Sin texturas",      Config.FPS_Texturas,    function(v)
    Config.FPS_Texturas = v
    settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
end))

-- Abrir ESP por defecto
AbrirTab("ESP")

-- ============================================
-- MINIMIZAR / EXPANDIR
-- ============================================
local expandido = true
local HEXP      = 390
local HMIN      = 38

local function RecalcAltura()
    if not expandido then return end
    local items = 0
    for _, elem in ipairs(TabItems[TabActivo] or {}) do
        if elem.Visible then items = items + 1 end
    end
    local h = BL.AbsoluteContentSize.Y + 66 + 20
    HEXP = math.clamp(h, 180, 500)
    Win.Size = UDim2.new(0, 224, 0, HEXP)
end

BL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RecalcAltura)

BMin.MouseButton1Click:Connect(function()
    expandido = not expandido
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    if expandido then
        TweenService:Create(Win, info, {Size=UDim2.new(0,224,0,HEXP)}):Play()
        task.delay(0.05, function()
            TBar.Visible=true; TSep.Visible=true; Body.Visible=true
        end)
        BMin.Text = "—"
    else
        TBar.Visible=false; TSep.Visible=false; Body.Visible=false
        TweenService:Create(Win, info, {Size=UDim2.new(0,224,0,HMIN)}):Play()
        BMin.Text = "+"
    end
end)

print("[Nycluu Script] ✓ Delta | Segundo Mar")
print("[Nycluu Script] Tabs: ESP · FARM · MISC · FPS")
