--// aimb0t hub by henrique
--// Somente para testes em servidores privados
--// Sistema de Otimização Visual Adaptativo v2.0 integrado

-- ╔══════════════════════════════════════════════════════╗
-- ║              SERVICES & CORE REFERENCES              ║
-- ╚══════════════════════════════════════════════════════╝
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ╔══════════════════════════════════════════════════════╗
-- ║           CONFIGURAÇÕES DO AIMBOT                    ║
-- ╚══════════════════════════════════════════════════════╝
local AimSettings = {
    Enabled    = false,
    TeamCheck  = true,
    AimPart    = "Head",
    FOV        = 120,
    ShowFOV    = true,
    Smoothness = 0.35,
    HoldMode   = true,
}

local isHolding    = false
local currentTarget = nil
local aimConnection = nil

-- ╔══════════════════════════════════════════════════════╗
-- ║        CONFIGURAÇÕES DO SISTEMA DE OTIMIZAÇÃO        ║
-- ╚══════════════════════════════════════════════════════╝

-- Thresholds configuráveis (podem ser ajustados pelo usuário)
local CONFIG = {
    FPS = {
        DROP_LEVEL_1     = 30,   -- FPS abaixo disto por 5s → reduz 1 nível
        DROP_LEVEL_2     = 20,   -- FPS abaixo disto por 3s → reduz 2 níveis
        INCREASE         = 55,   -- FPS acima disto por 10s → aumenta 1 nível
        RTX_FALLBACK     = 50,   -- FPS abaixo disto por 6s com RTX → desativa RTX
        RTX_REQUIRED     = 60,   -- FPS mínimo para habilitar RTX
        RTX_RECOMMENDED  = 70,   -- FPS para habilitar RTX automático
    },
    TIMERS = {
        DROP_LEVEL_1     = 5,    -- segundos para reduzir 1 nível
        DROP_LEVEL_2     = 3,    -- segundos para reduzir 2 níveis
        INCREASE         = 10,   -- segundos para aumentar 1 nível
        RTX_FALLBACK     = 6,    -- segundos para desativar RTX
        COOLDOWN         = 8,    -- cooldown entre trocas automáticas
        BENCHMARK        = 10,   -- duração do benchmark em segundos
    },
    RTX = {
        LITE_ONLY_FPS    = 55,   -- FPS mínimo para RTX Lite
        BLOOM_INTENSITY  = 2.5,
        BLOOM_SIZE       = 30,
        SUNRAYS_INTENSITY = 0.15,
        SHADOW_SOFTNESS  = 0.15,
        ENV_DIFFUSE      = 1.0,
        ENV_SPECULAR     = 1.0,
    }
}

-- Definição dos modos de qualidade
local QUALITY_MODES = {
    {
        name = "RAY TRACING",
        key  = "RTX",
        icon = "🔮",
        -- RTX é tratado separadamente como camada extra
    },
    {
        name = "Ultra",
        key  = "ULTRA",
        icon = "⚡",
        globalShadows     = true,
        brightness        = 2,
        envDiffuse        = 1.0,
        envSpecular       = 1.0,
        shadowSoftness    = 0.2,
        bloom             = {enabled=true, intensity=1.5, size=24, threshold=0.95},
        sunRays           = {enabled=true, intensity=0.1, spread=1.0},
        colorCorrection   = {enabled=true, brightness=0.02, contrast=0.1, saturation=0.1},
        blur              = {enabled=false, size=0},
        particles         = true,
        decals            = true,
        renderDistance    = 512,
        lodFactor         = 1.0,
    },
    {
        name = "Alto",
        key  = "HIGH",
        icon = "🔥",
        globalShadows     = true,
        brightness        = 2,
        envDiffuse        = 0.8,
        envSpecular       = 0.8,
        shadowSoftness    = 0.3,
        bloom             = {enabled=true, intensity=1.0, size=20, threshold=1.0},
        sunRays           = {enabled=true, intensity=0.07, spread=0.8},
        colorCorrection   = {enabled=true, brightness=0.01, contrast=0.05, saturation=0.05},
        blur              = {enabled=false, size=0},
        particles         = true,
        decals            = true,
        renderDistance    = 400,
        lodFactor         = 0.85,
    },
    {
        name = "Médio",
        key  = "MEDIUM",
        icon = "⚙️",
        globalShadows     = true,
        brightness        = 1.8,
        envDiffuse        = 0.6,
        envSpecular        = 0.5,
        shadowSoftness    = 0.5,
        bloom             = {enabled=true, intensity=0.7, size=16, threshold=1.05},
        sunRays           = {enabled=false, intensity=0, spread=0},
        colorCorrection   = {enabled=false, brightness=0, contrast=0, saturation=0},
        blur              = {enabled=false, size=0},
        particles         = true,
        decals            = true,
        renderDistance    = 256,
        lodFactor         = 0.7,
    },
    {
        name = "Baixo",
        key  = "LOW",
        icon = "📉",
        globalShadows     = false,
        brightness        = 1.5,
        envDiffuse        = 0.4,
        envSpecular        = 0.3,
        shadowSoftness    = 1.0,
        bloom             = {enabled=false, intensity=0, size=0, threshold=2},
        sunRays           = {enabled=false, intensity=0, spread=0},
        colorCorrection   = {enabled=false, brightness=0, contrast=0, saturation=0},
        blur              = {enabled=false, size=0},
        particles         = false,
        decals            = false,
        renderDistance    = 128,
        lodFactor         = 0.5,
    },
    {
        name = "Batata",
        key  = "POTATO",
        icon = "🥔",
        globalShadows     = false,
        brightness        = 1.3,
        envDiffuse        = 0.2,
        envSpecular        = 0.1,
        shadowSoftness    = 1.0,
        bloom             = {enabled=false, intensity=0, size=0, threshold=2},
        sunRays           = {enabled=false, intensity=0, spread=0},
        colorCorrection   = {enabled=false, brightness=0, contrast=0, saturation=0},
        blur              = {enabled=false, size=0},
        particles         = false,
        decals            = false,
        renderDistance    = 64,
        lodFactor         = 0.3,
    },
    {
        name = "EXTREMO",
        key  = "EXTREME",
        icon = "💀",
        globalShadows     = false,
        brightness        = 1.0,
        envDiffuse        = 0.0,
        envSpecular        = 0.0,
        shadowSoftness    = 1.0,
        bloom             = {enabled=false, intensity=0, size=0, threshold=2},
        sunRays           = {enabled=false, intensity=0, spread=0},
        colorCorrection   = {enabled=false, brightness=0, contrast=0, saturation=0},
        blur              = {enabled=false, size=0},
        particles         = false,
        decals            = false,
        renderDistance    = 32,
        lodFactor         = 0.1,
    },
}

-- Índices dos modos (sem RTX, que é camada extra)
local MODE_NAMES = {"ULTRA", "HIGH", "MEDIUM", "LOW", "POTATO", "EXTREME"}
local MODE_INDEX = {ULTRA=1, HIGH=2, MEDIUM=3, LOW=4, POTATO=5, EXTREME=6}

-- Estado do sistema de otimização
local OptState = {
    currentModeKey    = "HIGH",       -- modo atual
    currentModeIndex  = 2,            -- índice no MODE_NAMES
    autoMode          = true,         -- ajuste automático
    rtxEnabled        = false,        -- RTX ativo
    rtxLiteMode       = false,        -- RTX Lite (parcial)
    benchmarkDone     = false,        -- benchmark já foi feito
    benchmarkCategory = "Mid",        -- Low/Mid/High/Ultra
    benchmarkAvgFPS   = 60,
    rtxCapable        = false,        -- dispositivo suporta RTX
    rtxLiteCapable    = false,
    isAdjusting       = false,        -- trocando modo agora
    lastModeChange    = 0,
    prevModeKey       = "HIGH",       -- modo antes do RTX
    status            = "Estável",    -- Estável / Instável / Ajustando
}

-- ╔══════════════════════════════════════════════════════╗
-- ║                   FOV CIRCLE                         ║
-- ╚══════════════════════════════════════════════════════╝
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position     = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius       = AimSettings.FOV
FOVCircle.Color        = Color3.fromRGB(138, 43, 226)
FOVCircle.Thickness    = 1.5
FOVCircle.NumSides     = 64
FOVCircle.Filled       = false
FOVCircle.Visible      = false
FOVCircle.Transparency = 0.8

-- ╔══════════════════════════════════════════════════════╗
-- ║             MÓDULO: FPS MONITOR                      ║
-- ╚══════════════════════════════════════════════════════╝
local FPSMonitor = {}
do
    local samples    = {}
    local maxSamples = 60
    local lastTime   = tick()

    -- Adiciona sample de FPS
    function FPSMonitor.sample()
        local now = tick()
        local dt  = now - lastTime
        lastTime  = now
        if dt <= 0 then return end
        local fps = math.floor(1 / dt)
        table.insert(samples, fps)
        if #samples > maxSamples then table.remove(samples, 1) end
    end

    -- Retorna média dos últimos N samples
    function FPSMonitor.getAverage(count)
        count = count or #samples
        if #samples == 0 then return 60 end
        local sum = 0
        local from = math.max(1, #samples - count + 1)
        for i = from, #samples do sum = sum + samples[i] end
        return math.floor(sum / (#samples - from + 1))
    end

    -- Retorna FPS atual (último sample)
    function FPSMonitor.getCurrent()
        if #samples == 0 then return 60 end
        return samples[#samples]
    end

    -- Retorna jitter (variação entre samples)
    function FPSMonitor.getJitter()
        if #samples < 2 then return 0 end
        local min, max = math.huge, 0
        for _, v in ipairs(samples) do
            if v < min then min = v end
            if v > max then max = v end
        end
        return max - min
    end

    -- Retorna todos os samples para benchmark
    function FPSMonitor.getSamples()
        return samples
    end

    function FPSMonitor.clear()
        samples = {}
    end
end

-- ╔══════════════════════════════════════════════════════╗
-- ║          MÓDULO: QUALITY MANAGER                     ║
-- ╚══════════════════════════════════════════════════════╝
local QualityManager = {}
do
    -- Encontra modo por key
    local function getModeByKey(key)
        for _, mode in ipairs(QUALITY_MODES) do
            if mode.key == key then return mode end
        end
        return QUALITY_MODES[2] -- default: Alto
    end

    -- Gerencia efeitos de post-processing
    local postEffects = {}
    local function getOrCreate(class, name)
        local existing = Lighting:FindFirstChild(name)
        if existing and existing:IsA(class) then
            postEffects[name] = existing
            return existing
        end
        local effect = Instance.new(class)
        effect.Name = name
        effect.Parent = Lighting
        postEffects[name] = effect
        return effect
    end

    -- Aplica configurações de iluminação base
    local function applyLighting(mode)
        if not mode.globalShadows then
            Lighting.GlobalShadows      = mode.globalShadows
        else
            Lighting.GlobalShadows      = true
        end
        Lighting.Brightness             = mode.brightness or 2
        Lighting.EnvironmentDiffuseScale = mode.envDiffuse or 1
        Lighting.EnvironmentSpecularScale = mode.envSpecular or 1
        if mode.shadowSoftness then
            Lighting.ShadowSoftness = mode.shadowSoftness
        end
    end

    -- Aplica post-processing effects
    local function applyPostFX(mode)
        -- Bloom
        local bloom = getOrCreate("BloomEffect", "OptBloom")
        bloom.Enabled   = mode.bloom.enabled
        bloom.Intensity = mode.bloom.intensity
        bloom.Size      = mode.bloom.size
        bloom.Threshold = mode.bloom.threshold

        -- SunRays
        local sunRays = getOrCreate("SunRaysEffect", "OptSunRays")
        sunRays.Enabled   = mode.sunRays.enabled
        sunRays.Intensity = mode.sunRays.intensity
        sunRays.Spread    = mode.sunRays.spread

        -- ColorCorrection
        local cc = getOrCreate("ColorCorrectionEffect", "OptColorCorrection")
        cc.Enabled    = mode.colorCorrection.enabled
        cc.Brightness = mode.colorCorrection.brightness
        cc.Contrast   = mode.colorCorrection.contrast
        cc.Saturation = mode.colorCorrection.saturation
    end

    -- Gerencia partículas e decals no workspace
    local function applyWorldQuality(mode)
        -- Partículas
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = mode.particles
                if not mode.particles then obj.Rate = 0 end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = mode.decals and 0 or 1
            elseif obj:IsA("SpecialMesh") and not mode.decals then
                -- sem alteração drástica em meshes para não corromper o jogo
            end
        end

        -- Render distance via Camera ClippingEnabled + MaxViewDistance
        if Camera then
            Camera.MaxAxisFieldOfView = mode.lodFactor and 120 * mode.lodFactor or 120
        end
    end

    -- ► Aplica modo principal
    function QualityManager.applyMode(modeKey)
        local mode = getModeByKey(modeKey)
        if not mode or mode.key == "RTX" then return end

        OptState.isAdjusting  = true
        OptState.status       = "Ajustando"

        applyLighting(mode)
        applyPostFX(mode)
        applyWorldQuality(mode)

        OptState.currentModeKey   = modeKey
        OptState.currentModeIndex = MODE_INDEX[modeKey] or 2
        OptState.lastModeChange   = tick()

        task.delay(1.5, function()
            OptState.isAdjusting = false
            OptState.status      = "Estável"
        end)
    end

    -- ► Aplica camada RTX (sobre o modo atual)
    function QualityManager.applyRTX(lite)
        local bloom = getOrCreate("BloomEffect", "OptBloom")
        bloom.Enabled   = true
        bloom.Intensity = lite and 1.8 or CONFIG.RTX.BLOOM_INTENSITY
        bloom.Size      = lite and 22  or CONFIG.RTX.BLOOM_SIZE
        bloom.Threshold = 0.9

        local sunRays = getOrCreate("SunRaysEffect", "OptSunRays")
        sunRays.Enabled   = true
        sunRays.Intensity = lite and 0.08 or CONFIG.RTX.SUNRAYS_INTENSITY
        sunRays.Spread    = lite and 0.7  or 1.0

        -- Reflexos / iluminação global intensificados
        Lighting.GlobalShadows           = true
        Lighting.ShadowSoftness          = lite and 0.2 or CONFIG.RTX.SHADOW_SOFTNESS
        Lighting.EnvironmentDiffuseScale = lite and 0.9 or CONFIG.RTX.ENV_DIFFUSE
        Lighting.EnvironmentSpecularScale = lite and 0.9 or CONFIG.RTX.ENV_SPECULAR
        Lighting.Brightness              = 2.2

        -- Color Correction RTX
        local cc = getOrCreate("ColorCorrectionEffect", "OptColorCorrection")
        cc.Enabled    = true
        cc.Brightness = lite and 0.03 or 0.05
        cc.Contrast   = lite and 0.12 or 0.18
        cc.Saturation = lite and 0.08 or 0.12

        -- Depth of Field simulado (RTX full)
        if not lite then
            local dof = getOrCreate("DepthOfFieldEffect", "OptDOF")
            dof.Enabled         = true
            dof.FarIntensity    = 0.4
            dof.NearIntensity   = 0.0
            dof.FocusDistance   = 80
            dof.InFocusRadius   = 50
        end

        OptState.rtxEnabled  = true
        OptState.rtxLiteMode = lite or false
        OptState.status      = lite and "RTX Lite" or "RTX Full"
    end

    -- ► Remove camada RTX, restaura modo anterior
    function QualityManager.disableRTX()
        -- Remove DOF se existir
        local dof = Lighting:FindFirstChild("OptDOF")
        if dof then dof:Destroy() end

        -- Restaura o modo anterior
        OptState.rtxEnabled  = false
        OptState.rtxLiteMode = false
        QualityManager.applyMode(OptState.prevModeKey or OptState.currentModeKey)
        OptState.status = "Estável"
    end

    -- ► Sobe 1 nível de qualidade
    function QualityManager.increaseQuality()
        local idx = OptState.currentModeIndex
        if idx <= 1 then return end
        local newKey = MODE_NAMES[idx - 1]
        QualityManager.applyMode(newKey)
    end

    -- ► Desce N níveis de qualidade
    function QualityManager.decreaseQuality(levels)
        levels = levels or 1
        local idx = OptState.currentModeIndex
        local newIdx = math.min(#MODE_NAMES, idx + levels)
        local newKey = MODE_NAMES[newIdx]
        QualityManager.applyMode(newKey)
    end
end

-- ╔══════════════════════════════════════════════════════╗
-- ║              MÓDULO: BENCHMARK                       ║
-- ╚══════════════════════════════════════════════════════╝
local Benchmark = {}
do
    -- Classifica dispositivo pela média de FPS
    local function classify(avgFPS, jitter)
        if avgFPS >= 80 and jitter <= 15 then
            return "Ultra"
        elseif avgFPS >= 60 and jitter <= 25 then
            return "High"
        elseif avgFPS >= 40 then
            return "Mid"
        else
            return "Low"
        end
    end

    -- Executa benchmark e chama callback com resultado
    function Benchmark.run(onComplete)
        FPSMonitor.clear()
        OptState.status = "Benchmark..."

        local elapsed = 0
        local conn

        conn = RunService.RenderStepped:Connect(function(dt)
            elapsed = elapsed + dt
            FPSMonitor.sample()

            if elapsed >= CONFIG.TIMERS.BENCHMARK then
                conn:Disconnect()

                local avgFPS  = FPSMonitor.getAverage()
                local jitter  = FPSMonitor.getJitter()
                local category = classify(avgFPS, jitter)

                OptState.benchmarkDone     = true
                OptState.benchmarkCategory = category
                OptState.benchmarkAvgFPS   = avgFPS
                OptState.rtxCapable        = (category == "High" or category == "Ultra") and avgFPS >= CONFIG.FPS.RTX_REQUIRED
                OptState.rtxLiteCapable    = avgFPS >= CONFIG.FPS.RTX_LITE_ONLY_FPS

                -- Sugere modo inicial baseado no benchmark
                if category == "Ultra" then
                    QualityManager.applyMode("ULTRA")
                elseif category == "High" then
                    QualityManager.applyMode("HIGH")
                elseif category == "Mid" then
                    QualityManager.applyMode("MEDIUM")
                else
                    QualityManager.applyMode("LOW")
                end

                OptState.status = "Estável"
                FPSMonitor.clear()

                if onComplete then onComplete(avgFPS, jitter, category) end
            end
        end)
    end

    -- Benchmark rápido para checar se RTX é viável (10s)
    function Benchmark.runRTXCheck(onComplete)
        FPSMonitor.clear()
        OptState.status = "Testando RTX..."

        -- Aplica perfil RTX temporário
        QualityManager.applyRTX(false)

        local elapsed = 0
        local conn

        conn = RunService.RenderStepped:Connect(function(dt)
            elapsed = elapsed + dt
            FPSMonitor.sample()

            if elapsed >= CONFIG.TIMERS.BENCHMARK then
                conn:Disconnect()
                local avgFPS = FPSMonitor.getAverage()
                local ok     = avgFPS >= CONFIG.FPS.RTX_REQUIRED

                if not ok then
                    -- Reverte se não passou
                    QualityManager.disableRTX()
                end

                OptState.status = ok and "RTX Full" or "Estável"
                FPSMonitor.clear()
                if onComplete then onComplete(avgFPS, ok) end
            end
        end)
    end
end

-- ╔══════════════════════════════════════════════════════╗
-- ║            MÓDULO: AUTO QUALITY LOOP                 ║
-- ╚══════════════════════════════════════════════════════╝
local AutoQuality = {}
do
    local timeBelowL1  = 0
    local timeBelowL2  = 0
    local timeAbove    = 0
    local timeRTXLow   = 0
    local lastStep     = tick()

    function AutoQuality.start()
        RunService.Heartbeat:Connect(function()
            if not OptState.autoMode then
                -- Reseta contadores quando auto está desligado
                timeBelowL1 = 0
                timeBelowL2 = 0
                timeAbove   = 0
                timeRTXLow  = 0
                return
            end

            local now = tick()
            local dt  = now - lastStep
            lastStep  = now

            -- Cooldown entre trocas
            if (now - OptState.lastModeChange) < CONFIG.TIMERS.COOLDOWN then return end
            if OptState.isAdjusting then return end

            local avgFPS = FPSMonitor.getAverage(30)

            -- ► Fallback RTX automático
            if OptState.rtxEnabled then
                if avgFPS < CONFIG.FPS.RTX_FALLBACK then
                    timeRTXLow = timeRTXLow + dt
                    if timeRTXLow >= CONFIG.TIMERS.RTX_FALLBACK then
                        timeRTXLow = 0
                        OptState.status = "RTX Desativado (FPS baixo)"
                        QualityManager.disableRTX()
                        QualityManager.decreaseQuality(1)
                    end
                else
                    timeRTXLow = 0
                end
                return -- Com RTX ativo, não ajusta modo base
            end

            -- ► FPS muito baixo → desce 2 níveis
            if avgFPS < CONFIG.FPS.DROP_LEVEL_2 then
                timeBelowL2 = timeBelowL2 + dt
                timeBelowL1 = 0
                timeAbove   = 0
                OptState.status = "Instável"
                if timeBelowL2 >= CONFIG.TIMERS.DROP_LEVEL_2 then
                    timeBelowL2 = 0
                    QualityManager.decreaseQuality(2)
                end

            -- ► FPS baixo → desce 1 nível
            elseif avgFPS < CONFIG.FPS.DROP_LEVEL_1 then
                timeBelowL1 = timeBelowL1 + dt
                timeBelowL2 = 0
                timeAbove   = 0
                OptState.status = "Instável"
                if timeBelowL1 >= CONFIG.TIMERS.DROP_LEVEL_1 then
                    timeBelowL1 = 0
                    QualityManager.decreaseQuality(1)
                end

            -- ► FPS bom → sobe 1 nível
            elseif avgFPS > CONFIG.FPS.INCREASE then
                timeAbove   = timeAbove + dt
                timeBelowL1 = 0
                timeBelowL2 = 0
                OptState.status = "Estável"
                if timeAbove >= CONFIG.TIMERS.INCREASE then
                    timeAbove = 0
                    QualityManager.increaseQuality()
                end

            else
                -- FPS estável na faixa neutra
                timeBelowL1 = math.max(0, timeBelowL1 - dt)
                timeBelowL2 = math.max(0, timeBelowL2 - dt)
                timeAbove   = math.max(0, timeAbove - dt)
                OptState.status = "Estável"
            end
        end)
    end
end

-- ╔══════════════════════════════════════════════════════╗
-- ║              MÓDULO: PERSISTENCE                     ║
-- ╚══════════════════════════════════════════════════════╝
-- NOTA: Roblox não tem localStorage nativo em LocalScript puro.
-- Usamos uma variável global como "sessão" e exibimos JSON para
-- o usuário copiar/restaurar. Para persistência real entre sessões,
-- converter para DataStoreService no server-side.
local Persistence = {}
do
    local savedConfig = {}

    function Persistence.save()
        savedConfig = {
            mode     = OptState.currentModeKey,
            auto     = OptState.autoMode,
            rtx      = OptState.rtxEnabled,
            rtxLite  = OptState.rtxLiteMode,
        }
        -- Ponto de integração server-side: aqui você pode
        -- fazer FireServer para salvar via DataStore.
        return savedConfig
    end

    function Persistence.load()
        -- Retorna config salva (ou defaults)
        return savedConfig
    end

    function Persistence.toJSON()
        local t = Persistence.save()
        return string.format(
            '{"mode":"%s","auto":%s,"rtx":%s,"rtxLite":%s}',
            t.mode or "HIGH",
            tostring(t.auto or true),
            tostring(t.rtx or false),
            tostring(t.rtxLite or false)
        )
    end
end

-- ╔══════════════════════════════════════════════════════╗
-- ║             FUNÇÕES DO AIMBOT                        ║
-- ╚══════════════════════════════════════════════════════╝
local function isAlive(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getClosestPlayer()
    local closest  = nil
    local shortest = AimSettings.FOV
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AimSettings.TeamCheck and player.Team and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end
        if not isAlive(char) then continue end

        local part = char:FindFirstChild(AimSettings.AimPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < shortest then
            shortest = dist
            closest  = player
        end
    end
    return closest
end

-- ╔══════════════════════════════════════════════════════╗
-- ║                INPUT (Aimbot)                        ║
-- ╚══════════════════════════════════════════════════════╝
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHolding   = false
        currentTarget = nil
    end
end)

-- ╔══════════════════════════════════════════════════════╗
-- ║              LOOP PRINCIPAL (Aimbot)                 ║
-- ╚══════════════════════════════════════════════════════╝
local function startAimLoop()
    if aimConnection then return end
    aimConnection = RunService.RenderStepped:Connect(function()
        -- Atualiza FOV circle
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius   = AimSettings.FOV
        FOVCircle.Visible  = AimSettings.ShowFOV and AimSettings.Enabled

        -- Sample FPS para o monitor
        FPSMonitor.sample()

        if not AimSettings.Enabled then return end

        local shouldAim = AimSettings.HoldMode and isHolding or AimSettings.Enabled
        if shouldAim then
            local target = getClosestPlayer()
            if target and target.Character then
                local part = target.Character:FindFirstChild(AimSettings.AimPart)
                if part then
                    local smoothFactor = 1 - math.clamp(AimSettings.Smoothness, 0, 0.99)
                    local goalCF = CFrame.new(Camera.CFrame.Position, part.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(goalCF, smoothFactor)
                end
            end
        end
    end)
end

local function stopAimLoop()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
    FOVCircle.Visible = false
end

startAimLoop()
AutoQuality.start()

-- ╔══════════════════════════════════════════════════════╗
-- ║               KEY SYSTEM + RAYFIELD UI               ║
-- ╚══════════════════════════════════════════════════════╝
local keyLink = "https://linkvertise.com/3852364/kbMTaa3j2CcF"
if setclipboard then setclipboard(keyLink) end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = "aimb0t hub",
    Icon             = nil,
    LoadingTitle     = "aimb0t hub",
    LoadingSubtitle  = "by henrique",
    Theme            = "Default",
    ToggleUIKeybind  = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    ConfigurationSaving = {
        Enabled    = true,
        FolderName = nil,
        FileName   = "aimb0t_hub_cfg"
    },

    Discord = { Enabled = false },

    KeySystem = true,
    KeySettings = {
        Title           = "aimb0t hub | Key System",
        Subtitle        = "Key System",
        Note            = "Pegue a key em: linkvertise.com/3852364/kbMTaa3j2CcF\n\n(Link copiado automaticamente para o clipboard!)",
        FileName        = "aimb0t_hub_key",
        SaveKey         = true,
        GrabKeyFromSite = true,
        Key             = {"FREE_KEY82819W929"},
    },
})

-- ╔══════════════════════════════════════════════════════╗
-- ║                TAB: AIMBOT                           ║
-- ╚══════════════════════════════════════════════════════╝
local TabAimbot = Window:CreateTab("Aimbot", 4483362458)
TabAimbot:CreateSection("Principal")

TabAimbot:CreateToggle({
    Name         = "Ativar Aimbot",
    CurrentValue = AimSettings.Enabled,
    Flag         = "AimbotToggle",
    Callback     = function(value)
        AimSettings.Enabled = value
        if value then startAimLoop() end
    end,
})

TabAimbot:CreateToggle({
    Name         = "Modo Segurar (Hold RMB)",
    CurrentValue = AimSettings.HoldMode,
    Flag         = "HoldMode",
    Callback     = function(value) AimSettings.HoldMode = value end,
})

TabAimbot:CreateToggle({
    Name         = "Team Check",
    CurrentValue = AimSettings.TeamCheck,
    Flag         = "TeamCheck",
    Callback     = function(value) AimSettings.TeamCheck = value end,
})

TabAimbot:CreateSection("Configurações de Mira")

TabAimbot:CreateDropdown({
    Name          = "Parte do Corpo",
    Options       = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = {AimSettings.AimPart},
    Flag          = "AimPart",
    Callback      = function(option)
        AimSettings.AimPart = type(option) == "table" and option[1] or option
    end,
})

TabAimbot:CreateSlider({
    Name         = "FOV (Campo de Visão)",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = "px",
    CurrentValue = AimSettings.FOV,
    Flag         = "FOVSlider",
    Callback     = function(value) AimSettings.FOV = value end,
})

TabAimbot:CreateSlider({
    Name         = "Smoothness (Suavidade)",
    Range        = {0, 95},
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = math.floor(AimSettings.Smoothness * 100),
    Flag         = "SmoothnessSlider",
    Callback     = function(value) AimSettings.Smoothness = value / 100 end,
})

TabAimbot:CreateSection("Visual")

TabAimbot:CreateToggle({
    Name         = "Mostrar Círculo FOV",
    CurrentValue = AimSettings.ShowFOV,
    Flag         = "ShowFOV",
    Callback     = function(value) AimSettings.ShowFOV = value end,
})

TabAimbot:CreateColorPicker({
    Name         = "Cor do Círculo FOV",
    Color        = FOVCircle.Color,
    Flag         = "FOVColor",
    Callback     = function(color) FOVCircle.Color = color end,
})

-- ╔══════════════════════════════════════════════════════╗
-- ║                TAB: VISUAIS / ESP                    ║
-- ╚══════════════════════════════════════════════════════╝
local TabVisuals = Window:CreateTab("Visuais", 4483362458)
TabVisuals:CreateSection("Destaques")

local highlightEnabled = false
local highlights = {}

local function clearHighlights()
    for _, hl in pairs(highlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    highlights = {}
end

local function applyHighlights()
    clearHighlights()
    if not highlightEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AimSettings.TeamCheck and player.Team and player.Team == LocalPlayer.Team then continue end
        local char = player.Character
        if char and isAlive(char) then
            local hl = Instance.new("Highlight")
            hl.Adornee             = char
            hl.FillColor           = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency    = 0.65
            hl.OutlineTransparency = 0
            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent              = char
            table.insert(highlights, hl)
        end
    end
end

TabVisuals:CreateToggle({
    Name         = "ESP Highlight",
    CurrentValue = false,
    Flag         = "ESPToggle",
    Callback     = function(value)
        highlightEnabled = value
        if value then applyHighlights() else clearHighlights() end
    end,
})

Players.PlayerAdded:Connect(function() task.wait(2) applyHighlights() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) applyHighlights() end)

-- ╔══════════════════════════════════════════════════════╗
-- ║                 TAB: PLAYER                          ║
-- ╚══════════════════════════════════════════════════════╝
local TabPlayer = Window:CreateTab("Player", 4483362458)
TabPlayer:CreateSection("Movimento")

TabPlayer:CreateSlider({
    Name         = "WalkSpeed",
    Range        = {16, 150},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end,
})

TabPlayer:CreateSlider({
    Name         = "JumpPower",
    Range        = {0, 150},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = value end
        end
    end,
})

-- ╔══════════════════════════════════════════════════════╗
-- ║           TAB: OTIMIZAÇÃO VISUAL                     ║
-- ╚══════════════════════════════════════════════════════╝
local TabOpt = Window:CreateTab("Otimização", 4483362458)

-- ── Status em tempo real ────────────────────────────────
TabOpt:CreateSection("Monitor em Tempo Real")

TabOpt:CreateParagraph({
    Title   = "📊 Status do Sistema",
    Content = "FPS: atualizando...\nModo: " .. OptState.currentModeKey .. "\nStatus: " .. OptState.status,
})

-- Atualiza o parágrafo de status a cada 2 segundos
task.spawn(function()
    while true do
        task.wait(2)
        -- Rayfield não suporta atualização dinâmica de parágrafo nativo,
        -- então usamos notificações para FPS crítico.
        local fps = FPSMonitor.getAverage(10)
        if fps < 20 and OptState.autoMode then
            Rayfield:Notify({
                Title    = "⚠️ FPS Crítico",
                Content  = "FPS: " .. fps .. " | Reduzindo qualidade...",
                Duration = 3,
            })
        end
    end
end)

-- ── Controle Automático ──────────────────────────────────
TabOpt:CreateSection("Controle Automático")

TabOpt:CreateToggle({
    Name         = "Auto-Otimização",
    CurrentValue = OptState.autoMode,
    Flag         = "AutoOptToggle",
    Callback     = function(value)
        OptState.autoMode = value
        Rayfield:Notify({
            Title    = value and "✅ Auto-Otimização" or "⚙️ Modo Manual",
            Content  = value and "Sistema ajustará qualidade automaticamente." or "Controle manual ativado.",
            Duration = 3,
        })
    end,
})

-- ── Benchmark ────────────────────────────────────────────
TabOpt:CreateSection("Benchmark")

TabOpt:CreateButton({
    Name     = "🔬 Executar Benchmark (10s)",
    Callback = function()
        Rayfield:Notify({
            Title   = "🔬 Benchmark Iniciado",
            Content = "Aguarde 10 segundos para a análise completa.",
            Duration = 4,
        })
        Benchmark.run(function(avgFPS, jitter, category)
            Rayfield:Notify({
                Title   = "✅ Benchmark Concluído",
                Content = string.format(
                    "Média FPS: %d | Jitter: %d | Categoria: %s\nModo sugerido aplicado.",
                    avgFPS, jitter, category
                ),
                Duration = 6,
            })
        end)
    end,
})

-- ── Modos Manuais ────────────────────────────────────────
TabOpt:CreateSection("Modos de Qualidade")

TabOpt:CreateDropdown({
    Name          = "Selecionar Modo",
    Options       = {"Ultra ⚡", "Alto 🔥", "Médio ⚙️", "Baixo 📉", "Batata 🥔", "EXTREMO 💀"},
    CurrentOption = {"Alto 🔥"},
    Flag          = "QualityMode",
    Callback      = function(option)
        local map = {
            ["Ultra ⚡"] = "ULTRA",
            ["Alto 🔥"]  = "HIGH",
            ["Médio ⚙️"] = "MEDIUM",
            ["Baixo 📉"] = "LOW",
            ["Batata 🥔"] = "POTATO",
            ["EXTREMO 💀"] = "EXTREME",
        }
        local sel = type(option) == "table" and option[1] or option
        local key = map[sel]
        if key then
            OptState.autoMode = false
            QualityManager.applyMode(key)
            Rayfield:Notify({
                Title   = "🎮 Modo Alterado",
                Content = "Modo " .. sel .. " aplicado.\nAuto-Otimização desativada.",
                Duration = 3,
            })
        end
    end,
})

-- ── Botões rápidos por modo ───────────────────────────────
TabOpt:CreateButton({
    Name     = "⚡ Aplicar Ultra",
    Callback = function()
        OptState.autoMode = false
        QualityManager.applyMode("ULTRA")
        Rayfield:Notify({ Title="⚡ Ultra", Content="Qualidade máxima aplicada.", Duration=2 })
    end,
})

TabOpt:CreateButton({
    Name     = "💀 Aplicar EXTREMO (Máx. FPS)",
    Callback = function()
        OptState.autoMode = false
        QualityManager.applyMode("EXTREME")
        Rayfield:Notify({ Title="💀 EXTREMO", Content="Modo máximo de performance aplicado.", Duration=2 })
    end,
})

-- ── RTX ──────────────────────────────────────────────────
TabOpt:CreateSection("🔮 RAY TRACING (RTX)")

TabOpt:CreateParagraph({
    Title   = "ℹ️ Sobre o RTX",
    Content = "RTX é uma simulação de ray tracing via post-processing.\nRoblox não possui ray tracing hardware nativo.\nSombras, reflexos e iluminação são aprimorados via efeitos avançados.",
})

TabOpt:CreateButton({
    Name     = "🔮 Ativar RTX Full",
    Callback = function()
        if OptState.rtxEnabled then
            Rayfield:Notify({ Title="⚠️ RTX", Content="RTX já está ativo!", Duration=2 })
            return
        end
        Rayfield:Notify({
            Title   = "🔮 Iniciando Teste RTX (10s)",
            Content = "Testando capacidade do dispositivo para RTX...",
            Duration = 4,
        })
        OptState.prevModeKey = OptState.currentModeKey
        Benchmark.runRTXCheck(function(avgFPS, ok)
            if ok then
                Rayfield:Notify({
                    Title   = "✅ RTX Full Ativado!",
                    Content = string.format("FPS médio no teste: %d\nReflexos, sombras e iluminação RTX ativos.", avgFPS),
                    Duration = 5,
                })
            else
                Rayfield:Notify({
                    Title   = "❌ Dispositivo Incompatível",
                    Content = string.format("FPS médio: %d (mínimo: %d)\nTente RTX Lite.", avgFPS, CONFIG.FPS.RTX_REQUIRED),
                    Duration = 5,
                })
            end
        end)
    end,
})

TabOpt:CreateButton({
    Name     = "🔮 Ativar RTX Lite",
    Callback = function()
        if OptState.rtxEnabled and OptState.rtxLiteMode then
            Rayfield:Notify({ Title="⚠️ RTX", Content="RTX Lite já está ativo!", Duration=2 })
            return
        end
        OptState.prevModeKey = OptState.currentModeKey
        QualityManager.applyRTX(true)
        Rayfield:Notify({
            Title   = "✅ RTX Lite Ativado",
            Content = "Efeitos parciais de RTX aplicados.\nMenor impacto no FPS.",
            Duration = 3,
        })
    end,
})

TabOpt:CreateButton({
    Name     = "❌ Desativar RTX",
    Callback = function()
        if not OptState.rtxEnabled then
            Rayfield:Notify({ Title="⚠️ RTX", Content="RTX não está ativo.", Duration=2 })
            return
        end
        QualityManager.disableRTX()
        Rayfield:Notify({
            Title   = "❌ RTX Desativado",
            Content = "Modo anterior restaurado.",
            Duration = 3,
        })
    end,
})

-- ── Thresholds customizáveis ──────────────────────────────
TabOpt:CreateSection("Thresholds do Auto-Ajuste")

TabOpt:CreateSlider({
    Name         = "FPS mínimo (reduz 1 nível)",
    Range        = {15, 50},
    Increment    = 1,
    Suffix       = " FPS",
    CurrentValue = CONFIG.FPS.DROP_LEVEL_1,
    Flag         = "ThreshL1",
    Callback     = function(v) CONFIG.FPS.DROP_LEVEL_1 = v end,
})

TabOpt:CreateSlider({
    Name         = "FPS mínimo (reduz 2 níveis)",
    Range        = {5, 30},
    Increment    = 1,
    Suffix       = " FPS",
    CurrentValue = CONFIG.FPS.DROP_LEVEL_2,
    Flag         = "ThreshL2",
    Callback     = function(v) CONFIG.FPS.DROP_LEVEL_2 = v end,
})

TabOpt:CreateSlider({
    Name         = "FPS alvo (aumenta nível)",
    Range        = {40, 90},
    Increment    = 1,
    Suffix       = " FPS",
    CurrentValue = CONFIG.FPS.INCREASE,
    Flag         = "ThreshUp",
    Callback     = function(v) CONFIG.FPS.INCREASE = v end,
})

TabOpt:CreateSlider({
    Name         = "Cooldown entre trocas",
    Range        = {3, 30},
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = CONFIG.TIMERS.COOLDOWN,
    Flag         = "ThreshCD",
    Callback     = function(v) CONFIG.TIMERS.COOLDOWN = v end,
})

-- ── Persistência / Export ─────────────────────────────────
TabOpt:CreateSection("Persistência")

TabOpt:CreateButton({
    Name     = "💾 Copiar Config (JSON)",
    Callback = function()
        local json = Persistence.toJSON()
        if setclipboard then
            setclipboard(json)
            Rayfield:Notify({
                Title   = "💾 Config Copiada",
                Content = "JSON copiado para o clipboard:\n" .. json,
                Duration = 5,
            })
        else
            Rayfield:Notify({
                Title   = "💾 Config JSON",
                Content = json,
                Duration = 8,
            })
        end
    end,
})

-- ╔══════════════════════════════════════════════════════╗
-- ║                  TAB: INFO                           ║
-- ╚══════════════════════════════════════════════════════╝
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateSection("Sobre")

TabInfo:CreateParagraph({
    Title   = "aimb0t hub v2.0",
    Content = "Desenvolvido por henrique\n\nSomente para testes em servidores privados.\n\nToggle UI: K\nMira: Segurar botão direito do mouse\n\n[NOVO] Sistema de Otimização Visual com RTX simulado integrado.",
})

TabInfo:CreateParagraph({
    Title   = "ℹ️ Nota sobre RTX",
    Content = "O modo RTX simula efeitos de ray tracing via post-processing (Bloom, SunRays, ColorCorrection, DepthOfField, sombras e iluminação avançada). Roblox não possui ray tracing hardware nativo exposto.",
})

TabInfo:CreateButton({
    Name     = "Desligar Script",
    Callback = function()
        stopAimLoop()
        clearHighlights()
        FOVCircle:Remove()

        -- Remove efeitos criados pelo otimizador
        for _, name in ipairs({"OptBloom", "OptSunRays", "OptColorCorrection", "OptDOF"}) do
            local e = Lighting:FindFirstChild(name)
            if e then e:Destroy() end
        end

        Rayfield:Destroy()
    end,
})

------------------------------------------------------------
Rayfield:LoadConfiguration()

-- Executa benchmark na primeira vez automaticamente (após 3s de carregamento)
task.delay(3, function()
    if not OptState.benchmarkDone then
        Rayfield:Notify({
            Title   = "🔬 Benchmark Automático",
            Content = "Analisando seu dispositivo por 10 segundos...",
            Duration = 4,
        })
        Benchmark.run(function(avgFPS, jitter, category)
            Rayfield:Notify({
                Title   = "✅ Benchmark Concluído",
                Content = string.format(
                    "Categoria: %s | FPS médio: %d\nModo sugerido aplicado automaticamente.",
                    category, avgFPS
                ),
                Duration = 6,
            })
        end)
    end
end)
