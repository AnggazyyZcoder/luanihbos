--//////////////////////////////////////////////////////////////////////////////////
-- Anggazyy Hub - Fish It (FINAL) + Weather Machine + Trick or Treat + Blatant Fishing + Merchant System
-- WindUI Version - Modern, Mobile-Friendly Design
-- Author: Anggazyy (refactor)
--//////////////////////////////////////////////////////////////////////////////////

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

-- Import required modules
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local spr = require(ReplicatedStorage.Packages.spr)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Soundbook = require(ReplicatedStorage.Shared.Soundbook)
local GuiControl = require(ReplicatedStorage.Modules.GuiControl)
local HUDController = require(ReplicatedStorage.Controllers.HUDController)
local AnimationController = require(ReplicatedStorage.Controllers.AnimationController)
local TextNotificationController = require(ReplicatedStorage.Controllers.TextNotificationController)
local BlockedHumanoidStates = require(ReplicatedStorage.Shared.BlockedHumanoidStates)

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

-- Merchant System Variables
local merchantItems = {}
local selectedMerchantItem = nil

-- Blatant Fishing Configuration
local blatantReelDelay = 0.5  -- Default delay reel
local blatantFishingDelay = 0.90  -- Default delay fishing

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
        Title = "Welcome to Anggazyy Hub!",
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
-- MERCHANT SYSTEM MODULE - DIPERBAIKI DENGAN ERROR HANDLING
-- =============================================================================
local MerchantLite = {}

function MerchantLite.Initialize()
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        
        -- Load required modules dengan error handling
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        local TierUtility = require(ReplicatedStorage.Shared.TierUtility)
        local CurrencyUtility = require(ReplicatedStorage.Modules.CurrencyUtility)
        local MarketItemData = require(ReplicatedStorage.Shared.MarketItemData)
        local InventoryMapping = require(ReplicatedStorage.Shared.InventoryMapping)
        local PlayerStatsUtility = require(ReplicatedStorage.Shared.PlayerStatsUtility)
        local Net = require(ReplicatedStorage.Packages.Net)
        
        -- Cari TextNotificationController dengan path yang benar
        local TextNotificationController
        local success, controller = pcall(function()
            return require(ReplicatedStorage.Controllers.TextNotificationController)
        end)
        if not success then
            success, controller = pcall(function()
                return require(ReplicatedStorage.Client.TextNotificationController)
            end)
        end
        TextNotificationController = controller

        -- Remote untuk pembelian
        local PurchaseRemote = Net:RemoteFunction("PurchaseMarketItem")

        -- Variabel utama
        local LocalPlayer = Players.LocalPlayer
        local MerchantData = Replion.Client:WaitReplion("Merchant")
        local PlayerData = Replion.Client:WaitReplion("Data")

        ------------------------------------------------------------
        -- Fungsi ambil data item dari MarketItemData
        ------------------------------------------------------------
        function MerchantLite.GetMarketDataFromId(id)
            for _, v in pairs(MarketItemData) do
                if v.Id == id then
                    return v
                end
            end
            return nil
        end

        ------------------------------------------------------------
        -- Fungsi untuk cek apakah player sudah punya item
        ------------------------------------------------------------
        function MerchantLite.OwnsLocalItem(data)
            if not data.Type or not data.Identifier then
                return false
            end

            local itemInfo = ItemUtility.GetItemDataFromItemType(data.Type, data.Identifier)
            if not itemInfo then
                return false
            end

            local found = PlayerStatsUtility:GetItemFromInventory(PlayerData, function(item)
                return item.Id == itemInfo.Data.Id
            end, InventoryMapping[data.Type or "Items"])

            return found ~= nil
        end

        ------------------------------------------------------------
        -- Fungsi untuk menampilkan daftar item coin-only (bukan crate)
        ------------------------------------------------------------
        function MerchantLite.ListCoinItems()
            local items = {}
            local merchantItemsData = MerchantData:Get("Items") or MerchantData:Get("items") or {}

            for _, v in ipairs(merchantItemsData) do
                local itemId = v.Id or v.id or v.ItemId
                local data = MerchantLite.GetMarketDataFromId(itemId)

                if data and not data.SkinCrate and data.Currency == "Coins" then
                    local owned = MerchantLite.OwnsLocalItem(data)
                    local itemInfo = {
                        Name = data.Name or "Unknown",
                        Id = data.Id,
                        Price = data.Price or data.Cost or 0,
                        Currency = data.Currency,
                        Owned = owned,
                        DisplayName = ("%s - %s Coins [%s]"):format(data.Name or "Unknown", data.Price or 0, owned and "OWNED" or "AVAILABLE")
                    }
                    table.insert(items, itemInfo)
                end
            end

            table.sort(items, function(a, b)
                return a.Price < b.Price
            end)

            return items
        end

        ------------------------------------------------------------
        -- Fungsi pembelian item coin-only
        ------------------------------------------------------------
        function MerchantLite.BuyItem(itemId)
            local item = MerchantLite.GetMarketDataFromId(itemId)
            if not item then
                warn("❌ Item not found for ID:", itemId)
                return false, "Item not found"
            end

            if item.SkinCrate or item.Currency ~= "Coins" then
                warn("⏩ Skipped non-coin item:", itemId)
                return false, "Non-coin items not supported"
            end

            local currency = CurrencyUtility:GetCurrency(item.Currency)
            if not currency then
                warn("❌ Invalid currency for:", itemId)
                return false, "Invalid currency"
            end

            local playerCoins = PlayerData:Get(currency.Path) or 0
            if playerCoins < (item.Price or item.Cost or 0) then
                if TextNotificationController then
                    TextNotificationController:DeliverNotification({
                        Type = "Text",
                        Text = "You don't have enough coins!",
                        TextColor = { R = 255, G = 0, B = 0 },
                    })
                end
                return false, "Not enough coins"
            end

            local success = PurchaseRemote:InvokeServer(item.Id)
            if success then
                if TextNotificationController then
                    TextNotificationController:DeliverNotification({
                        Type = "Text",
                        Text = ("Purchased %s successfully!"):format(item.Name),
                        TextColor = { R = 0, G = 255, B = 0 },
                    })
                end
                return true, "Purchase successful"
            else
                if TextNotificationController then
                    TextNotificationController:DeliverNotification({
                        Type = "Text",
                        Text = ("Purchase failed for %s."):format(item.Name),
                        TextColor = { R = 255, G = 0, B = 0 },
                    })
                end
                return false, "Purchase failed"
            end
        end

        -- Load awal
        merchantItems = MerchantLite.ListCoinItems()
        return true
    end)

    if success then
        print("✅ Merchant system initialized successfully")
        Notify({
            Title = "Merchant System",
            Content = "Merchant system loaded successfully!",
            Duration = 3
        })
        return true
    else
        warn("❌ Failed to initialize merchant:", result)
        Notify({
            Title = "Merchant Error",
            Content = "Failed to load merchant system: " .. tostring(result),
            Duration = 4
        })
        return false
    end
end

------------------------------------------------------------
-- Fungsi tambahan merchant
------------------------------------------------------------
function MerchantLite.RefreshItems()
    local success, result = pcall(function()
        merchantItems = MerchantLite.ListCoinItems()
        return merchantItems
    end)
    if success then
        return merchantItems
    else
        warn("Failed to refresh merchant items:", result)
        return {}
    end
end

function MerchantLite.GetItemDisplayNames()
    local names = {}
    for _, item in ipairs(merchantItems or {}) do
        table.insert(names, item.DisplayName)
    end
    if #names == 0 then
        table.insert(names, "No items available - Refresh first")
    end
    return names
end

function MerchantLite.BuyItemByDisplayName(displayName)
    for _, item in ipairs(merchantItems or {}) do
        if item.DisplayName == displayName then
            return MerchantLite.BuyItem(item.Id)
        end
    end
    return false, "Item not found"
end

function MerchantLite.GetItemByDisplayName(displayName)
    for _, item in ipairs(merchantItems or {}) do
        if item.DisplayName == displayName then
            return item
        end
    end
    return nil
end

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
-- BLATANT FISHING SYSTEM - DIPERBAIKI
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

    -- Delay Fishing Complete sebelum loop Fast Fishing kembali melempar
    if blatantFishingDelay > 0 then
        task.wait(blatantFishingDelay)
    end
end

-- Fungsi HOOK untuk menimpa 'FishingRodStarted'
local function HookFishingRodStarted(rodData, minigameData)
    if isBlatantActive then
        -- Jika mode Blatant aktif, langsung selesaikan di thread terpisah
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
        
        -- Panggil RequestChargeFishingRod dengan parameter
        local castResult = module_upvr:RequestChargeFishingRod(mousePos, nil)
        
        _G.confirmFishingInput = nil
        return castResult
    end)
    
    return success
end

-- Main blatant casting function
local function BlatantCastFishingRod()
    -- Coba method 1: RequestChargeFishingRod dengan bypass
    local success = BlatantCastMethod1()
    if success then
        print("✅ Blatant Cast: Method 1 successful")
        return true
    end
    
    print("❌ Blatant Cast: Method 1 failed")
    return false
end

-- Blatant Fishing Loop
local function BlatantFishingLoop()
    while isBlatantActive do
        local castSuccess = BlatantCastFishingRod()
        
        if not castSuccess then
            print("🔄 Retrying cast...")
        end

        -- Delay sebelum cast berikutnya
        task.wait(blatantFishingDelay)
    end
end

-- Hook untuk RequestChargeFishingRod
local function HookRequestChargeFishingRod(arg1, arg2, arg3)
    if isBlatantActive then
        print("⚡ Blatant Mode: Fast casting via RequestChargeFishingRod")
        
        -- Di Blatant Mode, gunakan parameter untuk skip charging
        local mousePos = arg1 or GetSafeMousePosition()
        
        return originalRequestChargeFishingRod(mousePos, arg2, arg3)
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
        
        -- Jalankan loop Fast Fishing
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Add(task.spawn(BlatantFishingLoop))
        end
        
        Notify({Title = "⚡ Blatant Fishing", Content = "Fast fishing mode activated - Instant casting and bypassing minigame", Duration = 3})
        
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
        Notify({
            Title = "Weather List Updated",
            Content = string.format("Loaded %d available weathers", #newWeathers),
            Duration = 3
        })
    end
})

-- ========== MERCHANT TAB BARU - DITAMBAHKAN FITUR MERCHANT ==========
local MerchantTab = Window:Tab({
    Title = "Merchant",
    Icon = "shopping-bag",
})

MerchantTab:Section({
    Title = "Merchant System",
    Desc = "Buy items from merchant using coins",
})

-- Initialize merchant system
MerchantTab:Button({
    Title = "Initialize Merchant System",
    Icon = "zap",
    Callback = function()
        MerchantLite.Initialize()
    end
})

MerchantTab:Space()

-- Merchant Item Selection
MerchantTab:Dropdown({
    Title = "Select Item to Buy",
    Flag = "MerchantItemSelect",
    Values = {"Initialize merchant first..."},
    Value = "Initialize merchant first...",
    Callback = function(selected)
        selectedMerchantItem = selected
    end
})

MerchantTab:Button({
    Title = "Refresh Item List",
    Icon = "refresh-cw",
    Callback = function()
        local items = MerchantLite.RefreshItems()
        local displayNames = MerchantLite.GetItemDisplayNames()
        
        if #displayNames > 0 then
            Notify({
                Title = "Merchant Items",
                Content = string.format("Loaded %d available items", #items),
                Duration = 3
            })
            
            -- Show items in console for debugging
            print("=== 🛒 Available Merchant Items ===")
            for _, item in ipairs(items) do
                local status = item.Owned and "[✅ OWNED]" or "[🆕 AVAILABLE]"
                print(string.format("%s %s - %d Coins", status, item.Name, item.Price))
            end
        else
            Notify({
                Title = "Merchant Error",
                Content = "No items found or merchant not initialized",
                Duration = 3
            })
        end
    end
})

MerchantTab:Button({
    Title = "Buy Selected Item",
    Icon = "shopping-cart",
    Color = Color3.fromHex("#30ff6a"),
    Callback = function()
        if not selectedMerchantItem or selectedMerchantItem == "Initialize merchant first..." then
            Notify({
                Title = "Purchase Error",
                Content = "Please select an item first",
                Duration = 3
            })
            return
        end
        
        local success, message = MerchantLite.BuyItemByDisplayName(selectedMerchantItem)
        if success then
            Notify({
                Title = "✅ Purchase Successful",
                Content = "Item purchased successfully!",
                Duration = 3
            })
        else
            Notify({
                Title = "❌ Purchase Failed",
                Content = message or "Failed to purchase item",
                Duration = 4
            })
        end
    end
})

MerchantTab:Space()

-- Quick Buy Section
MerchantTab:Section({
    Title = "Quick Buy",
    Desc = "Quick purchase common items",
})

MerchantTab:Button({
    Title = "Buy Basic Rod",
    Icon = "fishing-rod",
    Callback = function()
        -- Try to find and buy basic fishing rod
        local items = MerchantLite.RefreshItems()
        for _, item in ipairs(items) do
            if string.find(item.Name:lower(), "basic") or string.find(item.Name:lower(), "rod") then
                local success, message = MerchantLite.BuyItem(item.Id)
                if success then
                    Notify({
                        Title = "✅ Rod Purchased",
                        Content = "Basic fishing rod purchased!",
                        Duration = 3
                    })
                end
                break
            end
        end
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

-- DROPDOWN UNTUK MAP TELEPORT - DITAMBAHKAN LOKASI BARU
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

-- BUTTON TELEPORT - DITAMBAHKAN FUNGSI TELEPORT KE LOKASI BARU
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
            -- Default position jika tidak ada yang cocok
            targetPosition = Vector3.new(-637, 16, 626)
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

-- ========== SETTINGS TAB ==========
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings-2",
})

SettingsTab:Section({
    Title = "UI Management",
    Desc = "Control the hub interface",
})

SettingsTab:Button({
    Title = "Unload Hub",
    Icon = "power",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Center",
    Callback = function()
        StopAutoFish()
        ToggleBlatantMode(false)
        Window:Destroy()
        Notify({Title = "Unload", Content = "Hub unloaded successfully", Duration = 2})
    end
})

-- Initial Notification
Notify({
    Title = "Anggazyy Hub Ready", 
    Content = "WindUI System initialized successfully with Merchant System + Blatant Fishing",
    Duration = 4
})

-- Auto-initialize merchant system after a delay
task.spawn(function()
    task.wait(5)
    MerchantLite.Initialize()
end)

--//////////////////////////////////////////////////////////////////////////////////
-- WindUI System Initialization Complete
--//////////////////////////////////////////////////////////////////////////////////
