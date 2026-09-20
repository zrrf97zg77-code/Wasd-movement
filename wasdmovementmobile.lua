local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera

if _G.WASDGui then pcall(function() _G.WASDGui:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "WASDMobile"
gui.ResetOnSpawn = false
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

local shiftBtn = mkbtn("🔓", UDim2.new(0,60,0,60), UDim2.new(1,-80,0,12), Color3.fromRGB(40,40,40))

local W = mkbtn("W", UDim2.new(0,70,0,70), UDim2.new(0, 20,  1, -170))
local A = mkbtn("A", UDim2.new(0,70,0,70), UDim2.new(0, 100, 1, -170))
local S = mkbtn("S", UDim2.new(0,70,0,70), UDim2.new(1, -170, 1, -170))
local D = mkbtn("D", UDim2.new(0,70,0,70), UDim2.new(1, -90,  1, -170))

local allBtns = {W, A, S, D, shiftBtn, toggleBtn}
local keys = {W=false, A=false, S=false, D=false}
local shiftLock = false
local wasdOn = true

local function isOnOurButtons(pos)
    for _, b in ipairs(allBtns) do
        local tl = b.AbsolutePosition
        local br = tl + b.AbsoluteSize
        if pos.X >= tl.X and pos.X <= br.X and pos.Y >= tl.Y and pos.Y <= br.Y then
            return true
        end
    end
    return false
end

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

-- ===== SHIFTLOCK (real, minimal) =====
local function applyShift()
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if shiftLock then
        hum.CameraOffset = Vector3.new(1.75, 0, 0)
        hum.AutoRotate = true
        shiftBtn.Text = "🔒"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    else
        hum.CameraOffset = Vector3.new(0, 0, 0)
        hum.AutoRotate = true
        shiftBtn.Text = "🔓"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    end
end

shiftBtn.Activated:Connect(function()
    shiftLock = not shiftLock
    applyShift()
end)

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

-- ===== MOVEMENT =====
RS.RenderStepped:Connect(function()
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

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
            if look.Magnitude > 0 then look = look.Unit end
            if right.Magnitude > 0 then right = right.Unit end
            hum:Move((look * -mv.Z) + (right * mv.X), false)
        else
            hum:Move(Vector3.zero, false)
        end
    end
end)

-- ===== TOUCH CAMERA ROTATION (smooth, native-feeling) =====
-- We use a velocity/decay model instead of direct CFrame override.
-- This is what makes it feel like real Roblox camera drag.

local activeDrags = {}
local uiTouches = {}

-- Camera rotation velocity (radians per frame) for smoothness
local yawVel = 0
local pitchVel = 0

UIS.InputBegan:Connect(function(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    if isOnOurButtons(input.Position) then
        uiTouches[input] = true
        return
    end

    if gp then return end
    if not shiftLock then return end
    activeDrags[input] = {last = input.Position, delta = Vector2.zero}
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    if uiTouches[input] then return end
    local d = activeDrags[input]
    if not d then return end
    d.delta = input.Position - d.last
    d.last = input.Position
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        activeDrags[input] = nil
        uiTouches[input] = nil
    end
end)

-- Apply camera rotation smoothly using velocity decay
RS.RenderStepped:Connect(function(dt)
    if not shiftLock then return end

    local totalDelta = Vector2.zero
    for _, d in pairs(activeDrags) do
        totalDelta = totalDelta + d.delta
        d.delta = Vector2.zero
    end

    -- Convert to camera velocity (scaled by 1/dt for consistent speed)
    local sens = 0.006
    yawVel = -totalDelta.X * sens * 60
    pitchVel = -totalDelta.Y * sens * 60

    -- Apply to camera via CFrame rotation using Roblox's own camera math
    -- (rotate around camera position, not set absolute lookAt)
    local rotX = CFrame.Angles(0, yawVel * dt, 0)
    local rotY = CFrame.Angles(pitchVel * dt, 0, 0)
    
    -- Rotate in camera-local space for pitch, world space for yaw
    cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, 0) -- no-op, keep Roblox cam
    cam.CFrame = CFrame.new(cam.CFrame.Position) * cam.CFrame.Rotation * CFrame.Angles(pitchVel * dt, yawVel * dt, 0)

    -- Clamp pitch so camera can't flip
    local look = cam.CFrame.LookVector
    local curPitch = math.asin(math.clamp(look.Y, -1, 1))
    if curPitch > math.rad(80) then
        cam.CFrame = CFrame.new(cam.CFrame.Position) * (cam.CFrame.Rotation * CFrame.Angles(math.rad(-5), 0, 0))
    elseif curPitch < math.rad(-80) then
        cam.CFrame = CFrame.new(cam.CFrame.Position) * (cam.CFrame.Rotation * CFrame.Angles(math.rad(5), 0, 0))
    end
end)

-- ===== HIDE DEFAULT MOBILE CONTROLS =====
RS.Heartbeat:Connect(function()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return end
    local tg = pg:FindFirstChild("TouchGui")
    if tg then
        local cf = tg:FindFirstChild("TouchControlFrame")
        if cf then cf.Visible = not wasdOn end
    end
end)

plr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if shiftLock then applyShift() end
end)
