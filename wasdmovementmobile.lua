local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local cam = workspace.CurrentCamera

if _G.WASDGui then
    pcall(function()
        _G.WASDGui:Destroy()
    end)
end

-- ============================================================
-- DISABLE AUTO JUMP COMPLETELY
-- ============================================================

local function disableAutoJump()
    pcall(function()
        if plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.AutoJumpEnabled = false
            end
        end
    end)

    pcall(function()
        local pg = plr:FindFirstChild("PlayerGui")
        if not pg then return end

        local tg = pg:FindFirstChild("TouchGui")
        if not tg then return end

        for _, obj in ipairs(tg:GetDescendants()) do
            if obj.Name == "TouchJump" then
                pcall(function()
                    obj.AutoButtonColor = false
                end)

                pcall(function()
                    obj.Visible = false
                end)

                pcall(function()
                    obj.Enabled = false
                end)

                pcall(function()
                    obj.autoJumpEnabled = false
                end)

                pcall(function()
                    obj.AutoJumpEnabled = false
                end)
            end
        end
    end)
end

task.spawn(function()
    while true do
        disableAutoJump()
        task.wait(0.25)
    end
end)

-- ============================================================
-- GUI
-- ============================================================

local gui = Instance.new("ScreenGui")
gui.Name = "WASDMobile"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = plr:WaitForChild("PlayerGui")

_G.WASDGui = gui

local function mkbtn(txt, size, pos, bg)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg or Color3.fromRGB(30,30,30)
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = txt
    b.TextSize = 26
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = gui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,12)
    c.Parent = b

    return b
end

local toggleBtn = mkbtn(
    "WASD: ON",
    UDim2.new(0,110,0,40),
    UDim2.new(0,12,0,12),
    Color3.fromRGB(0,120,200)
)

toggleBtn.TextSize = 15

-- ============================================================
-- SHIFT LOCK
-- ============================================================

local shiftBtn = Instance.new("ImageButton")
shiftBtn.Size = UDim2.fromOffset(55,55)
shiftBtn.Position = UDim2.new(1,-75,0,12)
shiftBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
shiftBtn.BackgroundTransparency = 0.15
shiftBtn.BorderSizePixel = 0
shiftBtn.AutoButtonColor = false
shiftBtn.Parent = gui

local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(1,0)
sc.Parent = shiftBtn

local ss = Instance.new("UIStroke")
ss.Thickness = 2
ss.Transparency = 0.25
ss.Parent = shiftBtn

local shiftIcon = Instance.new("TextLabel")
shiftIcon.Size = UDim2.fromScale(1,1)
shiftIcon.BackgroundTransparency = 1
shiftIcon.Text = "🔒"
shiftIcon.TextScaled = true
shiftIcon.Font = Enum.Font.GothamBold
shiftIcon.TextColor3 = Color3.fromRGB(255,255,255)
shiftIcon.Parent = shiftBtn

-- ============================================================
-- WASD
-- ============================================================

local W = mkbtn(
    "W",
    UDim2.new(0,70,0,70),
    UDim2.new(0,20,1,-170)
)

local A = mkbtn(
    "A",
    UDim2.new(0,70,0,70),
    UDim2.new(0,100,1,-170)
)

local S = mkbtn(
    "S",
    UDim2.new(0,70,0,70),
    UDim2.new(1,-170,1,-170)
)

local D = mkbtn(
    "D",
    UDim2.new(0,70,0,70),
    UDim2.new(1,-90,1,-170)
)

-- ============================================================
-- JUMP BUTTON
-- ============================================================

local jumpBtn = Instance.new("TextButton")
jumpBtn.Size = UDim2.fromOffset(70,70)
jumpBtn.Position = UDim2.new(1,-90,1,-260)
jumpBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
jumpBtn.BackgroundTransparency = 0.15
jumpBtn.BorderSizePixel = 0
jumpBtn.AutoButtonColor = false
jumpBtn.Text = "⬆"
jumpBtn.TextScaled = true
jumpBtn.Font = Enum.Font.GothamBold
jumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
jumpBtn.Parent = gui

local jc = Instance.new("UICorner")
jc.CornerRadius = UDim.new(1,0)
jc.Parent = jumpBtn

local js = Instance.new("UIStroke")
js.Thickness = 2
js.Transparency = 0.25
js.Parent = jumpBtn

-- ============================================================
-- VARIABLES
-- ============================================================

local keys = {
    W = false,
    A = false,
    S = false,
    D = false
}

local shiftLock = false
local wasdOn = true

local humanoid
local rootPart

local SHIFT_OFFSET = Vector3.new(1.75,0,0)
local NORMAL_OFFSET = Vector3.new(0,0,0)

-- ============================================================
-- CHARACTER SETUP
-- ============================================================

local function setupCharacter(character)

    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- HARD DISABLE AUTO JUMP
    humanoid.AutoJumpEnabled = false

    humanoid.CameraOffset = NORMAL_OFFSET
    humanoid.AutoRotate = true

    humanoid:GetPropertyChangedSignal("AutoJumpEnabled"):Connect(function()
        if humanoid then
            humanoid.AutoJumpEnabled = false
        end
    end)
end

if plr.Character then
    setupCharacter(plr.Character)
end

plr.CharacterAdded:Connect(function(character)
    setupCharacter(character)
end)

-- ============================================================
-- WASD BUTTONS
-- ============================================================

local function bind(btn,key)

    btn.MouseButton1Down:Connect(function()
        keys[key] = true
        btn.BackgroundColor3 = Color3.fromRGB(0,120,200)
    end)

    btn.MouseButton1Up:Connect(function()
        keys[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    end)

    btn.MouseLeave:Connect(function()
        keys[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    end)

    btn.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.Touch then

            keys[key] = true
            btn.BackgroundColor3 = Color3.fromRGB(0,120,200)

            input.Changed:Connect(function()

                if input.UserInputState == Enum.UserInputState.End then
                    keys[key] = false
                    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                end

            end)
        end

    end)
end

bind(W,"W")
bind(A,"A")
bind(S,"S")
bind(D,"D")

-- ============================================================
-- REAL ROBLOX-STYLE JUMP
-- ============================================================

local function jump()

    if not humanoid then
        return
    end

    if humanoid.Health <= 0 then
        return
    end

    -- This is the equivalent of pressing Space.
    humanoid.Jump = true

    -- Force the humanoid into the normal Roblox jumping state.
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    jumpBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
end

local function releaseJump()

    jumpBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
end

jumpBtn.MouseButton1Down:Connect(jump)
jumpBtn.MouseButton1Up:Connect(releaseJump)
jumpBtn.MouseLeave:Connect(releaseJump)

jumpBtn.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch then

        jump()

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                releaseJump()
            end

        end)
    end

end)

-- ============================================================
-- WASD TOGGLE
-- ============================================================

toggleBtn.Activated:Connect(function()

    wasdOn = not wasdOn

    W.Visible = wasdOn
    A.Visible = wasdOn
    S.Visible = wasdOn
    D.Visible = wasdOn
    jumpBtn.Visible = wasdOn

    if wasdOn then

        toggleBtn.Text = "WASD: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)

    else

        toggleBtn.Text = "WASD: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150,30,30)

        keys.W = false
        keys.A = false
        keys.S = false
        keys.D = false

    end
end)

-- ============================================================
-- SHIFT LOCK
-- ============================================================

local function setShiftLock(enabled)

    shiftLock = enabled

    if not humanoid then
        return
    end

    if enabled then

        humanoid.AutoRotate = false

        shiftBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)

        shiftIcon.TextColor3 = Color3.fromRGB(0,0,0)
        shiftIcon.Text = "🔓"

    else

        humanoid.AutoRotate = true

        shiftBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)

        shiftIcon.TextColor3 = Color3.fromRGB(255,255,255)
        shiftIcon.Text = "🔒"

    end
end

shiftBtn.Activated:Connect(function()
    setShiftLock(not shiftLock)
end)

-- ============================================================
-- MOVEMENT
-- ============================================================

RS.RenderStepped:Connect(function()

    if not humanoid or not rootPart then
        return
    end

    -- Keep auto jump OFF.
    humanoid.AutoJumpEnabled = false

    -- Shift lock camera offset.
    local targetOffset =
        shiftLock and SHIFT_OFFSET or NORMAL_OFFSET

    humanoid.CameraOffset =
        humanoid.CameraOffset:Lerp(targetOffset,0.2)

    -- Rotate character toward camera.
    if shiftLock then

        local look = cam.CFrame.LookVector

        local flatLook =
            Vector3.new(look.X,0,look.Z)

        if flatLook.Magnitude > 0.001 then

            rootPart.CFrame =
                CFrame.lookAt(
                    rootPart.Position,
                    rootPart.Position + flatLook
                )

        end
    end

    -- WASD movement.
    if wasdOn then

        local mv = Vector3.zero

        if keys.W then
            mv += Vector3.new(0,0,-1)
        end

        if keys.S then
            mv += Vector3.new(0,0,1)
        end

        if keys.A then
            mv += Vector3.new(-1,0,0)
        end

        if keys.D then
            mv += Vector3.new(1,0,0)
        end

        if mv.Magnitude > 0 then

            mv = mv.Unit

            local cf = cam.CFrame

            local look =
                Vector3.new(
                    cf.LookVector.X,
                    0,
                    cf.LookVector.Z
                )

            local right =
                Vector3.new(
                    cf.RightVector.X,
                    0,
                    cf.RightVector.Z
                )

            if look.Magnitude > 0.01 then
                look = look.Unit
            else
                look = Vector3.new(0,0,-1)
            end

            if right.Magnitude > 0.01 then
                right = right.Unit
            else
                right = Vector3.new(1,0,0)
            end

            humanoid:Move(
                (look * -mv.Z) +
                (right * mv.X),
                false
            )

        else

            humanoid:Move(Vector3.zero,false)

        end
    end
end)

-- ============================================================
-- HIDE DEFAULT ROBLOX TOUCH CONTROLS
-- ============================================================

local lastState = nil

task.spawn(function()

    while true do

        if lastState ~= wasdOn then

            lastState = wasdOn

            local pg = plr:FindFirstChild("PlayerGui")

            if pg then

                local tg =
                    pg:FindFirstChild("TouchGui")

                if tg then

                    local cf =
                        tg:FindFirstChild("TouchControlFrame")

                    if cf then
                        cf.Visible = not wasdOn
                    end

                end
            end
        end

        task.wait(0.25)
    end
end)
