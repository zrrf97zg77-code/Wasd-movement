local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera

if _G.WASDGui then pcall(function() _G.WASDGui:Destroy() end) end
if _G.ShiftPart then pcall(function() _G.ShiftPart:Destroy() end) end

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

-- ===== SHIFTLOCK via CameraSubject swap =====
-- Create an invisible part that sits behind/beside the character.
-- Point the camera at it. Now the native mobile camera drag follows it.
-- This is how real mobile shiftlock works.

local function createShiftPart()
    local char = plr.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local part = Instance.new("Part")
    part.Name = "ShiftLockSubject"
    part.Size = Vector3.new(1, 1, 1)
    part.Transparency = 1
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Anchored = true
    part.Parent = workspace
    part.CFrame = root.CFrame
    return part
end

local function applyShift()
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if shiftLock then
        local part = createShiftPart()
        if part then
            _G.ShiftPart = part
            -- Point camera at the invisible part (native camera keeps control)
            cam.CameraSubject = part
            -- Also offset the humanoid so the character body appears offset
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end
        shiftBtn.Text = "🔒"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    else
        if _G.ShiftPart then
            pcall(function() _G.ShiftPart:Destroy() end)
            _G.ShiftPart = nil
        end
        cam.CameraSubject = hum
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

-- ===== MOVEMENT =====
RS.RenderStepped:Connect(function()
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Update shift part position each frame (this is what makes it stick)
    if shiftLock and _G.ShiftPart then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Position the part so camera looks from side: offset to the right of character
            local offset = cam.CFrame.RightVector * -1.5
            _G.ShiftPart.CFrame = CFrame.new(root.Position + offset, root.Position + offset + cam.CFrame.LookVector)
        end
    end

    if not wasdOn then return end

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

-- ===== HIDE DEFAULT MOBILE CONTROLS =====
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

plr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if shiftLock then applyShift() end
end)
