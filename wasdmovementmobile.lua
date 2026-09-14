-- Mobile WASD Movement Script with Camera-Relative Movement + Shiftlock
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

-- Wait for character
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Disable auto jump
    humanoid.AutoJumpEnabled = false
    
    humanoid:GetPropertyChangedSignal("AutoJumpEnabled"):Connect(function()
        if humanoid.AutoJumpEnabled then
            humanoid.AutoJumpEnabled = false
        end
    end)
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================================
-- SHIFTLOCK SETUP
-- ============================================================
local shiftlockEnabled = false
local originalOffset = nil

-- Store the original camera offset on the humanoid
local function setupHumanoidForShiftlock(character)
    local humanoid = character:WaitForChild("Humanoid")
    -- Save original camera offset (usually Vector3.new(0,0,0) or a shoulder offset)
    originalOffset = humanoid.CameraOffset
    humanoid.CameraOffset = originalOffset
end

if player.Character then
    setupHumanoidForShiftlock(player.Character)
end
player.CharacterAdded:Connect(setupHumanoidForShiftlock)

-- Function to toggle shiftlock
local function setShiftlock(enabled)
    shiftlockEnabled = enabled
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if enabled then
        -- Enable shiftlock: offset camera to the right shoulder and lock rotation to character
        player.CameraMode = Enum.CameraMode.LockFirstPerson  -- fallback trick
        -- Actually, we want classic shiftlock behavior:
        -- The camera rotates around the character and the character follows camera
        humanoid.CameraOffset = Vector3.new(1.75, 0.5, 0) -- right shoulder offset
        -- Set camera to follow the humanoid's rotation
        camera.CameraSubject = humanoid
        
        -- We also need to make the character face the camera direction
        -- This will be handled in the RenderStepped loop
    else
        -- Disable shiftlock: restore original offset
        humanoid.CameraOffset = originalOffset or Vector3.new(0, 0, 0)
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

-- WASD Container
local container = Instance.new("Frame")
container.Name = "Container"
container.BackgroundTransparency = 1
container.Size = UDim2.new(0, 300, 0, 300)
container.Position = UDim2.new(0, 20, 1, -320)
container.Parent = screenGui

-- Movement state
local moveState = {
    W = false,
    A = false,
    S = false,
    D = false,
}

-- Function to create a button
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
    button.Parent = parent or container
    
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

local btnSize = UDim2.new(0, 80, 0, 80)

local wButton = createButton("W", "W", UDim2.new(0, 100, 0, 0), btnSize)
local aButton = createButton("A", "A", UDim2.new(0, 10, 0, 100), btnSize)
local sButton = createButton("S", "S", UDim2.new(0, 100, 0, 100), btnSize)
local dButton = createButton("D", "D", UDim2.new(0, 190, 0, 100), btnSize)

-- ============================================================
-- SHIFTLOCK BUTTON
-- ============================================================
local shiftButton = createButton(
    "Shiftlock", 
    "🔒", 
    UDim2.new(0, 100, 0, 200), 
    UDim2.new(0, 80, 0, 60),
    container
)
shiftButton.TextSize = 40
shiftButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

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
    
    -- Shiftlock: make character rotate to face camera direction
    if shiftlockEnabled then
        local lookFlat = Vector3.new(camLook.X, 0, camLook.Z)
        if lookFlat.Magnitude > 0 then
            local targetCFrame = CFrame.lookAt(character.HumanoidRootPart.Position, character.HumanoidRootPart.Position + lookFlat.Unit)
            character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position, character.HumanoidRootPart.Position + lookFlat.Unit)
        end
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
    
    -- Update visual
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

-- Update movement every frame
RunService.RenderStepped:Connect(updateMovement)

-- ============================================================
-- DESKTOP KEYBOARD SUPPORT (for testing)
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
-- DRAGGABLE CONTAINER
-- ============================================================
local dragging = false
local dragInput, dragStart, startPos

container.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

container.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        container.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)
