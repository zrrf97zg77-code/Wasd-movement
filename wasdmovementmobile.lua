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

-- ===== REAL SHIFTLOCK =====
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
    if shiftLock then
        -- seed camera yaw/pitch from current camera so it doesn't snap
        local look = cam.CFrame.LookVector
        yaw = math.atan2(-look.X, -look.Z)
        pitch = math.asin(math.clamp(look.Y, -1, 1))
    end
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

-- ===== CAMERA CONTROL FOR SHIFTLOCK =====
yaw = 0
pitch = 0

local function updateCamera()
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local dir = Vector3.new(
        -math.sin(yaw) * math.cos(pitch),
         math.sin(pitch),
        -math.cos(yaw) * math.cos(pitch)
    )
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + dir)

    -- Y-axis-only rotation (never tilts X/Z)
    local flatDir = Vector3.new(dir.X, 0, dir.Z)
    if flatDir.Magnitude > 0.01 then
        flatDir = flatDir.Unit
        local currentYaw = math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z)
        local targetYaw = math.atan2(-flatDir.X, -flatDir.Z)
        local diff = math.atan2(math.sin(targetYaw - currentYaw), math.cos(targetYaw - currentYaw))
        local newYaw = currentYaw + diff * 0.3
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, newYaw, 0)
    end
end

-- ===== MAIN LOOP =====
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

    if shiftLock then
        updateCamera()
    end
end)

-- ===== TOUCH DRAG (multi-touch safe, tagged touches) =====
local activeDrags = {}
local uiTouches   = {}

UIS.InputBegan:Connect(function(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    -- Tag every touch at the moment it starts
    if isOnOurButtons(input.Position) then
        uiTouches[input] = true
        return
    end

    if gp then return end
    if not shiftLock then return end
    activeDrags[input] = input.Position
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    if uiTouches[input] then return end
    local last = activeDrags[input]
    if not last then return end
    local d = input.Position - last
    activeDrags[input] = input.Position

    yaw = yaw - d.X * 0.006
    pitch = math.clamp(pitch - d.Y * 0.006, math.rad(-80), math.rad(80))
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        activeDrags[input] = nil
        uiTouches[input] = nil
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
    if shiftLock then
        applyShift()
        local look = cam.CFrame.LookVector
        yaw = math.atan2(-look.X, -look.Z)
        pitch = math.asin(math.clamp(look.Y, -1, 1))
    end
end)
