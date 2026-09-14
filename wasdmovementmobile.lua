-- Mobile WASD Movement Script with Auto-Jump Disabled
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
    
    -- Disable auto jump (mobile jump when moving forward)
    humanoid.AutoJumpEnabled = false
    
    -- Also handle if it gets re-enabled
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

-- Create the GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileWASD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Container frame
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
local function createButton(name, text, position, size)
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
    button.Parent = container
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = button
    
    return button
end

-- Button size
local btnSize = UDim2.new(0, 80, 0, 80)

-- Create W button (top)
local wButton = createButton("W", "W", UDim2.new(0, 100, 0, 0), btnSize)

-- Create A button (left)
local aButton = createButton("A", "A", UDim2.new(0, 10, 0, 100), btnSize)

-- Create S button (bottom)
local sButton = createButton("S", "S", UDim2.new(0, 100, 0, 100), btnSize)

-- Create D button (right)
local dButton = createButton("D", "D", UDim2.new(0, 190, 0, 100), btnSize)

-- Function to update movement based on button states
local function updateMovement()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Calculate move direction
    local moveVector = Vector3.new(0, 0, 0)
    
    if moveState.W then
        moveVector = moveVector + Vector3.new(0, 0, -1)
    end
    if moveState.S then
        moveVector = moveVector + Vector3.new(0, 0, 1)
    end
    if moveState.A then
        moveVector = moveVector + Vector3.new(-1, 0, 0)
    end
    if moveState.D then
        moveVector = moveVector + Vector3.new(1, 0, 0)
    end
    
    -- Apply movement
    if moveVector.Magnitude > 0 then
        humanoid:Move(moveVector.Unit, false)
    else
        humanoid:Move(Vector3.new(0, 0, 0), false)
    end
end

-- Button press handlers
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
    
    -- Touch events for better mobile support
    button.TouchLongPress:Connect(function()
        -- Prevent long press context menu
    end)
end

setupButton(wButton, "W")
setupButton(aButton, "A")
setupButton(sButton, "S")
setupButton(dButton, "D")

-- Update movement every frame
RunService.RenderStepped:Connect(updateMovement)

-- Also handle gamepad/desktop WASD if needed
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

-- Make it draggable (optional - makes the whole container draggable)
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
