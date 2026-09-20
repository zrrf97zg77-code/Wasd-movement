local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera

if _G.WASDGui then pcall(function() _G.WASDGui:Destroy() end) end

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
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = b
    return b
end

local toggleBtn = mkbtn("WASD: ON", UDim2.new(0,110,0,40), UDim2.new(0,12,0,12), Color3.fromRGB(0,120,200))
toggleBtn.TextSize = 15

-- Shiftlock button (round, styled like the script you sent)
local shiftBtn = Instance.new("ImageButton")
shiftBtn.Name = "ShiftLockButton"
shiftBtn.Size = UDim2.fromOffset(55, 55)
shiftBtn.Position = UDim2.new(1, -75, 0, 12)
shiftBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
shiftBtn.BackgroundTransparency = 0.15
shiftBtn.BorderSizePixel = 0
shiftBtn.AutoButtonColor = false
shiftBtn.Parent = gui

local shiftCorner = Instance.new("UICorner")
shiftCorner.CornerRadius = UDim.new(1, 0)
shiftCorner.Parent = shiftBtn

local shiftStroke = Instance.new("UIStroke")
shiftStroke.Thickness = 2
shiftStroke.Transparency = 0.25
shiftStroke.Parent = shiftBtn

local shiftIcon = Instance.new("TextLabel")
shiftIcon.Size = UDim2.fromScale(1, 1)
shiftIcon.BackgroundTransparency = 1
shiftIcon.Text = "🔒"
shiftIcon.TextScaled = true
shiftIcon.Font = Enum.Font.GothamBold
shiftIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
shiftIcon.Parent = shiftBtn

local W = mkbtn("W", UDim2.new(0,70,0,70), UDim2.new(0, 20,  1, -170))
local A = mkbtn("A", UDim2.new(0,70,0,70), UDim2.new(0, 100, 1, -170))
local S = mkbtn("S", UDim2.new(0,70,0,70), UDim2.new(1, -170, 1, -170))
local D = mkbtn("D", UDim2.new(0,70,0,70), UDim2.new(1, -90,  1, -170))

local keys = {W=false, A=false, S=false, D=false}
local shiftLock = false
local wasdOn = true

local humanoid
local rootPart

local SHIFT_OFFSET = Vector3.new(1.75, 0, 0)
local NORMAL_OFFSET = Vector3.new(0, 0, 0)

-- Character setup
local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.CameraOffset = NORMAL_OFFSET
    humanoid.AutoRotate = true
end

if plr.Character then
    setupCharacter(plr.Character)
end
plr.CharacterAdded:Connect(setupCharacter)

-- WASD binding
local function bind(btn, key)
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
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            keys[key] = true
            btn.BackgroundColor3 = Color3.fromRGB(0,120,200)
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    keys[key] = false
                    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                end
            end)
        end
    end)
end

bind(W,"W") bind(A,"A") bind(S,"S") bind(D,"D")

-- Toggle WASD
toggleBtn.Activated:Connect(function()
    wasdOn = not wasdOn
    W.Visible = wasdOn
    A.Visible = wasdOn
    S.Visible = wasdOn
    D.Visible = wasdOn
    if wasdOn then
        toggleBtn.Text = "WASD: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
    else
        toggleBtn.Text = "WASD: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150,30,30)
        keys.W, keys.A, keys.S, keys.D = false, false, false, false
    end
end)

-- Shiftlock toggle (your logic)
local function setShiftLock(enabled)
    shiftLock = enabled

    if not humanoid then return end

    if enabled then
        humanoid.AutoRotate = false
        shiftBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        shiftIcon.TextColor3 = Color3.fromRGB(0, 0, 0)
        shiftIcon.Text = "🔓"
    else
        humanoid.AutoRotate = true
        shiftBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        shiftIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
        shiftIcon.Text = "🔒"
    end
end

shiftBtn.Activated:Connect(function()
    setShiftLock(not shiftLock)
end)

-- Main loop: shiftlock lerp + WASD movement
RS.RenderStepped:Connect(function()
    if not humanoid or not rootPart then return end

    local targetOffset = shiftLock and SHIFT_OFFSET or NORMAL_OFFSET
    humanoid.CameraOffset = humanoid.CameraOffset:Lerp(targetOffset, 0.2)

    if shiftLock then
        local look = cam.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0.001 then
            rootPart.CFrame = CFrame.lookAt(
                rootPart.Position,
                rootPart.Position + flatLook
            )
        end
    end

    if wasdOn then
        local mv = Vector3.zero
        if keys.W then mv = mv + Vector3.new(0,0,-1) end
        if keys.S then mv = mv + Vector3.new(0,0, 1) end
        if keys.A then mv = mv + Vector3.new(-1,0,0) end
        if keys.D then mv = mv + Vector3.new( 1,0,0) end

        if mv.Magnitude > 0 then
            mv = mv.Unit
            local cf = cam.CFrame
            local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            if look.Magnitude > 0.01 then look = look.Unit else look = Vector3.new(0,0,-1) end
            if right.Magnitude > 0.01 then right = right.Unit else right = Vector3.new(1,0,0) end
            humanoid:Move((look * -mv.Z) + (right * mv.X), false)
        else
            humanoid:Move(Vector3.zero, false)
        end
    end
end)

-- Hide default mobile controls when WASD is on
local lastState = nil
task.spawn(function()
    while true do
        if lastState ~= wasdOn then
            lastState = wasdOn
            local pg = plr:FindFirstChild("PlayerGui")
            if pg then
                local tg = pg:FindFirstChild("TouchGui")
                if tg then
                    local cf = tg:FindFirstChild("TouchControlFrame")
                    if cf then cf.Visible = not wasdOn end
                end
            end
        end
        task.wait(0.5)
    end
end)
