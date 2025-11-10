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

-- UI Variables
local PlayerGui = LocalPlayer.PlayerGui
local Charge_upvr = PlayerGui:WaitForChild("Charge")
local Fishing_upvr = PlayerGui:WaitForChild("Fishing")
local Main_upvr = Fishing_upvr.Main
local CanvasGroup_upvr = Main_upvr.Display.CanvasGroup

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
local blatantFishingDelay = 0.90  -- Default delay fishing

-- Display Name System Variables
local displayNameEnabled = false
local customDisplayName = ""
local originalDisplayName = LocalPlayer.DisplayName
local displayNameConnection = nil

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
        Title = "Anggazyy Hub - Fish It",
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
-- DISPLAY NAME SYSTEM - Visual DisplayName Change (Client-side Only)
-- =============================================================================

local function OverrideDisplayNameVisual()
    if not displayNameEnabled or customDisplayName == "" then return end
    
    -- Simpan nama asli jika belum disimpan
    if not originalDisplayName then
        originalDisplayName = LocalPlayer.DisplayName
    end
    
    -- Override properti DisplayName secara lokal
    local function overrideDisplayName()
        pcall(function()
            local mt = getrawmetatable(LocalPlayer)
            local oldIndex = mt.__index
            
            setreadonly(mt, false)
            
            mt.__index = newcclosure(function(self, key)
                if key == "DisplayName" and displayNameEnabled and customDisplayName ~= "" then
                    return customDisplayName
                end
                return oldIndex(self, key)
            end)
            
            setreadonly(mt, true)
        end)
    end
    
    -- Hook untuk NameDisplay (jika ada)
    local function hookNameDisplay()
        pcall(function()
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    if string.find(gui.Text, originalDisplayName) then
                        gui.Text = string.gsub(gui.Text, originalDisplayName, customDisplayName)
                    end
                end
            end
        end)
    end
    
    -- Hook untuk leaderboard/player list
    local function hookLeaderboard()
        pcall(function()
            for _, playerFrame in ipairs(PlayerGui:GetDescendants()) do
                if playerFrame:IsA("Frame") and playerFrame:FindFirstChild("NameLabel") then
                    local nameLabel = playerFrame.NameLabel
                    if nameLabel:IsA("TextLabel") and nameLabel.Text == originalDisplayName then
                        nameLabel.Text = customDisplayName
                    end
                end
            end
        end)
    end
    
    pcall(overrideDisplayName)
    pcall(hookNameDisplay)
    pcall(hookLeaderboard)
    
    -- Update terus menerus
    if displayNameConnection then
        displayNameConnection:Disconnect()
    end
    
    displayNameConnection = RunService.Heartbeat:Connect(function()
        if displayNameEnabled and customDisplayName ~= "" then
            pcall(hookNameDisplay)
            pcall(hookLeaderboard)
        end
    end)
end

local function RestoreDisplayName()
    if displayNameConnection then
        displayNameConnection:Disconnect()
        displayNameConnection = nil
    end
    
    -- Restore metatable
    pcall(function()
        local mt = getrawmetatable(LocalPlayer)
        setreadonly(mt, false)
        
        -- Reset ke index original
        local oldIndex = mt.__index
        if oldIndex and type(oldIndex) == "function" then
            -- Coba restore ke state semula
            mt.__index = oldIndex
        end
        
        setreadonly(mt, true)
    end)
    
    -- Restore UI elements
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                if string.find(gui.Text, customDisplayName) then
                    gui.Text = string.gsub(gui.Text, customDisplayName, originalDisplayName)
                end
            end
        end
    end)
end

local function ToggleDisplayName(state)
    if state then
        if customDisplayName == "" then
            WindUI:Notify({
                Title = "Display Name Error",
                Content = "Please set a custom name first",
                Duration = 3
            })
            return false
        end
        
        displayNameEnabled = true
        OverrideDisplayNameVisual()
        
        WindUI:Notify({
            Title = "Display Name",
            Content = "Display name changed to: " .. customDisplayName,
            Duration = 3
        })
        return true
    else
        displayNameEnabled = false
        RestoreDisplayName()
        
        WindUI:Notify({
            Title = "Display Name",
            Content = "Display name restored to original",
            Duration = 3
        })
        return true
    end
end

local function SetCustomDisplayName(name)
    if not name or string.len(name) < 1 then
        return false, "Name cannot be empty"
    end
    
    if string.len(name) > 20 then
        return false, "Name too long (max 20 characters)"
    end
    
    customDisplayName = name
    
    -- Jika display name sedang aktif, update langsung
    if displayNameEnabled then
        task.spawn(function()
            task.wait(0.5)
            ToggleDisplayName(true)
        end)
    end
    
    return true, "Custom name set to: " .. name
end

-- =============================================================================
-- UI RELOAD SYSTEM - Fixed Version
-- =============================================================================

local function CleanupAllSystems()
    -- Stop semua sistem yang berjalan
    if autoFishEnabled then
        autoFishEnabled = false
        if autoFishLoopThread then
            pcall(task.cancel, autoFishLoopThread)
            autoFishLoopThread = nil
        end
    end
    
    if lockPositionEnabled then
        lockPositionEnabled = false
        if lockPositionLoop then
            pcall(function() lockPositionLoop:Disconnect() end)
            lockPositionLoop = nil
        end
    end
    
    if antiLagEnabled then
        antiLagEnabled = false
        -- Restore graphics settings
        pcall(function()
            if originalGraphicsSettings.GraphicsQualityLevel then
                UserGameSettings.GraphicsQualityLevel = originalGraphicsSettings.GraphicsQualityLevel
            end
            settings().Rendering.QualityLevel = 10
        end)
    end
    
    if fishingRadarEnabled then
        fishingRadarEnabled = false
    end
    
    if divingGearEnabled then
        divingGearEnabled = false
    end
    
    if autoSellEnabled then
        autoSellEnabled = false
        if autoSellLoop then
            pcall(task.cancel, autoSellLoop)
            autoSellLoop = nil
        end
    end
    
    if autoTrickTreatEnabled then
        autoTrickTreatEnabled = false
        if trickTreatLoop then
            pcall(task.cancel, trickTreatLoop)
            trickTreatLoop = nil
        end
    end
    
    if isBlatantActive then
        isBlatantActive = false
        if BLATANT_MODE_TROVE then
            pcall(function() BLATANT_MODE_TROVE:Clean() end)
        end
    end
    
    -- Restore display name
    if displayNameEnabled then
        displayNameEnabled = false
        RestoreDisplayName()
    end
    
    -- Destroy coordinate display
    if coordinateGui then
        pcall(function() coordinateGui:Destroy() end)
        coordinateGui = nil
    end
end

local function UnloadUI()
    WindUI:Notify({
        Title = "UI System", 
        Content = "Unloading Anggazyy Hub...",
        Duration = 2
    })
    
    -- Cleanup semua sistem
    CleanupAllSystems()
    
    -- Hapus UI WindUI
    pcall(function()
        if Window then
            Window:Destroy()
        end
    end)
    
    -- Hapus semua instance UI yang dibuat
    pcall(function()
        for _, obj in ipairs(CoreGui:GetDescendants()) do
            if obj:FindFirstAncestorWhichIsA("ScreenGui") and (
                string.find(obj:GetFullName(), "AnggazyyHub") or 
                string.find(obj:GetFullName(), "WindUI") or
                string.find(obj:GetFullName(), "Anggazyy_Coordinates")
            ) then
                obj:Destroy()
            end
        end
    end)
    
    -- Hapus dari memory
    pcall(function()
        getgenv().AnggazyyHub = nil
        getgenv().WindUI = nil
    end)
    
    WindUI:Notify({Title = "UI System", Content = "Anggazyy Hub unloaded successfully", Duration = 2})
end

local function ReloadUI()
    WindUI:Notify({
        Title = "UI System", 
        Content = "Reloading UI...",
        Duration = 2
    })
    
    -- Unload UI terlebih dahulu
    UnloadUI()
    
    -- Tunggu sebentar sebelum reload
    task.wait(2)
    
    -- Execute ulang script
    local success, result = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/main.lua"))()
    end)
    
    if not success then
        WindUI:Notify({
            Title = "Reload Error",
            Content = "Failed to reload UI. Please execute script manually.",
            Duration = 4
        })
    end
end

-- =============================================================================
-- ANTI AFK SYSTEM
-- =============================================================================
local antiAFKEnabled = false

local function AntiKickReconnect()
    if getgenv().AntiKick_Started then return end
    getgenv().AntiKick_Started = true

    -- Cegah AFK Kick
    LocalPlayer.Idled:Connect(function()
        task.wait(1)
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)

    -- Cegah manual kick
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" or method == "kick" then
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function ToggleAntiAFK(state)
    if state then
        antiAFKEnabled = true
        AntiKickReconnect()
        WindUI:Notify({
            Title = "Anti AFK System", 
            Content = "Anti Kick + Auto Reconnect activated",
            Duration = 3
        })
    else
        antiAFKEnabled = false
        WindUI:Notify({
            Title = "Anti AFK System", 
            Content = "Basic protection remains active for safety",
            Duration = 3
        })
    end
end

-- Auto-clean money icons
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            for _, obj in ipairs(CoreGui:GetDescendants()) do
                if obj and (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) then
                    local nameLower = (obj.Name or ""):lower()
                    local textLower = (obj.Text or ""):lower()
                    if string.find(nameLower, "money") or string.find(textLower, "money") or string.find(nameLower, "100") then
                        obj.Visible = false
                        if obj:IsA("GuiObject") then
                            obj.Active = false
                        end
                    end
                end
            end
        end)
    end
end)

-- =============================================================================
-- BLATANT FISHING SYSTEM
-- =============================================================================

local function InitializeBlatantFishing()
    local success, result = pcall(function()
        Net_upvr = require(ReplicatedStorage.Packages.Net)
        Trove_upvr = require(ReplicatedStorage.Packages.Trove)
        Constants_upvr = require(ReplicatedStorage.Shared.Constants)
        
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
        
        FISHING_COMPLETED_REMOTE = Net_upvr:RemoteEvent("FishingCompleted")
        RequestFishingMinigameStarted_Net = Net_upvr:RemoteFunction("RequestFishingMinigameStarted")
        
        if module_upvr then
            originalFishingRodStarted = module_upvr.FishingRodStarted
            originalSendFishingRequestToServer = module_upvr.SendFishingRequestToServer
            originalRequestChargeFishingRod = module_upvr.RequestChargeFishingRod
        end
        
        BLATANT_MODE_TROVE = Trove_upvr.new()
        
        return true
    end)
    
    if success then
        WindUI:Notify({Title = "Blatant Fishing", Content = "System initialized successfully", Duration = 3})
        return true
    else
        WindUI:Notify({Title = "Blatant Fishing Error", Content = "Failed to initialize: " .. tostring(result), Duration = 4})
        return false
    end
end

local function AutoFishComplete(rodData, minigameData)
    local reelDelay = blatantReelDelay
    if reelDelay > 0 then
        task.wait(reelDelay)
    end
    
    pcall(function()
        FISHING_COMPLETED_REMOTE:FireServer() 
    end)
    
    if blatantFishingDelay > 0 then
        task.wait(blatantFishingDelay)
    end
end

local function HookFishingRodStarted(rodData, minigameData)
    if isBlatantActive then
        task.spawn(function()
            AutoFishComplete(rodData, minigameData)
        end)
    else
        if originalFishingRodStarted then
            originalFishingRodStarted(rodData, minigameData)
        end
    end
end

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

local function BlatantCastMethod1()
    local success, result = pcall(function()
        _G.confirmFishingInput = function() return true end
        
        local mousePos = GetSafeMousePosition()
        local skipCharge = true
        
        local castResult = module_upvr:RequestChargeFishingRod(mousePos, nil)
        
        _G.confirmFishingInput = nil
        return castResult
    end)
    
    return success and result
end

local function BlatantCastFishingRod()
    local success = BlatantCastMethod1()
    if success then
        return true
    end
    return false
end

local function BlatantFishingLoop()
    while isBlatantActive do
        local castSuccess = BlatantCastFishingRod()
        task.wait(blatantFishingDelay)
    end
end

local function HookRequestChargeFishingRod(arg1, arg2, arg3)
    if isBlatantActive then
        local mousePos = arg1 or GetSafeMousePosition()
        local skipCharge = true
        return originalRequestChargeFishingRod(mousePos, arg2, skipCharge)
    else
        return originalRequestChargeFishingRod(arg1, arg2, arg3)
    end
end

local function HookSendFishingRequestToServer(mousePosition, power, skipCharge)
    if isBlatantActive then
        return originalSendFishingRequestToServer(mousePosition, 0.5, true)
    else
        return originalSendFishingRequestToServer(mousePosition, power, skipCharge)
    end
end

local function SetBlatantReelDelay(delay)
    if type(delay) == "number" and delay >= 0 and delay <= 1.87 then
        blatantReelDelay = delay
        WindUI:Notify({
            Title = "Blatant Fishing", 
            Content = string.format("Reel delay set to %.4f seconds", delay),
            Duration = 3
        })
        return true
    end
    return false
end

local function SetBlatantFishingDelay(delay)
    if type(delay) == "number" and delay >= 0 and delay <= 5 then
        blatantFishingDelay = delay
        WindUI:Notify({
            Title = "Blatant Fishing", 
            Content = string.format("Fishing delay (loop) set to %.4f seconds", delay),
            Duration = 3
        })
        return true
    end
    return false
end

local function ToggleBlatantMode(enable)
    if enable == isBlatantActive then return end
    
    if enable then
        if not module_upvr or not FISHING_COMPLETED_REMOTE then
            if not InitializeBlatantFishing() then
                return false
            end
        end
        
        isBlatantActive = true
        
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
        
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Add(task.spawn(BlatantFishingLoop))
        end
        
        WindUI:Notify({Title = "⚡ Blatant Fishing", Content = "Fast fishing mode activated", Duration = 3})
        
    else
        isBlatantActive = false
        
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Clean()
        end
        
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
        
        WindUI:Notify({Title = "Blatant Fishing", Content = "Fast fishing mode deactivated", Duration = 3})
    end
    
    return true
end

local function ManualBlatantFish()
    if not isBlatantActive then
        WindUI:Notify({Title = "Blatant Fishing", Content = "Please enable Blatant Mode first", Duration = 3})
        return
    end
    
    pcall(function()
        local success = BlatantCastFishingRod()
        if success then
            WindUI:Notify({Title = "⚡ Manual Cast", Content = "Casting fishing rod instantly...", Duration = 2})
        else
            WindUI:Notify({Title = "❌ Manual Cast Failed", Content = "Failed to cast fishing rod", Duration = 2})
        end
    end)
end

-- =============================================================================
-- WEATHER MACHINE SYSTEM
-- =============================================================================

local function LoadWeatherData()
    local success, result = pcall(function()
        local EventUtility = require(ReplicatedStorage.Shared.EventUtility)
        local StringLibrary = require(ReplicatedStorage.Shared.StringLibrary)
        local Events = require(ReplicatedStorage.Events)
        
        local weatherList = {}
        
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
        
        table.sort(weatherList, function(a, b)
            return a.Price < b.Price
        end)
        
        return weatherList
    end)
    
    if success then
        return result
    else
        return {}
    end
end

local function PurchaseWeather(weatherName)
    local success, result = pcall(function()
        local Net = require(ReplicatedStorage.Packages.Net)
        local PurchaseWeatherEvent = Net:RemoteFunction("PurchaseWeatherEvent")
        local purchaseResult = PurchaseWeatherEvent:InvokeServer(weatherName)
        return purchaseResult
    end)
    
    return success, result
end

local function BuySelectedWeathers()
    if not next(selectedWeathers) then
        WindUI:Notify({
            Title = "Weather Purchase",
            Content = "No weathers selected!",
            Duration = 3
        })
        return
    end
    
    local totalPurchases = 0
    local successfulPurchases = 0
    
    WindUI:Notify({
        Title = "Weather Purchase",
        Content = "Processing purchases...",
        Duration = 2
    })
    
    for weatherName, selected in pairs(selectedWeathers) do
        if selected then
            totalPurchases = totalPurchases + 1
            
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
                end
            end
            
            task.wait(0.5)
        end
    end
    
    selectedWeathers = {}
    
    WindUI:Notify({
        Title = "Purchase Complete",
        Content = string.format("Successfully purchased %d/%d weathers", successfulPurchases, totalPurchases),
        Duration = 4
    })
end

local function RefreshWeatherList()
    availableWeathers = LoadWeatherData()
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
    
    trickTreatLoop = task.spawn(function()
        while autoTrickTreatEnabled do
            local doors = FindTrickOrTreatDoors()
            
            if #doors > 0 then
                for _, door in ipairs(doors) do
                    if not autoTrickTreatEnabled then break end
                    pcall(KnockDoor, door)
                    task.wait(0.5)
                end
            end
            
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
end

local function ManualKnockAllDoors()
    local doors = FindTrickOrTreatDoors()
    
    if #doors == 0 then
        WindUI:Notify({
            Title = "🎃 Trick or Treat",
            Content = "No Trick or Treat doors found!",
            Duration = 3
        })
        return
    end
    
    local successfulKnocks = 0
    
    for _, door in ipairs(doors) do
        local success, result = KnockDoor(door)
        if success then
            successfulKnocks = successfulKnocks + 1
        end
        task.wait(0.5)
    end
    
    WindUI:Notify({
        Title = "🎃 Knock Complete",
        Content = string.format("Success: %d/%d doors", successfulKnocks, #doors),
        Duration = 4
    })
end

-- =============================================================================
-- AUTO FISHING SYSTEM
-- =============================================================================

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

local function StartAutoFish()
    if autoFishEnabled then return end
    autoFishEnabled = true

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
    
    pcall(function()
        SafeInvokeAutoFishing(false)
    end)
end

-- =============================================================================
-- ANTI LAG SYSTEM
-- =============================================================================

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

local function EnableAntiLag()
    if antiLagEnabled then return end
    
    SaveOriginalGraphics()
    antiLagEnabled = true
    
    pcall(function()
        UserGameSettings.GraphicsQualityLevel = 1
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        Lighting.Brightness = 5
        Lighting.ShadowSoftness = 0
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 0
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        
        if workspace.Terrain then
            workspace.Terrain.Decoration = false
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 1
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
        end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                if obj:FindFirstChildOfClass("Texture") then
                    obj:FindFirstChildOfClass("Texture"):Destroy()
                end
                if obj:FindFirstChildOfClass("Decal") then
                    obj:FindFirstChildOfClass("Decal"):Destroy()
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.BrickColor = BrickColor.new("White")
                obj.Reflectance = 0
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Sound") and not obj:FindFirstAncestorWhichIsA("Player") then
                obj:Stop()
            end
        end
        
        settings().Rendering.QualityLevel = 1
    end)
    
    WindUI:Notify({Title = "Ultra Anti Lag", Content = "White texture mode enabled", Duration = 3})
end

local function DisableAntiLag()
    if not antiLagEnabled then return end
    antiLagEnabled = false
    
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
        
        if workspace.Terrain then
            workspace.Terrain.Decoration = true
            workspace.Terrain.WaterReflectance = 0.5
            workspace.Terrain.WaterTransparency = 0.5
            workspace.Terrain.WaterWaveSize = 0.5
            workspace.Terrain.WaterWaveSpeed = 10
        end
        
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        
        settings().Rendering.QualityLevel = 10
    end)
    
    WindUI:Notify({Title = "Anti Lag", Content = "Graphics settings restored", Duration = 3})
end

-- =============================================================================
-- POSITION MANAGEMENT
-- =============================================================================

local function SaveCurrentPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        lastSavedPosition = character.HumanoidRootPart.Position
        return true
    end
    return false
end

local function LoadSavedPosition()
    if not lastSavedPosition then
        return false
    end
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(lastSavedPosition)
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
end

local function StopLockPosition()
    if not lockPositionEnabled then return end
    lockPositionEnabled = false
    
    if lockPositionLoop then
        lockPositionLoop:Disconnect()
        lockPositionLoop = nil
    end
end

-- =============================================================================
-- BYPASS SYSTEM
-- =============================================================================

local function ToggleFishingRadar()
    local success, result = pcall(function()
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local UpdateFishingRadar = Net:RemoteFunction("UpdateFishingRadar")
        
        local Data = Replion.Client:WaitReplion("Data")
        if not Data then
            return false, "Data Replion tidak ditemukan!"
        end

        local currentState = Data:Get("RegionsVisible")
        local desiredState = not currentState

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
    end
end

local function StopFishingRadar()
    if not fishingRadarEnabled then return end
    
    local success, message = ToggleFishingRadar()
    if success then
        fishingRadarEnabled = false
    end
end

local function ToggleDivingGear()
    local success, result = pcall(function()
        local Net = require(ReplicatedStorage.Packages.Net)
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        
        local DivingGear = ItemUtility.GetItemDataFromItemType("Gears", "Diving Gear")
        if not DivingGear then
            return false, "Diving Gear tidak ditemukan!"
        end

        local Data = Replion.Client:WaitReplion("Data")
        if not Data then
            return false, "Data Replion tidak ditemukan!"
        end

        local UnequipOxygenTank = Net:RemoteFunction("UnequipOxygenTank")
        local EquipOxygenTank = Net:RemoteFunction("EquipOxygenTank")

        local EquippedId = Data:Get("EquippedOxygenTankId")
        local isEquipped = EquippedId == DivingGear.Data.Id
        local success

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
    end
end

local function StopDivingGear()
    if not divingGearEnabled then return end
    
    local success, message = ToggleDivingGear()
    if success then
        divingGearEnabled = false
    end
end

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
        WindUI:Notify({Title = "Manual Sell", Content = result, Duration = 3})
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
                        end
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function StopAutoSell()
    if not autoSellEnabled then return end
    autoSellEnabled = false
    
    if autoSellLoop then
        task.cancel(autoSellLoop)
        autoSellLoop = nil
    end
end

local function SetAutoSellThreshold(amount)
    if type(amount) == "number" and amount > 0 then
        autoSellThreshold = amount
        return true
    end
    return false
end

-- =============================================================================
-- COORDINATE DISPLAY
-- =============================================================================

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
    Title = "v2.0",
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

AutoTab:Space()

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
        WindUI:Notify({
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
    Callback = function()
        local success, message = ToggleFishingRadar()
        if success then
            WindUI:Notify({Title = "Fishing Radar", Content = message, Duration = 3})
        end
    end
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
    Callback = function()
        local success, message = ToggleDivingGear()
        if success then
            WindUI:Notify({Title = "Diving Gear", Content = message, Duration = 3})
        end
    end
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
        WindUI:Notify({Title = "Bypass", Content = "All bypass features enabled", Duration = 3})
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
        WindUI:Notify({Title = "Bypass", Content = "All bypass features disabled", Duration = 3})
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

-- Display Name System Section
PlayerConfigTab:Section({
    Title = "Display Name System",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

PlayerConfigTab:Input({
    Title = "Custom Display Name",
    Desc = "Set your custom display name (max 20 chars)",
    Flag = "CustomDisplayName",
    Placeholder = "Enter custom name...",
    Callback = function(text)
        local success, message = SetCustomDisplayName(text)
        if success then
            WindUI:Notify({
                Title = "Display Name",
                Content = message,
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Display Name Error",
                Content = message,
                Duration = 4
            })
        end
    end
})

PlayerConfigTab:Toggle({
    Title = "Enable Custom Display Name",
    Desc = "Toggle custom display name on/off",
    Flag = "DisplayNameToggle",
    Default = false,
    Callback = function(state)
        ToggleDisplayName(state)
    end
})

PlayerConfigTab:Button({
    Title = "Reset to Original Name",
    Icon = "refresh-cw",
    Callback = function()
        ToggleDisplayName(false)
        customDisplayName = ""
        WindUI:Notify({
            Title = "Display Name",
            Content = "Display name reset to original",
            Duration = 3
        })
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
    Callback = function()
        if SaveCurrentPosition() then
            WindUI:Notify({Title = "Position Saved", Content = "Position saved successfully", Duration = 2})
        end
    end
})

PlayerConfigTab:Button({
    Title = "Load Position",
    Icon = "navigation",
    Callback = function()
        if LoadSavedPosition() then
            WindUI:Notify({Title = "Position Loaded", Content = "Teleported to saved position", Duration = 2})
        else
            WindUI:Notify({Title = "Load Failed", Content = "No position saved", Duration = 2})
        end
    end
})

PlayerConfigTab:Toggle({
    Title = "Lock Position",
    Desc = "Prevent movement from saved position",
    Flag = "LockPositionToggle",
    Default = false,
    Callback = function(state)
        if state then
            StartLockPosition()
            WindUI:Notify({Title = "Position Lock", Content = "Player position locked", Duration = 2})
        else
            StopLockPosition()
            WindUI:Notify({Title = "Position Lock", Content = "Player position unlocked", Duration = 2})
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
            WindUI:Notify({Title = "Reset", Content = "Movement reset to default", Duration = 2})
        end
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
        WindUI:Notify({Title = "Performance", Content = "Maximum performance enabled", Duration = 2})
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
        "Fishermand Iland"
    },
    Value = "Kohana",
    Callback = function(selected)
        currentSelectedMap = selected
    end
})

TeleportTab:Button({
    Title = "Teleport Now",
    Icon = "navigation",
    Callback = function()
        local targetPosition
        
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
            targetPosition = Vector3.new(-637, 16, 626)
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            WindUI:Notify({
                Title = "Teleport Success", 
                Content = string.format("Teleported to %s", currentSelectedMap),
                Duration = 3
            })
        else
            WindUI:Notify({
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

-- ========== SETTINGS TAB ==========
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings-2",
})

SettingsTab:Section({
    Title = "UI Management",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

SettingsTab:Button({
    Title = "Unload Hub",
    Icon = "power",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Center",
    Callback = UnloadUI
})

SettingsTab:Button({
    Title = "Reload UI",
    Icon = "refresh-cw",
    Color = Color3.fromHex("#30a2ff"),
    Justify = "Center",
    Callback = ReloadUI
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
        WindUI:Notify({Title = "Clean", Content = "UI cleaned", Duration = 2})
    end
})

SettingsTab:Space()

SettingsTab:Section({
    Title = "System Information",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

SettingsTab:Label({
    Title = "Player Name: " .. LocalPlayer.Name,
    Icon = "user",
})

SettingsTab:Label({
    Title = "Display Name: " .. LocalPlayer.DisplayName,
    Icon = "tag",
})

SettingsTab:Label({
    Title = "Account Age: " .. LocalPlayer.AccountAge .. " days",
    Icon = "calendar",
})

SettingsTab:Label({
    Title = "User ID: " .. LocalPlayer.UserId,
    Icon = "id-card",
})

-- Initial Notification
WindUI:Notify({
    Title = "Anggazyy Hub Ready", 
    Content = "WindUI System initialized successfully with FIXED Display Name & UI Systems",
    Duration = 4
})

print("Anggazyy Hub v2.0 Loaded Successfully!")
