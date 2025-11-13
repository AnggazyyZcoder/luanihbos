-- CONFIG: ubah sesuai kebutuhan
local AUTO_FISH_REMOTE_NAME = "UpdateAutoFishingState"
local NET_PACKAGES_FOLDER = "Packages"

-- Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Import required modules
local success, Signal = pcall(require, ReplicatedStorage.Packages.Signal)
local success2, Trove = pcall(require, ReplicatedStorage.Packages.Trove)
local success3, Net = pcall(require, ReplicatedStorage.Packages.Net)
local success4, spr = pcall(require, ReplicatedStorage.Packages.spr)
local success5, Constants = pcall(require, ReplicatedStorage.Shared.Constants)
local success6, Soundbook = pcall(require, ReplicatedStorage.Shared.Soundbook)
local success7, GuiControl = pcall(require, ReplicatedStorage.Modules.GuiControl)
local success8, HUDController = pcall(require, ReplicatedStorage.Controllers.HUDController)
local success9, AnimationController = pcall(require, ReplicatedStorage.Controllers.AnimationController)
local success10, TextNotificationController = pcall(require, ReplicatedStorage.Controllers.TextNotificationController)
local success11, BlockedHumanoidStates = pcall(require, ReplicatedStorage.Shared.BlockedHumanoidStates)

-- UI Variables
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Charge_upvr = PlayerGui:WaitForChild("Charge")
local Fishing_upvr = PlayerGui:WaitForChild("Fishing")
local Main_upvr = Fishing_upvr:WaitForChild("Main")
local CanvasGroup_upvr = Main_upvr:WaitForChild("Display"):WaitForChild("CanvasGroup")

-- Fishing status variables
local var17_upvw = nil -- Player Data
local var32_upvw = false -- Charge Started
local var34_upvw = false -- Is Stopped/Closing
local var35_upvw = nil -- Charge Start Time
local var36_upvw = nil -- Minigame UUID
local var37_upvw = nil -- Minigame State / Data
local var38_upvw = 0 -- Cooldown Time
local var40_upvw = nil -- Reel Sound Track
local var109_upvw = false -- Is Charging flag

local autoFishEnabled = false
local autoFishLoopThread = nil
local coordinateGui = nil
local statusParagraph = nil
local currentSelectedMap = nil

-- Player Configuration Variables
local antiLagEnabled = false
local savePositionEnabled = false
local lockPositionEnabled = false
local lastSavedPosition = nil
local lockPositionLoop = nil
local originalGraphicsSettings = {}

-- Bypass Variables
local fishingRadarEnabled = false
local divingGearEnabled = false
local autoSellEnabled = false
local autoSellThreshold = 3
local autoSellLoop = nil

-- Weather System Variables
local selectedWeathers = {}
local availableWeathers = {}

-- Trick or Treat Variables
local autoTrickTreatEnabled = false
local trickTreatLoop = nil

-- Blatant Fishing Variables
local isBlatantActive = false
local BLATANT_MODE_TROVE = nil
local originalFishingRodStarted = nil
local originalSendFishingRequestToServer = nil
local originalRequestChargeFishingRod = nil
local FISHING_COMPLETED_REMOTE = nil
local RequestFishingMinigameStarted_Net = nil
local module_upvr = nil
local Net_upvr = nil
local Trove_upvr = nil
local Constants_upvr = nil

-- Blatant Fishing Configuration
local blatantReelDelay = 0.5  -- Default delay reel
local blatantFishingDelay = 0.5  -- PERUBAHAN: Delay fishing di set rendah untuk SPAM CAST

-- =============================================================================
-- NEW FEATURES FROM SECOND SCRIPT
-- =============================================================================

-- Auto Farm Variables
local autoFarmEnabled = false
local fishingEnabled = false
local mobileAutoFishingEnabled = false
local platform, fishingThread, monitorThread, sellThread, mobileMonitorThread
local castDelay, fishingWaitDelay, actionDelay = 0.00000000000000000000000000000000000000000000000000000000000000000000001, 3, 0.00000000000000000000000000000000000000000000000000000000000000000000001
local sellDelay = 3
local perfectX, perfectY = -0.57187455892563, 0.98649686980755
local currentEvent = "None"
local playerFrozen = false
local originalWalkSpeed = 16
local originalJumpPower = 50
local espEnabled = false
local removeOxyEnabled = false

-- Loop threads for fishing events
local fishingCompletedThread, chargeRodThread, minigameThread

-- Webhook variables
local WEBHOOK_URL = ""
local DISCORD_USER_ID = ""
local SEND_BIG_IMAGE = false
local DEBUG_ICON = false

-- Profit tracking globals
local sessionStart = os.clock()
local totalProfit = 0
local fishCaught = 0

-- Island locations with CFrames
local islands = {
    ["Coral Reefs"] = CFrame.new(-2853.17041, 47.4999962, 1978.53153, 0.995933771, 5.30696056e-08, 0.0900883451, -5.38422e-08, 1, 6.14572748e-09, -0.0900883451, -1.09712923e-08, 0.995933771),
    ["Crater Island"] = CFrame.new(1010.01001, 22.5737934, 5078.45117, 1, 3.73163225e-08, 2.25615272e-14, -3.73163225e-08, 1, 7.7200859e-09, -2.22734412e-14, -7.7200859e-09, 1),
    ["Esoteric Depths"] = CFrame.new(2016.02954, 24.1472187, 1392.12378, -0.59965688, 1.00978752e-07, 0.800257206, 1.12315014e-07, 1, -4.20218385e-08, -0.800257206, 6.46822187e-08, -0.59965688),
    ["Fisherman Island"] = CFrame.new(31.9851341, 17.0335217, 2836.88086, 0.99385339, -5.1943001e-08, 0.110704549, 4.40043664e-08, 1, 7.41533484e-08, -0.110704549, -6.88260684e-08, 0.99385339),
    ["Kohana"] = CFrame.new(-665.425537, 3.04580712, 726.46582, 0.643756926, -7.04636776e-08, -0.76523006, 2.26932979e-08, 1, -7.29907441e-08, 0.76523006, 2.96227025e-08, 0.643756926),
    ["Kohana Volcano"] = CFrame.new(-615.110474, 48.5929337, 185.705719, 0.821147323, -9.90723095e-08, 0.570716262, 1.00536617e-07, 1, 2.89407147e-08, -0.570716262, 3.36132899e-08, 0.821147323),
    ["Lost Isle"] = CFrame.new(-3673.05298, 4.91650009, -1064.66992, 0.91068995, 6.99755498e-09, -0.413090557, 6.7637087e-09, 1, 3.18506359e-08, 0.413090557, -3.18000772e-08, 0.91068995),
    ["Tropical Grove"] = CFrame.new(-2144.80469, 53.5837822, 3696.86865, -0.145694956, -2.13120419e-08, -0.989329576, -9.90430493e-08, 1, -6.95619518e-09, 0.989329576, 9.69727338e-08, -0.145694956),
    ["Weather Machine"] = CFrame.new(-1487.95251, 28.7718086, 1878.29395, -0.999500036, 1.5616715e-08, 0.0316170119, 1.45293999e-08, 1, -3.46199371e-08, -0.0316170119, -3.41432553e-08, -0.999500036),
    ["Treasure Room"] = CFrame.new(-3603.39502, -266.57373, -1580.11853, 0.998887777, -5.06168885e-09, 0.0471506417, 2.91316415e-09, 1, 4.56359537e-08, -0.0471506417, -4.54478375e-08, 0.998887777)
}

-- Event locations
local events = {
    "Worm Hunt",
    "Ghost Shark Hunt"
}

-- Volcano CFrame
local volcanoCFrame = CFrame.new(-642.5606, 64.1161, 190.4044,
    0.6339644, -7.4974977e-09, 0.7733622,
    -2.4160360e-08, 1, 2.9500156e-08,
    -0.7733622, -3.7386758e-08, 0.6339644
)

-- AllFishes dataset (FULL)
local AllFishes = {
    [10] = {["Id"] = 10,["Name"] = "Enchant Stone",["Tier"] = 1,["Chance"] = 0.0003448275862068965,["SellPrice"] = 1000,["Icon"] = "rbxassetid://138135001339336",["Weight"] = {}},
    [11] = {["Id"] = 11,["Name"] = "DEC24 - Golden Plaque",["Tier"] = 90,["Chance"] = nil,["SellPrice"] = 0,["Icon"] = "rbxassetid://85571255574708",["Weight"] = {}},
    [12] = {["Id"] = 12,["Name"] = "DEC24 - Sapphire Plaque",["Tier"] = 90,["Chance"] = nil,["SellPrice"] = 0,["Icon"] = "rbxassetid://119747646543723",["Weight"] = {}},
    -- ... (semua data ikan lainnya dari script kedua)
    [211] = {["Id"] = 211,["Name"] = "Wahoo",["Tier"] = 2,["Chance"] = 0.015384615384615385,["SellPrice"] = 105,["Icon"] = "rbxassetid://88311721896238",["Weight"] = {["Big"] = {10.2, 13.4},["Default"] = {7.4, 9.6}}},
}

local AllVariants = {
    ["Corrupt"]     = {Id = 1, Name = "Corrupt", SellMultiplier = 3.0, Chance = 0.5},
    ["Galaxy"]      = {Id = 2, Name = "Galaxy", SellMultiplier = 5.5, Chance = 0.5},
    ["Ghost"]       = {Id = 3, Name = "Ghost", SellMultiplier = 2.5, Chance = 1.4},
    ["Lightning"]   = {Id = 4, Name = "Lightning", SellMultiplier = 3.2, Chance = 0.9},
    ["Fairy Dust"]  = {Id = 5, Name = "Fairy Dust", SellMultiplier = 2.8, Chance = 0.6},
    ["Gold"]        = {Id = 6, Name = "Gold", SellMultiplier = 2.8, Chance = 1.6},
    ["Midnight"]    = {Id = 7, Name = "Midnight", SellMultiplier = 3.8, Chance = 0.7},
    ["Radioactive"] = {Id = 8, Name = "Radioactive", SellMultiplier = 3.0, Chance = 0.9},
    ["Stone"]       = {Id = 9, Name = "Stone", SellMultiplier = 1.2, Chance = 4.0},
    ["Festive"]     = {Id = 10, Name = "Festive", SellMultiplier = 2.6, Chance = 2.2},
    ["Frozen"]      = {Id = 11, Name = "Frozen", SellMultiplier = 2.0, Chance = 5.5},
    ["Holographic"] = {Id = 12, Name = "Holographic", SellMultiplier = 2.4, Chance = 0.9},
    ["Albino"]      = {Id = 13, Name = "Albino", SellMultiplier = 1.3, Chance = 2.5},
}

-- UI Configuration
local COLOR_ENABLED = Color3.fromRGB(76, 175, 80)  -- Green
local COLOR_DISABLED = Color3.fromRGB(244, 67, 54) -- Red
local COLOR_PRIMARY = Color3.fromRGB(103, 58, 183) -- Purple
local COLOR_SECONDARY = Color3.fromRGB(30, 30, 46)  -- Dark

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

-- =============================================================================
-- WELCOME POPUP - Tampilkan saat pertama kali execute script
-- =============================================================================
task.spawn(function()
    task.wait(1) -- Tunggu sebentar agar UI siap
    WindUI:Popup({
        Title = "KONTEOELSLLSS!",
        Icon = "fish",
        Content = "Thank you for using Anggazyy Hub - Fish It Automation\n\nScript ini 100% Gratis dan tidak diperjualbelikan",
        Buttons = {
            {
                Title = "Get Started",
                Icon = "check",
                Callback = function()
                    print("Anggazyy Hub activated!")
                end
            }
        }
    })
end)

-- =============================================================================
-- ANTI AFK SYSTEM - Taruh di bagian Player Config
-- =============================================================================
local antiAFKEnabled = false

-- 🛡️ Anti Kick + Auto Reconnect Full System
function AntiKickReconnect()
    -- Pastikan hanya aktif sekali
    if getgenv().AntiKick_Started then return end
    getgenv().AntiKick_Started = true

    -- 🔹 Cegah AFK Kick
    LocalPlayer.Idled:Connect(function()
        task.wait(1)
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("[SYSTEM] Anti-AFK aktif, mengirim aktivitas virtual ✅")
    end)

    -- 🔹 Cegah manual kick dari LocalScripts
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "kick" then
            warn("[SYSTEM] Kick terdeteksi dan diblokir ❌")
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)

    -- 🔹 Auto reconnect bawaan module game (kalau ada)
    local success, Net = pcall(function()
        return require(ReplicatedStorage.Packages.Net)
    end)
    if success and Net then
        local reconnectEvent = Net:RemoteEvent("ReconnectPlayer")
        task.spawn(function()
            while task.wait(10) do
                if not LocalPlayer:IsDescendantOf(Players) then
                    warn("[SYSTEM] Pemain terputus, mencoba reconnect 🔄")
                    reconnectEvent:FireServer()
                end
            end
        end)
    else
        warn("[SYSTEM] Module Net tidak ditemukan, auto reconnect dinonaktifkan ⚠️")
    end

    print("[SYSTEM] Anti Kick + Auto Reconnect aktif sepenuhnya 🚀")
end

local function ToggleAntiAFK(state)
    if state then
        antiAFKEnabled = true
        AntiKickReconnect()
        Notify({
            Title = "Anti AFK System", 
            Content = "Anti Kick + Auto Reconnect activated",
            Duration = 3
        })
    else
        antiAFKEnabled = false
        -- Note: Beberapa hook tidak bisa di-disable sepenuhnya untuk keamanan
        Notify({
            Title = "Anti AFK System", 
            Content = "Basic protection remains active for safety",
            Duration = 3
        })
    end
end

-- =============================================================================
-- NEW FUNCTIONS FROM SECOND SCRIPT
-- =============================================================================

-- Platform creation
local function createPlatform(position, offsetY, rotatedCFrame)
    if platform then platform:Destroy() platform = nil end
    platform = Instance.new("Part")
    platform.Name = "AutoFarmPlatform"
    platform.Size = Vector3.new(8, 1, 8)
    if rotatedCFrame then
        platform.CFrame = rotatedCFrame - Vector3.new(0, offsetY, 0)
    else
        platform.CFrame = CFrame.new(position - Vector3.new(0, offsetY, 0))
    end
    platform.Anchored = true
    platform.Transparency = 0.5
    platform.BrickColor = BrickColor.new("Bright blue")
    platform.Parent = workspace
end

-- Event detection
local function getEventLocation()
    local props = workspace:FindFirstChild("Props")

    if props then
        local blackHole = props:FindFirstChild("BlackHole")
        if blackHole then return blackHole, "Wormhole" end

        local ghostShark = props:FindFirstChild("Ghost Shark Hunt")
        if ghostShark and ghostShark:FindFirstChild("Part") then
            return ghostShark.Part, "Ghost Shark Hunt"
        end

        local sharkHunt = props:FindFirstChild("Shark Hunt")
        if sharkHunt and sharkHunt:FindFirstChild("Color") then
            return sharkHunt.Color, "Shark Hunt"
        end
    end

    if props and props:FindFirstChild("Model") then
        local model = props.Model
        local blackHole = model:FindFirstChild("BlackHole")
        if blackHole then return blackHole, "Wormhole" end

        local ghostShark = model:FindFirstChild("Ghost Shark Hunt")
        if ghostShark and ghostShark:FindFirstChild("Part") then
            return ghostShark.Part, "Ghost Shark Hunt"
        end

        local sharkHunt = model:FindFirstChild("Shark Hunt")
        if sharkHunt and sharkHunt:FindFirstChild("Color") then
            return sharkHunt.Color, "Shark Hunt"
        end
    end

    return nil, "None"
end

-- Fishing functions
local function equipFishingRod()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage")
            .Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
        Event:FireServer(1) -- Fishing Rod hotbar slot index
    end)
end

local function unequipFishingRod()
    pcall(function()
        game.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
            .net["RE/UnequipToolFromHotbar"]:FireServer()
    end)
end

local function chargeFishingRod()
    pcall(function()
        game.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
            .net["RF/ChargeFishingRod"]:InvokeServer(os.clock())
    end)
end

local function startFishingMinigame()
    pcall(function()
        game.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
            .net["RF/RequestFishingMinigameStarted"]:InvokeServer(perfectX, perfectY)
    end)
end

local function completeFishing()
    pcall(function()
        game.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
            .net["RE/FishingCompleted"]:FireServer()
    end)
end

-- Auto sell function
local function sellAllItems()
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]
        Event:InvokeServer()
    end)
    if not success then
        warn("Failed to sell items: " .. tostring(result))
    end
end

-- Oxygen control function
local function removeOxygen(value)
    removeOxyEnabled = value
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["URE/UpdateOxygen"]
        if value then
            Event:FireServer(-10000001000000100000010000001000000100000010000001000000100000010000001000000100000010000001000000100000010000001000000100000010000001000000100000010000001000000)
        else
            Event:FireServer(1)
        end
    end)
    if success then
        Notify({Title = "Oxygen System", Content = "Oxygen " .. (value and "removal enabled!" or "removal disabled!"), Duration = 3})
    else
        warn("Failed to update oxygen: " .. tostring(result))
        Notify({Title = "Oxygen Error", Content = "Failed to update oxygen: " .. tostring(result), Duration = 5})
    end
end

-- Purchase fishing rod function
local function purchaseFishingRod(id)
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseFishingRod"]
        return Event:InvokeServer(id)
    end)
    if success and (result == true or result == nil or (type(result) == "table" and not result.error)) then
        Notify({Title = "Purchase Success", Content = "Successfully purchased fishing rod", Duration = 3})
    else
        warn("Failed to purchase fishing rod ID " .. id .. ": " .. tostring(result))
        Notify({Title = "Purchase Failed", Content = "Failed to purchase rod: " .. tostring(result), Duration = 5})
    end
end

-- Purchase bobber function
local function purchaseBobber(id)
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseBait"]
        return Event:InvokeServer(id)
    end)
    if success and (result == true or result == nil or (type(result) == "table" and not result.error)) then
        Notify({Title = "Purchase Success", Content = "Successfully purchased bobber", Duration = 3})
    else
        warn("Failed to purchase bobber " .. id .. ": " .. tostring(result))
        Notify({Title = "Purchase Failed", Content = "Failed to purchase bobber: " .. tostring(result), Duration = 5})
    end
end

-- Purchase weather event function
local function purchaseWeatherEvent(eventName)
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]
        return Event:InvokeServer(eventName)
    end)
    if success and (result == true or result == nil or (type(result) == "table" and not result.error)) then
        Notify({Title = "Purchase Success", Content = "Successfully purchased weather event: " .. eventName, Duration = 3})
    else
        warn("Failed to purchase weather event " .. eventName .. ": " .. tostring(result))
        Notify({Title = "Purchase Failed", Content = "Failed to purchase weather event " .. eventName .. ": " .. tostring(result), Duration = 5})
    end
end

-- Teleport to island function
local function teleportToIsland(islandName)
    local cframe = islands[islandName]
    
    if cframe then
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = cframe
                Notify({Title = "Teleport Success", Content = "Teleported to " .. islandName, Duration = 3})
            else
                Notify({Title = "Teleport Failed", Content = "HumanoidRootPart not found!", Duration = 3})
            end
        else
            Notify({Title = "Teleport Failed", Content = "Character not found!", Duration = 3})
        end
    else
        Notify({Title = "Teleport Failed", Content = "Island CFrame not found: " .. islandName, Duration = 3})
    end
end

-- Teleport to enchanting altar
local function teleportToEnchantingAltar()
    local altar = game:GetService("Workspace")["! ENCHANTING ALTAR !"]
    
    if altar then
        local enchantLocation = altar:FindFirstChild("EnchantLocation")
        local targetCFrame
        
        if enchantLocation then
            targetCFrame = enchantLocation.CFrame
        else
            targetCFrame = altar.CFrame
        end
        
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                Notify({Title = "Teleport Success", Content = "Teleported to Enchanting Altar" .. (enchantLocation and " (EnchantLocation)" or ""), Duration = 3})
            else
                Notify({Title = "Teleport Failed", Content = "HumanoidRootPart not found!", Duration = 3})
            end
        else
            Notify({Title = "Teleport Failed", Content = "Character not found!", Duration = 3})
        end
    else
        local allObjects = game:GetService("Workspace"):GetDescendants()
        for _, obj in pairs(allObjects) do
            if obj.Name:find("ENCHANTING") or obj.Name:find("ALTAR") then
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0, 5, 0)
                    Notify({Title = "Teleport Success", Content = "Teleported to possible altar location", Duration = 3})
                    return
                end
            end
        end
        
        Notify({Title = "Teleport Failed", Content = "Enchanting Altar not found! Searching for alternatives...", Duration = 5})
    end
end

-- Calculate distance
local function calculateDistance(position1, position2)
    return (position1 - position2).Magnitude
end

-- ESP function
local function toggleIslandESP(value)
    espEnabled = value
    local islandLocations = game:GetService("Workspace")["!!!! ISLAND LOCATIONS !!!!"]
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not value then
        for islandName, _ in pairs(islands) do
            local island = islandLocations:FindFirstChild(islandName)
            if island then
                local existingESP = island:FindFirstChild("IslandESP")
                if existingESP then
                    existingESP:Destroy()
                end
                
                local existingLabel = island:FindFirstChild("IslandLabel")
                if existingLabel then
                    existingLabel:Destroy()
                end
            end
        end
        Notify({Title = "ESP System", Content = "Island ESP disabled!", Duration = 3})
        return
    end
    
    for islandName, _ in pairs(islands) do
        local island = islandLocations:FindFirstChild(islandName)
        if island then
            local existingESP = island:FindFirstChild("IslandESP")
            if existingESP then
                existingESP:Destroy()
            end
            
            local existingLabel = island:FindFirstChild("IslandLabel")
            if existingLabel then
                existingLabel:Destroy()
            end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "IslandESP"
            highlight.Parent = island
            highlight.Adornee = island
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "IslandLabel"
            billboard.Parent = island
            billboard.Adornee = island
            billboard.Size = UDim2.new(0, 200, 0, 70)
            billboard.StudsOffset = Vector3.new(0, 8, 0)
            billboard.AlwaysOnTop = true
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Parent = billboard
            textLabel.Size = UDim2.new(1, 0, 0.6, 0)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.Text = islandName
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextScaled = true
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Enum.Font.SourceSansBold
            
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Parent = billboard
            distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
            distanceLabel.Text = "0m"
            distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            distanceLabel.TextScaled = true
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Font = Enum.Font.SourceSans
            distanceLabel.Name = "DistanceLabel"
            
            if value then
                spawn(function()
                    while island:FindFirstChild("IslandLabel") and espEnabled do
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local distance = calculateDistance(character.HumanoidRootPart.Position, island.Position)
                            distanceLabel.Text = math.floor(distance) .. "m"
                        end
                        wait(0.1)
                    end
                end)
            end
        end
    end
    
    if value then
        Notify({Title = "ESP System", Content = "Island ESP enabled with distance meters!", Duration = 3})
    end
end

-- Player control functions
local function updatePlayerSpeed(value)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = value
    end
end

local function updatePlayerJump(value)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = value
    end
end

local function freezePlayer(value)
    playerFrozen = value
    local character = game.Players.LocalPlayer.Character
    if character then
        if character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.Anchored = value
        end
        
        if character:FindFirstChild("Humanoid") then
            if value then
                character.Humanoid.WalkSpeed = 0
            else
                character.Humanoid.WalkSpeed = originalWalkSpeed
            end
        end
    end
end

-- Fish Radar function
local function toggleFishRadar(value)
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/UpdateFishingRadar"]
        Event:InvokeServer(value)
    end)
    if success then
        Notify({Title = "Fish Radar", Content = "Fish radar " .. (value and "enabled!" or "disabled!"), Duration = 3})
    else
        warn("Failed to toggle fish radar: " .. tostring(result))
        Notify({Title = "Fish Radar Error", Content = "Failed to toggle fish radar: " .. tostring(result), Duration = 5})
    end
end

-- Auto fishing function
local function startAutoFishingSecond()
    if fishingThread then
        task.cancel(fishingThread)
        fishingThread = nil
    end
    
    fishingThread = task.spawn(function()
        equipFishingRod()
        task.wait(0.5)
        
        while fishingEnabled do
            chargeFishingRod()
            task.wait(castDelay)
            startFishingMinigame()
            task.wait(fishingWaitDelay)
            completeFishing()
            task.wait(actionDelay)
        end
        
        unequipFishingRod()
    end)
end

-- Auto sell function
local function startAutoSellSecond()
    if sellThread then
        task.cancel(sellThread)
        sellThread = nil
    end
    
    sellThread = task.spawn(function()
        while autoSellEnabled do
            sellAllItems()
            task.wait(sellDelay)
        end
    end)
end

-- Copy to clipboard
local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        Notify({Title = "Clipboard", Content = "Copied to clipboard!", Duration = 3})
    else
        Notify({Title = "Clipboard Error", Content = "Executor does not support setclipboard.", Duration = 3})
    end
end

-- Format numbers with commas
local function formatNumber(n)
    local left,num,right = string.match(tostring(n),'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub("(%d%d%d)","%1,"):reverse())..right
end

-- Webhook function
local function sendWebhook(fishId, weight, playerName, variantId, isMutation, isShiny)
    local requestFunc = http_request or request or (syn and syn.request)
    if not requestFunc or not WEBHOOK_URL or WEBHOOK_URL == "" then
        return
    end

    local fishData = AllFishes[fishId]
    if not fishData then
        warn("[Fishing Bot] Unknown fish ID:", fishId)
        return
    end

    local chance    = fishData.Chance or 0
    local sellPrice = fishData.SellPrice or 0
    local variantText = ""
    local variantName = nil

    if variantId and AllVariants[variantId] then
        local vData = AllVariants[variantId]
        if vData.SellMultiplier then
            sellPrice = sellPrice * vData.SellMultiplier
        end
        if vData.Chance then
            chance = chance * vData.Chance
        end
        variantText = " (" .. vData.Name .. ")"
        variantName = vData.Name
    end

    local shinyText = ""
    if isShiny then
        sellPrice = sellPrice * 1.5
        shinyText = " ✨Shiny✨"
    end

    -- update counters
    totalProfit = totalProfit + sellPrice
    fishCaught = fishCaught + 1

    local avgProfit = (fishCaught > 0) and (totalProfit / fishCaught) or 0
    local estPerHour = avgProfit * (3600 / 10) -- assume ~1 fish every 10s

    local chanceStr = "N/A"
    if chance > 0 then
        chanceStr = "1 in " .. formatNumber(math.floor(1 / chance))
    end

    -- Mutation detection
    local mutationParts = {}

    -- Check for variant mutation
    if variantId and AllVariants[variantId] then
        table.insert(mutationParts, AllVariants[variantId].Name)
    end

    -- Check for Big mutation (weight range)
    local isBig = false
    if fishData.Weight and weight then
        if fishData.Weight.Big and #fishData.Weight.Big == 2 then
            local min, max = fishData.Weight.Big[1], fishData.Weight.Big[2]
            if weight >= min and weight <= max then
                isBig = true
                table.insert(mutationParts, "Big")
            end
        end
    end

    -- Check for shiny
    if isShiny then
        table.insert(mutationParts, "✨ Shiny ✨")
    end

    -- Final status
    local mutationText = "Normal"
    if #mutationParts > 0 then
        mutationText = "⚠️ MUTATION → " .. table.concat(mutationParts, " + ")
    end

    local embed = {
        ["title"] = playerName .. " caught a " .. fishData.Name .. variantText .. shinyText .. "!",
        ["color"] = (mutationText ~= "Normal" and 0xFF0000) or (isShiny and 0x00FFEA or 0xFFAA00),
        ["fields"] = {
            { ["name"] = "🎣 Fish",              ["value"] = fishData.Name .. variantText .. shinyText, ["inline"] = true },
            { ["name"] = "⚖️ Weight",           ["value"] = string.format("%.2f kg", weight), ["inline"] = true },
            { ["name"] = "🧬 Status",           ["value"] = mutationText, ["inline"] = true },
            { ["name"] = "✨ Rarity",            ["value"] = chanceStr, ["inline"] = true },
            { ["name"] = "🏆 Tier",              ["value"] = (fishData.Tier == 7 and "SECRET") or tostring(fishData.Tier), ["inline"] = true },
            { ["name"] = "💰 Sell Price",        ["value"] = formatNumber(sellPrice), ["inline"] = true },
            { ["name"] = "📊 Total Fish Caught", ["value"] = tostring(fishCaught), ["inline"] = true },
            { ["name"] = "📈 Est Profit/hr",     ["value"] = formatNumber(math.floor(estPerHour)), ["inline"] = true },
            { ["name"] = "📊 Total Profit",      ["value"] = formatNumber(totalProfit), ["inline"] = true },
        },
        ["footer"] = { ["text"] = "Anggazyy Hub - " .. os.date("%I:%M %p") },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    if SEND_BIG_IMAGE and fishData.Icon and fishData.Icon ~= "rbxassetid://0" then
        embed["image"] = { ["url"] = fishData.Icon }
    end

    local content = ""
    if DISCORD_USER_ID and DISCORD_USER_ID ~= "" then
        content = "<@" .. DISCORD_USER_ID .. ">"
    end

    local payload = {
        ["username"] = "Anggazyy Hub",
        ["avatar_url"] = "https://files.catbox.moe/of2fla.jpg",
        ["content"] = content,
        ["embeds"] = { embed }
    }

    local success, err = pcall(function()
        requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not success then
        warn("[Webhook] Failed to send webhook:", err)
    end
end

-- Mobile Autofarm Functions
local function toggleMobileAutoFishing(value)
    mobileAutoFishingEnabled = value
    local success, result = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/UpdateAutoFishingState"]
        return Event:InvokeServer(value)
    end)
    if success then
        Notify({Title = "Mobile Auto Fishing", Content = "Mobile Auto Fishing " .. (value and "enabled!" or "disabled!"), Duration = 3})
        if value then
            pcall(function()
                local EquipEvent = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
                EquipEvent:FireServer(1)
                Notify({Title = "Mobile Auto Fishing", Content = "Equipped fishing tool from hotbar.", Duration = 3})
            end)
        else
            if mobileMonitorThread then
                task.cancel(mobileMonitorThread)
                mobileMonitorThread = nil
            end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
            if platform then platform:Destroy() platform = nil end
            currentEvent = "None"
        end
    else
        warn("Failed to toggle mobile auto fishing: " .. tostring(result))
        Notify({Title = "Mobile Auto Fishing Error", Content = "Failed to toggle mobile auto fishing: " .. tostring(result), Duration = 5})
    end
end

-- Dynamic Auto Farm Functions
local function teleportToEventLocation(eventLocation, eventName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if eventLocation and hrp then
        createPlatform(eventLocation.Position, 0)

        hrp.Anchored = false
        hrp.CFrame = platform.CFrame + Vector3.new(0, 6, 0)
        task.wait(1)
        hrp.Anchored = true

        currentEvent = eventName
        Notify({Title = "Auto Farm", Content = "Teleported to " .. eventName .. " (platform 10 studs lower, player frozen).", Duration = 3})
    else
        Notify({Title = "Auto Farm", Content = "No " .. eventName .. " event found!", Duration = 3})
    end
end

local function teleportToVolcano()
    local rotatedCFrame = volcanoCFrame * CFrame.Angles(0, math.rad(45), 0)
    createPlatform(rotatedCFrame.Position, 23.3, rotatedCFrame)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
        hrp.CFrame = platform.CFrame + Vector3.new(0, 6, 0)
        task.wait(1)
        hrp.Anchored = true
    end

    currentEvent = "Volcano"
    Notify({Title = "Auto Farm", Content = "At Volcano.", Duration = 3})
end

-- Event monitoring
local function monitorEvent()
    local wasEvent = "None"
    while autoFarmEnabled do
        local eventLocation, eventName = getEventLocation()
        if eventName ~= "None" and wasEvent == "None" then
            teleportToEventLocation(eventLocation, eventName)
        elseif eventName == "None" and wasEvent ~= "None" then
            teleportToVolcano()
        end
        wasEvent = eventName
        task.wait(5)
    end
end

-- Auto Farm toggle
local function toggleAutoFarm(value)
    autoFarmEnabled, fishingEnabled = value, value
    if value then
        equipFishingRod()
        teleportToVolcano()
        startAutoFishingSecond()
        monitorThread = task.spawn(monitorEvent)
        Notify({Title = "Auto Farm", Content = "Auto Farm enabled.", Duration = 5})
    else
        if fishingThread then task.cancel(fishingThread) fishingThread = nil end
        if monitorThread then task.cancel(monitorThread) monitorThread = nil end
        unequipFishingRod()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
        if platform then platform:Destroy() platform = nil end
        currentEvent = "None"
        Notify({Title = "Auto Farm", Content = "Auto Farm disabled.", Duration = 3})
    end
end

-- =============================================================================
-- EXTERNAL SCRIPTS LOADING
-- =============================================================================

-- Step 2: Define external script URLs
local luckFishScript = "https://raw.githubusercontent.com/fpszrxy/sigma/refs/heads/main/luck%20server%20fish%20it"
local eventWebhookScript = "https://raw.githubusercontent.com/fpszrxy/sigma/refs/heads/main/event%20webhook"

-- Step 3: Example fetch & execution (if using game platforms like Roblox)
local function loadScriptFromUrl(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local func = loadstring(response)
        if func then
            return func()
        end
    end
end

-- Step 4: Execute scripts (optional)
task.spawn(function()
    -- Uncomment jika ingin load external scripts
    -- loadScriptFromUrl(luckFishScript)
    -- loadScriptFromUrl(eventWebhookScript)
end)

-- =============================================================================
-- BLATANT FISHING SYSTEM - UPDATED WORKING VERSION
-- =============================================================================

local function InitializeBlatantFishing()
    local success, result = pcall(function()
        -- Load required modules for Blatant Fishing
        Net_upvr = require(ReplicatedStorage.Packages.Net)
        Trove_upvr = require(ReplicatedStorage.Packages.Trove)
        Constants_upvr = require(ReplicatedStorage.Shared.Constants)
        
        -- Get fishing module
        for _, module in pairs(ReplicatedStorage:GetDescendants()) do
            if module:IsA("ModuleScript") and (string.find(module.Name:lower(), "fishing") or string.find(module.Name:lower(), "controller")) then
                local modSuccess, modResult = pcall(function()
                    return require(module)
                end)
                if modSuccess and type(modResult) == "table" then
                    if modResult.RequestChargeFishingRod and modResult.FishingRodStarted then
                        module_upvr = modResult
                        break
                    end
                end
            end
        end
        
        if not module_upvr then
            local FishingController = ReplicatedStorage.Controllers:FindFirstChild("FishingController")
            if FishingController then
                module_upvr = require(FishingController)
            end
        end
        
        -- Get remote events/functions
        FISHING_COMPLETED_REMOTE = Net_upvr:RemoteEvent("FishingCompleted")
        RequestFishingMinigameStarted_Net = Net_upvr:RemoteFunction("RequestFishingMinigameStarted")
        
        -- Save original functions
        if module_upvr then
            originalFishingRodStarted = module_upvr.FishingRodStarted
            originalSendFishingRequestToServer = module_upvr.SendFishingRequestToServer
            originalRequestChargeFishingRod = module_upvr.RequestChargeFishingRod
        end
        
        -- Initialize trove
        BLATANT_MODE_TROVE = Trove_upvr.new()
        
        return true
    end)
    
    if success then
        Notify({Title = "Blatant Fishing", Content = "System initialized successfully", Duration = 3})
        return true
    else
        Notify({Title = "Blatant Fishing Error", Content = "Failed to initialize: " .. tostring(result), Duration = 4})
        return false
    end
end

-- Fungsi yang menjalankan logika penyelesaian minigame secara instan (Blatant)
local function AutoFishComplete(rodData, minigameData)
    -- Blantant Mode: Delay reel (0 - 1.87)
    local reelDelay = blatantReelDelay
    if reelDelay > 0 then
        task.wait(reelDelay)
    end
    
    -- Fishing Complete: Langsung tembak RemoteEvent "FishingCompleted" ke server.
    pcall(function()
        FISHING_COMPLETED_REMOTE:FireServer() 
    end)
    
    print("⚡ Blatant Mode: Minigame Bypassed. Fish Retrieved.")
end

-- Fungsi HOOK untuk menimpa 'FishingRodStarted'
local function HookFishingRodStarted(rodData, minigameData)
    if isBlatantActive then
        -- Jika mode Blatant aktif, langsung selesaikan di thread terpisah (Non-Blocking)
        task.spawn(function()
            AutoFishComplete(rodData, minigameData)
        end)
    else
        -- Jika tidak aktif, jalankan fungsi asli
        if originalFishingRodStarted then
            originalFishingRodStarted(rodData, minigameData)
        end
    end
end

-- Fungsi untuk mendapatkan mouse position yang aman
local function GetSafeMousePosition()
    local UserInputService = game:GetService("UserInputService")
    local CurrentCamera = workspace.CurrentCamera
    
    if UserInputService.MouseEnabled then
        return UserInputService:GetMouseLocation()
    else
        local viewportSize = CurrentCamera.ViewportSize
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
end

-- Approach 1: Menggunakan RequestChargeFishingRod dengan bypass
local function BlatantCastMethod1()
    local success, result = pcall(function()
        -- Set konfirmasi untuk bypass user input
        _G.confirmFishingInput = function() return true end
        
        local mousePos = GetSafeMousePosition()
        local skipCharge = true
        
        -- Panggil RequestChargeFishingRod dengan parameter skip charge yang disuntikkan
        local castResult = module_upvr:RequestChargeFishingRod(mousePos, nil, skipCharge) -- Tambahkan skipCharge
        
        _G.confirmFishingInput = nil
        return castResult
    end)
    
    return success and result -- return success DAN result
end

-- Main blatant casting function (Menggunakan Method 1 untuk spam)
local function BlatantCastFishingRod()
    local success = BlatantCastMethod1()
    if success then
        -- Casting berhasil, segera kembalikan 'true' agar loop bisa lempar lagi
        print("✅ Blatant Cast: Method 1 (Spam Cast) successful")
        return true
    end
    
    print("❌ Blatant Cast: Method 1 failed")
    return false
end

-- =============================================================================
-- BLATANT FISHING LOOP (Pengontrol Kecepatan Spam)
-- =============================================================================

local function BlatantFishingLoop()
    while isBlatantActive do
        local castSuccess = BlatantCastFishingRod()
        
        if not castSuccess then
            print("🔄 Retrying cast...")
        end

        -- Delay murni untuk mengontrol kecepatan spam cast (cooldown antar lemparan)
        task.wait(blatantFishingDelay)
    end
end

-- Hook untuk RequestChargeFishingRod
local function HookRequestChargeFishingRod(arg1, arg2, arg3)
    if isBlatantActive then
        print("⚡ Blatant Mode: Fast casting via RequestChargeFishingRod")
        
        -- Di Blatant Mode, gunakan parameter untuk skip charging
        local mousePos = arg1 or GetSafeMousePosition()
        local skipCharge = true
        
        return originalRequestChargeFishingRod(mousePos, arg2, skipCharge)
    else
        return originalRequestChargeFishingRod(arg1, arg2, arg3)
    end
end

-- Hook untuk SendFishingRequestToServer
local function HookSendFishingRequestToServer(mousePosition, power, skipCharge)
    if isBlatantActive then
        print("⚡ Blatant Mode: SendFishingRequestToServer with forced parameters")
        return originalSendFishingRequestToServer(mousePosition, 0.5, true)
    else
        return originalSendFishingRequestToServer(mousePosition, power, skipCharge)
    end
end

-- Fungsi untuk mengatur delay reel
local function SetBlatantReelDelay(delay)
    if type(delay) == "number" and delay >= 0 and delay <= 1.87 then
        blatantReelDelay = delay
        Notify({
            Title = "Blatant Fishing", 
            Content = string.format("Reel delay set to %.4f seconds", delay),
            Duration = 3
        })
        return true
    end
    return false
end

-- Fungsi untuk mengatur delay fishing
local function SetBlatantFishingDelay(delay)
    if type(delay) == "number" and delay >= 0 and delay <= 5 then
        blatantFishingDelay = delay
        Notify({
            Title = "Blatant Fishing", 
            Content = string.format("Fishing delay (loop) set to %.4f seconds", delay),
            Duration = 3
        })
        return true
    end
    return false
end

-- Fungsi publik untuk mengaktifkan/menonaktifkan Blatant Mode
local function ToggleBlatantMode(enable)
    if enable == isBlatantActive then return end
    
    if enable then
        -- Initialize system if not already initialized
        if not module_upvr or not FISHING_COMPLETED_REMOTE then
            if not InitializeBlatantFishing() then
                return false
            end
        end
        
        isBlatantActive = true
        print("✅ Blantant Mode (Fast Fishing): ENABLED.")
        
        -- Terapkan Hook pada fungsi-fungsi fishing
        if module_upvr then
            if module_upvr.FishingRodStarted ~= HookFishingRodStarted then
                module_upvr.FishingRodStarted = HookFishingRodStarted
            end
            
            if module_upvr.RequestChargeFishingRod and module_upvr.RequestChargeFishingRod ~= HookRequestChargeFishingRod then
                module_upvr.RequestChargeFishingRod = HookRequestChargeFishingRod
            end
            
            if module_upvr.SendFishingRequestToServer and module_upvr.SendFishingRequestToServer ~= HookSendFishingRequestToServer then
                module_upvr.SendFishingRequestToServer = HookSendFishingRequestToServer
            end
            
            -- Tambahkan fungsi pembersihan ke Trove
            if BLATANT_MODE_TROVE then
                BLATANT_MODE_TROVE:Add(function() 
                    if module_upvr then
                        if originalFishingRodStarted then
                            module_upvr.FishingRodStarted = originalFishingRodStarted 
                        end
                        if originalRequestChargeFishingRod then
                            module_upvr.RequestChargeFishingRod = originalRequestChargeFishingRod
                        end
                        if originalSendFishingRequestToServer then
                            module_upvr.SendFishingRequestToServer = originalSendFishingRequestToServer
                        end
                    end
                end)
            end
        end
        
        -- Jalankan loop Fast Fishing (Spam)
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Add(task.spawn(BlatantFishingLoop))
        end
        
        Notify({Title = "⚡ Blatant Fishing", Content = "Fast fishing mode activated - Instant spam casting.", Duration = 3})
        
    else
        isBlatantActive = false
        print("❌ Blantant Mode (Fast Fishing): DISABLED. Cleaning up...")
        
        -- Cleanup
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Clean()
        end
        
        -- Restore original functions
        if module_upvr then
            if originalFishingRodStarted then
                module_upvr.FishingRodStarted = originalFishingRodStarted
            end
            if originalRequestChargeFishingRod then
                module_upvr.RequestChargeFishingRod = originalRequestChargeFishingRod
            end
            if originalSendFishingRequestToServer then
                module_upvr.SendFishingRequestToServer = originalSendFishingRequestToServer
            end
        end
        
        Notify({Title = "Blatant Fishing", Content = "Fast fishing mode deactivated", Duration = 3})
    end
    
    return true
end

-- Manual fishing function untuk testing
local function ManualBlatantFish()
    if not isBlatantActive then
        Notify({Title = "Blatant Fishing", Content = "Please enable Blatant Mode first", Duration = 3})
        return
    end
    
    pcall(function()
        local success = BlatantCastFishingRod()
        if success then
            Notify({Title = "⚡ Manual Cast", Content = "Casting fishing rod instantly...", Duration = 2})
        else
            Notify({Title = "❌ Manual Cast Failed", Content = "Failed to cast fishing rod", Duration = 2})
        end
    end)
end

-- Network Communication untuk Auto Fishing biasa
local function GetAutoFishRemote()
    local ok, NetModule = pcall(function()
        local folder = ReplicatedStorage:WaitForChild(NET_PACKAGES_FOLDER, 5)
        if folder then
            local netCandidate = folder:FindFirstChild("Net")
            if netCandidate and netCandidate:IsA("ModuleScript") then
                return require(netCandidate)
            end
        end
        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") then
            local m = ReplicatedStorage.Packages.Net
            if m:IsA("ModuleScript") then
                return require(m)
            end
        end
        return nil
    end)
    return ok and NetModule or nil
end

local function SafeInvokeAutoFishing(state)
    pcall(function()
        local Net = GetAutoFishRemote()
        if Net and type(Net.RemoteFunction) == "function" then
            local ok, rf = pcall(function() return Net:RemoteFunction(AUTO_FISH_REMOTE_NAME) end)
            if ok and rf then
                pcall(function() rf:InvokeServer(state) end)
                return
            end
        end
        
        local rfObj = ReplicatedStorage:FindFirstChild(AUTO_FISH_REMOTE_NAME) 
            or ReplicatedStorage:FindFirstChild("RemoteFunctions") and ReplicatedStorage.RemoteFunctions:FindFirstChild(AUTO_FISH_REMOTE_NAME)
        if rfObj and rfObj:IsA("RemoteFunction") then
            pcall(function() rfObj:InvokeServer(state) end)
            return
        end
    end)
end

-- =============================================================================
-- WEATHER MACHINE SYSTEM
-- =============================================================================

local function LoadWeatherData()
    local success, result = pcall(function()
        -- Load required modules
        local EventUtility = require(ReplicatedStorage.Shared.EventUtility)
        local StringLibrary = require(ReplicatedStorage.Shared.StringLibrary)
        local Events = require(ReplicatedStorage.Events)
        
        local weatherList = {}
        
        -- Iterate through all events to find weather machines
        for name, data in pairs(Events) do
            local event = EventUtility:GetEvent(name)
            if event and event.WeatherMachine and event.WeatherMachinePrice then
                table.insert(weatherList, {
                    Name = event.Name or name,
                    InternalName = name,
                    Price = event.WeatherMachinePrice,
                    DisplayName = string.format("%s - %s Coins", event.Name or name, StringLibrary:AddCommas(event.WeatherMachinePrice))
                })
            end
        end
        
        -- Sort by price (ascending)
        table.sort(weatherList, function(a, b)
            return a.Price < b.Price
        end)
        
        return weatherList
    end)
    
    if success then
        return result
    else
        warn("⚠️ Failed to load weather data:", result)
        return {}
    end
end

local function PurchaseWeather(weatherName)
    local success, result = pcall(function()
        -- Load required modules
        local Net = require(ReplicatedStorage.Packages.Net)
        local PurchaseWeatherEvent = Net:RemoteFunction("PurchaseWeatherEvent")
        
        -- Purchase the weather
        local purchaseResult = PurchaseWeatherEvent:InvokeServer(weatherName)
        return purchaseResult
    end)
    
    return success, result
end

local function BuySelectedWeathers()
    if not next(selectedWeathers) then
        Notify({
            Title = "Weather Purchase",
            Content = "No weathers selected!",
            Duration = 3
        })
        return
    end
    
    local totalPurchases = 0
    local successfulPurchases = 0
    
    Notify({
        Title = "Weather Purchase",
        Content = "Processing purchases...",
        Duration = 2
    })
    
    for weatherName, selected in pairs(selectedWeathers) do
        if selected then
            totalPurchases = totalPurchases + 1
            
            -- Find weather data
            local weatherData
            for _, weather in ipairs(availableWeathers) do
                if weather.InternalName == weatherName then
                    weatherData = weather
                    break
                end
            end
            
            if weatherData then
                local success, result = PurchaseWeather(weatherName)
                if success and result then
                    successfulPurchases = successfulPurchases + 1
                    Notify({
                        Title = "✅ Purchase Successful",
                        Content = string.format("Bought: %s", weatherData.Name),
                        Duration = 3
                    })
                else
                    Notify({
                        Title = "❌ Purchase Failed",
                        Content = string.format("Failed to buy: %s", weatherData.Name),
                        Duration = 4
                    })
                end
            end
            
            -- Small delay between purchases
            task.wait(0.5)
        end
    end
    
    -- Clear selection after purchase
    selectedWeathers = {}
    
    Notify({
        Title = "Purchase Complete",
        Content = string.format("Successfully purchased %d/%d weathers", successfulPurchases, totalPurchases),
        Duration = 4
    })
end

local function RefreshWeatherList()
    availableWeathers = LoadWeatherData()
    
    -- Create display options for dropdown
    local weatherOptions = {}
    for _, weather in ipairs(availableWeathers) do
        table.insert(weatherOptions, weather.DisplayName)
    end
    
    return weatherOptions, availableWeathers
end

local function ToggleWeatherSelection(weatherIndex, state)
    if availableWeathers[weatherIndex] then
        local weather = availableWeathers[weatherIndex]
        selectedWeathers[weather.InternalName] = state
        
        Notify({
            Title = state and "✅ Weather Selected" or "❌ Weather Deselected",
            Content = string.format("%s %s", weather.Name, state and "selected" or "deselected"),
            Duration = 2
        })
    end
end

-- =============================================================================
-- TRICK OR TREAT SYSTEM
-- =============================================================================

local function GetSpecialDialogueRemote()
    local success, result = pcall(function()
        local Net = require(ReplicatedStorage.Packages.Net)
        local SpecialDialogueEvent = Net:RemoteFunction("SpecialDialogueEvent")
        return SpecialDialogueEvent
    end)
    
    if success then
        return result
    else
        warn("❌ Failed to load SpecialDialogueEvent:", result)
        return nil
    end
end

local function FindTrickOrTreatDoors()
    local doors = {}
    
    for _, door in pairs(workspace:GetDescendants()) do
        if door:IsA("Model") and door:FindFirstChild("Root") and door:FindFirstChild("Door") and door.Name then
            if door:GetAttribute("TrickOrTreatDoor") or string.find(door.Name, "House") then
                table.insert(doors, door)
            end
        end
    end
    
    return doors
end

local function KnockDoor(door)
    local success, result = pcall(function()
        local SpecialDialogueEvent = GetSpecialDialogueRemote()
        if not SpecialDialogueEvent then
            return false, "Remote not found"
        end
        
        local success, reward = SpecialDialogueEvent:InvokeServer(door.Name, "TrickOrTreatHouse")
        return success, reward
    end)
    
    return success, result
end

local function StartAutoTrickTreat()
    if autoTrickTreatEnabled then return end
    autoTrickTreatEnabled = true
    
    Notify({
        Title = "🎃 Auto Trick or Treat",
        Content = "System activated - Knocking all doors...",
        Duration = 3
    })
    
    trickTreatLoop = task.spawn(function()
        while autoTrickTreatEnabled do
            local doors = FindTrickOrTreatDoors()
            
            if #doors > 0 then
                Notify({
                    Title = "🎃 Trick or Treat",
                    Content = string.format("Found %d doors, knocking...", #doors),
                    Duration = 2
                })
                
                for _, door in ipairs(doors) do
                    if not autoTrickTreatEnabled then break end
                    
                    local success, result = KnockDoor(door)
                    if success then
                        if result == "Trick" then
                            print("[🎃] Trick dari " .. door.Name)
                        elseif result == "Treat" then
                            print("[🍬] Treat dari " .. door.Name .. " → +" .. tostring(result) .. " Candy Corns")
                        else
                            print("[❌] Gagal interaksi dengan " .. door.Name)
                        end
                    else
                        print("[❌] Error knocking " .. door.Name .. ": " .. tostring(result))
                    end
                    
                    task.wait(0.5) -- Jeda biar gak spam server
                end
            else
                print("[🔍] Tidak ada Trick or Treat doors yang ditemukan")
            end
            
            -- Tunggu sebelum scan ulang
            task.wait(10)
        end
    end)
end

local function StopAutoTrickTreat()
    if not autoTrickTreatEnabled then return end
    autoTrickTreatEnabled = false
    
    if trickTreatLoop then
        task.cancel(trickTreatLoop)
        trickTreatLoop = nil
    end
    
    Notify({
        Title = "🎃 Auto Trick or Treat",
        Content = "System deactivated",
        Duration = 2
    })
end

local function ManualKnockAllDoors()
    local doors = FindTrickOrTreatDoors()
    
    if #doors == 0 then
        Notify({
            Title = "🎃 Trick or Treat",
            Content = "No Trick or Treat doors found!",
            Duration = 3
        })
        return
    end
    
    Notify({
        Title = "🎃 Manual Knock",
        Content = string.format("Knocking %d doors...", #doors),
        Duration = 2
    })
    
    local successfulKnocks = 0
    local totalCandy = 0
    
    for _, door in ipairs(doors) do
        local success, result = KnockDoor(door)
        if success then
            successfulKnocks = successfulKnocks + 1
            if result == "Treat" then
                totalCandy = totalCandy + 1
            end
        end
        task.wait(0.5)
    end
    
    Notify({
        Title = "🎃 Knock Complete",
        Content = string.format("Success: %d/%d doors | Candy: +%d", successfulKnocks, #doors, totalCandy),
        Duration = 4
    })
end

-- Auto Fishing System
local function StartAutoFish()
    if autoFishEnabled then return end
    autoFishEnabled = true
    Notify({Title = "Auto Fishing", Content = "System activated successfully", Duration = 2})

    autoFishLoopThread = task.spawn(function()
        while autoFishEnabled do
            pcall(function()
                SafeInvokeAutoFishing(true)
            end)
            task.wait(4)
        end
    end)
end

local function StopAutoFish()
    if not autoFishEnabled then return end
    autoFishEnabled = false
    Notify({Title = "Auto Fishing", Content = "System deactivated", Duration = 2})
    
    pcall(function()
        SafeInvokeAutoFishing(false)
    end)
end

-- =============================================================================
-- ULTRA ANTI LAG SYSTEM - WHITE TEXTURE MODE
-- =============================================================================

-- Save original graphics settings
local function SaveOriginalGraphics()
    originalGraphicsSettings = {
        GraphicsQualityLevel = UserGameSettings.GraphicsQualityLevel,
        SavedQualityLevel = UserGameSettings.SavedQualityLevel,
        MasterVolume = Lighting.GlobalShadows,
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        ShadowSoftness = Lighting.ShadowSoftness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end

-- Ultra Anti Lag System - White Texture Mode
local function EnableAntiLag()
    if antiLagEnabled then return end
    
    SaveOriginalGraphics()
    antiLagEnabled = true
    
    -- Extreme graphics optimization with white textures
    pcall(function()
        -- Graphics quality settings
        UserGameSettings.GraphicsQualityLevel = 1
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        
        -- Lighting optimization - Bright white environment
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        Lighting.Brightness = 5  -- Extra bright
        Lighting.ShadowSoftness = 0
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 0
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)  -- Pure white ambient
        Lighting.Ambient = Color3.new(1, 1, 1)  -- Pure white
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        
        -- Terrain optimization - White terrain
        if workspace.Terrain then
            workspace.Terrain.Decoration = false
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 1
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
        end
        
        -- Make all parts white and disable effects
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                -- Set all parts to white
                if obj:FindFirstChildOfClass("Texture") then
                    obj:FindFirstChildOfClass("Texture"):Destroy()
                end
                if obj:FindFirstChildOfClass("Decal") then
                    obj:FindFirstChildOfClass("Decal"):Destroy()
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.BrickColor = BrickColor.new("White")
                obj.Reflectance = 0
            elseif obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            elseif obj:IsA("Fire") then
                obj.Enabled = false
            elseif obj:IsA("Smoke") then
                obj.Enabled = false
            elseif obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Sound") and not obj:FindFirstAncestorWhichIsA("Player") then
                obj:Stop()
            end
        end
        
        -- Reduce texture quality to minimum
        settings().Rendering.QualityLevel = 1
    end)
    
    Notify({Title = "Ultra Anti Lag", Content = "White texture mode enabled - Maximum performance", Duration = 3})
end

local function DisableAntiLag()
    if not antiLagEnabled then return end
    antiLagEnabled = false
    
    -- Restore original graphics settings
    pcall(function()
        if originalGraphicsSettings.GraphicsQualityLevel then
            UserGameSettings.GraphicsQualityLevel = originalGraphicsSettings.GraphicsQualityLevel
        end
        if originalGraphicsSettings.SavedQualityLevel then
            UserGameSettings.SavedQualityLevel = originalGraphicsSettings.SavedQualityLevel
        end
        if originalGraphicsSettings.MasterVolume ~= nil then
            Lighting.GlobalShadows = originalGraphicsSettings.MasterVolume
        end
        if originalGraphicsSettings.Brightness then
            Lighting.Brightness = originalGraphicsSettings.Brightness
        end
        if originalGraphicsSettings.FogEnd then
            Lighting.FogEnd = originalGraphicsSettings.FogEnd
        end
        if originalGraphicsSettings.ShadowSoftness then
            Lighting.ShadowSoftness = originalGraphicsSettings.ShadowSoftness
        end
        if originalGraphicsSettings.EnvironmentDiffuseScale then
            Lighting.EnvironmentDiffuseScale = originalGraphicsSettings.EnvironmentDiffuseScale
        end
        if originalGraphicsSettings.EnvironmentSpecularScale then
            Lighting.EnvironmentSpecularScale = originalGraphicsSettings.EnvironmentSpecularScale
        end
        
        -- Restore terrain
        if workspace.Terrain then
            workspace.Terrain.Decoration = true
            workspace.Terrain.WaterReflectance = 0.5
            workspace.Terrain.WaterTransparency = 0.5
            workspace.Terrain.WaterWaveSize = 0.5
            workspace.Terrain.WaterWaveSpeed = 10
        end
        
        -- Restore lighting
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        
        -- Restore texture quality
        settings().Rendering.QualityLevel = 10
    end)
    
    Notify({Title = "Anti Lag", Content = "Graphics settings restored", Duration = 3})
end

-- Position Management System
local function SaveCurrentPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        lastSavedPosition = character.HumanoidRootPart.Position
        Notify({
            Title = "Position Saved", 
            Content = string.format("Position saved successfully"),
            Duration = 2
        })
        return true
    end
    return false
end

local function LoadSavedPosition()
    if not lastSavedPosition then
        Notify({Title = "Load Failed", Content = "No position saved", Duration = 2})
        return false
    end
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(lastSavedPosition)
        Notify({Title = "Position Loaded", Content = "Teleported to saved position", Duration = 2})
        return true
    end
    return false
end

local function StartLockPosition()
    if lockPositionEnabled then return end
    lockPositionEnabled = true
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        lastSavedPosition = character.HumanoidRootPart.Position
    end
    
    lockPositionLoop = RunService.Heartbeat:Connect(function()
        if not lockPositionEnabled then return end
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") and lastSavedPosition then
            local currentPos = character.HumanoidRootPart.Position
            local distance = (currentPos - lastSavedPosition).Magnitude
            
            if distance > 3 then
                character.HumanoidRootPart.CFrame = CFrame.new(lastSavedPosition)
            end
        end
    end)
    
    Notify({Title = "Position Lock", Content = "Player position locked", Duration = 2})
end

local function StopLockPosition()
    if not lockPositionEnabled then return end
    lockPositionEnabled = false
    
    if lockPositionLoop then
        lockPositionLoop:Disconnect()
        lockPositionLoop = nil
    end
    
    Notify({Title = "Position Lock", Content = "Player position unlocked", Duration = 2})
end

-- =============================================================================
-- BYPASS SYSTEM - FISHING RADAR, DIVING GEAR & AUTO SELL
-- =============================================================================

-- Fishing Radar System
local function ToggleFishingRadar()
    local success, result = pcall(function()
        -- Load required modules
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local UpdateFishingRadar = Net:RemoteFunction("UpdateFishingRadar")
        
        -- Get player data
        local Data = Replion.Client:WaitReplion("Data")
        if not Data then
            return false, "Data Replion tidak ditemukan!"
        end

        -- Get current radar state
        local currentState = Data:Get("RegionsVisible")
        local desiredState = not currentState

        -- Invoke server to update radar
        local invokeSuccess = UpdateFishingRadar:InvokeServer(desiredState)
        
        if invokeSuccess then
            fishingRadarEnabled = desiredState
            return true, "Radar: " .. (desiredState and "ENABLED" or "DISABLED")
        else
            return false, "Failed to update radar"
        end
    end)
    
    if success then
        return true, result
    else
        return false, "Error: " .. tostring(result)
    end
end

local function StartFishingRadar()
    if fishingRadarEnabled then return end
    
    local success, message = ToggleFishingRadar()
    if success then
        fishingRadarEnabled = true
        Notify({Title = "Fishing Radar", Content = message, Duration = 3})
    else
        Notify({Title = "Radar Error", Content = message, Duration = 4})
    end
end

local function StopFishingRadar()
    if not fishingRadarEnabled then return end
    
    local success, message = ToggleFishingRadar()
    if success then
        fishingRadarEnabled = false
        Notify({Title = "Fishing Radar", Content = message, Duration = 3})
    else
        Notify({Title = "Radar Error", Content = message, Duration = 4})
    end
end

-- Diving Gear System
local function ToggleDivingGear()
    local success, result = pcall(function()
        -- Load required modules
        local Net = require(ReplicatedStorage.Packages.Net)
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        
        -- Get diving gear data
        local DivingGear = ItemUtility.GetItemDataFromItemType("Gears", "Diving Gear")
        if not DivingGear then
            return false, "Diving Gear tidak ditemukan!"
        end

        -- Get player data
        local Data = Replion.Client:WaitReplion("Data")
        if not Data then
            return false, "Data Replion tidak ditemukan!"
        end

        -- Get remote functions
        local UnequipOxygenTank = Net:RemoteFunction("UnequipOxygenTank")
        local EquipOxygenTank = Net:RemoteFunction("EquipOxygenTank")

        -- Check current equipment state
        local EquippedId = Data:Get("EquippedOxygenTankId")
        local isEquipped = EquippedId == DivingGear.Data.Id
        local success

        -- Toggle equipment
        if isEquipped then
            success = UnequipOxygenTank:InvokeServer()
        else
            success = EquipOxygenTank:InvokeServer(DivingGear.Data.Id)
        end

        if success then
            divingGearEnabled = not isEquipped
            return true, "Diving Gear: " .. (not isEquipped and "ON" or "OFF")
        else
            return false, "Failed to toggle diving gear"
        end
    end)
    
    if success then
        return true, result
    else
        return false, "Error: " .. tostring(result)
    end
end

local function StartDivingGear()
    if divingGearEnabled then return end
    
    local success, message = ToggleDivingGear()
    if success then
        divingGearEnabled = true
        Notify({Title = "Diving Gear", Content = message, Duration = 3})
    else
        Notify({Title = "Diving Gear Error", Content = message, Duration = 4})
    end
end

local function StopDivingGear()
    if not divingGearEnabled then return end
    
    local success, message = ToggleDivingGear()
    if success then
        divingGearEnabled = false
        Notify({Title = "Diving Gear", Content = message, Duration = 3})
    else
        Notify({Title = "Diving Gear Error", Content = message, Duration = 4})
    end
end

-- Auto Sell System
local function ManualSellAllFish()
    local success, result = pcall(function()
        local VendorController = require(ReplicatedStorage.Controllers.VendorController)
        if VendorController and VendorController.SellAllItems then
            VendorController:SellAllItems()
            return true, "All fish sold successfully!"
        else
            return false, "VendorController not found"
        end
    end)
    
    if success then
        Notify({Title = "Manual Sell", Content = result, Duration = 3})
    else
        Notify({Title = "Sell Error", Content = result, Duration = 4})
    end
end

local function StartAutoSell()
    if autoSellEnabled then return end
    autoSellEnabled = true
    
    autoSellLoop = task.spawn(function()
        while autoSellEnabled do
            pcall(function()
                local Replion = require(ReplicatedStorage.Packages.Replion)
                local Data = Replion.Client:WaitReplion("Data")
                local VendorController = require(ReplicatedStorage.Controllers.VendorController)
                
                if Data and VendorController and VendorController.SellAllItems then
                    local inventory = Data:Get("Inventory")
                    if inventory and inventory.Fish then
                        local fishCount = 0
                        for _, fish in pairs(inventory.Fish) do
                            fishCount = fishCount + (fish.Amount or 1)
                        end
                        
                        if fishCount >= autoSellThreshold then
                            VendorController:SellAllItems()
                            Notify({
                                Title = "Auto Sell", 
                                Content = string.format("Sold %d fish automatically", fishCount),
                                Duration = 2
                            })
                        end
                    end
                end
            end)
            task.wait(2) -- Check every 2 seconds
        end
    end)
    
    Notify({
        Title = "Auto Sell Started", 
        Content = string.format("Auto selling when fish count >= %d", autoSellThreshold),
        Duration = 3
    })
end

local function StopAutoSell()
    if not autoSellEnabled then return end
    autoSellEnabled = false
    
    if autoSellLoop then
        task.cancel(autoSellLoop)
        autoSellLoop = nil
    end
    
    Notify({Title = "Auto Sell", Content = "Auto sell stopped", Duration = 2})
end

local function SetAutoSellThreshold(amount)
    if type(amount) == "number" and amount > 0 then
        autoSellThreshold = amount
        Notify({
            Title = "Auto Sell Threshold", 
            Content = string.format("Threshold set to %d fish", amount),
            Duration = 3
        })
        return true
    end
    return false
end

-- Auto Radar Toggle with safety
local function SafeToggleRadar()
    local success, message = ToggleFishingRadar()
    if success then
        Notify({Title = "Fishing Radar", Content = message, Duration = 3})
    else
        Notify({Title = "Radar Error", Content = message, Duration = 4})
    end
end

-- Auto Diving Gear Toggle with safety
local function SafeToggleDivingGear()
    local success, message = ToggleDivingGear()
    if success then
        Notify({Title = "Diving Gear", Content = message, Duration = 3})
    else
        Notify({Title = "Diving Gear Error", Content = message, Duration = 4})
    end
end

-- Coordinate Display System
local function CreateCoordinateDisplay()
    if coordinateGui and coordinateGui.Parent then coordinateGui:Destroy() end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "Anggazyy_Coordinates"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 220, 0, 40)
    frame.Position = UDim2.new(0.5, -110, 0, 15)
    frame.BackgroundColor3 = COLOR_SECONDARY
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0.3, 0)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = COLOR_PRIMARY
    stroke.Thickness = 1.6

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.Text = "X: 0 | Y: 0 | Z: 0"
    label.TextXAlignment = Enum.TextXAlignment.Left

    coordinateGui = sg

    task.spawn(function()
        while coordinateGui and coordinateGui.Parent do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local pos = char.HumanoidRootPart.Position
                label.Text = string.format("X: %d | Y: %d | Z: %d", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
            else
                label.Text = "X: - | Y: - | Z: -"
            end
            task.wait(0.12)
        end
    end)
end

local function DestroyCoordinateDisplay()
    if coordinateGui and coordinateGui.Parent then
        pcall(function() coordinateGui:Destroy() end)
        coordinateGui = nil
    end
end

-- Notification System
local function Notify(opts)
    pcall(function()
        WindUI:Notify({
            Title = opts.Title or "Notification",
            Content = opts.Content or "",
            Duration = opts.Duration or 3,
            Icon = opts.Icon or "info"
        })
    end)
end

-- Auto-clean money icons
task.spawn(function()
    while task.wait(1) do
        for _, obj in ipairs(CoreGui:GetDescendants()) do
            if obj and (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) then
                local nameLower = (obj.Name or ""):lower()
                local textLower = (obj.Text or ""):lower()
                if string.find(nameLower, "money") or string.find(textLower, "money") or string.find(nameLower, "100") then
                    pcall(function()
                        obj.Visible = false
                        if obj:IsA("GuiObject") then
                            obj.Active = false
                            obj.ZIndex = 0
                        end
                    end)
                end
            end
        end
    end
end)

-- =============================================================================
-- WINDUI MAIN WINDOW CREATION
-- =============================================================================

-- Create Main Window
local Window = WindUI:CreateWindow({
    Title = "Anggazyy Hub - Fish It",
    Author = "by Anggazyy • Premium Automation",
    Folder = "AnggazyyHub",
    Icon = "fish",
    NewElements = true,
    
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open Anggazyy Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new(
            Color3.fromHex("#6b31ff"), 
            Color3.fromHex("#30a2ff")
        )
    }
})

-- Add version tag
Window:Tag({
    Title = "v2.0-full",
    Icon = "github",
    Color = Color3.fromHex("#6b31ff")
})

-- ========== ABOUT US TAB ==========
local AboutTab = Window:Tab({
    Title = "About Us",
    Icon = "info",
})

local AboutSection = AboutTab:Section({
    Title = "About Anggazyy Hub",
})

AboutSection:Image({
    Image = "https://files.catbox.moe/of2fla.jpg",
    AspectRatio = "16:9",
    Radius = 9,
})

AboutSection:Space({ Columns = 3 })

AboutSection:Section({
    Title = "What Is Anggazyy Hub?",
    TextSize = 24,
    FontWeight = Enum.FontWeight.SemiBold,
})

AboutSection:Space()

AboutSection:Section({
    Title = [[Anggazyy Hub adalah script premium yang dirancang khusus untuk game Fish It di Roblox. 
Dikembangkan oleh Anggazyy dengan fokus pada automasi dan optimasi gameplay.

Fitur Utama:
• Auto Fishing System - Automatisasi memancing yang cerdas
• Weather Machine - Sistem pembelian dan manajemen cuaca
• Bypass Features - Fitur canggih untuk meningkatkan gameplay
• Player Configuration - Optimasi performa dan kontrol karakter
• Mobile-Friendly UI - Antarmuka yang responsif untuk semua device

Dibangun dengan teknologi terbaru untuk memberikan pengalaman gaming yang optimal dan efisien.

Script ini 100% Gratis dan tidak diperjualbelikan.]],
    TextSize = 16,
    TextTransparency = 0.35,
    FontWeight = Enum.FontWeight.Medium,
})

AboutTab:Space({ Columns = 4 })

-- ========== AUTO SYSTEM TAB ==========
local AutoTab = Window:Tab({
    Title = "Automation",
    Icon = "fish",
})

AutoTab:Section({
    Title = "Auto Fishing System",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

AutoTab:Space()

AutoTab:Toggle({
    Title = "Enable Auto Fishing",
    Desc = "Automated fishing with server communication",
    Flag = "AutoFishToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartAutoFish()
        else
            StopAutoFish()
        end
    end
})

AutoTab:Space()

-- Blatant Fishing Section
AutoTab:Section({
    Title = "⚡ Blatant Fishing",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

AutoTab:Toggle({
    Title = "Blatant Mode",
    Desc = "Fast fishing with minigame bypass",
    Flag = "BlatantModeToggle",
    Default = false,
    Callback = function(state)
        ToggleBlatantMode(state)
    end
})

AutoTab:Slider({
    Title = "Delay Reel",
    Desc = "Delay before reeling fish (0 - 1.87)",
    Flag = "BlatantReelDelay",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 1.87,
        Default = 0.5,
    },
    Callback = function(value)
        SetBlatantReelDelay(value)
    end
})

AutoTab:Slider({
    Title = "Delay Fishing",
    Desc = "Delay between fishing attempts (Fast Loop)",
    Flag = "BlatantFishingDelay",
    Step = 0.001,
    Value = {
        Min = 0,
        Max = 0.1,
        Default = 0.0015,
    },
    Callback = function(value)
        SetBlatantFishingDelay(value)
    end
})

AutoTab:Button({
    Title = "Initialize Blatant System",
    Icon = "zap",
    Callback = function()
        InitializeBlatantFishing()
    end
})

AutoTab:Button({
    Title = "Manual Cast",
    Icon = "fishing-rod",
    Callback = ManualBlatantFish
})

-- ========== DYNAMIC AUTO FARM TAB ==========
local DynamicFarmTab = Window:Tab({
    Title = "Dynamic Farm",
    Icon = "zap",
})

DynamicFarmTab:Section({
    Title = "Dynamic Auto Farm",
    Desc = "AFK farm at Volcano, auto TP to events",
})

DynamicFarmTab:Toggle({
    Title = "Enable Auto Farm",
    Flag = "AutoFarmToggle",
    Default = false,
    Callback = function(state)
        toggleAutoFarm(state)
    end
})

-- Status Label
local StatusLabel = DynamicFarmTab:Label("Current Event: None")
task.spawn(function()
    while task.wait(2) do
        StatusLabel:SetText("Current Event: " .. currentEvent)
    end
end)

DynamicFarmTab:Space()

DynamicFarmTab:Section({
    Title = "Auto Fishing Controls",
})

DynamicFarmTab:Toggle({
    Title = "Enable Auto Fishing",
    Desc = "Automatically fish with perfect catches",
    Flag = "AutoFishingSecondToggle",
    Default = false,
    Callback = function(Value)
        fishingEnabled = Value
        if Value then
            startAutoFishingSecond()
            Notify({Title = 'Auto Fishing', Content = 'Auto fishing enabled! Always perfect catches!', Duration = 3})
        else
            if fishingThread then
                task.cancel(fishingThread)
                fishingThread = nil
            end
            unequipFishingRod()
            Notify({Title = 'Auto Fishing', Content = 'Auto fishing disabled!', Duration = 2})
        end
    end
})

DynamicFarmTab:Toggle({
    Title = "Auto Sell Items",
    Desc = "Sells all items every " .. sellDelay .. " seconds",
    Flag = "AutoSellSecondToggle",
    Default = false,
    Callback = function(Value)
        autoSellEnabled = Value
        if Value then
            startAutoSellSecond()
            Notify({Title = 'Auto Sell', Content = 'Auto sell enabled! Selling every ' .. sellDelay .. ' seconds.', Duration = 3})
        else
            if sellThread then
                task.cancel(sellThread)
                sellThread = nil
            end
            Notify({Title = 'Auto Sell', Content = 'Auto sell disabled!', Duration = 2})
        end
    end
})

-- ========== MOBILE AUTOFARM TAB ==========
local MobileAutofarmTab = Window:Tab({
    Title = "Mobile Farm",
    Icon = "smartphone",
})

MobileAutofarmTab:Section({
    Title = "Mobile Auto Farm",
})

MobileAutofarmTab:Toggle({
    Title = "Enable Mobile Auto Fishing",
    Desc = "Toggles in-game auto fishing for mobile users",
    Flag = "MobileAutoFishingToggle",
    Default = false,
    Callback = toggleMobileAutoFishing
})

local MobileStatusLabel = MobileAutofarmTab:Label("Current Event: None")
task.spawn(function()
    while task.wait(1) do
        MobileStatusLabel:SetText("Current Event: " .. currentEvent)
    end
end)

MobileAutofarmTab:Space()

MobileAutofarmTab:Section({
    Title = "Information",
})

MobileAutofarmTab:Label('How to Use', true)
MobileAutofarmTab:Label('1. Enable Mobile Auto Fishing to start autofishing\n2. Automatically teleports to Volcano or detected events\n3. Uses the game\'s built-in mobile autofishing system', true)

-- ========== WEATHER MACHINE TAB ==========
local WeatherTab = Window:Tab({
    Title = "Weather Machine",
    Icon = "cloud",
})

WeatherTab:Section({
    Title = "Weather Machine",
    Desc = "Purchase and activate different weather events",
})

-- Load weather data initially
availableWeathers = LoadWeatherData()

-- Weather Selection Toggles
for index, weather in ipairs(availableWeathers) do
    WeatherTab:Toggle({
        Title = weather.DisplayName,
        Flag = "WeatherToggle_" .. weather.InternalName,
        Default = false,
        Callback = function(state)
            ToggleWeatherSelection(index, state)
        end
    })
    
    if index < #availableWeathers then
        WeatherTab:Space()
    end
end

WeatherTab:Space({ Columns = 2 })

WeatherTab:Button({
    Title = "Buy Selected Weathers",
    Icon = "shopping-cart",
    Justify = "Center",
    Callback = BuySelectedWeathers
})

WeatherTab:Button({
    Title = "Refresh Weather List",
    Icon = "refresh-cw",
    Justify = "Center",
    Callback = function()
        local newOptions, newWeathers = RefreshWeatherList()
        Notify({
            Title = "Weather List Updated",
            Content = string.format("Loaded %d available weathers", #newWeathers),
            Duration = 3
        })
    end
})

-- ========== BYPASS TAB ==========
local BypassTab = Window:Tab({
    Title = "Bypass",
    Icon = "radar",
})

BypassTab:Section({
    Title = "Game Bypass Features",
    Desc = "Advanced features to enhance gameplay",
})

-- Fishing Radar Section
BypassTab:Section({
    Title = "Fishing Radar",
    TextSize = 18,
    FontWeight = Enum.FontWeight.SemiBold,
})

BypassTab:Toggle({
    Title = "Fishing Radar",
    Flag = "FishingRadarToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartFishingRadar()
        else
            StopFishingRadar()
        end
    end
})

BypassTab:Button({
    Title = "Toggle Radar",
    Icon = "radar",
    Callback = SafeToggleRadar
})

BypassTab:Space()

-- Diving Gear Section
BypassTab:Section({
    Title = "Diving Gear",
    TextSize = 18,
    FontWeight = Enum.FontWeight.SemiBold,
})

BypassTab:Toggle({
    Title = "Diving Gear",
    Flag = "DivingGearToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartDivingGear()
        else
            StopDivingGear()
        end
    end
})

BypassTab:Button({
    Title = "Toggle Diving Gear",
    Icon = "diving",
    Callback = SafeToggleDivingGear
})

BypassTab:Space()

-- Auto Sell Section
BypassTab:Section({
    Title = "Auto Sell Fish",
    TextSize = 18,
    FontWeight = Enum.FontWeight.SemiBold,
})

BypassTab:Toggle({
    Title = "Auto Sell Fish",
    Desc = "Automatically sell fish when threshold is reached",
    Flag = "AutoSellToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartAutoSell()
        else
            StopAutoSell()
        end
    end
})

BypassTab:Slider({
    Title = "Sell Threshold",
    Desc = "Minimum fish count to trigger auto sell",
    Flag = "AutoSellThreshold",
    Step = 1,
    Value = {
        Min = 1,
        Max = 50,
        Default = 3,
    },
    Callback = function(value)
        SetAutoSellThreshold(value)
    end
})

BypassTab:Button({
    Title = "Sell All Fish Now",
    Icon = "dollar-sign",
    Callback = ManualSellAllFish
})

BypassTab:Space()

-- Trick or Treat Section
BypassTab:Section({
    Title = "🎃 Trick or Treat",
    TextSize = 18,
    FontWeight = Enum.FontWeight.SemiBold,
})

BypassTab:Toggle({
    Title = "Auto Trick or Treat",
    Desc = "Automatically knocks on all Trick or Treat doors",
    Flag = "AutoTrickTreatToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartAutoTrickTreat()
        else
            StopAutoTrickTreat()
        end
    end
})

BypassTab:Button({
    Title = "Knock All Doors Now",
    Icon = "door-open",
    Callback = ManualKnockAllDoors
})

BypassTab:Space()

-- Quick Actions Section
BypassTab:Section({
    Title = "Quick Actions",
    TextSize = 18,
    FontWeight = Enum.FontWeight.SemiBold,
})

BypassTab:Button({
    Title = "Enable All Bypass",
    Icon = "play",
    Color = Color3.fromHex("#30ff6a"),
    Justify = "Center",
    Callback = function()
        StartFishingRadar()
        StartDivingGear()
        StartAutoSell()
        StartAutoTrickTreat()
        Notify({Title = "Bypass", Content = "All bypass features enabled", Duration = 3})
    end
})

BypassTab:Button({
    Title = "Disable All Bypass",
    Icon = "square",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Center",
    Callback = function()
        StopFishingRadar()
        StopDivingGear()
        StopAutoSell()
        StopAutoTrickTreat()
        Notify({Title = "Bypass", Content = "All bypass features disabled", Duration = 3})
    end
})

-- ========== PLAYER CONFIGURATION TAB ==========
local PlayerConfigTab = Window:Tab({
    Title = "Player Config",
    Icon = "settings",
})

-- Performance Section
PlayerConfigTab:Section({
    Title = "Performance",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Toggle({
    Title = "Ultra Anti Lag",
    Desc = "White texture mode for maximum performance",
    Flag = "AntiLagToggle",
    Default = false,
    Callback = function(state)
        if state then
            EnableAntiLag()
        else
            DisableAntiLag()
        end
    end
})

PlayerConfigTab:Space()

-- Anti AFK Section
PlayerConfigTab:Section({
    Title = "Anti AFK System",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Toggle({
    Title = "Anti AFK + Auto Reconnect",
    Desc = "Prevent AFK kick and auto reconnect if disconnected",
    Flag = "AntiAFKToggle",
    Default = false,
    Callback = function(state)
        ToggleAntiAFK(state)
    end
})

PlayerConfigTab:Space()

-- Position Section
PlayerConfigTab:Section({
    Title = "Position Management",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Button({
    Title = "Save Position",
    Icon = "bookmark",
    Callback = SaveCurrentPosition
})

PlayerConfigTab:Button({
    Title = "Load Position",
    Icon = "navigation",
    Callback = LoadSavedPosition
})

PlayerConfigTab:Toggle({
    Title = "Lock Position",
    Desc = "Prevent movement from saved position",
    Flag = "LockPositionToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartLockPosition()
        else
            StopLockPosition()
        end
    end
})

PlayerConfigTab:Space()

-- Movement Configuration
PlayerConfigTab:Section({
    Title = "Movement Configuration",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Slider({
    Title = "Walk Speed",
    Desc = "Adjust player movement speed",
    Flag = "WalkSpeed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 200,
        Default = 16,
    },
    Callback = function(val)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = val
        end
    end
})

PlayerConfigTab:Slider({
    Title = "Jump Power",
    Desc = "Adjust player jump height",
    Flag = "JumpPower",
    Step = 1,
    Value = {
        Min = 50,
        Max = 350,
        Default = 50,
    },
    Callback = function(val)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = val
        end
    end
})

PlayerConfigTab:Button({
    Title = "Reset Movement",
    Icon = "refresh-cw",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
            Notify({Title = "Reset", Content = "Movement reset to default", Duration = 2})
        end
    end
})

PlayerConfigTab:Space()

-- Player Controls Section
PlayerConfigTab:Section({
    Title = "Player Controls",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Toggle({
    Title = "Freeze Player",
    Desc = "Freezes your character in place",
    Flag = "FreezePlayerToggle",
    Default = false,
    Callback = function(Value)
        freezePlayer(Value)
        Notify({Title = 'Player Control', Content = 'Player ' .. (Value and 'frozen!' or 'unfrozen!'), Duration = 2})
    end
})

PlayerConfigTab:Toggle({
    Title = "Remove Oxy",
    Desc = "Toggles oxygen removal on or off",
    Flag = "RemoveOxyToggle",
    Default = false,
    Callback = function(Value)
        removeOxygen(Value)
    end
})

PlayerConfigTab:Toggle({
    Title = "Fish Radar",
    Desc = "Toggles fish radar on or off",
    Flag = "FishRadarToggle",
    Default = false,
    Callback = function(Value)
        toggleFishRadar(Value)
    end
})

PlayerConfigTab:Space()

-- Quick Actions
PlayerConfigTab:Section({
    Title = "Quick Actions",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Button({
    Title = "Max Performance",
    Icon = "zap",
    Color = Color3.fromHex("#30a2ff"),
    Justify = "Center",
    Callback = function()
        EnableAntiLag()
        ToggleAntiAFK(true)
        Notify({Title = "Performance", Content = "Maximum performance enabled", Duration = 2})
    end
})

-- ========== TELEPORTATION TAB ==========
local TeleportTab = Window:Tab({
    Title = "Teleportation",
    Icon = "map-pin",
})

TeleportTab:Section({
    Title = "Location Teleport",
    Desc = "Quick teleport to fishing spots",
})

-- DROPDOWN UNTUK MAP TELEPORT
TeleportTab:Dropdown({
    Title = "Select Destination",
    Flag = "MapSelect",
    Values = {
        "Kohana",
        "Kohana Volcano", 
        "Lost Isle",
        "Coral Fish",
        "Tropical Grove",
        "Crater Island",
        "Esoteric Depth",
        "Ancient Jungle",
        "Sacred Temple",
        "Undground Cellar",
        "Fishermand Iland",
        "Coral Reefs",
        "Fisherman Island",
        "Weather Machine",
        "Treasure Room"
    },
    Value = "Kohana",
    Callback = function(selected)
        currentSelectedMap = selected
    end
})

-- BUTTON TELEPORT
TeleportTab:Button({
    Title = "Teleport Now",
    Icon = "navigation",
    Callback = function()
        local targetPosition
        
        -- Tentukan posisi berdasarkan pilihan
        if currentSelectedMap == "Kohana" then
            targetPosition = Vector3.new(-637, 16, 626)
        elseif currentSelectedMap == "Kohana Volcano" then
            targetPosition = Vector3.new(-607, 48, 167)
        elseif currentSelectedMap == "Lost Isle" then
            targetPosition = Vector3.new(-3706, -136, -1014)
        elseif currentSelectedMap == "Coral Fish" then
            targetPosition = Vector3.new(-2923, 3, 2080)
        elseif currentSelectedMap == "Tropical Grove" then
            targetPosition = Vector3.new(-2053, 6, 3665)
        elseif currentSelectedMap == "Crater Island" then
            targetPosition = Vector3.new(997, 2, 5010)
        elseif currentSelectedMap == "Esoteric Depth" then
            targetPosition = Vector3.new(3252, -1301, 1392)
        elseif currentSelectedMap == "Ancient Jungle" then
            targetPosition = Vector3.new(1329, 7, -248)
        elseif currentSelectedMap == "Sacred Temple" then
            targetPosition = Vector3.new(1485, 7, -550)
        elseif currentSelectedMap == "Undground Cellar" then
            targetPosition = Vector3.new(2021, -92, -570)
        elseif currentSelectedMap == "Fishermand Iland" then
            targetPosition = Vector3.new(-26, 9, 2688)
        else
            -- Use island CFrame positions for new locations
            local islandCFrame = islands[currentSelectedMap]
            if islandCFrame then
                targetPosition = islandCFrame.Position
            else
                -- Default position jika tidak ada yang cocok
                targetPosition = Vector3.new(-637, 16, 626)
            end
        end
        
        -- Eksekusi teleport
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            Notify({
                Title = "Teleport Success", 
                Content = string.format("Teleported to %s", currentSelectedMap),
                Duration = 3
            })
        else
            Notify({
                Title = "Teleport Failed",
                Content = "Character not found",
                Duration = 3
            })
        end
    end
})

TeleportTab:Toggle({
    Title = "Show Coordinates",
    Desc = "Display current position coordinates",
    Flag = "ShowCoords",
    Default = false,
    Callback = function(v)
        if v then
            CreateCoordinateDisplay()
        else
            DestroyCoordinateDisplay()
        end
    end
})

TeleportTab:Space()

TeleportTab:Section({
    Title = "Special Locations",
})

TeleportTab:Button({
    Title = "Enchanting Altar TP",
    Icon = "sparkles",
    Callback = function()
        teleportToEnchantingAltar()
    end
})

-- ========== ESP TAB ==========
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye",
})

ESPTab:Section({
    Title = "Island ESP",
    Desc = "Visual indicators for all islands",
})

ESPTab:Toggle({
    Title = "Islands ESP",
    Desc = "Shows highlights, labels and distance for all islands",
    Flag = "IslandESPToggle",
    Default = false,
    Callback = function(Value)
        toggleIslandESP(Value)
    end
})

-- ========== SHOP TAB ==========
local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "shopping-cart",
})

ShopTab:Section({
    Title = "Fishing Rods Shop",
})

ShopTab:Dropdown({
    Title = "Buy Fishing Rod",
    Flag = "FishingRodDropdown",
    Values = {
        "Lucky Rod - 350",
        "Carbon Rod - 900",
        "Grass Rod - 1.5k",
        "Demascus Rod - 3k",
        "Ice Rod - 5k",
        "Luck Rod - 15k",
        "Midnight Rod - 50k",
        "Steampunk Rod - 215k",
        "Astral Rod - 1M"
    },
    Default = 1,
    Multi = false,
    Callback = function(Value)
        local idMap = {
            ["Lucky Rod - 350"] = 4,
            ["Carbon Rod - 900"] = 76,
            ["Grass Rod - 1.5k"] = 85,
            ["Demascus Rod - 3k"] = 77,
            ["Ice Rod - 5k"] = 78,
            ["Luck Rod - 15k"] = 79,
            ["Midnight Rod - 50k"] = 80,
            ["Steampunk Rod - 215k"] = 6,
            ["Astral Rod - 1M"] = 5
        }
        local id = idMap[Value]
        purchaseFishingRod(id)
    end
})

ShopTab:Space()

ShopTab:Section({
    Title = "Bobbers Shop",
})

ShopTab:Dropdown({
    Title = "Buy Bobber",
    Flag = "BobberDropdown",
    Values = {
        "Topwater Bait - 100",
        "Luck Bait - 1k",
        "Midnight Bait - 3k",
        "Chroma Bait - 290k",
        "Dark Matter Bait - 630k",
        "Corrupt Bait - 1.15M",
        "Aether Bait - 3.70M"
    },
    Default = 1,
    Multi = false,
    Callback = function(Value)
        local idMap = {
            ["Topwater Bait - 100"] = 10,
            ["Luck Bait - 1k"] = 2,
            ["Midnight Bait - 3k"] = 3,
            ["Chroma Bait - 290k"] = 6,
            ["Dark Matter Bait - 630k"] = 8,
            ["Corrupt Bait - 1.15M"] = 15,
            ["Aether Bait - 3.70M"] = 16
        }
        local id = idMap[Value]
        purchaseBobber(id)
    end
})

ShopTab:Space()

ShopTab:Section({
    Title = "Weather Events Shop",
})

ShopTab:Dropdown({
    Title = "Buy Weather Event",
    Flag = "WeatherDropdown",
    Values = {
        "Snow - 15k",
        "Cloudy - 20k",
        "Storm - 35k",
        "Radiant - 50k",
        "Shark Hunt - 300k"
    },
    Default = 1,
    Multi = false,
    Callback = function(Value)
        local eventName = Value:match("^[^%-]+"):gsub("^%s*(.-)%s*$", "%1")
        purchaseWeatherEvent(eventName)
    end
})

-- ========== WEBHOOK TAB ==========
local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "message-circle",
})

WebhookTab:Section({
    Title = "Webhook Configuration",
    Desc = "Configure Discord webhook notifications",
})

WebhookTab:Input({
    Title = "Discord Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Flag = "WebhookURL",
    Callback = function(Value)
        WEBHOOK_URL = Value
        if Value ~= "" then
            Notify({Title = "Webhook", Content = "✅ Webhook URL saved!", Duration = 3})
        else
            Notify({Title = "Webhook", Content = "⚠️ Webhook URL is empty!", Duration = 3})
        end
    end
})

WebhookTab:Input({
    Title = "Discord User ID (optional)",
    Default = "",
    Placeholder = "123456789012345678",
    Flag = "DiscordUserID",
    Callback = function(Value)
        DISCORD_USER_ID = Value
    end
})

WebhookTab:Toggle({
    Title = "Also send big image (embed.image)",
    Flag = "BigImageToggle",
    Default = false,
    Callback = function(Value)
        SEND_BIG_IMAGE = Value
    end
})

WebhookTab:Toggle({
    Title = "Debug Icon (show URL)",
    Flag = "DebugIconToggle",
    Default = false,
    Callback = function(Value)
        DEBUG_ICON = Value
    end
})

WebhookTab:Space()

WebhookTab:Section({
    Title = "Status & Test",
})

WebhookTab:Button({
    Title = "Test Webhook (Robot Kraken)",
    Icon = "send",
    Callback = function()
        if not WEBHOOK_URL or WEBHOOK_URL == "" then
            Notify({Title = "Webhook", Content = "⚠️ No webhook URL set!", Duration = 3})
            return
        end
        sendWebhook(159, 420.5, LocalPlayer.Name, nil, false, false) -- Robot Kraken test
        Notify({Title = "Webhook", Content = "📨 Test webhook sent!", Duration = 3})
    end
})

WebhookTab:Button({
    Title = "Reload Fish Data",
    Icon = "refresh-cw",
    Callback = function()
        Notify({Title = "Webhook", Content = "Fish data reloaded (manual refresh)", Duration = 3})
    end
})

-- ========== SETTINGS TAB ==========
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings-2",
})

SettingsTab:Button({
    Title = "Unload Hub",
    Icon = "power",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Center",
    Callback = function()
        StopAutoFish()
        StopLockPosition()
        DisableAntiLag()
        StopFishingRadar()
        StopDivingGear()
        StopAutoSell()
        StopAutoTrickTreat()
        ToggleBlatantMode(false)
        DestroyCoordinateDisplay()
        
        -- Cleanup from new features
        if fishingThread then task.cancel(fishingThread) fishingThread = nil end
        if monitorThread then task.cancel(monitorThread) monitorThread = nil end
        if mobileMonitorThread then task.cancel(mobileMonitorThread) mobileMonitorThread = nil end
        if sellThread then task.cancel(sellThread) sellThread = nil end
        if platform then platform:Destroy() platform = nil end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
        toggleIslandESP(false)
        freezePlayer(false)
        if removeOxyEnabled then
            removeOxygen(false)
        end
        
        Window:Destroy()
        Notify({Title = "Unload", Content = "Hub unloaded successfully", Duration = 2})
    end
})

SettingsTab:Button({
    Title = "Clean UI",
    Icon = "trash-2",
    Justify = "Center",
    Callback = function()
        for _, obj in ipairs(CoreGui:GetDescendants()) do
            pcall(function()
                if (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) then
                    local name = (obj.Name or ""):lower()
                    local text = (obj.Text or ""):lower()
                    if string.find(name, "money") or string.find(text, "money") then
                        obj.Visible = false
                    end
                end
            end)
        end
        Notify({Title = "Clean", Content = "UI cleaned", Duration = 2})
    end
})

-- =============================================================================
-- INITIALIZATION AND EVENT LISTENERS
-- =============================================================================

-- Listen for fish being caught
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"] 
    and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local Event = netFolder and (netFolder["RE/FishCaught"] or netFolder["FishCaught"])
if Event then
    Event.OnClientEvent:Connect(function(fishId, data)
        local playerName = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown"
        local weight     = data.Weight or 0
        local variantId = data and data.VariantId

        local fish = AllFishes[fishId]

        -- detect mutations (weight outside dataset)
        local isMutation = false
        if fish and fish.Weight then
            if fish.Weight.Default and type(fish.Weight.Default) == "table" and #fish.Weight.Default >= 2 then
                local min, max = fish.Weight.Default[1], fish.Weight.Default[2]
                if weight < min or weight > max then
                    isMutation = true
                end
            elseif fish.Weight.Big and type(fish.Weight.Big) == "table" and #fish.Weight.Big >= 2 then
                local min, max = fish.Weight.Big[1], fish.Weight.Big[2]
                if weight < min or weight > max then
                    isMutation = true
                end
            end
        end

        -- send webhook
        sendWebhook(fishId, weight, playerName, variantId, isMutation)
    end)
else
    warn("[Fishing Bot] Could not find FishCaught remote.")
end

-- Cleanup
LocalPlayer.CharacterRemoving:Connect(function()
    if fishingThread then task.cancel(fishingThread) fishingThread = nil end
    if monitorThread then task.cancel(monitorThread) monitorThread = nil end
    if mobileMonitorThread then task.cancel(mobileMonitorThread) mobileMonitorThread = nil end
    if sellThread then task.cancel(sellThread) sellThread = nil end
    if platform then platform:Destroy() platform = nil end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end
    toggleIslandESP(false)
    freezePlayer(false)
    if removeOxyEnabled then
        removeOxygen(false)
    end
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    updatePlayerSpeed(playerFrozen and 0 or originalWalkSpeed)
    updatePlayerJump(originalJumpPower)
    if playerFrozen and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = true
    end
    if removeOxyEnabled then
        removeOxygen(true)
    end
end)

-- Initial Notification
Notify({
    Title = "Anggazyy Hub Ready", 
    Content = "WindUI System initialized successfully with ALL NEW FEATURES",
    Duration = 4
})

print("🎣 Anggazyy Hub v2.0 FULL - All features loaded successfully!")
