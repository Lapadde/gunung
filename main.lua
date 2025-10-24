-- Auto Play Script untuk Mendaki Gunung MT Daun Roblox
-- Script ini akan merekam gameplay Anda dan memutarnya kembali secara otomatis
loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Click%20Teleport.lua"))()
loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Infinite%20Jump.lua"))()
loadstring(game:HttpGet("https://obj.wearedevs.net/175531/scripts/Anti%20Afk%20Kick%20Script.lua"))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Recording Settings
local isRecording = false
local isPlaying = false
local recordingData = {}
local playbackData = {}
local currentPlaybackIndex = 1
local recordingStartTime = 0
local playbackStartTime = 0
local recordingInterval = 0 -- No fixed interval, record based on game frame rate
local adaptiveRecording = true -- Adaptive recording based on game performance
local playbackSpeed = 1.0
local recordingQuality = "High" -- High, Medium, Low
local playbackQuality = "Ultra" -- Ultra, High, Medium
local loopPlayback = false -- Loop playback when finished
local loopCount = 0 -- Counter for number of loops

-- Input Recording Settings
local recordInputs = true -- Record user inputs (keyboard, mouse)
local inputRecordingData = {}
local inputPlaybackData = {}
local currentInputPlaybackIndex = 1

-- Auto Play Settings
local autoPlayEnabled = false
local autoWalkEnabled = false
local autoJumpEnabled = false
local autoClimbEnabled = false
local followPathEnabled = false
local obstacleAvoidanceEnabled = true
local infiniteJumpEnabled = false

-- Anti-Idle Settings
local antiIdleEnabled = false
local antiIdleInterval = 15 -- Detik antara gerakan anti-idle
local antiIdleLastAction = 0
local antiIdleActions = {"move", "jump", "look", "camera"} -- Jenis gerakan anti-idle
local antiIdleIntensity = 1 -- Intensitas gerakan (1 = kecil, 2 = sedang, 3 = besar)

-- Advanced Anti-Idle (Disable Idled Event)
local advancedAntiIdleEnabled = false
local idledConnections = {}

-- Define getconnections function if not available
local getconnections = getconnections or function(signal)
    -- Fallback implementation for executors that don't have getconnections
    local connections = {}
    -- Try to get connections using debug library if available
    local success, result = pcall(function()
        return debug.getupvalue(signal.Connect, 1)
    end)
    if not success then
        -- If debug method fails, return empty table
        return connections
    end
    return connections
end

-- Movement Settings (TIDAK MENGUBAH MOVEMENT SETTINGS)
local detectionDistance = 50
local jumpCooldown = 0.5
local lastJumpTime = 0

-- Path Following Settings
local pathPoints = {}
local currentPathIndex = 1
local pathTolerance = 5
local pathUpdateInterval = 2
local lastPathUpdate = 0

-- Obstacle Detection Settings
local obstacleKeywords = {"wall", "rock", "stone", "boulder", "tree", "log", "barrier", "fence"}
local climbableKeywords = {"ladder", "rope", "vine", "climb", "step", "stair", "platform"}

-- Player State
local isMoving = false
local isJumping = false
local isClimbing = false
local lastPosition = Vector3.new(0, 0, 0)
local stuckCounter = 0
local maxStuckTime = 3

-- Infinite Jump Settings
local jumpCount = 0
local maxJumps = 10
local lastJumpTime = 0
local jumpCooldown = 0.1 -- Reduced cooldown for spam jumping
local isGrounded = false
local spamJumpEnabled = true -- Allow spam jumping

-- Saved Recordings
local savedRecordings = {}
local currentRecordingName = ""

-- GUI Setup
local function createAutoPlayGUI()
    local existingGUI = player.PlayerGui:FindFirstChild("AutoPlayGUI")
    if existingGUI then
        existingGUI:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoPlayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 650)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    title.BorderSizePixel = 0
    title.Text = "🎮 MT Daun Recorder & Auto Play 🎮"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Auto Play Toggle
    local autoPlayToggle = Instance.new("TextButton")
    autoPlayToggle.Name = "AutoPlayToggle"
    autoPlayToggle.Size = UDim2.new(1, -20, 0, 40)
    autoPlayToggle.Position = UDim2.new(0, 10, 0, 60)
    autoPlayToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    autoPlayToggle.BorderSizePixel = 0
    autoPlayToggle.Text = "🤖 Auto Play: OFF"
    autoPlayToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoPlayToggle.TextScaled = true
    autoPlayToggle.Font = Enum.Font.Gotham
    autoPlayToggle.Parent = mainFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = autoPlayToggle
    
    -- Recording Section
    local recordingFrame = Instance.new("Frame")
    recordingFrame.Name = "RecordingFrame"
    recordingFrame.Size = UDim2.new(1, -20, 0, 180)
    recordingFrame.Position = UDim2.new(0, 10, 0, 110)
    recordingFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
    recordingFrame.BorderSizePixel = 0
    recordingFrame.Parent = mainFrame
    
    local recordingCorner = Instance.new("UICorner")
    recordingCorner.CornerRadius = UDim.new(0, 5)
    recordingCorner.Parent = recordingFrame
    
    -- Recording Title
    local recordingTitle = Instance.new("TextLabel")
    recordingTitle.Name = "RecordingTitle"
    recordingTitle.Size = UDim2.new(1, 0, 0, 25)
    recordingTitle.Position = UDim2.new(0, 0, 0, 0)
    recordingTitle.BackgroundTransparency = 1
    recordingTitle.Text = "🎬 Recording & Playback"
    recordingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    recordingTitle.TextScaled = true
    recordingTitle.Font = Enum.Font.GothamBold
    recordingTitle.Parent = recordingFrame
    
    -- Record Button
    local recordButton = Instance.new("TextButton")
    recordButton.Name = "RecordButton"
    recordButton.Size = UDim2.new(0.3, -5, 0, 25)
    recordButton.Position = UDim2.new(0, 5, 0, 30)
    recordButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    recordButton.BorderSizePixel = 0
    recordButton.Text = "🔴 Record"
    recordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    recordButton.TextScaled = true
    recordButton.Font = Enum.Font.Gotham
    recordButton.Parent = recordingFrame
    
    local recordCorner = Instance.new("UICorner")
    recordCorner.CornerRadius = UDim.new(0, 3)
    recordCorner.Parent = recordButton
    
    -- Play Button
    local playButton = Instance.new("TextButton")
    playButton.Name = "PlayButton"
    playButton.Size = UDim2.new(0.3, -5, 0, 25)
    playButton.Position = UDim2.new(0.35, 0, 0, 30)
    playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    playButton.BorderSizePixel = 0
    playButton.Text = "▶️ Play"
    playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playButton.TextScaled = true
    playButton.Font = Enum.Font.Gotham
    playButton.Parent = recordingFrame
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 3)
    playCorner.Parent = playButton
    
    -- Save Button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0.3, -5, 0, 25)
    saveButton.Position = UDim2.new(0.7, 0, 0, 30)
    saveButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    saveButton.BorderSizePixel = 0
    saveButton.Text = "💾 Save"
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.TextScaled = true
    saveButton.Font = Enum.Font.Gotham
    saveButton.Parent = recordingFrame
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 3)
    saveCorner.Parent = saveButton
    
    -- Recording Name Input
    local recordingNameInput = Instance.new("TextBox")
    recordingNameInput.Name = "RecordingNameInput"
    recordingNameInput.Size = UDim2.new(0.6, -5, 0, 20)
    recordingNameInput.Position = UDim2.new(0, 5, 0, 60)
    recordingNameInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    recordingNameInput.BorderSizePixel = 0
    recordingNameInput.Text = "Recording_" .. os.date("%Y%m%d_%H%M%S")
    recordingNameInput.PlaceholderText = "Nama rekaman..."
    recordingNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    recordingNameInput.TextScaled = true
    recordingNameInput.Font = Enum.Font.Gotham
    recordingNameInput.Parent = recordingFrame
    
    local recordingNameCorner = Instance.new("UICorner")
    recordingNameCorner.CornerRadius = UDim.new(0, 3)
    recordingNameCorner.Parent = recordingNameInput
    
    -- Load Button
    local loadButton = Instance.new("TextButton")
    loadButton.Name = "LoadButton"
    loadButton.Size = UDim2.new(0.35, -5, 0, 20)
    loadButton.Position = UDim2.new(0.65, 0, 0, 60)
    loadButton.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
    loadButton.BorderSizePixel = 0
    loadButton.Text = "📁 Load"
    loadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadButton.TextScaled = true
    loadButton.Font = Enum.Font.Gotham
    loadButton.Parent = recordingFrame
    
    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 3)
    loadCorner.Parent = loadButton
    
    -- Test Input Button
    local testInputButton = Instance.new("TextButton")
    testInputButton.Name = "TestInputButton"
    testInputButton.Size = UDim2.new(0.35, -5, 0, 20)
    testInputButton.Position = UDim2.new(0.65, 0, 0, 85)
    testInputButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    testInputButton.BorderSizePixel = 0
    testInputButton.Text = "🧪 Test Input"
    testInputButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    testInputButton.TextScaled = true
    testInputButton.Font = Enum.Font.Gotham
    testInputButton.Parent = recordingFrame
    
    local testInputCorner = Instance.new("UICorner")
    testInputCorner.CornerRadius = UDim.new(0, 3)
    testInputCorner.Parent = testInputButton
    
    -- Loop Toggle
    local loopToggle = Instance.new("TextButton")
    loopToggle.Name = "LoopToggle"
    loopToggle.Size = UDim2.new(0.48, -5, 0, 35)
    loopToggle.Position = UDim2.new(0, 5, 0, 90)
    loopToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
    loopToggle.BorderSizePixel = 2
    loopToggle.BorderColor3 = Color3.fromRGB(255, 255, 0)
    loopToggle.Text = "🔄 LOOP: OFF"
    loopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    loopToggle.TextScaled = true
    loopToggle.Font = Enum.Font.GothamBold
    loopToggle.Parent = recordingFrame
    
    -- Debug: Make sure Loop Toggle is visible
    print("LOOP DEBUG: Loop Toggle created at position Y=90 in recordingFrame")
    print("LOOP DEBUG: Loop Toggle should be visible with 🔄 LOOP: OFF text and yellow border")
    
    local loopCorner = Instance.new("UICorner")
    loopCorner.CornerRadius = UDim.new(0, 5)
    loopCorner.Parent = loopToggle
    
    -- Speed Control Button
    local speedButton = Instance.new("TextButton")
    speedButton.Name = "SpeedButton"
    speedButton.Size = UDim2.new(0.48, -5, 0, 35)
    speedButton.Position = UDim2.new(0.52, 0, 0, 90)
    speedButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    speedButton.BorderSizePixel = 2
    speedButton.BorderColor3 = Color3.fromRGB(100, 200, 255)
    speedButton.Text = "⚡ Speed: 1.0x"
    speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedButton.TextScaled = true
    speedButton.Font = Enum.Font.GothamBold
    speedButton.Parent = recordingFrame
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 5)
    speedCorner.Parent = speedButton
    
    -- Infinite Jump Toggle
    local infiniteJumpToggle = Instance.new("TextButton")
    infiniteJumpToggle.Name = "InfiniteJumpToggle"
    infiniteJumpToggle.Size = UDim2.new(0.48, -5, 0, 35)
    infiniteJumpToggle.Position = UDim2.new(0, 10, 0, 300)
    infiniteJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    infiniteJumpToggle.BorderSizePixel = 2
    infiniteJumpToggle.BorderColor3 = Color3.fromRGB(255, 200, 100)
    infiniteJumpToggle.Text = "🚀 Infinite Jump: OFF"
    infiniteJumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    infiniteJumpToggle.TextScaled = true
    infiniteJumpToggle.Font = Enum.Font.GothamBold
    infiniteJumpToggle.Parent = mainFrame
    
    local infiniteJumpCorner = Instance.new("UICorner")
    infiniteJumpCorner.CornerRadius = UDim.new(0, 5)
    infiniteJumpCorner.Parent = infiniteJumpToggle
    
    -- Anti-Idle Toggle
    local antiIdleToggle = Instance.new("TextButton")
    antiIdleToggle.Name = "AntiIdleToggle"
    antiIdleToggle.Size = UDim2.new(0.48, -5, 0, 35)
    antiIdleToggle.Position = UDim2.new(0.52, 0, 0, 300)
    antiIdleToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
    antiIdleToggle.BorderSizePixel = 2
    antiIdleToggle.BorderColor3 = Color3.fromRGB(255, 150, 255)
    antiIdleToggle.Text = "🚫 Anti-Idle: OFF"
    antiIdleToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiIdleToggle.TextScaled = true
    antiIdleToggle.Font = Enum.Font.GothamBold
    antiIdleToggle.Parent = mainFrame
    
    local antiIdleCorner = Instance.new("UICorner")
    antiIdleCorner.CornerRadius = UDim.new(0, 5)
    antiIdleCorner.Parent = antiIdleToggle
    
    -- Advanced Anti-Idle Toggle
    local advancedAntiIdleToggle = Instance.new("TextButton")
    advancedAntiIdleToggle.Name = "AdvancedAntiIdleToggle"
    advancedAntiIdleToggle.Size = UDim2.new(1, -20, 0, 35)
    advancedAntiIdleToggle.Position = UDim2.new(0, 10, 0, 345)
    advancedAntiIdleToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    advancedAntiIdleToggle.BorderSizePixel = 2
    advancedAntiIdleToggle.BorderColor3 = Color3.fromRGB(100, 200, 255)
    advancedAntiIdleToggle.Text = "🛡️ Advanced Anti-Idle: OFF"
    advancedAntiIdleToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    advancedAntiIdleToggle.TextScaled = true
    advancedAntiIdleToggle.Font = Enum.Font.GothamBold
    advancedAntiIdleToggle.Parent = mainFrame
    
    local advancedAntiIdleCorner = Instance.new("UICorner")
    advancedAntiIdleCorner.CornerRadius = UDim.new(0, 5)
    advancedAntiIdleCorner.Parent = advancedAntiIdleToggle
    
    -- Auto Walk Toggle
    local autoWalkToggle = Instance.new("TextButton")
    autoWalkToggle.Name = "AutoWalkToggle"
    autoWalkToggle.Size = UDim2.new(0.48, -5, 0, 35)
    autoWalkToggle.Position = UDim2.new(0, 10, 0, 390)
    autoWalkToggle.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    autoWalkToggle.BorderSizePixel = 2
    autoWalkToggle.BorderColor3 = Color3.fromRGB(150, 255, 150)
    autoWalkToggle.Text = "🚶 Auto Walk: OFF"
    autoWalkToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoWalkToggle.TextScaled = true
    autoWalkToggle.Font = Enum.Font.GothamBold
    autoWalkToggle.Parent = mainFrame
    
    local walkCorner = Instance.new("UICorner")
    walkCorner.CornerRadius = UDim.new(0, 5)
    walkCorner.Parent = autoWalkToggle
    
    -- Auto Jump Toggle
    local autoJumpToggle = Instance.new("TextButton")
    autoJumpToggle.Name = "AutoJumpToggle"
    autoJumpToggle.Size = UDim2.new(0.48, -5, 0, 35)
    autoJumpToggle.Position = UDim2.new(0.52, 0, 0, 390)
    autoJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
    autoJumpToggle.BorderSizePixel = 2
    autoJumpToggle.BorderColor3 = Color3.fromRGB(255, 200, 100)
    autoJumpToggle.Text = "🦘 Auto Jump: OFF"
    autoJumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoJumpToggle.TextScaled = true
    autoJumpToggle.Font = Enum.Font.GothamBold
    autoJumpToggle.Parent = mainFrame
    
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.CornerRadius = UDim.new(0, 5)
    jumpCorner.Parent = autoJumpToggle
    
    -- Auto Climb Toggle
    local autoClimbToggle = Instance.new("TextButton")
    autoClimbToggle.Name = "AutoClimbToggle"
    autoClimbToggle.Size = UDim2.new(0.48, -5, 0, 35)
    autoClimbToggle.Position = UDim2.new(0, 10, 0, 435)
    autoClimbToggle.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
    autoClimbToggle.BorderSizePixel = 2
    autoClimbToggle.BorderColor3 = Color3.fromRGB(200, 150, 255)
    autoClimbToggle.Text = "🧗 Auto Climb: OFF"
    autoClimbToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoClimbToggle.TextScaled = true
    autoClimbToggle.Font = Enum.Font.GothamBold
    autoClimbToggle.Parent = mainFrame
    
    local climbCorner = Instance.new("UICorner")
    climbCorner.CornerRadius = UDim.new(0, 5)
    climbCorner.Parent = autoClimbToggle
    
    -- Follow Path Toggle
    local followPathToggle = Instance.new("TextButton")
    followPathToggle.Name = "FollowPathToggle"
    followPathToggle.Size = UDim2.new(0.48, -5, 0, 35)
    followPathToggle.Position = UDim2.new(0.52, 0, 0, 435)
    followPathToggle.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    followPathToggle.BorderSizePixel = 2
    followPathToggle.BorderColor3 = Color3.fromRGB(150, 200, 255)
    followPathToggle.Text = "🛤️ Follow Path: OFF"
    followPathToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    followPathToggle.TextScaled = true
    followPathToggle.Font = Enum.Font.GothamBold
    followPathToggle.Parent = mainFrame
    
    local pathCorner = Instance.new("UICorner")
    pathCorner.CornerRadius = UDim.new(0, 5)
    pathCorner.Parent = followPathToggle
    
    -- Settings Section
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(1, -20, 0, 100)
    settingsFrame.Position = UDim2.new(0, 10, 0, 480)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = mainFrame
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 5)
    settingsCorner.Parent = settingsFrame
    
    -- Settings Title
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Name = "SettingsTitle"
    settingsTitle.Size = UDim2.new(1, 0, 0, 25)
    settingsTitle.Position = UDim2.new(0, 0, 0, 0)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Text = "⚙️ Pengaturan"
    settingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsTitle.TextScaled = true
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.Parent = settingsFrame
    
    -- Movement Settings Info
    local movementInfoLabel = Instance.new("TextLabel")
    movementInfoLabel.Name = "MovementInfoLabel"
    movementInfoLabel.Size = UDim2.new(1, -10, 0, 40)
    movementInfoLabel.Position = UDim2.new(0, 5, 0, 30)
    movementInfoLabel.BackgroundTransparency = 1
    movementInfoLabel.Text = "TIDAK MENGUBAH\nMOVEMENT SETTINGS"
    movementInfoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    movementInfoLabel.TextScaled = true
    movementInfoLabel.Font = Enum.Font.Gotham
    movementInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    movementInfoLabel.Parent = settingsFrame
    
    -- Apply Settings Button
    local applyButton = Instance.new("TextButton")
    applyButton.Name = "ApplyButton"
    applyButton.Size = UDim2.new(0.4, -5, 0, 25)
    applyButton.Position = UDim2.new(0.55, 0, 0, 30)
    applyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    applyButton.BorderSizePixel = 0
    applyButton.Text = "✅ Apply"
    applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyButton.TextScaled = true
    applyButton.Font = Enum.Font.Gotham
    applyButton.Parent = settingsFrame
    
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 3)
    applyCorner.Parent = applyButton
    
    -- Reset Settings Button
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Size = UDim2.new(0.4, -5, 0, 25)
    resetButton.Position = UDim2.new(0.55, 0, 0, 55)
    resetButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    resetButton.BorderSizePixel = 0
    resetButton.Text = "🔄 Reset"
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextScaled = true
    resetButton.Font = Enum.Font.Gotham
    resetButton.Parent = settingsFrame
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 3)
    resetCorner.Parent = resetButton
    
    -- Status Section
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, -20, 1, -590)
    statusFrame.Position = UDim2.new(0, 10, 0, 590)
    statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 5)
    statusCorner.Parent = statusFrame
    
    -- Status Title
    local statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "StatusTitle"
    statusTitle.Size = UDim2.new(1, 0, 0, 25)
    statusTitle.Position = UDim2.new(0, 0, 0, 0)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "📊 Status"
    statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusTitle.TextScaled = true
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.Parent = statusFrame
    
    -- Status Text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -10, 1, -30)
    statusText.Position = UDim2.new(0, 5, 0, 25)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Siap untuk auto play..."
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextScaled = true
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextWrapped = true
    statusText.Parent = statusFrame
    
    return screenGui, {
        autoPlayToggle = autoPlayToggle,
        recordButton = recordButton,
        playButton = playButton,
        saveButton = saveButton,
        loadButton = loadButton,
        testInputButton = testInputButton,
        loopToggle = loopToggle,
        speedButton = speedButton,
        recordingNameInput = recordingNameInput,
        infiniteJumpToggle = infiniteJumpToggle,
        antiIdleToggle = antiIdleToggle,
        advancedAntiIdleToggle = advancedAntiIdleToggle,
        autoWalkToggle = autoWalkToggle,
        autoJumpToggle = autoJumpToggle,
        autoClimbToggle = autoClimbToggle,
        followPathToggle = followPathToggle,
        movementInfoLabel = movementInfoLabel,
        applyButton = applyButton,
        resetButton = resetButton,
        statusText = statusText
    }
end

-- Create GUI
local screenGui, guiElements = createAutoPlayGUI()

-- Update Status Function
local function updateStatus(message)
    if guiElements.statusText then
        guiElements.statusText.Text = message
    end
    print("[Auto Play] " .. message)
end

-- Recording Functions
local function startRecording()
    if isRecording then
        return
    end
    
    isRecording = true
    recordingData = {}
    inputRecordingData = {} -- Reset input recording data
    recordingStartTime = tick()
    currentRecordingName = guiElements.recordingNameInput.Text or "Recording_" .. os.date("%Y%m%d_%H%M%S")
    
    guiElements.recordButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    guiElements.recordButton.Text = "Recording..."
    guiElements.playButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    guiElements.playButton.Text = "Play (Disabled)"
    
    updateStatus("Mulai merekam: " .. currentRecordingName .. " (dengan input recording)")
    print("RECORDING: Input recording diaktifkan - semua input keyboard/mouse akan direkam")
    print("RECORDING DEBUG: isRecording = " .. tostring(isRecording) .. ", recordInputs = " .. tostring(recordInputs))
    print("RECORDING DEBUG: recordingStartTime = " .. recordingStartTime)
end

local function stopRecording()
    if not isRecording then
        return
    end
    
    isRecording = false
    
    guiElements.recordButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    guiElements.recordButton.Text = "Record"
    guiElements.playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    guiElements.playButton.Text = "Play"
    
    updateStatus("Rekaman selesai! Total " .. #recordingData .. " frame, " .. #inputRecordingData .. " input direkam")
    print("RECORDING STOP: Total frames: " .. #recordingData .. ", Total inputs: " .. #inputRecordingData)
    
    -- Debug: Show first few inputs
    if #inputRecordingData > 0 then
        print("RECORDING DEBUG: First 3 inputs recorded:")
        for i = 1, math.min(3, #inputRecordingData) do
            local input = inputRecordingData[i]
            print("  Input " .. i .. ": " .. tostring(input.inputType) .. " - " .. tostring(input.keyCode) .. " - " .. tostring(input.userInputState) .. " (Time: " .. string.format("%.2f", input.time) .. "s)")
        end
    else
        print("RECORDING DEBUG: No inputs recorded! Check if you pressed any keys during recording.")
    end
end

local function recordFrame()
    if not isRecording or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    local humanoid = player.Character.Humanoid
    
    local frameData = {
        time = tick() - recordingStartTime,
        position = humanoidRootPart.Position,
        rotation = humanoidRootPart.CFrame.Rotation,
        velocity = humanoidRootPart.Velocity,
        health = humanoid.Health,
        maxHealth = humanoid.MaxHealth,
        jump = humanoid.Jump,
        moveDirection = humanoid.MoveDirection
    }
    
    table.insert(recordingData, frameData)
end

-- Input Recording Functions
local function recordInput(input, gameProcessed)
    if not isRecording or not recordInputs then
        return
    end
    
    -- Skip GUI inputs and script shortcuts
    if gameProcessed then
        return
    end
    
    -- Skip F keys (script shortcuts)
    if input.KeyCode and (input.KeyCode.Value >= 112 and input.KeyCode.Value <= 123) then
        return
    end
    
    local inputData = {
        time = tick() - recordingStartTime,
        inputType = input.UserInputType,
        keyCode = input.KeyCode,
        userInputState = input.UserInputState,
        position = input.Position,
        delta = input.Delta
    }
    
    table.insert(inputRecordingData, inputData)
    print("INPUT RECORD: " .. tostring(input.UserInputType) .. " - " .. tostring(input.KeyCode) .. " - " .. tostring(input.UserInputState) .. " (Time: " .. string.format("%.2f", inputData.time) .. "s)")
end

local function playbackInput(inputData)
    if not inputData then
        return
    end
    
    -- Simulate input by directly controlling character
    if inputData.inputType == Enum.UserInputType.Keyboard and inputData.keyCode then
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            if inputData.keyCode == Enum.KeyCode.W then
                humanoid:Move(Vector3.new(0, 0, -1))
            elseif inputData.keyCode == Enum.KeyCode.S then
                humanoid:Move(Vector3.new(0, 0, 1))
            elseif inputData.keyCode == Enum.KeyCode.A then
                humanoid:Move(Vector3.new(-1, 0, 0))
            elseif inputData.keyCode == Enum.KeyCode.D then
                humanoid:Move(Vector3.new(1, 0, 0))
            elseif inputData.keyCode == Enum.KeyCode.Space then
                humanoid.Jump = true
            end
        end
    elseif inputData.inputType == Enum.UserInputType.MouseButton1 then
        -- Simulate mouse click by moving character slightly
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.new(0, 0, 0.1))
        end
    end
    
    print("INPUT PLAYBACK: " .. tostring(inputData.inputType) .. " - " .. tostring(inputData.keyCode) .. " - " .. tostring(inputData.userInputState) .. " (Time: " .. string.format("%.2f", inputData.time) .. "s)")
end

local function startPlayback()
    if isPlaying or #recordingData == 0 then
        print("PLAYBACK DEBUG: Cannot start - isPlaying: " .. tostring(isPlaying) .. ", frames: " .. #recordingData)
        return
    end
    
    isPlaying = true
    playbackData = recordingData
    inputPlaybackData = inputRecordingData -- Set input playback data
    currentPlaybackIndex = 1
    currentInputPlaybackIndex = 1
    playbackStartTime = tick()
    loopCount = 0 
    
    print("LOOP DEBUG: Starting playback - frames: " .. #playbackData .. ", inputs: " .. #inputPlaybackData .. ", loopPlayback: " .. tostring(loopPlayback) .. ", loopCount reset to: " .. loopCount)
    
    guiElements.playButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    guiElements.playButton.Text = "Playing..."
    guiElements.recordButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    guiElements.recordButton.Text = "Record (Disabled)"
    
    local loopStatus = loopPlayback and " (Loop: ON)" or " (Loop: OFF)"
    local inputStatus = #inputPlaybackData > 0 and " (dengan input)" or " (tanpa input)"
    updateStatus("Memulai playback: " .. currentRecordingName .. loopStatus .. inputStatus)
    print("PLAYBACK: Input playback diaktifkan - " .. #inputPlaybackData .. " input akan diputar")
    
    -- Debug: Show first few inputs that will be played
    if #inputPlaybackData > 0 then
        print("PLAYBACK DEBUG: First 3 inputs to be played:")
        for i = 1, math.min(3, #inputPlaybackData) do
            local input = inputPlaybackData[i]
            print("  Input " .. i .. ": " .. tostring(input.inputType) .. " - " .. tostring(input.keyCode) .. " - " .. tostring(input.userInputState) .. " (Time: " .. string.format("%.2f", input.time) .. "s)")
        end
    else
        print("PLAYBACK DEBUG: No inputs to play! Recording might not have captured any inputs.")
    end
end

local function stopPlayback()
    if not isPlaying then
        return
    end
    
    isPlaying = false
    loopCount = 0 
    
    print("LOOP DEBUG: Stopping playback - total loops: " .. loopCount .. ", loopCount reset to: 0")
    
    guiElements.playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    guiElements.playButton.Text = "Play"
    guiElements.recordButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    guiElements.recordButton.Text = "Record"
    
    updateStatus("Playback selesai!")
end

local function playbackFrame()
    if not isPlaying or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    if #playbackData == 0 then
        print("LOOP DEBUG: No playback data available")
        return
    end
    
    local currentTime = tick() - playbackStartTime
    
    -- Playback input events
    if #inputPlaybackData > 0 then
        local inputsPlayed = 0
        for i = currentInputPlaybackIndex, #inputPlaybackData do
            local inputData = inputPlaybackData[i]
            if inputData.time * playbackSpeed <= currentTime then
                playbackInput(inputData)
                currentInputPlaybackIndex = i + 1
                inputsPlayed = inputsPlayed + 1
            else
                break
            end
        end
        
        -- Debug: Show input playback progress
        if inputsPlayed > 0 then
            print("PLAYBACK DEBUG: Played " .. inputsPlayed .. " inputs at time " .. string.format("%.2f", currentTime) .. "s")
        end
    else
        -- Debug: Show that no inputs are available
        if currentTime > 1 and currentTime < 2 then -- Only show once
            print("PLAYBACK DEBUG: No input data available for playback")
        end
    end
    
    local totalDuration = playbackData[#playbackData].time * playbackSpeed
    -- Add small tolerance to ensure loop works
    if currentTime >= totalDuration - 0.1 then
        print("LOOP DEBUG: End reached - currentTime: " .. string.format("%.2f", currentTime) .. "s >= totalDuration: " .. string.format("%.2f", totalDuration) .. "s, loopPlayback: " .. tostring(loopPlayback))
        -- Check if looping is enabled
        if loopPlayback then
            -- Reset to beginning for loop
            loopCount = loopCount + 1
            currentPlaybackIndex = 1
            currentInputPlaybackIndex = 1 -- Reset input playback index
            playbackStartTime = tick()
            print("LOOP DEBUG: Resetting playback - currentTime: " .. string.format("%.2f", currentTime) .. "s, totalDuration: " .. string.format("%.2f", totalDuration) .. "s")
            print("LOOP DEBUG: Loop successful - resetting to frame 1 (Loop #" .. loopCount .. ")")
            updateStatus("Playback looping... (Loop #" .. loopCount .. ", Duration: " .. string.format("%.1f", totalDuration) .. "s)")
            return
        else
            -- Stop playback normally
            stopPlayback()
            return
        end
    end
    local humanoidRootPart = player.Character.HumanoidRootPart
    local humanoid = player.Character.Humanoid
    
    -- Find the current frame and next frame for interpolation
    local currentFrame = nil
    local nextFrame = nil
    local alpha = 0
    
    -- Find current frame based on time
    for i = currentPlaybackIndex, #playbackData do
        local frame = playbackData[i]
        if currentTime >= frame.time * playbackSpeed then
            currentFrame = frame
            currentPlaybackIndex = i
            
            -- Get next frame for interpolation
            if i < #playbackData then
                nextFrame = playbackData[i + 1]
                local frameTime = nextFrame.time * playbackSpeed
                local currentFrameTime = currentFrame.time * playbackSpeed
                
                if frameTime > currentFrameTime then
                    alpha = (currentTime - currentFrameTime) / (frameTime - currentFrameTime)
                    alpha = math.min(math.max(alpha, 0), 1)
                end
            end
        else
            break
        end
    end
    
    if currentFrame then
        -- Smooth interpolation for realistic movement
        if nextFrame and alpha > 0 then
            -- Interpolate position for ultra smooth movement
            local interpolatedPosition = currentFrame.position:Lerp(nextFrame.position, alpha)
            
            -- Interpolate rotation for smooth turning
            local currentRotation = currentFrame.rotation
            local nextRotation = nextFrame.rotation
            local interpolatedRotation = currentRotation:Lerp(nextRotation, alpha)
            
            -- Apply position and rotation with smooth interpolation
            humanoidRootPart.CFrame = CFrame.new(interpolatedPosition) * interpolatedRotation
        else
            -- Use exact position and rotation
            humanoidRootPart.CFrame = CFrame.new(currentFrame.position) * currentFrame.rotation
        end
        
        -- Tidak mengubah WalkSpeed dan JumpPower
        
        -- Apply movement with realistic timing
        if currentFrame.moveDirection.Magnitude > 0 then
            humanoid:Move(currentFrame.moveDirection)
        end
        
        -- Apply jump with realistic timing
        if currentFrame.jump then
            humanoid.Jump = true
        end
        
        -- Update camera to follow player naturally
        local camera = workspace.CurrentCamera
        if camera then
            -- Ultra smooth camera following
            local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, 2, 8)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.05) -- Slower lerp for smoother camera
        end
    end
end

local function saveRecording()
    if #recordingData == 0 then
        updateStatus("Tidak ada rekaman untuk disimpan!")
        return
    end
    
    local recordingName = guiElements.recordingNameInput.Text or "Recording_" .. os.date("%Y%m%d_%H%M%S")
    
    -- Create recording data
    local saveData = {
        name = recordingName,
        data = recordingData,
        inputData = inputRecordingData, -- Save input data
        duration = recordingData[#recordingData].time,
        frameCount = #recordingData,
        inputCount = #inputRecordingData,
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Save to savedRecordings
    savedRecordings[recordingName] = saveData
    
    -- Try to save to file (this might not work in all environments)
    local success, error = pcall(function()
        local jsonData = HttpService:JSONEncode(saveData)
        -- Note: writefile might not be available in all Roblox environments
        -- This is a placeholder for file saving functionality
        print("Recording saved: " .. recordingName)
    end)
    
    if success then
        updateStatus("Rekaman disimpan: " .. recordingName .. " (" .. #recordingData .. " frame, " .. #inputRecordingData .. " input)")
    else
        updateStatus("Rekaman disimpan ke memory: " .. recordingName .. " (" .. #recordingData .. " frame, " .. #inputRecordingData .. " input)")
    end
end

local function loadRecording()
    local recordingName = guiElements.recordingNameInput.Text
    
    if not recordingName or recordingName == "" then
        updateStatus("Masukkan nama rekaman untuk dimuat!")
        return
    end
    
    if savedRecordings[recordingName] then
        local saveData = savedRecordings[recordingName]
        recordingData = saveData.data
        inputRecordingData = saveData.inputData or {} -- Load input data
        currentRecordingName = recordingName
        
        guiElements.playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        guiElements.playButton.Text = "Play"
        
        local inputInfo = saveData.inputCount and " (" .. saveData.inputCount .. " input)" or ""
        updateStatus("Rekaman dimuat: " .. recordingName .. " (" .. saveData.frameCount .. " frame, " .. math.floor(saveData.duration) .. "s)" .. inputInfo)
        print("LOAD: Input data dimuat - " .. #inputRecordingData .. " input events")
    else
        updateStatus("Rekaman tidak ditemukan: " .. recordingName)
    end
end

-- Test Input Function
local function testInput()
    updateStatus("Testing input recording... Tekan WASD atau Space!")
    print("TEST INPUT: Mulai test input recording")
    print("TEST INPUT: Tekan WASD atau Space untuk test")
    
    -- Simulate some test inputs
    spawn(function()
        wait(1)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            print("TEST INPUT: Simulating W key press")
            humanoid:Move(Vector3.new(0, 0, -1))
            wait(0.5)
            print("TEST INPUT: Simulating Space key press")
            humanoid.Jump = true
            wait(0.5)
            print("TEST INPUT: Simulating A key press")
            humanoid:Move(Vector3.new(-1, 0, 0))
            wait(0.5)
            print("TEST INPUT: Test completed")
            updateStatus("Test input selesai! Cek console untuk hasil.")
        end
    end)
end

-- Advanced Anti-Idle Functions
local function toggleAdvancedAntiIdle()
    advancedAntiIdleEnabled = not advancedAntiIdleEnabled
    
    if advancedAntiIdleEnabled then
        -- Disable all Idled event connections
        local success, error = pcall(function()
            -- Check if getconnections is available
            if type(getconnections) == "function" then
                local connections = getconnections(game:GetService("Players").LocalPlayer.Idled)
                for i, v in next, connections do
                    if v and v.Disable then
                        v:Disable()
                        table.insert(idledConnections, v)
                    end
                end
            else
                -- Fallback: Create a dummy connection to prevent idle
                local dummyConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                    -- Do nothing, just prevent idle
                end)
                table.insert(idledConnections, dummyConnection)
            end
        end)
        
        if success then
            guiElements.advancedAntiIdleToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            guiElements.advancedAntiIdleToggle.Text = "🛡️ Advanced Anti-Idle: ON"
            updateStatus("Advanced Anti-Idle diaktifkan! (Idled event disabled)")
            print("ADVANCED ANTI-IDLE: Idled event connections disabled - " .. #idledConnections .. " connections")
        else
            updateStatus("Error: " .. tostring(error))
            print("ADVANCED ANTI-IDLE ERROR: " .. tostring(error))
        end
    else
        -- Re-enable all Idled event connections
        local success, error = pcall(function()
            for i, v in pairs(idledConnections) do
                if v and v.Enable then
                    v:Enable()
                elseif v and v.Disconnect then
                    v:Disconnect()
                end
            end
            idledConnections = {}
        end)
        
        if success then
            guiElements.advancedAntiIdleToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            guiElements.advancedAntiIdleToggle.Text = "🛡️ Advanced Anti-Idle: OFF"
            updateStatus("Advanced Anti-Idle dinonaktifkan!")
            print("ADVANCED ANTI-IDLE: Idled event connections re-enabled")
        else
            updateStatus("Error: " .. tostring(error))
            print("ADVANCED ANTI-IDLE ERROR: " .. tostring(error))
        end
    end
end

-- Anti-Idle Functions
local function toggleAntiIdle()
    antiIdleEnabled = not antiIdleEnabled
    
    if antiIdleEnabled then
        guiElements.antiIdleToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.antiIdleToggle.Text = "🚫 Anti-Idle: ON"
        updateStatus("Anti-Idle diaktifkan! (Bypass idle 20 menit)")
    else
        guiElements.antiIdleToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.antiIdleToggle.Text = "🚫 Anti-Idle: OFF"
        updateStatus("Anti-Idle dinonaktifkan!")
    end
end

local function performAntiIdleAction()
    if not antiIdleEnabled or not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = player.Character.Humanoid
    local humanoidRootPart = player.Character.HumanoidRootPart
    local camera = workspace.CurrentCamera
    
    if not humanoidRootPart then
        return
    end
    
    -- Pilih aksi anti-idle secara random
    local action = antiIdleActions[math.random(1, #antiIdleActions)]
    
    if action == "move" then
        -- Gerakan kecil ke samping atau mundur
        local directions = {
            Vector3.new(1, 0, 0),   -- Kanan
            Vector3.new(-1, 0, 0),  -- Kiri
            Vector3.new(0, 0, -1),  -- Mundur
            Vector3.new(0.5, 0, 0.5) -- Diagonal
        }
        local direction = directions[math.random(1, #directions)]
        humanoid:Move(direction * antiIdleIntensity)
        updateStatus("Anti-Idle: Gerakan kecil (" .. action .. ")")
        
    elseif action == "jump" then
        -- Lompat kecil
        humanoid.Jump = true
        updateStatus("Anti-Idle: Lompat kecil (" .. action .. ")")
        
    elseif action == "look" then
        -- Putar kepala sedikit
        local currentCFrame = humanoidRootPart.CFrame
        local randomRotation = math.random(-30, 30) -- Derajat
        local newCFrame = currentCFrame * CFrame.Angles(0, math.rad(randomRotation), 0)
        humanoidRootPart.CFrame = newCFrame
        updateStatus("Anti-Idle: Putar kepala (" .. action .. ")")
        
    elseif action == "camera" then
        -- Gerakan kamera kecil
        if camera then
            local currentCFrame = camera.CFrame
            local randomOffset = Vector3.new(
                math.random(-2, 2),
                math.random(-1, 1),
                math.random(-2, 2)
            )
            local newCFrame = currentCFrame + randomOffset
            camera.CFrame = newCFrame
            updateStatus("Anti-Idle: Gerakan kamera (" .. action .. ")")
        end
    end
    
    antiIdleLastAction = tick()
end

-- Infinite Jump Functions
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled
    
    if infiniteJumpEnabled then
        guiElements.infiniteJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.infiniteJumpToggle.Text = "Infinite Jump: ON"
        updateStatus("Infinite Jump diaktifkan!")
    else
        guiElements.infiniteJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.infiniteJumpToggle.Text = "Infinite Jump: OFF"
        updateStatus("Infinite Jump dinonaktifkan!")
    end
end

local function checkGrounded()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(
        humanoidRootPart.Position,
        Vector3.new(0, -5, 0),
        raycastParams
    )
    
    return raycastResult ~= nil
end

local function performInfiniteJump()
    if not infiniteJumpEnabled or not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local currentTime = tick()
    if currentTime - lastJumpTime < jumpCooldown then
        return
    end
    
    local humanoid = player.Character.Humanoid
    local isCurrentlyGrounded = checkGrounded()
    
    -- Reset jump count when grounded (only if not spam jumping)
    if isCurrentlyGrounded and not spamJumpEnabled then
        jumpCount = 0
    end
    
    -- Allow unlimited jumping if spam jump is enabled
    if spamJumpEnabled then
        humanoid.Jump = true
        jumpCount = jumpCount + 1
        lastJumpTime = currentTime
        
        updateStatus("Spam Jump " .. jumpCount .. " (Unlimited)")
    else
        -- Original logic for limited jumps
        if isCurrentlyGrounded or jumpCount < maxJumps then
            humanoid.Jump = true
            jumpCount = jumpCount + 1
            lastJumpTime = currentTime
            
            updateStatus("Jump " .. jumpCount .. "/" .. maxJumps)
        end
    end
end

-- Quality Settings Functions
local function setRecordingQuality(quality)
    recordingQuality = quality
    if quality == "High" then
        recordingInterval = 0.008 -- 120 FPS
    elseif quality == "Medium" then
        recordingInterval = 0.016 -- 60 FPS
    elseif quality == "Low" then
        recordingInterval = 0.033 -- 30 FPS
    end
    updateStatus("Recording quality: " .. quality .. " (" .. math.floor(1/recordingInterval) .. " FPS)")
end

local function setPlaybackQuality(quality)
    playbackQuality = quality
    if quality == "Ultra" then
        -- Will be handled in playback loop
    elseif quality == "High" then
        -- Will be handled in playback loop
    elseif quality == "Medium" then
        -- Will be handled in playback loop
    end
    updateStatus("Playback quality: " .. quality)
end

-- Adaptive Recording Functions
local function toggleAdaptiveRecording()
    adaptiveRecording = not adaptiveRecording
    
    if adaptiveRecording then
        updateStatus("Adaptive Recording: ON (Frame-perfect recording)")
    else
        updateStatus("Adaptive Recording: OFF (Fixed interval recording)")
    end
end

local function getCurrentFPS()
    -- Calculate current FPS based on RunService
    local currentTime = tick()
    local deltaTime = currentTime - (getCurrentFPS.lastTime or currentTime)
    getCurrentFPS.lastTime = currentTime
    
    if deltaTime > 0 then
        return math.floor(1 / deltaTime)
    else
        return 60 -- Default fallback
    end
end

-- Apply Settings Function (TIDAK MENGUBAH MOVEMENT SETTINGS)
local function applySettings()
    -- Tidak mengubah WalkSpeed dan JumpPower
    updateStatus("Settings diterapkan (TIDAK mengubah Speed/Jump)")
end

-- Reset Settings Function (TIDAK MENGUBAH MOVEMENT SETTINGS)
local function resetSettings()
    -- Tidak mengubah WalkSpeed dan JumpPower
    updateStatus("Settings direset (TIDAK mengubah Speed/Jump)")
end

-- Toggle Functions
local function toggleLoopPlayback()
    loopPlayback = not loopPlayback
    
    print("LOOP DEBUG: Toggle loop - loopPlayback = " .. tostring(loopPlayback))
    
    if guiElements.loopToggle then
        if loopPlayback then
            guiElements.loopToggle.Text = "🔄 LOOP: ON"
            guiElements.loopToggle.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            updateStatus("Loop Playback: ON (akan berulang otomatis)")
        else
            guiElements.loopToggle.Text = "🔄 LOOP: OFF"
            guiElements.loopToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 200)
            updateStatus("Loop Playback: OFF")
        end
    end
end

local function toggleAutoPlay()
    autoPlayEnabled = not autoPlayEnabled
    
        if autoPlayEnabled then
            guiElements.autoPlayToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            guiElements.autoPlayToggle.Text = "🤖 Auto Play: ON"
            updateStatus("Auto Play diaktifkan!")
        else
            guiElements.autoPlayToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            guiElements.autoPlayToggle.Text = "🤖 Auto Play: OFF"
            updateStatus("Auto Play dinonaktifkan!")
        
        -- Stop all auto functions
        autoWalkEnabled = false
        autoJumpEnabled = false
        autoClimbEnabled = false
        followPathEnabled = false
        
        -- Update toggle buttons
        guiElements.autoWalkToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoWalkToggle.Text = "Auto Walk: OFF"
        guiElements.autoJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoJumpToggle.Text = "Auto Jump: OFF"
        guiElements.autoClimbToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoClimbToggle.Text = "Auto Climb: OFF"
        guiElements.followPathToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.followPathToggle.Text = "Follow Path: OFF"
    end
end

local function toggleAutoWalk()
    autoWalkEnabled = not autoWalkEnabled
    
    if autoWalkEnabled then
        guiElements.autoWalkToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.autoWalkToggle.Text = "Auto Walk: ON"
        updateStatus("Auto Walk diaktifkan!")
    else
        guiElements.autoWalkToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoWalkToggle.Text = "Auto Walk: OFF"
        updateStatus("Auto Walk dinonaktifkan!")
    end
end

local function toggleAutoJump()
    autoJumpEnabled = not autoJumpEnabled
    
    if autoJumpEnabled then
        guiElements.autoJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.autoJumpToggle.Text = "Auto Jump: ON"
        updateStatus("Auto Jump diaktifkan!")
    else
        guiElements.autoJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoJumpToggle.Text = "Auto Jump: OFF"
        updateStatus("Auto Jump dinonaktifkan!")
    end
end

local function toggleAutoClimb()
    autoClimbEnabled = not autoClimbEnabled
    
    if autoClimbEnabled then
        guiElements.autoClimbToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.autoClimbToggle.Text = "Auto Climb: ON"
        updateStatus("Auto Climb diaktifkan!")
    else
        guiElements.autoClimbToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.autoClimbToggle.Text = "Auto Climb: OFF"
        updateStatus("Auto Climb dinonaktifkan!")
    end
end

local function toggleFollowPath()
    followPathEnabled = not followPathEnabled
    
    if followPathEnabled then
        guiElements.followPathToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        guiElements.followPathToggle.Text = "Follow Path: ON"
        updateStatus("Follow Path diaktifkan!")
    else
        guiElements.followPathToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        guiElements.followPathToggle.Text = "Follow Path: OFF"
        updateStatus("Follow Path dinonaktifkan!")
    end
end

-- Movement Functions
local function isObstacleAhead()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(
        humanoidRootPart.Position,
        humanoidRootPart.CFrame.LookVector * detectionDistance,
        raycastParams
    )
    
    if raycastResult then
        local hit = raycastResult.Instance
        local hitName = string.lower(hit.Name)
        
        -- Check if it's an obstacle
        for _, keyword in pairs(obstacleKeywords) do
            if string.find(hitName, keyword) then
                return true, hit
            end
        end
        
        -- Check if it's climbable
        for _, keyword in pairs(climbableKeywords) do
            if string.find(hitName, keyword) then
                return false, hit, true -- Return climbable object
            end
        end
    end
    
    return false
end

local function isPlayerStuck()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local currentPosition = player.Character.HumanoidRootPart.Position
    local distance = (currentPosition - lastPosition).Magnitude
    
    if distance < 1 then
        stuckCounter = stuckCounter + 1
    else
        stuckCounter = 0
    end
    
    lastPosition = currentPosition
    
    return stuckCounter > maxStuckTime
end

local function performJump()
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local currentTime = tick()
    if currentTime - lastJumpTime < jumpCooldown then
        return
    end
    
    local humanoid = player.Character.Humanoid
    humanoid.Jump = true
    lastJumpTime = currentTime
    
    updateStatus("Melompat!")
end

local function performClimb(target)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = player.Character.Humanoid
    local humanoidRootPart = player.Character.HumanoidRootPart
    
    if target and target.Position then
        local direction = (target.Position - humanoidRootPart.Position).Unit
        humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + direction)
        
        -- Move towards climbable object
        humanoid:Move(direction)
        
        updateStatus("Memanjat: " .. target.Name)
    end
end

local function findPathToTarget(targetPosition)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(humanoidRootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        updateStatus("Pathfinding gagal: " .. tostring(errorMessage))
        return nil
    end
end

local function followPath()
    if not followPathEnabled or #pathPoints == 0 then
        return
    end
    
    if currentPathIndex > #pathPoints then
        currentPathIndex = 1
        return
    end
    
    local currentWaypoint = pathPoints[currentPathIndex]
    if not currentWaypoint then
        return
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    local distance = (currentWaypoint.Position - humanoidRootPart.Position).Magnitude
    
    if distance <= pathTolerance then
        currentPathIndex = currentPathIndex + 1
        return
    end
    
    local humanoid = player.Character.Humanoid
    local direction = (currentWaypoint.Position - humanoidRootPart.Position).Unit
    
    -- Face the direction
    humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + direction)
    
    -- Move towards waypoint
    humanoid:Move(direction)
    
    -- Jump if waypoint requires it
    if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
        performJump()
    end
end

local function autoWalkForward()
    if not autoWalkEnabled or not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = player.Character.Humanoid
    local humanoidRootPart = player.Character.HumanoidRootPart
    
    -- Check for obstacles
    local obstacleAhead, obstacle, isClimbable = isObstacleAhead()
    
    if obstacleAhead then
        -- Try to jump over obstacle
        if autoJumpEnabled then
            performJump()
        end
        return
    elseif isClimbable and autoClimbEnabled then
        -- Climb the object
        performClimb(obstacle)
        return
    end
    
    -- Check if player is stuck
    if isPlayerStuck() then
        updateStatus("Player terjebak! Mencoba melompat...")
        if autoJumpEnabled then
            performJump()
        end
        return
    end
    
    -- Move forward
    humanoid:Move(humanoidRootPart.CFrame.LookVector)
end

-- Adaptive Recording Loop (Based on game frame rate)
spawn(function()
    while true do
        if isRecording then
            recordFrame()
            
            if adaptiveRecording then
                -- Use RunService.Heartbeat for frame-perfect recording
                RunService.Heartbeat:Wait()
            else
                wait(recordingInterval)
            end
        else
            wait(0.1)
        end
    end
end)

-- Infinite Jump Loop
spawn(function()
    while true do
        if infiniteJumpEnabled then
            performInfiniteJump()
        end
        wait(0.1)
    end
end)

-- Spam Jump Detection
local lastSpacePress = 0
local spacePressCooldown = 0.008 -- Ultra fast response for spam jumping (120 FPS)

-- Spam Jump Loop (Ultra responsive)
spawn(function()
    while true do
        if infiniteJumpEnabled and spamJumpEnabled then
            -- Check if space is being held down
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local currentTime = tick()
                if currentTime - lastSpacePress > spacePressCooldown then
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        local humanoid = player.Character.Humanoid
                        humanoid.Jump = true
                        jumpCount = jumpCount + 1
                        lastSpacePress = currentTime
                        lastJumpTime = currentTime
                        
                        updateStatus("Spam Jump " .. jumpCount .. " (Space Held)")
                    end
                end
            end
        end
        wait(0.008) -- Ultra fast response (120 FPS)
    end
end)

-- Adaptive Playback Loop (Based on game frame rate)
spawn(function()
    while true do
        if isPlaying then
            playbackFrame()
            
            if adaptiveRecording then
                -- Use RunService.Heartbeat for frame-perfect playback
                RunService.Heartbeat:Wait()
            else
                -- Adjust wait time based on playback quality
                if playbackQuality == "Ultra" then
                    wait(0.004) -- 240 FPS for ultra smooth playback
                elseif playbackQuality == "High" then
                    wait(0.008) -- 120 FPS for high quality playback
                elseif playbackQuality == "Medium" then
                    wait(0.016) -- 60 FPS for medium quality playback
                else
                    wait(0.008) -- Default to 120 FPS
                end
            end
        else
            wait(0.1)
        end
    end
end)

-- Main Auto Play Loop
spawn(function()
    while true do
        if autoPlayEnabled and not isPlaying then
            if followPathEnabled then
                followPath()
            else
                autoWalkForward()
            end
        end
        wait(0.1)
    end
end)

-- Path Update Loop
spawn(function()
    while true do
        if followPathEnabled then
            local currentTime = tick()
            if currentTime - lastPathUpdate > pathUpdateInterval then
                -- Update path to mouse position or random high point
                local targetPosition = mouse.Hit.Position
                if targetPosition == Vector3.new(0, 0, 0) then
                    -- If no mouse target, find a random high point
                    targetPosition = Vector3.new(
                        math.random(-100, 100),
                        math.random(50, 200),
                        math.random(-100, 100)
                    )
                end
                
                local newPath = findPathToTarget(targetPosition)
                if newPath then
                    pathPoints = newPath
                    currentPathIndex = 1
                    updateStatus("Path diperbarui ke target baru")
                end
                
                lastPathUpdate = currentTime
            end
        end
        wait(1)
    end
end)

-- Anti-Idle Loop
spawn(function()
    while true do
        if antiIdleEnabled then
            local currentTime = tick()
            if currentTime - antiIdleLastAction > antiIdleInterval then
                performAntiIdleAction()
            end
        end
        wait(1) -- Check every second
    end
end)

-- Event Connections
guiElements.autoPlayToggle.MouseButton1Click:Connect(toggleAutoPlay)
guiElements.recordButton.MouseButton1Click:Connect(function()
    if isRecording then
        stopRecording()
    else
        startRecording()
    end
end)
guiElements.playButton.MouseButton1Click:Connect(function()
    if isPlaying then
        stopPlayback()
    else
        startPlayback()
    end
end)
guiElements.saveButton.MouseButton1Click:Connect(saveRecording)
guiElements.loadButton.MouseButton1Click:Connect(loadRecording)
guiElements.testInputButton.MouseButton1Click:Connect(testInput)
guiElements.loopToggle.MouseButton1Click:Connect(toggleLoopPlayback)
guiElements.infiniteJumpToggle.MouseButton1Click:Connect(toggleInfiniteJump)
guiElements.antiIdleToggle.MouseButton1Click:Connect(toggleAntiIdle)
guiElements.advancedAntiIdleToggle.MouseButton1Click:Connect(toggleAdvancedAntiIdle)
guiElements.autoWalkToggle.MouseButton1Click:Connect(toggleAutoWalk)
guiElements.autoJumpToggle.MouseButton1Click:Connect(toggleAutoJump)
guiElements.autoClimbToggle.MouseButton1Click:Connect(toggleAutoClimb)
guiElements.followPathToggle.MouseButton1Click:Connect(toggleFollowPath)
guiElements.applyButton.MouseButton1Click:Connect(applySettings)
guiElements.resetButton.MouseButton1Click:Connect(resetSettings)

-- Input Recording Connection
UserInputService.InputBegan:Connect(recordInput)
UserInputService.InputEnded:Connect(recordInput)
UserInputService.InputChanged:Connect(recordInput)

-- Keyboard Shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        toggleAutoPlay()
    elseif input.KeyCode == Enum.KeyCode.F2 then
        -- Toggle Recording
        if isRecording then
            stopRecording()
        else
            startRecording()
        end
    elseif input.KeyCode == Enum.KeyCode.F3 then
        -- Toggle Playback
        if isPlaying then
            stopPlayback()
        else
            startPlayback()
        end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        saveRecording()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        loadRecording()
    elseif input.KeyCode == Enum.KeyCode.F6 then
        toggleInfiniteJump()
    elseif input.KeyCode == Enum.KeyCode.F7 then
        toggleAntiIdle()
    elseif input.KeyCode == Enum.KeyCode.F8 then
        toggleAdvancedAntiIdle()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        toggleAutoWalk()
    elseif input.KeyCode == Enum.KeyCode.F10 then
        toggleAutoJump()
    elseif input.KeyCode == Enum.KeyCode.F11 then
        toggleAutoClimb()
    elseif input.KeyCode == Enum.KeyCode.F12 then
        toggleFollowPath()
    elseif input.KeyCode == Enum.KeyCode.F13 then
        applySettings()
    elseif input.KeyCode == Enum.KeyCode.F14 then
        resetSettings()
    elseif input.KeyCode == Enum.KeyCode.F15 then
        -- Toggle GUI visibility
        local gui = player.PlayerGui:FindFirstChild("AutoPlayGUI")
        if gui then
            gui.Enabled = not gui.Enabled
            updateStatus("GUI " .. (gui.Enabled and "ditampilkan" or "disembunyikan"))
        end
    elseif input.KeyCode == Enum.KeyCode.F16 then
        -- Toggle Adaptive Recording
        toggleAdaptiveRecording()
    elseif input.KeyCode == Enum.KeyCode.F17 then
        -- Toggle Loop Playback
        toggleLoopPlayback()
    elseif input.KeyCode == Enum.KeyCode.F then
        -- Toggle GUI Minimize/Maximize
        local gui = player.PlayerGui:FindFirstChild("AutoPlayGUI")
        if gui then
            if gui.Visible then
                -- Minimize GUI (hide entire GUI)
                gui.Visible = false
                updateStatus("📦 GUI diminimize (F untuk tampilkan)")
                print("GUI MINIMIZED - Tekan F untuk menampilkan kembali")
            else
                -- Maximize GUI (show entire GUI)
                gui.Visible = true
                updateStatus("🎮 GUI ditampilkan (F untuk minimize)")
                print("GUI MAXIMIZED - Semua button tersedia")
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Space then
        -- Spam jump detection
        if infiniteJumpEnabled and spamJumpEnabled then
            local currentTime = tick()
            if currentTime - lastSpacePress > spacePressCooldown then
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    local humanoid = player.Character.Humanoid
                    humanoid.Jump = true
                    jumpCount = jumpCount + 1
                    lastSpacePress = currentTime
                    lastJumpTime = currentTime
                    
                    updateStatus("Spam Jump " .. jumpCount .. " (Space Pressed)")
                end
            end
        end
    end
end)

-- Player respawn detection
player.CharacterAdded:Connect(function(character)
    wait(1)
    -- Don't auto-apply settings on respawn
    updateStatus("Character respawned, settings tidak otomatis diterapkan")
end)

-- Initial setup - Don't auto-apply settings
if player.Character then
    wait(1)
    updateStatus("Script dimuat! TIDAK mengubah movement settings")
end

updateStatus("MT Daun Recorder & Auto Play siap! Tekan F untuk minimize GUI")
print("MT Daun Recorder & Auto Play dimuat!")
print("Kontrol:")
print("F1 - Toggle Auto Play")
print("F2 - Toggle Recording")
print("F3 - Toggle Playback")
print("F4 - Save Recording")
print("F5 - Load Recording")
print("F6 - Toggle Infinite Jump")
print("F7 - Toggle Anti-Idle (Bypass idle 20 menit)")
print("F8 - Toggle Advanced Anti-Idle (Disable Idled event)")
print("F9 - Toggle Auto Walk")
print("F10 - Toggle Auto Jump")
print("F11 - Toggle Auto Climb")
print("F12 - Toggle Follow Path")
print("F13 - Apply Settings (TIDAK mengubah Speed/Jump)")
print("F14 - Reset Settings")
print("F15 - Toggle GUI")
print("F16 - Toggle Adaptive Recording")
print("F17 - Toggle Loop Playback (🔄 LOOP button)")
print("F - Toggle GUI Minimize/Maximize (hide/show entire GUI)")
print("")
print("GUI Controls:")
print("- F: Minimize/Maximize GUI (hide/show entire GUI)")
print("- F13: Enable/Disable GUI completely")
print("")
print("Fitur Recording:")
print("- Record: Merekam gerakan player secara real-time")
print("- Play: Memutar kembali rekaman yang sudah disimpan")
print("- Save: Menyimpan rekaman ke memory")
print("- Load: Memuat rekaman dari memory")
print("- Loop: Playback berulang otomatis setelah selesai")
print("- Input Recording: Merekam semua input keyboard & mouse")
print("- Input Playback: Memutar kembali input user yang asli")
print("- Anti-Idle Bypass: Input playback mencegah idle detection")
print("- Adaptive Recording: ON (Frame-perfect recording)")
print("- Recording Quality: Dynamic (mengikuti FPS game Anda)")
print("- Playback Quality: Dynamic (mengikuti FPS game Anda)")
print("- Playback Speed: 1.0x (dapat disesuaikan)")
print("- Advanced Interpolation: Position & rotation smoothing")
print("- No Fixed Interval: Recording mengikuti performa game")
print("")
print("Fitur Auto Play:")
print("- Infinite Jump: Spam jump unlimited (tekan spasi berulang)")
print("- Anti-Idle: Bypass idle 20 menit dengan gerakan kecil otomatis")
print("- Advanced Anti-Idle: Disable Idled event (100% efektif)")
print("- Auto Walk: Berjalan otomatis ke depan")
print("- Auto Jump: Melompat otomatis saat ada rintangan")
print("- Auto Climb: Memanjat objek yang bisa dipanjat")
print("- Follow Path: Mengikuti jalur ke target mouse")
print("- Obstacle Detection: Mendeteksi rintangan dan objek yang bisa dipanjat")
print("- Stuck Detection: Mendeteksi jika player terjebak")
print("- Realistic Playback: Gerakan halus dengan interpolasi dan camera following")
print("")
print("Pengaturan:")
print("- Speed: 1-100 (default: 20)")
print("- Jump: 1-200 (default: 50)")
print("- Detection Distance: 50 studs")
print("- Jump Cooldown: 0.5 detik")
print("- Path Update: setiap 2 detik")
print("- Recording Interval: 0.1 detik")
print("")
print("Cara Penggunaan:")
print("1. Script TIDAK mengubah movement settings (Speed & Jump)")
print("2. Klik 'Record' atau tekan F2 untuk mulai merekam")
print("3. Lakukan gerakan yang ingin direkam (semua input keyboard/mouse akan direkam)")
print("4. Klik 'Record' lagi atau tekan F2 untuk berhenti merekam")
print("5. Klik 'Save' atau tekan F4 untuk menyimpan rekaman")
print("6. Klik 'Play' atau tekan F3 untuk memutar rekaman")
print("7. Input playback akan mencegah idle detection secara otomatis")
print("8. Gunakan Auto Play untuk gerakan otomatis tanpa rekaman")
print("9. Aktifkan Infinite Jump untuk spam jump saat mendaki")
print("")
print("Infinite Jump (Spam Jump):")
print("- Lompat unlimited tanpa batas")
print("- Tekan spasi berulang untuk spam jump")
print("- Tidak perlu menyentuh tanah")
print("- Cooldown 0.1 detik antar lompatan")
print("- Ultra responsive (120 FPS detection)")
print("- Bisa tahan spasi untuk lompat terus")
print("")
print("Anti-Idle (Bypass Idle 20 Menit):")
print("- Gerakan kecil otomatis setiap 15 detik")
print("- 4 jenis gerakan: move, jump, look, camera")
print("- Gerakan sangat kecil dan natural")
print("- Tidak mengganggu gameplay normal")
print("- Mencegah idle detection Roblox")
print("- Bisa diaktifkan/dinonaktifkan kapan saja")
print("- Keyboard shortcut: F7")
print("")
print("Advanced Anti-Idle (Disable Idled Event):")
print("- Menonaktifkan event Idled secara permanen")
print("- 100% efektif mencegah idle kick")
print("- Tidak perlu gerakan atau input simulation")
print("- Lebih ringan dan tidak memakan resource")
print("- Bisa diaktifkan/dinonaktifkan kapan saja")
print("- Keyboard shortcut: F8")
print("- Rekomendasi: Gunakan ini untuk anti-idle yang paling efektif")
print("")
print("Realistic Playback:")
print("- Ultra smooth interpolation (120 FPS)")
print("- Position & rotation interpolation")
print("- Camera following yang natural")
print("- Timing yang akurat sesuai rekaman")
print("- Gerakan yang terlihat seperti bermain manual")
print("- Tidak ada lagi gerakan patah-patah!")
print("")
print("Input Recording System:")
print("- Real Input Recording: Merekam semua input keyboard & mouse")
print("- Input Playback: Memutar kembali input user yang asli")
print("- Anti-Idle Bypass: Input playback mencegah idle detection")
print("- Perfect Timing: Input disinkronkan dengan gerakan")
print("- Natural Input: Terlihat seperti input user yang sebenarnya")
print("- Keyboard & Mouse: Semua jenis input direkam")
print("- Loop Support: Input juga berulang saat loop playback")
print("- Save/Load: Input data tersimpan bersama rekaman")
print("")
print("Adaptive Recording System:")
print("- Frame-Perfect Recording: Mengikuti FPS game Anda")
print("- No Fixed Interval: Tidak ada interval tetap")
print("- Dynamic Quality: Kualitas menyesuaikan performa")
print("- RunService.Heartbeat: Sinkronisasi sempurna dengan game")
print("- Advanced interpolation algorithm")
print("- Smooth camera movement")
print("- Perfect timing synchronization")
print("- Professional grade recording & playback")
print("- Zero Lag Recording: Tidak ada delay recording")
print("- Input Recording: Merekam input user untuk anti-idle bypass")
