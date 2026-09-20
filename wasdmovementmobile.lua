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

local keys = {W=false, A=false, S=false, D=false}
local shiftLock = false
local wasdOn = true

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

local function applyShift()
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if shiftLock then
        hum.CameraOffset = Vector3.new(1.75, 0, 0)
        shiftBtn.Text = "🔒"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    else
        hum.CameraOffset = Vector3.new(0, 0, 0)
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

-- ===== MOVEMENT (only ONE per-frame loop, no camera math) =====
RS.RenderStepped:Connect(function()
    if not wasdOn then return end
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

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
        hum:Move((look * -mv.Z) + (right * mv.X), false)
    else
        hum:Move(Vector3.zero, false)
    end
end)

-- ===== HIDE DEFAULT MOBILE CONTROLS (only when state changes) =====
local lastWasdState = nil
local function refreshTouchGui()
    if lastWasdState == wasdOn then return end
    lastWasdState = wasdOn
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return end
    local tg = pg:FindFirstChild("TouchGui")
    if tg then
        local cf = tg:FindFirstChild("TouchControlFrame")
        if cf then cf.Visible = not wasdOn end
    end
end

-- Only check every 0.5s instead of every frame
task.spawn(function()
    while true do
        refreshTouchGui()
        task.wait(0.5)
    end
end)

plr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if shiftLock then applyShift() end
end)
