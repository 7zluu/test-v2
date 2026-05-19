-- ============================================
--   Blox Fruits Script | Delta Executor
--   Funciones: ESP + Auto Farm + FPS Boost
--   Mar: Segundo Mar
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- CONFIGURACIÓN GENERAL
-- ============================================
local Config = {
    ESP = {
        Enabled = true,
        Jugadores = true,
        Frutas = true,
        Mobs = true,
        ColorJugador = Color3.fromRGB(255, 50, 50),
        ColorFruta = Color3.fromRGB(255, 215, 0),
        ColorMob = Color3.fromRGB(50, 200, 255),
        MaxDistancia = 1500,
    },
    AutoFarm = {
        Enabled = false,
        AutoAttack = true,
        AutoCollect = true,
        RangoAtaque = 15,
        DelayAtaque = 0.3,
    },
    FPS = {
        Enabled = true,
        ReducirSombras = true,
        ReducirParticulas = true,
        ReducirTexturas = true,
        ReducirDistancia = true,
        DesactivarNiebla = true,
        FPSLimit = 60,
    }
}

-- ============================================
-- MÓDULO FPS BOOST
-- ============================================
local function AplicarFPSBoost()
    if not Config.FPS.Enabled then return end

    -- Reducir calidad de texturas
    if Config.FPS.ReducirTexturas then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end

    -- Desactivar/reducir sombras
    if Config.FPS.ReducirSombras then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end

    -- Desactivar niebla
    if Config.FPS.DesactivarNiebla then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    end

    -- Reducir partículas y efectos visuales
    if Config.FPS.ReducirParticulas then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
    end

    -- Reducir distancia de renderizado
    if Config.FPS.ReducirDistancia then
        Workspace.StreamingEnabled = true
        Camera.FieldOfView = 70
    end

    -- FPS cap con Delta Executor
    if syn and syn.set_fps_cap then
        syn.set_fps_cap(Config.FPS.FPSLimit)
    end

    print("[FPS Boost] Aplicado correctamente ✓")
end

-- Aplicar FPS Boost al iniciar
AplicarFPSBoost()

-- Detectar nuevas partículas y desactivarlas
if Config.FPS.ReducirParticulas then
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

-- ============================================
-- MÓDULO ESP
-- ============================================
local ESPObjetos = {}

local function CrearLabel(parent, texto, color)
    local label = Drawing.new("Text")
    label.Text = texto
    label.Color = color
    label.Size = 13
    label.Center = true
    label.Outline = true
    label.OutlineColor = Color3.fromRGB(0, 0, 0)
    label.Visible = false
    label.Font = Drawing.Fonts.UI
    return label
end

local function CrearCaja(color)
    local caja = Drawing.new("Square")
    caja.Color = color
    caja.Thickness = 1.5
    caja.Filled = false
    caja.Visible = false
    return caja
end

local function MundoApantalla(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- ESP Jugadores
local function ConfigurarESPJugador(player)
    if player == LocalPlayer then return end

    local espData = {
        NombreLabel = CrearLabel(nil, player.Name, Config.ESP.ColorJugador),
        VidaLabel = CrearLabel(nil, "HP", Color3.fromRGB(50, 255, 50)),
        Caja = CrearCaja(Config.ESP.ColorJugador),
    }

    ESPObjetos[player] = espData

    local conexion
    conexion = RunService.RenderStepped:Connect(function()
        if not Config.ESP.Enabled or not Config.ESP.Jugadores then
            espData.NombreLabel.Visible = false
            espData.VidaLabel.Visible = false
            espData.Caja.Visible = false
            return
        end

        if not player or not player.Parent then
            espData.NombreLabel:Remove()
            espData.VidaLabel:Remove()
            espData.Caja:Remove()
            ESPObjetos[player] = nil
            conexion:Disconnect()
            return
        end

        local char = player.Character
        if not char then
            espData.NombreLabel.Visible = false
            espData.VidaLabel.Visible = false
            espData.Caja.Visible = false
            return
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then
            espData.NombreLabel.Visible = false
            espData.VidaLabel.Visible = false
            espData.Caja.Visible = false
            return
        end

        local distancia = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if distancia > Config.ESP.MaxDistancia then
            espData.NombreLabel.Visible = false
            espData.VidaLabel.Visible = false
            espData.Caja.Visible = false
            return
        end

        local screenPos, onScreen = MundoArantalla(rootPart.Position)

        if onScreen then
            -- Nombre + distancia
            espData.NombreLabel.Position = screenPos - Vector2.new(0, 40)
            espData.NombreLabel.Text = player.Name .. " [" .. math.floor(distancia) .. "m]"
            espData.NombreLabel.Visible = true

            -- HP
            local hpPct = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            espData.VidaLabel.Position = screenPos - Vector2.new(0, 25)
            espData.VidaLabel.Text = "HP: " .. hpPct .. "%"
            espData.VidaLabel.Color = Color3.fromRGB(255 - hpPct * 2.55, hpPct * 2.55, 0)
            espData.VidaLabel.Visible = true

            -- Caja
            local topPos = MundoArantalla(rootPart.Position + Vector3.new(0, 3, 0))
            local botPos = MundoArantalla(rootPart.Position - Vector3.new(0, 3, 0))
            local altPx = math.abs(topPos.Y - botPos.Y)
            local anchoPx = altPx * 0.5
            espData.Caja.Size = Vector2.new(anchoPx, altPx)
            espData.Caja.Position = screenPos - Vector2.new(anchoPx / 2, altPx / 2)
            espData.Caja.Visible = true
        else
            espData.NombreLabel.Visible = false
            espData.VidaLabel.Visible = false
            espData.Caja.Visible = false
        end
    end)
end

-- Workaround para nombre de función (typo intencional corregido aquí)
MundoArantalla = MundoArantalla or MundoArantalla
-- (usa la misma función, alias)
MundoArantalla = function(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Conectar jugadores existentes y nuevos
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(ConfigurarESPJugador, player)
end

Players.PlayerAdded:Connect(ConfigurarESPJugador)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjetos[player] then
        for _, obj in pairs(ESPObjetos[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjetos[player] = nil
    end
end)

-- ============================================
-- ESP FRUTAS (spawneadas en el mapa)
-- ============================================
local FrutasESP = {}

local function EsUnaFruta(obj)
    -- Las frutas en Blox Fruits suelen estar en una carpeta llamada "Fruits" o tienen "Fruit" en el nombre
    return obj:IsA("Model") and (
        obj.Name:find("Fruit") or
        obj.Name:find("fruit") or
        obj.Name:find("Logia") or
        obj.Name:find("Zoan") or
        obj.Name:find("Paramecia")
    )
end

local function AgregarESPFruta(obj)
    if not EsUnaFruta(obj) then return end
    if FrutasESP[obj] then return end

    local label = CrearLabel(nil, "🍎 " .. obj.Name, Config.ESP.ColorFruta)
    FrutasESP[obj] = label

    local conexion
    conexion = RunService.RenderStepped:Connect(function()
        if not Config.ESP.Enabled or not Config.ESP.Frutas then
            label.Visible = false
            return
        end

        if not obj or not obj.Parent then
            label:Remove()
            FrutasESP[obj] = nil
            conexion:Disconnect()
            return
        end

        local rootPart = obj:FindFirstChild("Handle") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
        if not rootPart then
            label.Visible = false
            return
        end

        local distancia = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if distancia > Config.ESP.MaxDistancia then
            label.Visible = false
            return
        end

        local screenPos, onScreen = MundoArantalla(rootPart.Position + Vector3.new(0, 2, 0))
        if onScreen then
            label.Position = screenPos
            label.Text = "🍎 " .. obj.Name .. " [" .. math.floor(distancia) .. "m]"
            label.Visible = true
        else
            label.Visible = false
        end
    end)
end

-- Escanear frutas existentes y nuevas
for _, obj in ipairs(Workspace:GetDescendants()) do
    task.spawn(AgregarESPFruta, obj)
end

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    AgregarESPFruta(obj)
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if FrutasESP[obj] then
        pcall(function() FrutasESP[obj]:Remove() end)
        FrutasESP[obj] = nil
    end
end)

-- ============================================
-- AUTO FARM (Segundo Mar)
-- Mobs comunes: Swan Pirates, Fishman, etc.
-- ============================================
local AutoFarmConexion = nil

local MobsSegundoMar = {
    "Swan Pirate", "Fishman Warrior", "Fishman Lord",
    "Fishman Raider", "Fishman Captain", "Tide Keeper",
    "Ship Deckhand", "Ship Engineer", "Ship Steward",
    "Ship Officer", "Snowman Minion", "Snowflake Warrior",
    "Arctic Warrior", "Mammoth", "Yeti",
}

local function EsUnMob(name)
    for _, mobName in ipairs(MobsSegundoMar) do
        if name:find(mobName) then return true end
    end
    return false
end

local function ObtenerMobMasCercano()
    local mejorMob = nil
    local menorDist = Config.AutoFarm.RangoAtaque

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and EsUnMob(obj.Name) then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                local dist = (rootPart.Position - (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero)).Magnitude
                if dist < menorDist then
                    menorDist = dist
                    mejorMob = obj
                end
            end
        end
    end

    return mejorMob
end

local function IniciarAutoFarm()
    if AutoFarmConexion then
        AutoFarmConexion:Disconnect()
        AutoFarmConexion = nil
    end

    AutoFarmConexion = RunService.Heartbeat:Connect(function()
        if not Config.AutoFarm.Enabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        -- Recolectar frutas cercanas
        if Config.AutoFarm.AutoCollect then
            for obj, _ in pairs(FrutasESP) do
                if obj and obj.Parent then
                    local fruitPart = obj:FindFirstChild("Handle") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                    if fruitPart then
                        local dist = (fruitPart.Position - rootPart.Position).Magnitude
                        if dist < 10 then
                            rootPart.CFrame = CFrame.new(fruitPart.Position)
                        end
                    end
                end
            end
        end

        -- Atacar mobs
        if Config.AutoFarm.AutoAttack then
            local mob = ObtenerMobMasCercano()
            if mob then
                local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                if mobRoot then
                    rootPart.CFrame = CFrame.new(mobRoot.Position - (mobRoot.Position - rootPart.Position).Unit * 5)
                    -- Simular click / ataque
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("RemoteEvent") then
                        tool.RemoteEvent:FireServer()
                    end
                end
            end
        end
    end)
end

IniciarAutoFarm()

-- ============================================
-- GUI MINIMALISTA — NEGRO Y BLANCO
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitsScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Contenedor principal
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 290)
Frame.Position = UDim2.new(0, 14, 0.28, 0)
Frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)

-- Borde sutil blanco
local Borde = Instance.new("UIStroke")
Borde.Color = Color3.fromRGB(255, 255, 255)
Borde.Thickness = 0.8
Borde.Transparency = 0.82
Borde.Parent = Frame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BorderSizePixel = 0
Header.Parent = Frame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 4)

-- Fix esquinas inferiores del header
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 8)
HeaderFix.Position = UDim2.new(0, 0, 1, -8)
HeaderFix.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local TituloLabel = Instance.new("TextLabel")
TituloLabel.Size = UDim2.new(1, -40, 1, 0)
TituloLabel.Position = UDim2.new(0, 12, 0, 0)
TituloLabel.BackgroundTransparency = 1
TituloLabel.Text = "BF SCRIPT"
TituloLabel.TextColor3 = Color3.fromRGB(8, 8, 8)
TituloLabel.Font = Enum.Font.GothamBold
TituloLabel.TextSize = 13
TituloLabel.TextXAlignment = Enum.TextXAlignment.Left
TituloLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -12, 1, 0)
SubLabel.Position = UDim2.new(0, 12, 0, 14)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "DELTA  ·  2° MAR"
SubLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 9
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Header

-- Botón minimizar [ — ]
local BtnMin = Instance.new("TextButton")
BtnMin.Size = UDim2.new(0, 26, 0, 26)
BtnMin.Position = UDim2.new(1, -32, 0, 6)
BtnMin.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BtnMin.Text = "—"
BtnMin.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnMin.Font = Enum.Font.GothamBold
BtnMin.TextSize = 11
BtnMin.BorderSizePixel = 0
BtnMin.Parent = Header
Instance.new("UICorner", BtnMin).CornerRadius = UDim.new(0, 3)

-- Separador decorativo
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0.88, 0, 0, 1)
Sep.Position = UDim2.new(0.06, 0, 0, 46)
Sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Sep.BackgroundTransparency = 0.88
Sep.BorderSizePixel = 0
Sep.Parent = Frame

-- Cuerpo con padding
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, 0, 1, -50)
Body.Position = UDim2.new(0, 0, 0, 50)
Body.BackgroundTransparency = 1
Body.Parent = Frame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Parent = Body

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 10)
Padding.PaddingRight = UDim.new(0, 10)
Padding.PaddingTop = UDim.new(0, 6)
Padding.Parent = Body

-- Función para crear toggle minimalista
local function CrearToggle(parent, label, estadoInicial, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    Row.BorderSizePixel = 0
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Color = Color3.fromRGB(255, 255, 255)
    RowStroke.Thickness = 0.6
    RowStroke.Transparency = 0.88
    RowStroke.Parent = Row

    -- Nombre de la función
    local Nombre = Instance.new("TextLabel")
    Nombre.Size = UDim2.new(1, -52, 1, 0)
    Nombre.Position = UDim2.new(0, 12, 0, 0)
    Nombre.BackgroundTransparency = 1
    Nombre.Text = label
    Nombre.TextColor3 = Color3.fromRGB(220, 220, 220)
    Nombre.Font = Enum.Font.Gotham
    Nombre.TextSize = 11
    Nombre.TextXAlignment = Enum.TextXAlignment.Left
    Nombre.Parent = Row

    -- Toggle pill
    local PillBg = Instance.new("Frame")
    PillBg.Size = UDim2.new(0, 36, 0, 18)
    PillBg.Position = UDim2.new(1, -46, 0.5, -9)
    PillBg.BackgroundColor3 = estadoInicial and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
    PillBg.BorderSizePixel = 0
    PillBg.Parent = Row
    Instance.new("UICorner", PillBg).CornerRadius = UDim.new(1, 0)

    local PillStroke = Instance.new("UIStroke")
    PillStroke.Color = Color3.fromRGB(255, 255, 255)
    PillStroke.Thickness = 0.8
    PillStroke.Transparency = estadoInicial and 1 or 0.6
    PillStroke.Parent = PillBg

    local Circulo = Instance.new("Frame")
    Circulo.Size = UDim2.new(0, 12, 0, 12)
    Circulo.Position = estadoInicial and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    Circulo.BackgroundColor3 = estadoInicial and Color3.fromRGB(8, 8, 8) or Color3.fromRGB(180, 180, 180)
    Circulo.BorderSizePixel = 0
    Circulo.Parent = PillBg
    Instance.new("UICorner", Circulo).CornerRadius = UDim.new(1, 0)

    -- Dot indicador de estado
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 5, 0, 5)
    Dot.Position = UDim2.new(0, 12, 0.5, -2)
    Dot.BackgroundColor3 = estadoInicial and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
    Dot.BorderSizePixel = 0
    Dot.Parent = Row
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local estado = estadoInicial

    local function Animar()
        local TW = TweenService:Create
        local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if estado then
            TW(PillBg, info, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            TW(Circulo, info, { Position = UDim2.new(1, -15, 0.5, -6), BackgroundColor3 = Color3.fromRGB(8, 8, 8) }):Play()
            TW(Dot, info, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            PillStroke.Transparency = 1
        else
            TW(PillBg, info, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }):Play()
            TW(Circulo, info, { Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Color3.fromRGB(180, 180, 180) }):Play()
            TW(Dot, info, { BackgroundColor3 = Color3.fromRGB(60, 60, 60) }):Play()
            PillStroke.Transparency = 0.6
        end
    end

    Row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            estado = not estado
            Animar()
            callback(estado)
        end
    end)

    return Row
end

-- Crear los 4 toggles
CrearToggle(Body, "ESP  JUGADORES", Config.ESP.Jugadores, function(v)
    Config.ESP.Jugadores = v
end)

CrearToggle(Body, "ESP  FRUTAS", Config.ESP.Frutas, function(v)
    Config.ESP.Frutas = v
end)

CrearToggle(Body, "AUTO FARM", Config.AutoFarm.Enabled, function(v)
    Config.AutoFarm.Enabled = v
end)

CrearToggle(Body, "FPS  BOOST", Config.FPS.Enabled, function(v)
    Config.FPS.Enabled = v
    if v then
        AplicarFPSBoost()
    else
        Lighting.GlobalShadows = true
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end)

-- Lógica minimizar / expandir
local expandido = true
BtnMin.MouseButton1Click:Connect(function()
    expandido = not expandido
    local TW = TweenService:Create
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if expandido then
        Body.Visible = true
        Sep.Visible = true
        TW(Frame, info, { Size = UDim2.new(0, 200, 0, 290) }):Play()
        BtnMin.Text = "—"
    else
        TW(Frame, info, { Size = UDim2.new(0, 200, 0, 38) }):Play()
        task.delay(0.2, function()
            Body.Visible = false
            Sep.Visible = false
        end)
        BtnMin.Text = "+"
    end
end)

print("[BF Script] Cargado correctamente para Delta ✓")
print("[BF Script] Segundo Mar | ESP + Auto Farm + FPS Boost")
