-- =============================================
-- AUTO FARM COINS - nil.lua MM2
-- =============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local AutoFarm = {}

local isRunning = false
local coinCollectorThread = nil
local TWEEN_SPEED = 20
local TELEPORT_DISTANCE = 200

local visitedCoins = {}

local mapPaths = {
    "IceCastle", "SkiLodge", "Station", "LogCabin", "Bank2", "BioLab",
    "House2", "Factory", "Hospital3", "Hotel", "Mansion2", "MilBase",
    "Office3", "PoliceStation", "Workplace", "ResearchFacility", "ChristmasItaly"
}

-- ==================== FUNÇÕES INTERNAS ====================

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function findActiveCoinContainer()
    for _, mapName in ipairs(mapPaths) do
        local map = Workspace:FindFirstChild(mapName)
        if map then
            local container = map:FindFirstChild("CoinContainer")
            if container then
                return container
            end
        end
    end
    return nil
end

local function findNearestCoin(container)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, shortest = nil, math.huge

    for _, coin in ipairs(container:GetChildren()) do
        if coin:IsA("BasePart") and not visitedCoins[coin] then
            local distance = (root.Position - coin.Position).Magnitude
            if distance < shortest then
                shortest = distance
                nearest = coin
            end
        end
    end
    return nearest
end

-- ==================== CONTROLE PRINCIPAL ====================

function AutoFarm.Start()
    if isRunning then return end
    isRunning = true
    visitedCoins = {}

    print("🟢 Auto Farm Coins Iniciado")

    coinCollectorThread = RunService.Heartbeat:Connect(function()
        local character = getCharacter()
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local container = findActiveCoinContainer()
        if not container then return end

        local coin = findNearestCoin(container)
        if not coin then 
            visitedCoins = {} -- reset se não achar mais coins
            return 
        end

        local distance = (root.Position - coin.Position).Magnitude

        if distance >= TELEPORT_DISTANCE then
            root.CFrame = CFrame.new(coin.Position)
        else
            local tweenInfo = TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(coin.Position)})
            tween:Play()
            tween.Completed:Wait()
        end

        visitedCoins[coin] = true

        -- Falling animation
        if character:FindFirstChild("Humanoid") then
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)
end

function AutoFarm.Stop()
    isRunning = false
    if coinCollectorThread then
        coinCollectorThread:Disconnect()
        coinCollectorThread = nil
    end
    visitedCoins = {}
    print("🔴 Auto Farm Coins Parado")
end

function AutoFarm.SetTweenSpeed(speed)
    TWEEN_SPEED = math.clamp(speed, 5, 50)
end

-- Retorna a tabela para o main
return AutoFarm
