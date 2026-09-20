-- Mobile WASD (Delta-safe)
local UserInputService = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local player            = Players.LocalPlayer
local camera            = workspace.CurrentCamera

print("[WASD] Script started")

-- Cleanup old
if getgenv and getgenv().MobileWASD and getgenv().MobileWASD.gui then
    pcall(function() getgenv().MobileWASD.gui:Destroy() end)
end

local connections = {}
local function track(c) table.insert(connections, c); return c end

-- GUI parent
local gui = Instance.new("ScreenGui")
gui.Name = "MobileWASD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
print("[WASD] GUI parented")

getgenv().MobileWASD = { gui = gui }

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = p
end

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 110, 0, 40)
toggleBtn.Position = UDim2.new(0, 12, 0, 12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Text = "WASD: ON"
toggleBtn.TextSize = 15
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Active = true
toggleBtn.Parent = gui
corner(toggleBtn, 8)

-- Shiftlock button
local shiftBtn = Instance.new("TextButton")
shiftBtn.Size = UDim2.new(0, 60, 0, 60)
shiftBtn.Position = UDim2.new(0.5, -30, 0.35, 0)
shiftBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
shiftBtn.TextColor3 = Color3.fromRGB(255,255,255)
shiftBtn.Text = "🔓"
shiftBtn.TextSize = 26
shiftBtn.Font = Enum.Font.GothamBold
shiftBtn.BorderSizePixel = 0
shiftBtn.Active = true
shiftBtn.Parent = gui
corner(shiftBtn, 999)

-- WASD buttons
local function makeKey(name, pos, label)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, 70, 0, 70)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(30,30,30)
    b.BackgroundTransparency = 0.25
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = label
    b.TextSize = 28
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Active = true
    b.Parent = gui
    corner(b, 14)
    return b
end

local WButton = makeKey("WButton", UDim2.new(0, 20,  1, -170), "W")
local AButton = makeKey("AButton", UDim2.new(0, 100, 1, -170), "A")
local SButton = makeKey("SButton", UDim2.new(1, -170, 1, -170), "S")
local DButton = makeKey("DButton", UDim2.new(1, -90,  1, -170), "D")
print("[WASD] Buttons created")

local keys = { W=false, A=false, S=false, D=false }
local shiftLock = false
local wasdOn = true

local function bindKey(btn, key)
    track(btn.MouseButton1Down:Connect(function()
        keys[key] = true
        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    end))
    track(btn.MouseButton1Up:Connect(function()
        keys[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    end))
    track(btn.MouseLeave:Connect(function()
        keys[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    end))
    track(btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            keys[key] = true
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            track(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    keys[key] = false
                    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                end
            end))
        end
    end))
end

bindKey(WButton, "W")
bindKey(AButton, "A")
bindKey(SButton, "S")
bindKey(DButton, "D")

-- Shiftlock
local function applyShiftlock()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if shiftLock then
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        shiftBtn.Text = "🔒"
        if hum then hum.CameraOffset = Vector3.new(1.75, 0, 0) end
    else
        shiftBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        shiftBtn.Text = "🔓"
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end
end

track(shiftBtn.MouseButton1Click:Connect(function()
    shiftLock = not shiftLock
    applyShiftlock()
end))
track(shiftBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        shiftLock = not shiftLock
        applyShiftlock()
    end
end))

-- WASD toggle
local function setWASDVisible(v)
    WButton.Visible = v; AButton.Visible = v
    SButton.Visible = v; DButton.Visible = v
end

local function toggleWASD()
    wasdOn = not wasdOn
    setWASDVisible(wasdOn)
    if wasdOn then
        toggleBtn.Text = "WASD: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    else
        toggleBtn.Text = "WASD: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        keys.W, keys.A, keys.S, keys.D = false, false, false, false
    end
end

track(toggleBtn.MouseButton1Click:Connect(toggleWASD))
track(toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then toggleWASD() end
end))

-- Movement
track(RunService.RenderStepped:Connect(function()
    if not wasdOn then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return end

    local mv = Vector3.zero
    if keys.W then mv = mv + Vector3.new(0,0,-1) end
    if keys.S then mv = mv + Vector3.new(0,0, 1) end
    if keys.A then mv = mv + Vector3.new(-1,0,0) end
    if keys.D then mv = mv + Vector3.new( 1,0,0) end

    if mv.Magnitude > 0 then
        mv = mv.Unit
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local fL = Vector3.new(look.X, 0, look.Z)
        local fR = Vector3.new(right.X, 0, right.Z)
        if fL.Magnitude > 0 then fL = fL.Unit end
        if fR.Magnitude > 0 then fR = fR.Unit end

        local world = (fL * -mv.Z) + (fR * mv.X)
        hum:Move(world, false)

        if shiftLock then
            local target = CFrame.lookAt(root.Position, root.Position + world)
            root.CFrame = root.CFrame:Lerp(
                CFrame.new(root.Position) * (target - target.Position), 0.35)
        end
    else
        hum:Move(Vector3.zero, false)
    end
end))

-- Touch camera drag for shiftlock
local lastTouch, dragging = nil, false
track(UserInputService.TouchStarted:Connect(function(input, gp)
    if gp or not shiftLock then return end
    local p = input.Position
    for _, b in ipairs({WButton,AButton,SButton,DButton,shiftBtn,toggleBtn}) do
        local tl = b.AbsolutePosition
        local br = tl + b.AbsoluteSize
        if p.X >= tl.X and p.X <= br.X and p.Y >= tl.Y and p.Y <= br.Y then
            return
        end
    end
    if p.X > camera.ViewportSize.X * 0.35 then
        lastTouch = p; dragging = true
    end
end))

track(UserInputService.TouchMoved:Connect(function(input)
    if not dragging or not lastTouch then return end
    local d = input.Position - lastTouch
    lastTouch = input.Position
    local sens = 0.006
    local look = camera.CFrame.LookVector
    local curYaw = math.atan2(-look.X, -look.Z)
    local curPitch = math.asin(math.clamp(look.Y, -1, 1))
    local newYaw = curYaw + (-d.X * sens)
    local newPitch = math.clamp(curPitch + (-d.Y * sens), math.rad(-80), math.rad(80))
    local dir = Vector3.new(
        -math.sin(newYaw) * math.cos(newPitch),
         math.sin(newPitch),
        -math.cos(newYaw) * math.cos(newPitch))
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + dir)
end))

track(UserInputService.TouchEnded:Connect(function()
    dragging = false; lastTouch = nil
end))

-- Hide default mobile controls
track(RunService.Heartbeat:Connect(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return end
    local tg = pg:FindFirstChild("TouchGui")
    if tg then
        local cf = tg:FindFirstChild("TouchControlFrame")
        if cf then cf.Visible = not wasdOn end
    end
end))

track(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if shiftLock then applyShiftlock() end
end))

setWASDVisible(true)
applyShiftlock()
print("[WASD] Loaded successfully")
