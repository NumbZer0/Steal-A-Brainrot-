--==============================================================
--  Steal A Brainrot • Mobile v21  •  by SoyDevWin + Assistente
--==============================================================
--  Ajustes robustos para cooldown de ProximityPrompt (mobile)
--  Speed boost forçado, Float/Glide ajustados, botões flutuantes
--==============================================================

-------------------- SERVIÇOS / JOGADOR ------------------------
local P  = game:GetService("Players")
local UIS= game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

local plr   = P.LocalPlayer
local char  = plr.Character or plr.CharacterAdded:Wait()
local hum   = char:WaitForChild("Humanoid")
local root  = char:WaitForChild("HumanoidRootPart")

------------------- PARÂMETROS E ESTADO -----------------------
local FLOAT_OFFSET   = 55
local FLOAT_STEP     = 5
local FALL_TOLERANCE = 4
local SPEED_MIN, SPEED_MAX = 16, 200
local PLATFORM_SIZE  = 120
local PLATFORM_HEIGHT = 6

local originalJump   = hum.JumpPower
local speedValue     = hum.WalkSpeed

local floatPart, floatFollow
local glideHeartbeat
local speedCoroutine

local states = {
    Float = {spawned = false, active = false, btn = nil},
    Glide = {spawned = false, active = false, btn = nil},
    Speed = {spawned = false, active = false, btn = nil},
}

local btnPositions = {}

-------------------- PROXIMITYPROMPT COOLDOWN -----------------
local monitoredPrompts = {}

local function optimizePromptCooldown(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    pcall(function() prompt.Cooldown = 0 end)
    pcall(function() prompt.HoldDuration = 0 end)
    prompt.Enabled = true
end

local function cooldownMonitor()
    RS.Heartbeat:Connect(function()
        for _, prompt in pairs(monitoredPrompts) do
            if prompt and prompt.Parent and prompt.Enabled then
                if prompt.HoldDuration > 0 then
                    pcall(function()
                        prompt.Cooldown = 0
                        prompt.HoldDuration = 0
                    end)
                end
            end
        end
    end)
end

local function trackPrompt(prompt)
    if monitoredPrompts[prompt] then return end
    monitoredPrompts[prompt] = prompt
    optimizePromptCooldown(prompt)
end

local function untrackPrompt(prompt)
    monitoredPrompts[prompt] = nil
end

local function initPromptMonitor()
    for _, p in pairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then trackPrompt(p) end
    end
    workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("ProximityPrompt") then
            trackPrompt(desc)
            desc.AncestryChanged:Connect(function(child, parent)
                if not parent then untrackPrompt(child) end
            end)
        end
    end)
    cooldownMonitor()
end

-------------------- FUNÇÕES DE UTILIDADE ---------------------
local function applyFont(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        obj.FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
    end
    for _,c in ipairs(obj:GetChildren()) do applyFont(c) end
end

local function tween(obj, goal, t)
    TS:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function makeDraggable(frame, handle, name)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    btnPositions[name] = frame.Position
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local function organizeFloatingButtons()
    local buttons = {}
    for _, st in pairs(states) do
        if st.spawned and st.btn and st.btn.Visible then table.insert(buttons, st.btn) end
    end
    table.sort(buttons, function(a,b) return a.Text < b.Text end)
    local baseY, spacing = 100, 40
    for i, b in ipairs(buttons) do
        local name
        for k,v in pairs(states) do if v.btn==b then name=k break end end
        local saved = btnPositions[name]
        if saved then
            b.Position = saved
        else
            b.Position = UDim2.new(1, -b.Size.X.Offset-10, 0, baseY+(i-1)*spacing)
        end
    end
end

---------------------- FUNÇÕES PRINCIPAIS ---------------------
local function enableFloat()
    if floatPart then return end
    floatPart = Instance.new("Part", workspace)
    floatPart.Size = Vector3.new(PLATFORM_SIZE, PLATFORM_HEIGHT, PLATFORM_SIZE)
    floatPart.Anchored, floatPart.CanCollide, floatPart.Transparency = true, true, 1
    floatPart.Position = root.Position + Vector3.new(0, FLOAT_OFFSET, 0)
    local function ascend()
        while states.Float.active and root.Position.Y < floatPart.Position.Y-0.5 do
            root.CFrame += Vector3.new(0, FLOAT_STEP, 0)
            task.wait()
        end
    end
    ascend()
    floatFollow = RS.Heartbeat:Connect(function()
        if not states.Float.active then return end
        floatPart.Position = Vector3.new(root.Position.X, floatPart.Position.Y, root.Position.Z)
        if root.Position.Y < floatPart.Position.Y - FALL_TOLERANCE then ascend() end
    end)
end
local function disableFloat()
    if floatFollow then floatFollow:Disconnect() end
    if floatPart then floatPart:Destroy(); floatPart=nil end
end

local function updateGlide()
    if states.Glide.active then
        hum.UseJumpPower=true
        hum.JumpPower=originalJump*1.3
        if glideHeartbeat then glideHeartbeat:Disconnect() end
        glideHeartbeat = RS.Heartbeat:Connect(function()
            if not states.Glide.active then return end
            if root.Velocity.Y<-10 then
                root.Velocity=Vector3.new(root.Velocity.X,-10,root.Velocity.Z)
            end
        end)
    else
        hum.JumpPower=originalJump
        if glideHeartbeat then glideHeartbeat:Disconnect(); glideHeartbeat=nil end
    end
end

local function updateSpeed()
    if speedCoroutine then speedCoroutine:Disconnect(); speedCoroutine=nil end
    if states.Speed.active then
        speedCoroutine = RS.Heartbeat:Connect(function()
            hum.WalkSpeed=speedValue
            local dir=hum.MoveDirection
            if dir.Magnitude>0 then
                root.Velocity=Vector3.new(dir.X*speedValue,root.Velocity.Y,dir.Z*speedValue)
            end
        end)
    else
        hum.WalkSpeed=16
    end
end

----------------------------------------------------------------
--  UI PRINCIPAL
----------------------------------------------------------------
local gui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "BrainrotGUI", false, Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame", gui)
main.Size, main.Position = UDim2.new(0,310,0,380), UDim2.new(0.5,-155,0.5,-190)
main.BackgroundColor3, main.ClipsDescendants = Color3.fromRGB(20,20,20), true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,4)

local top = Instance.new("Frame", main)
top.Size, top.BackgroundColor3 = UDim2.new(1,0,0,36), Color3.fromRGB(25,25,25)
Instance.new("UICorner", top).CornerRadius = UDim.new(0,4)

local title = Instance.new("TextLabel", top)
title.Size, title.Position = UDim2.new(1,-60,1,0), UDim2.new(0,10,0,0)
title.BackgroundTransparency, title.TextXAlignment, title.TextSize = 1, Enum.TextXAlignment.Left, 20
title.Text, title.TextColor3 = "STEAL A BRAINROT", Color3.fromRGB(235,235,235)

local mini = Instance.new("TextButton", top)
mini.Size, mini.Position = UDim2.new(0,28,0,28), UDim2.new(1,-34,0,4)
mini.BackgroundTransparency, mini.TextScaled, mini.TextColor3 = 1, true, Color3.fromRGB(235,235,235)
mini.Text = "˅"

makeDraggable(main, top)

local content = Instance.new("Frame", main)
content.Size, content.Position, content.BackgroundTransparency = UDim2.new(1,-16,1,-80), UDim2.new(0,8,0,44), 1
Instance.new("UIListLayout", content).Padding = UDim.new(0,6)

local speedFrame = Instance.new("Frame", content)
speedFrame.Size, speedFrame.BackgroundColor3 = UDim2.new(1,0,0,40), Color3.fromRGB(30,30,30)
Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0,4)

local speedBox = Instance.new("TextBox", speedFrame)
speedBox.Size, speedBox.Position = UDim2.new(1,-20,1,0), UDim2.new(0,10,0,0)
speedBox.BackgroundTransparency, speedBox.TextColor3, speedBox.TextSize = 1, Color3.fromRGB(200,200,200), 18
speedBox.ClearTextOnFocus=false
speedBox.Text=tostring(speedValue)
speedBox.TextXAlignment=Enum.TextXAlignment.Left
speedBox.FocusLost:Connect(function()
    local v=tonumber(speedBox.Text)
    if v then speedValue=math.clamp(math.floor(v+0.5),SPEED_MIN,SPEED_MAX) end
    speedBox.Text=tostring(speedValue)
    if states.Speed.active then updateSpeed() end
end)

local sign = Instance.new("TextLabel", main)
sign.Size, sign.Position = UDim2.new(1,-16,0,20), UDim2.new(0,8,1,-24)
sign.BackgroundTransparency, sign.TextXAlignment, sign.TextSize = 1, Enum.TextXAlignment.Left, 16
sign.TextColor3, sign.Text = Color3.fromRGB(130,130,130), "SoyDevWin"

local function newSpawner(name)
    local btn = Instance.new("TextButton", content)
    btn.Size, btn.BackgroundColor3 = UDim2.new(1,0,0,34), Color3.fromRGB(30,30,30)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.TextColor3, btn.TextSize, btn.AutoButtonColor = Color3.fromRGB(200,200,200), 18, false
    btn.Text = name..": OFF"

    btn.MouseButton1Click:Connect(function()
        local st=states[name]
        st.spawned=not st.spawned
        btn.Text=name..(st.spawned and ": ON" or ": OFF")
        if st.spawned then
            if st.btn then st.btn:Destroy() end
            local f=Instance.new("TextButton",gui) st.btn=f
            f.ZIndex=3 f.Size=UDim2.new(0,90,0,32)
            f.Position=btnPositions[name] or UDim2.new(1,-f.Size.X.Offset-10,0,100)
            f.BackgroundColor3=Color3.fromRGB(35,35,35)
            Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
            f.TextColor3,f.TextSize,f.AutoButtonColor=Color3.fromRGB(200,200,200),16,false
            f.Text=name..": OFF"
            makeDraggable(f,f,name)
            local function refresh()
                f.Text=name..": "..(st.active and "ON" or "OFF")
                f.BackgroundColor3=st.active and Color3.fromRGB(60,100,60) or Color3.fromRGB(35,35,35)
            end
            f.MouseButton1Click:Connect(function()
                st.active=not st.active
                if name=="Float" then if st.active then enableFloat() else disableFloat() end
                elseif name=="Glide" then updateGlide()
                elseif name=="Speed" then updateSpeed() end
                refresh() organizeFloatingButtons()
            end)
            applyFont(f) refresh() organizeFloatingButtons()
        else
            if st.btn then btnPositions[name]=st.btn.Position; st.btn:Destroy() end
            if st.active then
                if name=="Float" then disableFloat()
                elseif name=="Glide" then st.active=false updateGlide()
                elseif name=="Speed" then st.active=false updateSpeed() end
            end
            st.active=false
        end
    end)
end

newSpawner("Float") newSpawner("Glide") newSpawner("Speed")

-------------------- MINIMIZAR / EXPANDIR ----------------------
local collapsedH,minimized,savedH=44,false,main.Size.Y.Offset
mini.MouseButton1Click:Connect(function()
    minimized=not minimized
    if minimized then
        savedH=main.Size.Y.Offset
        tween(main,{Size=UDim2.new(main.Size.X.Scale,main.Size.X.Offset,0,collapsedH)},0.25)
        content.Visible,sign.Visible=false,false
        mini.Text="˄"
    else
        tween(main,{Size=UDim2.new(main.Size.X.Scale,main.Size.X.Offset,0,savedH)},0.25)
        content.Visible,sign.Visible=true,true
        mini.Text="˅"
        organizeFloatingButtons()
    end
end)

---------------------- FONTES & DRAG GLOBAL --------------------
applyFont(gui)

-------------------------- TECLA HIDE --------------------------
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        gui.Enabled=not gui.Enabled
        for _,st in pairs(states) do if st.btn then st.btn.Visible=gui.Enabled end end
        if gui.Enabled then organizeFloatingButtons() end
    end
end)

------------------ INICIAR REMOÇÃO COOLDOWN -------------------
initPromptMonitor()
