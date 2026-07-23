-- =============================================
-- AUTO FARM COINS - Versão Avançada
-- =============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local AutoFarm = {}

local isRunning = false
local farmingThread = nil

local settings = {
    Mode = "Nearest",           -- "Nearest" ou "StayAway"
    Speed = 25,
    AutoReset = true,
    FlingWhenFull = true,
    AntiFling = true,
    AntiAFK = true
}

local visitedCoins = {}
local lastReset = 0

local mapPaths = {"IceCastle","SkiLodge","Station","LogCabin","Bank2","BioLab","House2","Factory","Hospital3","Hotel","Mansion2","MilBase","Office3","PoliceStation","Workplace","ResearchFacility","ChristmasItaly"}

-- ==================== FUNÇÕES INTERNAS ====================

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local bp = plr:FindFirstChild("Backpack")
            if (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
                return plr
            end
        end
    end
    return nil
end

local function findNearestCoin()
    local root = getHRP()
    if not root then return nil end

    local nearest, shortest = nil, math.huge

    for _, mapName in ipairs(mapPaths) do
        local map = Workspace:FindFirstChild(mapName)
        if map then
            local container = map:FindFirstChild("CoinContainer")
            if container then
                for _, coin in ipairs(container:GetChildren()) do
                    if coin:IsA("BasePart") and not visitedCoins[coin] then
                        local dist = (root.Position - coin.Position).Magnitude
                        if dist < shortest then
                            shortest = dist
                            nearest = coin
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function stayAwayFromMurderer()
    local root = getHRP()
    local murderer = findMurderer()
    if not root or not murderer or not murderer.Character then return false end

    local murRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if murRoot then
        local direction = (root.Position - murRoot.Position).Unit
        root.CFrame = root.CFrame + direction * 30
        return true
    end
    return false
end

-- ==================== ANTI FLING & ANTI AFK ====================

local antiFlingConn = nil
function AutoFarm.ToggleAntiFling(state)
    settings.AntiFling = state
    if state then
        antiFlingConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            end
        end)
    else
        if antiFlingConn then antiFlingConn:Disconnect() end
    end
end

local antiAFKConn = nil
function AutoFarm.ToggleAntiAFK(state)
    settings.AntiAFK = state
    if state then
        antiAFKConn = task.spawn(function()
            while settings.AntiAFK do
                task.wait(180) -- 3 minutos
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    wait(0.1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)
    else
        if antiAFKConn then task.cancel(antiAFKConn) end
    end
end

-- ==================== MAIN FARM LOOP ====================

function AutoFarm.Start()
    if isRunning then return end
    isRunning = true
    visitedCoins = {}

    print("🟢 Auto Farm Iniciado")

    farmingThread = RunService.Heartbeat:Connect(function()
        local root = getHRP()
        if not root then return end

        -- Stay Away from Murderer
        if settings.Mode == "StayAway" then
            stayAwayFromMurderer()
        end

        local coin = findNearestCoin()
        if not coin then 
            visitedCoins = {} 
            return 
        end

        local dist = (root.Position - coin.Position).Magnitude

        if dist > 150 then
            root.CFrame = coin.CFrame
        else
            local tween = TweenService:Create(root, TweenInfo.new(dist / settings.Speed, Enum.EasingStyle.Linear), {CFrame = coin.CFrame})
            tween:Play()
            tween.Completed:Wait()
        end

        visitedCoins[coin] = true

        -- Reset quando bolsa cheia
        if settings.AutoReset and tick() - lastReset > 8 then
            local coinCount = #visitedCoins
            if coinCount > 35 then  -- aproximado de bolsa cheia
                if settings.FlingWhenFull then
                    local mur = findMurderer()
                    if mur then
                        -- Fling simples
                        local murRoot = mur.Character and mur.Character:FindFirstChild("HumanoidRootPart")
                        if murRoot then
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                            bv.Velocity = murRoot.CFrame.LookVector * 150
                            bv.Parent = murRoot
                            game.Debris:AddItem(bv, 1.5)
                        end
                    end
                end
                
                root:BreakJoints()
                lastReset = tick()
                visitedCoins = {}
            end
        end
    end)
end

function AutoFarm.Stop()
    isRunning = false
    if farmingThread then
        farmingThread:Disconnect()
        farmingThread = nil
    end
    visitedCoins = {}
    print("🔴 Auto Farm Parado")
end

function AutoFarm.SetMode(mode)
    settings.Mode = mode  -- "Nearest" or "StayAway"
end

function AutoFarm.SetSpeed(speed)
    settings.Speed = math.clamp(speed, 10, 40)
end

function AutoFarm.SetAutoReset(state)
    settings.AutoReset = state
end

function AutoFarm.SetFlingWhenFull(state)
    settings.FlingWhenFull = state
end

return AutoFarm
