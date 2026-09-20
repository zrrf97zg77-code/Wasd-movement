local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera

-- Cleanup old instance on re-execute
if _G.WASDMobileGui then
    pcall(function() _G.WASDMobileGui:Destroy() end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "WASDMobile"
gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")
_G.WASDMobileGui = gui

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

-- Toggle( button
local toggleBtn0 = mkbtn("WASD:. ON", UDim2.new5(0,110,0,-,40), UDim2.new(0,12,0,12), Color3.fromRGB(0,120,200))
toggleBtn.TextSize = 15

-- Shiftlock button (draggable)
local shiftBtn = mkbtn("🔓", UDim2.new(0,60,0,60), UDim2.new30,0.35,0), Color3.fromRGB(40,40,40))

-- ===== Drag logic for shiftlock button =====
local dragStart = nil
local startPos = nil

shiftBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = input.Position
        startPos = shiftBtn.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragStart then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        shiftBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = nil
        startPos = nil
    end
end)
-- ===== End drag logic =====

-- WASD buttons
local W = mkbtn("W", UDim2.new(0,70,0,70), UDim2.new(0, 20,  1, -170))
local A = mkbtn("A", UDim2.new(0,70,0,70), UDim2.new(0, 100, 1, -170))
local S = mkbtn("S", UDim2.new(0,70,0,70), UDim2.new(1, -170, 1, -170))
local D = mkbtn("D", UDim2.new(0,70,0,70), UDim2.new(1, -90,  1, -170))

local keys = {W=false, A=false, S=false, D=false}
local shiftLock = false
local wasdOn = true

-- WASD button binding (hold-to-move)
local function bind(btn, key)
    local function on()
        keys[key] = true
        btn.BackgroundColor3 = Color3.fromRGB(0,120,200)
    end
    local function off()
        keys[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    end

    btn.MouseButton1Down:Connect(on)
    btn.MouseButton1Up:Connect(off)
    btn.MouseLeave:Connect(off)

    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            on()
            local conn
            conn = i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    off()
                    conn:Disconnect()
                end
            end)
        end
    end)
end

bind(W, "W") bind(A, "A") bind(S, "S") bind(D, "D")

-- Shiftlock
local function applyShift()
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if shiftLock then
        shiftBtn.Text = "🔒"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
        if hum then hum.CameraOffset = Vector3.new(1.75, 0, 0) end
    else
        shiftBtn.Text = "🔓"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end
end

local function toggleShift()
    shiftLock = not shiftLock
    applyShift()
end

shiftBtn.Activated:Connect(toggleShift)

-- WASD toggle
local function toggleWASD()
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
end

toggleBtn.Activated:Connect(toggleWASD)

-- Movement + always-on shiftlock
RS.RenderStepped:Connect(function()
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return end

    -- WASD movement (only if WASD mode on)
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
            local world = (look * -mv.Z) + (right * mv.X)
            hum:Move(world, false)
        else
            hum:Move(Vector3.zero, false)
        end
    end

    -- Shiftlock always keeps character facing camera direction (even when idle)
    if shiftLock then
        local camLook = cam.CFrame.LookVector
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
        if flatLook.Magnitude > 0.01 then
            flatLook = flatLook.Unit
            local target = CFrame.lookAt(root.Position, root.Position + flatLook)
            root.CFrame = root.CFrame:Lerp(
                CFrame.new(root.Position) * (target - target.Position), 0.3)
        end
    end
end)

-- Touch camera drag for shiftlock
local lastTouch, dragging = nil, false

UIS.TouchStarted:Connect(function(input, gp)
    if gp or not shiftLock then return end
    local p = input.Position
    for _, b in ipairs({W,A,S,D,shiftBtn,toggleBtn}) do
        local tl = b.AbsolutePosition
        local br = tl + b.AbsoluteSize
        if p.X >= tl.X and p.X <= br.X and p.Y >= tl.Y and p.Y <= br.Y then
            return
        end
    end
    lastTouch = p
    dragging = true
end)

UIS.TouchMoved:Connect(function(input)
    if not dragging or not lastTouch then return end
    local d = input.Position - lastTouch
    lastTouch = input.Position
    local look = cam.CFrame.LookVector
    local curYaw = math.atan2(-look.X, -look.Z)
    local curPitch = math.asin(math.clamp(look.Y, -1, 1))
    local newYaw = curYaw - d.X * 0.006
    local newPitch = math.clamp(curPitch - d.Y * 0.006, math.rad(-80), math.rad(80))
    local dir = Vector3.new(
        -math.sin(newYaw) * math.cos(newPitch),
         math.sin(newPitch),
        -math.cos(newYaw) * math.cos(newPitch))
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + dir)
end)

UIS.TouchEnded:Connect(function()
    dragging = false
    lastTouch = nil
end)

-- Hide default mobile controls when WASD is on
RS.Heartbeat:Connect(function()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return end
    local tg = pg:FindFirstChild("TouchGui")
    if tg then
        local cf = tg:FindFirstChild("TouchControlFrame")
        if cf then cf.Visible = not wasdOn end
    end
end)

-- Respawn
plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    if shiftLock then applyShift() end
end)
