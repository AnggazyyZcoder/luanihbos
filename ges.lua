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
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Import required modules dengan error handling
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
local blatantFishingDelay = 0.1  -- PERUBAHAN: Delay fishing di set rendah untuk SPAM CAST

-- UI Configuration
local COLOR_ENABLED = Color3.fromRGB(76, 175, 80)  -- Green
local COLOR_DISABLED = Color3.fromRGB(244, 67, 54) -- Red
local COLOR_PRIMARY = Color3.fromRGB(103, 58, 183) -- Purple
local COLOR_SECONDARY = Color3.fromRGB(30, 30, 46)  -- Dark

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

-- =============================================================================
-- NOTIFICATION SYSTEM
-- =============================================================================
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

-- =============================================================================
-- WELCOME POPUP - Tampilkan saat pertama kali execute script
-- =============================================================================
task.spawn(function()
    task.wait(1) -- Tunggu sebentar agar UI siap
    WindUI:Popup({
        Title = "WHERJEJJEE?!",
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
local function AntiKickReconnect()
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
-- DRONE CAMERA SYSTEM - Mobile Compatible Version
-- =============================================================================

-- Drone Camera Variables
local droneCameraEnabled = false
local droneCamera = nil
local droneBodyGyro = nil
local droneBodyVelocity = nil
local droneConnection = nil
local originalCamera = nil
local droneGui = nil
local droneControlsGui = nil
local mobileControlsGui = nil
local touchInput = nil
local virtualJoystick = nil

-- Check if running on mobile
local IS_MOBILE = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

-- Drone Configuration
local DRONE_CONFIG = {
    MoveSpeed = 25,
    BoostSpeed = 50,
    RotationSpeed = 2,
    MouseSensitivity = 0.5,
    TouchSensitivity = 2.0,
    MaxSpeed = 100,
    Acceleration = 2,
    Deceleration = 4
}

-- Current drone state
local droneState = {
    Velocity = Vector3.new(0, 0, 0),
    IsBoosting = false,
    CurrentSpeed = DRONE_CONFIG.MoveSpeed,
    MobileMoveInput = Vector2.new(0, 0),
    MobileLookInput = Vector2.new(0, 0)
}

-- Input states
local inputStates = {
    Forward = false,
    Backward = false,
    Left = false,
    Right = false,
    Up = false,
    Down = false
}

-- Mobile touch states
local mobileTouchStates = {
    JoystickActive = false,
    LookActive = false,
    JoystickPosition = Vector2.new(0, 0),
    LookPosition = Vector2.new(0, 0)
}

-- Function to create drone camera
local function CreateDroneCamera()
    -- Save original camera
    originalCamera = workspace.CurrentCamera
    
    -- Create drone part
    local drone = Instance.new("Part")
    drone.Name = "AnggazyyDroneCamera"
    drone.Anchored = false
    drone.CanCollide = false
    drone.Massless = true
    drone.Size = Vector3.new(2, 1, 3)
    drone.Transparency = 0.8
    drone.Material = Enum.Material.Neon
    drone.BrickColor = BrickColor.new("Bright blue")
    drone.Parent = workspace
    
    -- Position drone at player's position
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        drone.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
    else
        drone.CFrame = CFrame.new(0, 10, 0)
    end
    
    -- Add body gyro for rotation control
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "DroneBodyGyro"
    bodyGyro.P = 10000
    bodyGyro.D = 1000
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.CFrame = drone.CFrame
    bodyGyro.Parent = drone
    
    -- Add body velocity for movement control
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "DroneBodyVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.P = 10000
    bodyVelocity.Parent = drone
    
    -- Set camera to drone
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    workspace.CurrentCamera.CFrame = drone.CFrame
    
    droneCamera = drone
    droneBodyGyro = bodyGyro
    droneBodyVelocity = bodyVelocity
    
    return drone
end

-- Function to create mobile controls GUI
local function CreateMobileControlsGUI()
    if mobileControlsGui and mobileControlsGui.Parent then
        mobileControlsGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileDroneControls"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    
    -- Left Joystick (Movement)
    local joystickFrame = Instance.new("Frame")
    joystickFrame.Size = UDim2.new(0, 150, 0, 150)
    joystickFrame.Position = UDim2.new(0, 50, 1, -200)
    joystickFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    joystickFrame.BackgroundTransparency = 0.3
    joystickFrame.BorderSizePixel = 0
    joystickFrame.Parent = screenGui
    
    local joystickCorner = Instance.new("UICorner")
    joystickCorner.CornerRadius = UDim.new(1, 0)
    joystickCorner.Parent = joystickFrame
    
    local joystickStroke = Instance.new("UIStroke")
    joystickStroke.Color = Color3.fromRGB(76, 175, 80)
    joystickStroke.Thickness = 3
    joystickStroke.Parent = joystickFrame
    
    local joystickThumb = Instance.new("Frame")
    joystickThumb.Size = UDim2.new(0, 50, 0, 50)
    joystickThumb.Position = UDim2.new(0.5, -25, 0.5, -25)
    joystickThumb.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    joystickThumb.BorderSizePixel = 0
    joystickThumb.Parent = joystickFrame
    
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = joystickThumb
    
    -- Right Touch Area (Camera Look)
    local lookFrame = Instance.new("Frame")
    lookFrame.Size = UDim2.new(0, 300, 0, 200)
    lookFrame.Position = UDim2.new(1, -350, 0.5, -100)
    lookFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    lookFrame.BackgroundTransparency = 0.7
    lookFrame.BorderSizePixel = 0
    lookFrame.Parent = screenGui
    
    local lookCorner = Instance.new("UICorner")
    lookCorner.CornerRadius = UDim.new(0.1, 0)
    lookCorner.Parent = lookFrame
    
    local lookLabel = Instance.new("TextLabel")
    lookLabel.Size = UDim2.new(1, 0, 1, 0)
    lookLabel.BackgroundTransparency = 1
    lookLabel.Text = "Touch to Look Around"
    lookLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    lookLabel.Font = Enum.Font.Gotham
    lookLabel.TextSize = 14
    lookLabel.Parent = lookFrame
    
    -- Action Buttons
    local buttonSize = UDim2.new(0, 80, 0, 80)
    
    -- Ascend Button
    local ascendButton = Instance.new("TextButton")
    ascendButton.Size = buttonSize
    ascendButton.Position = UDim2.new(1, -100, 1, -250)
    ascendButton.BackgroundColor3 = Color3.fromRGB(103, 58, 183)
    ascendButton.BackgroundTransparency = 0.3
    ascendButton.Text = "↑"
    ascendButton.TextColor3 = Color3.new(1, 1, 1)
    ascendButton.Font = Enum.Font.GothamBold
    ascendButton.TextSize = 20
    ascendButton.Parent = screenGui
    
    local ascendCorner = Instance.new("UICorner")
    ascendCorner.CornerRadius = UDim.new(0.2, 0)
    ascendCorner.Parent = ascendButton
    
    -- Descend Button
    local descendButton = Instance.new("TextButton")
    descendButton.Size = buttonSize
    descendButton.Position = UDim2.new(1, -100, 1, -150)
    descendButton.BackgroundColor3 = Color3.fromRGB(103, 58, 183)
    descendButton.BackgroundTransparency = 0.3
    descendButton.Text = "↓"
    descendButton.TextColor3 = Color3.new(1, 1, 1)
    descendButton.Font = Enum.Font.GothamBold
    descendButton.TextSize = 20
    descendButton.Parent = screenGui
    
    local descendCorner = Instance.new("UICorner")
    descendCorner.CornerRadius = UDim.new(0.2, 0)
    descendCorner.Parent = descendButton
    
    -- Boost Button
    local boostButton = Instance.new("TextButton")
    boostButton.Size = buttonSize
    boostButton.Position = UDim2.new(1, -200, 1, -150)
    boostButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    boostButton.BackgroundTransparency = 0.3
    boostButton.Text = "BOOST"
    boostButton.TextColor3 = Color3.new(1, 1, 1)
    boostButton.Font = Enum.Font.GothamBold
    boostButton.TextSize = 12
    boostButton.Parent = screenGui
    
    local boostCorner = Instance.new("UICorner")
    boostCorner.CornerRadius = UDim.new(0.2, 0)
    boostCorner.Parent = boostButton
    
    -- Exit Button
    local exitButton = Instance.new("TextButton")
    exitButton.Size = UDim2.new(0, 100, 0, 50)
    exitButton.Position = UDim2.new(0.5, -50, 1, -80)
    exitButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    exitButton.BackgroundTransparency = 0.3
    exitButton.Text = "EXIT DRONE"
    exitButton.TextColor3 = Color3.new(1, 1, 1)
    exitButton.Font = Enum.Font.GothamBold
    exitButton.TextSize = 14
    exitButton.Parent = screenGui
    
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0.2, 0)
    exitCorner.Parent = exitButton
    
    -- Store references
    virtualJoystick = {
        Frame = joystickFrame,
        Thumb = joystickThumb,
        StartPosition = joystickFrame.AbsolutePosition + joystickFrame.AbsoluteSize / 2
    }
    
    -- Connect mobile button events
    ascendButton.MouseButton1Down:Connect(function()
        inputStates.Up = true
    end)
    
    ascendButton.MouseButton1Up:Connect(function()
        inputStates.Up = false
    end)
    
    descendButton.MouseButton1Down:Connect(function()
        inputStates.Down = true
    end)
    
    descendButton.MouseButton1Up:Connect(function()
        inputStates.Down = false
    end)
    
    boostButton.MouseButton1Click:Connect(function()
        droneState.IsBoosting = not droneState.IsBoosting
        droneState.CurrentSpeed = droneState.IsBoosting and DRONE_CONFIG.BoostSpeed or DRONE_CONFIG.MoveSpeed
        boostButton.BackgroundColor3 = droneState.IsBoosting and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
    end)
    
    exitButton.MouseButton1Click:Connect(function()
        ToggleDroneCamera(false)
    end)
    
    mobileControlsGui = screenGui
    return screenGui
end

-- Function to handle mobile touch input
local function HandleMobileTouchInput(input, gameProcessed)
    if gameProcessed or not droneCameraEnabled or not mobileControlsGui then return end
    
    if input.UserInputType == Enum.UserInputType.Touch then
        local touchPosition = Vector2.new(input.Position.X, input.Position.Y)
        
        -- Check if touch is in joystick area
        local joystickFrame = virtualJoystick.Frame
        local joystickPosition = joystickFrame.AbsolutePosition
        local joystickSize = joystickFrame.AbsoluteSize
        
        if input.UserInputState == Enum.UserInputState.Begin then
            -- Check joystick area
            if touchPosition.X >= joystickPosition.X and touchPosition.X <= joystickPosition.X + joystickSize.X and
               touchPosition.Y >= joystickPosition.Y and touchPosition.Y <= joystickPosition.Y + joystickSize.Y then
                mobileTouchStates.JoystickActive = true
                mobileTouchStates.JoystickPosition = touchPosition
            else
                -- Check look area
                local lookFrame = mobileControlsGui:FindFirstChild("Frame")
                if lookFrame then
                    local lookPosition = lookFrame.AbsolutePosition
                    local lookSize = lookFrame.AbsoluteSize
                    if touchPosition.X >= lookPosition.X and touchPosition.X <= lookPosition.X + lookSize.X and
                       touchPosition.Y >= lookPosition.Y and touchPosition.Y <= lookPosition.Y + lookSize.Y then
                        mobileTouchStates.LookActive = true
                        mobileTouchStates.LookPosition = touchPosition
                    end
                end
            end
            
        elseif input.UserInputState == Enum.UserInputState.Change then
            if mobileTouchStates.JoystickActive then
                local delta = (touchPosition - virtualJoystick.StartPosition)
                local maxDistance = joystickSize.X / 3
                local direction = delta / maxDistance
                
                -- Clamp the direction
                if direction.Magnitude > 1 then
                    direction = direction.Unit
                end
                
                -- Update joystick thumb position
                virtualJoystick.Thumb.Position = UDim2.new(
                    0.5 + (direction.X * 0.3),
                    0,
                    0.5 + (direction.Y * 0.3),
                    0
                )
                
                droneState.MobileMoveInput = Vector2.new(direction.X, -direction.Y)
                
            elseif mobileTouchStates.LookActive then
                local delta = (touchPosition - mobileTouchStates.LookPosition) * DRONE_CONFIG.TouchSensitivity * 0.01
                droneState.MobileLookInput = Vector2.new(-delta.X, -delta.Y)
                mobileTouchStates.LookPosition = touchPosition
            end
            
        elseif input.UserInputState == Enum.UserInputState.End then
            if mobileTouchStates.JoystickActive then
                mobileTouchStates.JoystickActive = false
                droneState.MobileMoveInput = Vector2.new(0, 0)
                -- Reset joystick thumb
                virtualJoystick.Thumb.Position = UDim2.new(0.5, -25, 0.5, -25)
            elseif mobileTouchStates.LookActive then
                mobileTouchStates.LookActive = false
                droneState.MobileLookInput = Vector2.new(0, 0)
            end
        end
    end
end

-- Function to create drone info display (Mobile Optimized)
local function CreateDroneInfoDisplay()
    if droneGui and droneGui.Parent then
        droneGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DroneInfoDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    
    -- Info frame (positioned at top for mobile)
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -40, 0, IS_MOBILE and 100 or 80)
    infoFrame.Position = UDim2.new(0, 20, 0, 10)
    infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    infoFrame.BackgroundTransparency = 0.3
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = infoFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(76, 175, 80)
    stroke.Thickness = 2
    stroke.Parent = infoFrame
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, IS_MOBILE and 30 or 25)
    statusLabel.Position = UDim2.new(0, 5, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🚁 DRONE MODE ACTIVE" .. (IS_MOBILE and " (MOBILE)" or "")
    statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = IS_MOBILE and 16 or 14
    statusLabel.Parent = infoFrame
    
    -- Speed info
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, -5, 0, IS_MOBILE and 25 or 20)
    speedLabel.Position = UDim2.new(0, 5, 0, IS_MOBILE and 35 or 30)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Speed: " .. DRONE_CONFIG.MoveSpeed
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = IS_MOBILE and 14 or 12
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = infoFrame
    
    -- Mode info
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0.5, -5, 0, IS_MOBILE and 25 or 20)
    modeLabel.Position = UDim2.new(0.5, 0, 0, IS_MOBILE and 35 or 30)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "Mode: " .. (droneState.IsBoosting and "BOOST" or "NORMAL")
    modeLabel.TextColor3 = droneState.IsBoosting and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(200, 200, 200)
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = IS_MOBILE and 14 or 12
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = infoFrame
    
    -- Position info
    local posLabel = Instance.new("TextLabel")
    posLabel.Size = UDim2.new(1, -10, 0, IS_MOBILE and 25 or 20)
    posLabel.Position = UDim2.new(0, 5, 0, IS_MOBILE and 60 or 50)
    posLabel.BackgroundTransparency = 1
    posLabel.Text = "X: 0 Y: 0 Z: 0"
    posLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    posLabel.Font = Enum.Font.Gotham
    posLabel.TextSize = IS_MOBILE and 12 or 11
    posLabel.TextXAlignment = Enum.TextXAlignment.Left
    posLabel.Parent = infoFrame
    
    droneGui = screenGui
    
    -- Update position info in real-time
    task.spawn(function()
        while droneGui and droneGui.Parent and droneCameraEnabled do
            if droneCamera then
                local pos = droneCamera.Position
                posLabel.Text = string.format("X: %d Y: %d Z: %d", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
                
                -- Update speed and mode display
                local speed = droneState.IsBoosting and DRONE_CONFIG.BoostSpeed or DRONE_CONFIG.MoveSpeed
                speedLabel.Text = "Speed: " .. speed
                modeLabel.Text = "Mode: " .. (droneState.IsBoosting and "BOOST" or "NORMAL")
                modeLabel.TextColor3 = droneState.IsBoosting and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(200, 200, 200)
            end
            task.wait(0.1)
        end
    end)
    
    return screenGui
end

-- Function to handle desktop input
local function HandleDroneInput(input, gameProcessed)
    if gameProcessed or not droneCameraEnabled or not droneCamera then return end
    
    local keyCode = input.KeyCode
    
    -- Movement keys
    if keyCode == Enum.KeyCode.W then
        inputStates.Forward = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.S then
        inputStates.Backward = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.A then
        inputStates.Left = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.D then
        inputStates.Right = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.Space then
        inputStates.Up = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.LeftShift then
        inputStates.Down = input.UserInputState == Enum.UserInputState.Begin
    elseif keyCode == Enum.KeyCode.F and input.UserInputState == Enum.UserInputState.Begin then
        droneState.IsBoosting = not droneState.IsBoosting
        droneState.CurrentSpeed = droneState.IsBoosting and DRONE_CONFIG.BoostSpeed or DRONE_CONFIG.MoveSpeed
    elseif keyCode == Enum.KeyCode.R and input.UserInputState == Enum.UserInputState.Begin then
        -- Reset camera orientation
        if droneBodyGyro then
            droneBodyGyro.CFrame = CFrame.new(droneCamera.Position, droneCamera.Position + Vector3.new(0, 0, -1))
        end
    elseif keyCode == Enum.KeyCode.X and input.UserInputState == Enum.UserInputState.Begin then
        ToggleDroneCamera(false)
    end
end

-- Function to handle mouse movement
local function HandleMouseMovement(input)
    if not droneCameraEnabled or not droneBodyGyro then return end
    
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Delta.X, input.Delta.Y) * DRONE_CONFIG.MouseSensitivity
        
        if droneBodyGyro then
            local currentCF = droneBodyGyro.CFrame
            local yaw = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -delta.X * 0.01)
            local pitch = CFrame.fromAxisAngle(currentCF.RightVector, -delta.Y * 0.01)
            
            droneBodyGyro.CFrame = currentCF * yaw * pitch
        end
    end
end

-- Function to handle mouse wheel
local function HandleMouseWheel(input)
    if not droneCameraEnabled then return end
    
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        DRONE_CONFIG.MouseSensitivity = math.clamp(
            DRONE_CONFIG.MouseSensitivity + (input.Position.Z * 0.1),
            0.1,
            2.0
        )
    end
end

-- Modified movement function for mobile support
local function UpdateDroneMovement()
    if not droneCameraEnabled or not droneCamera or not droneBodyVelocity then return end
    
    local moveDirection = Vector3.new(0, 0, 0)
    local cameraCF = droneBodyGyro and droneBodyGyro.CFrame or droneCamera.CFrame
    
    if IS_MOBILE then
        -- Mobile movement using virtual joystick
        local joystickInput = droneState.MobileMoveInput
        if joystickInput.Magnitude > 0.1 then
            moveDirection = moveDirection + (cameraCF.LookVector * joystickInput.Y)
            moveDirection = moveDirection + (cameraCF.RightVector * joystickInput.X)
        end
        
        -- Mobile camera look
        local lookInput = droneState.MobileLookInput
        if lookInput.Magnitude > 0 then
            if droneBodyGyro then
                local yaw = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -lookInput.X)
                local pitch = CFrame.fromAxisAngle(cameraCF.RightVector, -lookInput.Y)
                droneBodyGyro.CFrame = cameraCF * yaw * pitch
            end
        end
        
    else
        -- Desktop movement (original code)
        if inputStates.Forward then
            moveDirection = moveDirection + cameraCF.LookVector
        end
        if inputStates.Backward then
            moveDirection = moveDirection - cameraCF.LookVector
        end
        if inputStates.Right then
            moveDirection = moveDirection + cameraCF.RightVector
        end
        if inputStates.Left then
            moveDirection = moveDirection - cameraCF.RightVector
        end
    end
    
    -- Vertical movement (both mobile and desktop)
    if inputStates.Up then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if inputStates.Down then
        moveDirection = moveDirection + Vector3.new(0, -1, 0)
    end
    
    -- Normalize direction and apply speed
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * droneState.CurrentSpeed
    end
    
    -- Apply smooth acceleration
    local targetVelocity = moveDirection
    droneState.Velocity = droneState.Velocity:Lerp(targetVelocity, 0.3)
    
    -- Set velocity
    droneBodyVelocity.Velocity = droneState.Velocity
    
    -- Desktop rotation (Q/E keys)
    if not IS_MOBILE and droneBodyGyro then
        local rotation = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            rotation = rotation + DRONE_CONFIG.RotationSpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
            rotation = rotation - DRONE_CONFIG.RotationSpeed
        end
        
        if rotation ~= 0 then
            local rotateCF = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), rotation * 0.05)
            droneBodyGyro.CFrame = droneBodyGyro.CFrame * rotateCF
        end
    end
end

-- Modified toggle function with mobile support
local function ToggleDroneCamera(enable)
    if enable == droneCameraEnabled then return end
    
    if enable then
        -- Enable drone camera
        droneCameraEnabled = true
        
        -- Create drone and GUI
        CreateDroneCamera()
        CreateDroneInfoDisplay()
        
        -- Create mobile controls if on mobile
        if IS_MOBILE then
            CreateMobileControlsGUI()
        end
        
        -- Connect input events
        droneConnection = RunService.Heartbeat:Connect(UpdateDroneMovement)
        
        if IS_MOBILE then
            -- Mobile touch events
            UserInputService.TouchStarted:Connect(HandleMobileTouchInput)
            UserInputService.TouchMoved:Connect(HandleMobileTouchInput)
            UserInputService.TouchEnded:Connect(HandleMobileTouchInput)
        else
            -- Desktop input events
            UserInputService.InputBegan:Connect(HandleDroneInput)
            UserInputService.InputEnded:Connect(HandleDroneInput)
            UserInputService.InputChanged:Connect(HandleMouseMovement)
            UserInputService.InputChanged:Connect(HandleMouseWheel)
        end
        
        -- Hide player character if exists
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 1
                end
            end
        end
        
        local platformText = IS_MOBILE and "Mobile controls activated!" or "Desktop controls activated!"
        Notify({
            Title = "🚁 Drone Camera", 
            Content = "Drone mode activated! " .. platformText,
            Duration = 5
        })
        
    else
        -- Disable drone camera
        droneCameraEnabled = false
        
        -- Disconnect events
        if droneConnection then
            droneConnection:Disconnect()
            droneConnection = nil
        end
        
        -- Restore original camera
        if originalCamera then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
        
        -- Clean up drone
        if droneCamera then
            droneCamera:Destroy()
            droneCamera = nil
        end
        
        -- Clean up GUI
        if droneControlsGui then
            droneControlsGui:Destroy()
            droneControlsGui = nil
        end
        
        if droneGui then
            droneGui:Destroy()
            droneGui = nil
        end
        
        if mobileControlsGui then
            mobileControlsGui:Destroy()
            mobileControlsGui = nil
        end
        
        -- Show player character
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
        
        -- Reset input states
        for key, _ in pairs(inputStates) do
            inputStates[key] = false
        end
        
        droneState = {
            Velocity = Vector3.new(0, 0, 0),
            IsBoosting = false,
            CurrentSpeed = DRONE_CONFIG.MoveSpeed,
            MobileMoveInput = Vector2.new(0, 0),
            MobileLookInput = Vector2.new(0, 0)
        }
        
        Notify({
            Title = "🚁 Drone Camera", 
            Content = "Drone mode deactivated.",
            Duration = 3
        })
    end
end

-- Mobile-specific functions
local function SetTouchSensitivity(sensitivity)
    if type(sensitivity) == "number" and sensitivity >= 0.5 and sensitivity <= 5.0 then
        DRONE_CONFIG.TouchSensitivity = sensitivity
        return true
    end
    return false
end

-- Drone configuration functions
local function SetDroneSpeed(speed)
    if type(speed) == "number" and speed > 0 and speed <= DRONE_CONFIG.MaxSpeed then
        DRONE_CONFIG.MoveSpeed = speed
        if not droneState.IsBoosting then
            droneState.CurrentSpeed = speed
        end
        return true
    end
    return false
end

local function SetDroneBoostSpeed(speed)
    if type(speed) == "number" and speed > 0 and speed <= DRONE_CONFIG.MaxSpeed then
        DRONE_CONFIG.BoostSpeed = speed
        if droneState.IsBoosting then
            droneState.CurrentSpeed = speed
        end
        return true
    end
    return false
end

local function SetDroneSensitivity(sensitivity)
    if type(sensitivity) == "number" and sensitivity >= 0.1 and sensitivity <= 2.0 then
        DRONE_CONFIG.MouseSensitivity = sensitivity
        return true
    end
    return false
end

-- Cinematic camera modes
local function SetCinematicMode(mode)
    if not droneCameraEnabled then return end
    
    local modes = {
        ["Default"] = {MoveSpeed = 25, BoostSpeed = 50, Sensitivity = 0.5},
        ["Cinematic"] = {MoveSpeed = 15, BoostSpeed = 30, Sensitivity = 0.3},
        ["Action"] = {MoveSpeed = 35, BoostSpeed = 70, Sensitivity = 0.8},
        ["Precision"] = {MoveSpeed = 10, BoostSpeed = 20, Sensitivity = 0.2},
        ["Mobile"] = {MoveSpeed = 20, BoostSpeed = 40, Sensitivity = 2.0}
    }
    
    if modes[mode] then
        DRONE_CONFIG.MoveSpeed = modes[mode].MoveSpeed
        DRONE_CONFIG.BoostSpeed = modes[mode].BoostSpeed
        if IS_MOBILE then
            DRONE_CONFIG.TouchSensitivity = modes[mode].Sensitivity
        else
            DRONE_CONFIG.MouseSensitivity = modes[mode].Sensitivity
        end
        
        if not droneState.IsBoosting then
            droneState.CurrentSpeed = DRONE_CONFIG.MoveSpeed
        end
        
        Notify({
            Title = "🎬 Cinematic Mode",
            Content = mode .. " mode activated",
            Duration = 3
        })
    end
end

-- Function to toggle drone freecam
local function ToggleFreecam()
    if not droneCameraEnabled or not droneCamera then return end
    
    droneCamera.CanCollide = not droneCamera.CanCollide
    Notify({
        Title = "🚁 Freecam",
        Content = droneCamera.CanCollide and "Collision: ON" or "Collision: OFF",
        Duration = 2
    })
end

-- Function to save drone position
local savedDronePositions = {}
local function SaveDronePosition(name)
    if not droneCameraEnabled or not droneCamera then return false end
    
    savedDronePositions[name] = {
        Position = droneCamera.Position,
        Orientation = droneCamera.Orientation
    }
    
    Notify({
        Title = "📍 Position Saved",
        Content = "Drone position '" .. name .. "' saved",
        Duration = 3
    })
    
    return true
end

-- Function to load drone position
local function LoadDronePosition(name)
    if not droneCameraEnabled or not droneCamera or not savedDronePositions[name] then return false end
    
    local pos = savedDronePositions[name]
    droneCamera.CFrame = CFrame.new(pos.Position) * CFrame.Angles(
        math.rad(pos.Orientation.X),
        math.rad(pos.Orientation.Y),
        math.rad(pos.Orientation.Z)
    )
    
    Notify({
        Title = "📍 Position Loaded",
        Content = "Teleported to '" .. name .. "'",
        Duration = 3
    })
    
    return true
end

-- Auto-adjust for mobile
local function AutoAdjustForMobile()
    if IS_MOBILE then
        -- Adjust settings for better mobile experience
        DRONE_CONFIG.MoveSpeed = 20
        DRONE_CONFIG.BoostSpeed = 40
        DRONE_CONFIG.TouchSensitivity = 2.0
    end
end

-- Call auto-adjust on startup
AutoAdjustForMobile()

-- =============================================================================
-- BLATANT FISHING SYSTEM - FIXED INSTANT CAST VERSION
-- =============================================================================

-- Variabel untuk tracking status
local isBlatantInitialized = false
local blatantLoopRunning = false

local function InitializeBlatantFishing()
    if isBlatantInitialized then return true end
    
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
        
        if not module_upvr then
            return false, "Fishing module not found"
        end
        
        -- Get remote events/functions
        FISHING_COMPLETED_REMOTE = Net_upvr:RemoteEvent("FishingCompleted")
        RequestFishingMinigameStarted_Net = Net_upvr:RemoteFunction("RequestFishingMinigameStarted")
        
        -- Save original functions
        originalFishingRodStarted = module_upvr.FishingRodStarted
        originalSendFishingRequestToServer = module_upvr.SendFishingRequestToServer
        originalRequestChargeFishingRod = module_upvr.RequestChargeFishingRod
        
        -- Initialize trove
        BLATANT_MODE_TROVE = Trove_upvr.new()
        
        isBlatantInitialized = true
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

-- =============================================================================
-- INSTANT CAST CORE FUNCTIONS
-- =============================================================================

local function GetSafeMousePosition()
    local CurrentCamera = workspace.CurrentCamera
    
    if UserInputService.MouseEnabled then
        return UserInputService:GetMouseLocation()
    else
        local viewportSize = CurrentCamera.ViewportSize
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
end

-- Method 1: Direct server call - PALING EFEKTIF
local function InstantCastMethod1()
    local success, result = pcall(function()
        -- Get character position
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return false, "No character found"
        end
        
        -- Position di depan karakter
        local throwPosition = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 12
        local power = 0.5  -- Power default
        local castTime = workspace:GetServerTimeNow()
        
        print("🎯 Attempting direct server cast...")
        
        -- Direct invoke ke server tanpa proses charge client
        local serverSuccess, serverResult = RequestFishingMinigameStarted_Net:InvokeServer(
            throwPosition.Y,  -- Y position untuk raycast
            power,            -- Power fishing
            castTime          -- Timestamp
        )
        
        if serverSuccess then
            print("✅ Direct server cast SUCCESS")
            -- Trigger FishingRodStarted manually untuk memulai fishing process
            if module_upvr and module_upvr.FishingRodStarted then
                module_upvr:FishingRodStarted(serverResult)
            end
            return true
        else
            print("❌ Direct server cast failed:", tostring(serverResult))
            return false, tostring(serverResult)
        end
    end)
    
    if not success then
        print("❌ Direct cast error:", tostring(result))
    end
    
    return success
end

-- Method 2: Bypass charge system
local function InstantCastMethod2()
    local success, result = pcall(function()
        -- Bypass semua input confirmation
        _G.confirmFishingInput = function() 
            print("✅ Bypassing user input confirmation")
            return true 
        end
        
        local mousePos = GetSafeMousePosition()
        
        print("🎯 Attempting bypass charge cast...")
        
        -- Paksa skip charge dengan parameter ketiga = true
        local castResult = module_upvr:RequestChargeFishingRod(mousePos, nil, true)
        
        _G.confirmFishingInput = nil
        
        if castResult then
            print("✅ Bypass charge cast SUCCESS")
        else
            print("❌ Bypass charge cast failed")
        end
        
        return castResult
    end)
    
    if not success then
        print("❌ Bypass cast error:", tostring(result))
    end
    
    return success
end

-- Main instant casting function dengan fallback
local function InstantCastFishingRod()
    print("🎣 ATTEMPTING INSTANT CAST...")
    
    -- Cek apakah fishing rod equipped
    if not module_upvr then
        print("❌ Fishing module not loaded")
        return false
    end
    
    -- Cek cooldown
    if module_upvr:OnCooldown() then
        print("⏳ On cooldown, waiting...")
        return false
    end
    
    -- Coba method direct server call dulu (paling reliable)
    local success = InstantCastMethod1()
    if success then
        return true
    end
    
    -- Tunggu sebentar sebelum fallback
    task.wait(0.05)
    
    -- Fallback ke method bypass charge
    success = InstantCastMethod2()
    return success
end

-- =============================================================================
-- INSTANT COMPLETION SYSTEM
-- =============================================================================

local function InstantFishComplete(rodData, minigameData)
    print("⚡ INSTANT COMPLETION: Starting...")
    
    -- Tunggu delay reel yang sangat kecil
    if blatantReelDelay > 0 then
        print("⏳ Waiting reel delay:", blatantReelDelay)
        task.wait(blatantReelDelay)
    end
    
    -- Langsung complete fishing
    local success = pcall(function()
        FISHING_COMPLETED_REMOTE:FireServer() 
    end)
    
    if success then
        print("✅ INSTANT COMPLETION: Fishing completed!")
    else
        print("❌ INSTANT COMPLETION: Failed to complete fishing")
    end
end

-- Hook untuk FishingRodStarted - INSTANT VERSION
local function HookFishingRodStarted_Instant(rodData, minigameData)
    if isBlatantActive then
        print("⚡ HOOK: FishingRodStarted triggered - Auto completing...")
        
        -- Langsung complete fishing tanpa blocking loop utama
        task.spawn(function()
            InstantFishComplete(rodData, minigameData)
        end)
    else
        -- Jika tidak aktif, jalankan fungsi asli
        if originalFishingRodStarted then
            originalFishingRodStarted(rodData, minigameData)
        end
    end
end

-- Hook untuk RequestChargeFishingRod - INSTANT VERSION
local function HookRequestChargeFishingRod_Instant(arg1, arg2, arg3)
    if isBlatantActive then
        print("⚡ HOOK: RequestChargeFishingRod - Bypassing charge animation")
        
        -- Force skip charge dengan parameter true
        local mousePos = arg1 or GetSafeMousePosition()
        
        return originalRequestChargeFishingRod(mousePos, arg2, true)
    else
        return originalRequestChargeFishingRod(arg1, arg2, arg3)
    end
end

-- =============================================================================
-- ROBUST FISHING LOOP - DENGAN ERROR HANDLING
-- =============================================================================

local function RobustFishingLoop()
    if blatantLoopRunning then
        print("⚠️ Fishing loop already running")
        return
    end
    
    blatantLoopRunning = true
    local castCount = 0
    
    print("🚀 STARTING ROBUST FISHING LOOP...")
    
    while isBlatantActive do
        local success, error = pcall(function()
            -- Instant cast tanpa delay apapun
            local castSuccess = InstantCastFishingRod()
            
            if castSuccess then
                castCount = castCount + 1
                print("🎯 CAST SUCCESS #" .. castCount)
            else
                print("🔄 CAST FAILED - Retrying...")
            end

            -- Delay sangat kecil untuk spam maksimal
            if blatantFishingDelay > 0 then
                task.wait(blatantFishingDelay)
            end
        end)
        
        if not success then
            print("❌ LOOP ERROR:", error)
            -- Tunggu sebentar sebelum retry jika ada error
            task.wait(0.1)
        end
        
        -- Safety check
        if not isBlatantActive then break end
    end
    
    blatantLoopRunning = false
    print("🛑 FISHING LOOP STOPPED. Total casts:", castCount)
end

-- =============================================================================
-- IMPROVED TOGGLE SYSTEM - DENGAN BETTER ERROR HANDLING
-- =============================================================================

local function ToggleBlatantMode(enable)
    if enable == isBlatantActive then 
        print("ℹ️ Blatant mode already", enable and "enabled" or "disabled")
        return 
    end
    
    if enable then
        print("🔄 ENABLING BLATANT MODE...")
        
        -- Initialize system if not already initialized
        if not isBlatantInitialized then
            print("🔧 Initializing blatant system...")
            if not InitializeBlatantFishing() then
                Notify({Title = "❌ Error", Content = "Failed to initialize fishing system", Duration = 3})
                return false
            end
        end
        
        isBlatantActive = true
        print("✅ BLATANT MODE: ENABLED")
        
        -- Terapkan Hook pada fungsi-fungsi fishing
        if module_upvr then
            print("🔗 Applying hooks...")
            
            -- Hook FishingRodStarted
            if module_upvr.FishingRodStarted ~= HookFishingRodStarted_Instant then
                module_upvr.FishingRodStarted = HookFishingRodStarted_Instant
                print("✅ Hooked FishingRodStarted")
            end
            
            -- Hook RequestChargeFishingRod
            if module_upvr.RequestChargeFishingRod and module_upvr.RequestChargeFishingRod ~= HookRequestChargeFishingRod_Instant then
                module_upvr.RequestChargeFishingRod = HookRequestChargeFishingRod_Instant
                print("✅ Hooked RequestChargeFishingRod")
            end
            
            -- Tambahkan fungsi pembersihan ke Trove
            if BLATANT_MODE_TROVE then
                BLATANT_MODE_TROVE:Add(function() 
                    print("🧹 Cleaning up hooks...")
                    if module_upvr then
                        if originalFishingRodStarted then
                            module_upvr.FishingRodStarted = originalFishingRodStarted 
                        end
                        if originalRequestChargeFishingRod then
                            module_upvr.RequestChargeFishingRod = originalRequestChargeFishingRod
                        end
                    end
                end)
            end
        else
            print("❌ Module_upvr not found!")
            Notify({Title = "❌ Error", Content = "Fishing module not found", Duration = 3})
            return false
        end
        
        -- Jalankan loop INSTANT Fishing
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Add(task.spawn(RobustFishingLoop))
            print("🔄 Starting fishing loop...")
        end
        
        Notify({Title = "⚡ INSTANT CAST", Content = "Instant fishing activated!", Duration = 3})
        
    else
        print("🔄 DISABLING BLATANT MODE...")
        isBlatantActive = false
        
        -- Cleanup
        if BLATANT_MODE_TROVE then
            BLATANT_MODE_TROVE:Clean()
            print("✅ Cleaned up trove")
        end
        
        -- Restore original functions
        if module_upvr then
            if originalFishingRodStarted then
                module_upvr.FishingRodStarted = originalFishingRodStarted
            end
            if originalRequestChargeFishingRod then
                module_upvr.RequestChargeFishingRod = originalRequestChargeFishingRod
            end
            print("✅ Restored original functions")
        end
        
        Notify({Title = "Blatant Fishing", Content = "Instant cast mode deactivated", Duration = 3})
        print("✅ BLATANT MODE: DISABLED")
    end
    
    return true
end

-- Manual fishing function untuk testing
local function ManualBlatantFish()
    if not isBlatantActive then
        Notify({Title = "Blatant Fishing", Content = "Please enable Blatant Mode first", Duration = 3})
        return
    end
    
    print("🎯 MANUAL CAST ATTEMPT...")
    pcall(function()
        local success = InstantCastFishingRod()
        if success then
            Notify({Title = "⚡ Manual Cast", Content = "Casting fishing rod instantly...", Duration = 2})
        else
            Notify({Title = "❌ Manual Cast Failed", Content = "Failed to cast fishing rod", Duration = 2})
        end
    end)
end

-- =============================================================================
-- CONFIGURATION FUNCTIONS
-- =============================================================================

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
    Title = "v1.0-beta",
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

-- Blatant Fishing Section - IMPROVED
AutoTab:Section({
    Title = "⚡ INSTANT CAST Fishing",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

AutoTab:Toggle({
    Title = "INSTANT CAST Mode",
    Desc = "No charge animation - Direct spam casting",
    Flag = "BlatantModeToggle",
    Default = false,
    Callback = function(state)
        local success = ToggleBlatantMode(state)
        if not success then
            -- Reset toggle state jika gagal
            AutoTab:GetElement("BlatantModeToggle"):Set(false)
        end
    end
})

AutoTab:Slider({
    Title = "Reel Delay",
    Desc = "Delay before auto-reeling fish (0 = INSTANT)",
    Flag = "BlatantReelDelay",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 1.0,
        Default = 0.1,
    },
    Callback = function(value)
        SetBlatantReelDelay(value)
    end
})

AutoTab:Slider({
    Title = "Cast Delay", 
    Desc = "Delay between instant casts (0 = MAX SPEED)",
    Flag = "BlatantFishingDelay",
    Step = 0.001,
    Value = {
        Min = 0,
        Max = 0.1,
        Default = 0.02,
    },
    Callback = function(value)
        SetBlatantFishingDelay(value)
    end
})

AutoTab:Button({
    Title = "Initialize System",
    Icon = "zap",
    Callback = function()
        local success = InitializeBlatantFishing()
        if success then
            Notify({Title = "✅ Success", Content = "System initialized!", Duration = 2})
        end
    end
})

AutoTab:Button({
    Title = "Manual Instant Cast",
    Icon = "fishing-rod",
    Callback = ManualBlatantFish
})

AutoTab:Space()

-- ========== DRONE CAMERA TAB (Mobile Compatible) ==========
local DroneTab = Window:Tab({
    Title = "Drone Camera",
    Icon = "camera",
})

DroneTab:Section({
    Title = "🚁 Drone Camera System",
    Desc = IS_MOBILE and "Mobile-optimized flying camera" or "Advanced flying camera for recording",
})

DroneTab:Toggle({
    Title = "Enable Drone Camera",
    Desc = IS_MOBILE and "Activate with mobile touch controls" or "Activate free-flying camera mode",
    Flag = "DroneToggle",
    Default = false,
    Callback = function(state)
        ToggleDroneCamera(state)
    end
})

DroneTab:Slider({
    Title = "Drone Speed",
    Desc = "Adjust movement speed",
    Flag = "DroneSpeed",
    Step = 1,
    Value = {
        Min = 10,
        Max = IS_MOBILE and 80 or 100,
        Default = IS_MOBILE and 20 or 25,
    },
    Callback = function(value)
        SetDroneSpeed(value)
    end
})

DroneTab:Slider({
    Title = "Boost Speed",
    Desc = "Adjust boost movement speed",
    Flag = "DroneBoostSpeed",
    Step = 1,
    Value = {
        Min = 20,
        Max = IS_MOBILE and 120 or 150,
        Default = IS_MOBILE and 40 or 50,
    },
    Callback = function(value)
        SetDroneBoostSpeed(value)
    end
})

if IS_MOBILE then
    DroneTab:Slider({
        Title = "Touch Sensitivity",
        Desc = "Adjust camera rotation sensitivity",
        Flag = "TouchSensitivity",
        Step = 0.1,
        Value = {
            Min = 0.5,
            Max = 5.0,
            Default = 2.0,
        },
        Callback = function(value)
            SetTouchSensitivity(value)
        end
    })
else
    DroneTab:Slider({
        Title = "Mouse Sensitivity",
        Desc = "Adjust camera rotation sensitivity",
        Flag = "DroneSensitivity",
        Step = 0.1,
        Value = {
            Min = 0.1,
            Max = 2.0,
            Default = 0.5,
        },
        Callback = function(value)
            SetDroneSensitivity(value)
        end
    })
end

DroneTab:Dropdown({
    Title = "Cinematic Mode",
    Desc = "Pre-configured camera modes",
    Flag = "CinematicMode",
    Values = {"Default", "Cinematic", "Action", "Precision", IS_MOBILE and "Mobile" or nil},
    Value = IS_MOBILE and "Mobile" or "Default",
    Callback = function(value)
        SetCinematicMode(value)
    end
})

DroneTab:Button({
    Title = IS_MOBILE and "Hide/Show Controls" or "Toggle Freecam",
    Icon = IS_MOBILE and "eye" or "eye",
    Callback = IS_MOBILE and function()
        if mobileControlsGui then
            mobileControlsGui.Enabled = not mobileControlsGui.Enabled
        end
    end or ToggleFreecam
})

DroneTab:Button({
    Title = "Reset Camera",
    Icon = "refresh-cw",
    Callback = function()
        if droneBodyGyro then
            droneBodyGyro.CFrame = CFrame.new(droneCamera.Position, droneCamera.Position + Vector3.new(0, 0, -1))
        end
    end
})

-- Mobile-specific info
if IS_MOBILE then
    DroneTab:Section({
        Title = "📱 Mobile Controls",
        Desc = "Virtual joystick and touch controls",
    })
    
    DroneTab:Label({
        Title = "Left Side: Virtual Joystick",
        Desc = "Move forward/backward/left/right"
    })
    
    DroneTab:Label({
        Title = "Right Side: Touch Look",
        Desc = "Drag to rotate camera view"
    })
    
    DroneTab:Label({
        Title = "Buttons: Ascend/Descend/Boost",
        Desc = "Tap buttons for vertical movement"
    })
end

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

-- Anti AFK Section - DITAMBAHKAN DI PLAYER CONFIG
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

-- Movement Configuration - DIPINDAHKAN DARI PLAYER STATS
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
        ToggleDroneCamera(false)
        DestroyCoordinateDisplay()
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

-- Initial Notification
Notify({
    Title = "Anggazyy Hub Ready", 
    Content = "WindUI System initialized successfully with UPDATED Blatant Fishing",
    Duration = 4
})

--//////////////////////////////////////////////////////////////////////////////////
-- WindUI System Initialization Complete
--//////////////////////////////////////////////////////////////////////////////////
