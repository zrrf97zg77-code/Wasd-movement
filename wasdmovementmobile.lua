-- Mobile WASD Movement Script with Native-Style Shiftlock
-- Place this in StarterPlayerScripts as a LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Disable auto-jump on mobile
pcall(function()
    player.DevEnableMouseLock = false
end)

-- ============================================================
-- SHIFTLOCK STATE
-- ============================================================
local shiftlockEnabled = false

local UserSettings = UserSettings()
local UserGameSettings = UserSettings.GameSettings

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.AutoJumpEnabled = false
    humanoid:GetPropertyChangedSignal("AutoJumpEnabled"):Connect(function()
        if humanoid.AutoJumpEnabled then
            humanoid.AutoJumpEnabled = false
        end
    end)
    
    if shiftlockEnabled then
        humanoid.CameraOffset = Vector3.new(1.75, 0.5, 0)
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================================
-- SHIFTLOCK FUNCTIONS
-- ============================================================
local function setShiftlock(enabled)
    shiftlockEnabled = enabled
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if enabled then
        humanoid.CameraOffset = Vector3.new(1.75, 0.5, 0)
        UserGameSettings.RotationType = Enum.RotationType.CameraRelative
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    else
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
        UserGameSettings.RotationType = Enum.RotationType.MovementRelative
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

-- ============================================================
-- GUI CREATION
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileWASD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Left container (W + Shiftlock)
local leftContainer = Instance.new("Frame")
leftContainer.Name = "LeftContainer"
leftContainer.BackgroundTransparency = 1
leftContainer.Size = UDim2.new(0, 100, 0, 150)
leftContainer.Position = UDim2.new(0, 20, 1, -190)
leftContainer.Parent = screenGui

-- Right container (A, S, D side by side)
local rightContainer = Instance.new("Frame")
rightContainer.Name = "RightContainer"
rightContainer.BackgroundTransparency = 1
rightContainer.Size = UDim2.new(0, 200, 0, 60)
rightContainer.Position = UDim2.new(1, -220, 0.5, -30)
rightContainer.Parent = screenGui

local moveState = {
    W = false,
    A = false,
    S = false,
    D = false,
}

local function createButton(name, text, position, size, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 0.5
    button.TextColor3 = Color3.fromRGB(0, 0, 0)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = button
    
    return button
end

-- Smaller button size
local btnSize = UDim2.new(0, 55, 0, 55)

-- Shiftlock button (smaller) - top of left container
local shiftButton = createButton(
    "Shiftlock", 
    "🔒", 
    UDim2.new(0, 10, 0, 0), 
    UDim2.new(0, 50, 0, 35),
    leftContainer
)
shiftButton.TextSize = 20
shiftButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

-- W button - below shiftlock
local wButton = createButton("W", "W", UDim2.new(0, 5, 0, 45), btnSize, leftContainer)

-- A, S, D side by side horizontally on the right
local aButton = createButton("A", "A", UDim2.new(0, 0, 0, 0), btnSize, rightContainer)
local sButton = createButton("S", "S", UDim2.new(0, 65, 0, 0), btnSize, rightContainer)
local dButton = createButton("D", "D", UDim2.new(0, 130, 0, 0), btnSize, rightContainer)

-- ============================================================
-- MOVEMENT LOGIC
-- ============================================================
local function updateMovement()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    local camLook = cam.CFrame.LookVector
    local camRight = cam.CFrame.RightVector
    
    local forward = Vector3.new(camLook.X, 0, camLook.Z)
    local right = Vector3.new(camRight.X, 0, camRight.Z)
    
    if forward.Magnitude > 0 then forward = forward.Unit end
    if right.Magnitude > 0 then right = right.Unit end
    
    local moveVector = Vector3.new(0, 0, 0)
    if moveState.W then moveVector = moveVector + forward end
    if moveState.S then moveVector = moveVector - forward end
    if moveState.A then moveVector = moveVector - right end
    if moveState.D then moveVector = moveVector + right end
    
    if moveVector.Magnitude > 0 then
        humanoid:Move(moveVector.Unit, false)
    else
        humanoid:Move(Vector3.new(0, 0, 0), false)
    end
end

-- ============================================================
-- BUTTON HANDLERS
-- ============================================================
local function setupButton(button, key)
    button.MouseButton1Down:Connect(function()
        moveState[key] = true
        button.BackgroundTransparency = 0.2
    end)
    
    button.MouseButton1Up:Connect(function()
        moveState[key] = false
        button.BackgroundTransparency = 0.5
    end)
    
    button.MouseLeave:Connect(function()
        moveState[key] = false
        button.BackgroundTransparency = 0.5
    end)
end

setupButton(wButton, "W")
setupButton(aButton, "A")
setupButton(sButton, "S")
setupButton(dButton, "D")

-- Shiftlock toggle
local shiftlockDebounce = false
shiftButton.MouseButton1Down:Connect(function()
    if shiftlockDebounce then return end
    shiftlockDebounce = true
    
    shiftlockEnabled = not shiftlockEnabled
    setShiftlock(shiftlockEnabled)
    
    if shiftlockEnabled then
        shiftButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        shiftButton.Text = "🔓"
    else
        shiftButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        shiftButton.Text = "🔒"
    end
    
    task.wait(0.2)
    shiftlockDebounce = false
end)

RunService.RenderStepped:Connect(updateMovement)

-- ============================================================
-- DESKTOP KEYBOARD SUPPORT
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        moveState.W = true
    elseif input.KeyCode == Enum.KeyCode.A then
        moveState.A = true
    elseif input.KeyCode == Enum.KeyCode.S then
        moveState.S = true
    elseif input.KeyCode == Enum.KeyCode.D then
        moveState.D = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        shiftlockEnabled = not shiftlockEnabled
        setShiftlock(shiftlockEnabled)
        if shiftlockEnabled then
            shiftButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            shiftButton.Text = "🔓"
        else
            shiftButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            shiftButton.Text = "🔒"
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W then
        moveState.W = false
    elseif input.KeyCode == Enum.KeyCode.A then
        moveState.A = false
    elseif input.KeyCode == Enum.KeyCode.S then
        moveState.S = false
    elseif input.KeyCode == Enum.KeyCode.D then
        moveState.D = false
    end
end)

-- ============================================================
-- DRAGGABLE CONTAINERS
-- ============================================================
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(leftContainer)
makeDraggable(rightContainer)
