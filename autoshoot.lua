-- =============================================
-- AUTO SHOOT - OnyxHub Style (Modular)
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local AutoShoot = {}
local enabled = false
local connection = nil

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer then
            local char = plr.Character
            local backpack = plr:FindFirstChild("Backpack")
            
            if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then
                return plr
            end
        end
    end
    return nil
end

local function getGun()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Gun") then
        return char.Gun
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild("Gun") then
        local gun = backpack.Gun
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:EquipTool(gun)
        end
        return gun
    end
    return nil
end

function AutoShoot.Toggle(state)
    enabled = state
    
    if enabled then
        print("🔫 Auto Shoot Ativado")
        
        connection = RunService.Heartbeat:Connect(function()
            if not enabled then return end
            
            local gun = getGun()
            if not gun then return end
            
            local murderer = findMurderer()
            if not murderer or not murderer.Character then return end
            
            local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return end
            
            -- Previsão simples de posição
            local predictedPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * 0.08)
            
            local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
            
            if shootRemote and shootRemote:IsA("RemoteEvent") then
                pcall(function()
                    shootRemote:FireServer(predictedPos)
                end)
            end
        end)
        
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
        print("🔫 Auto Shoot Desativado")
    end
end

function AutoShoot.IsEnabled()
    return enabled
end

return AutoShoot
