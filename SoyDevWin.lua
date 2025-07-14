--==============================================================
--  Steal A Brainrot • Mobile v23 •  by SoyDevWin + Assist
--==============================================================
--  • UI 240×270, texto LuckiestGuy
--  • ProximityPrompt: cooldown zerado a cada 0.25 s (leve)
--  • Float / Glide / Speed reativam após morte
--  • Botões flutuantes compactos, ativam/desativam certo
--==============================================================

-------------------- SERVIÇOS / JOGADOR ------------------------
local PS, UIS, RS, TS = game:GetService("Players"), game:GetService("UserInputService"),
                        game:GetService("RunService"), game:GetService("TweenService")
local plr = PS.LocalPlayer

--------------------------- ESTADO ----------------------------
local char, hum, root
local originalJump, speedValue = 50, 16
local FLOAT_OFFSET, FLOAT_STEP, FALL_TOL = 55, 5, 4
local SPEED_MIN, SPEED_MAX = 16, 200
local PLATFORM_SIZE, PLATFORM_H = 120, 6

local floatPart, floatFollow, glideHB, speedHB
local states = { Float={spawned=false,active=false},
                 Glide={spawned=false,active=false},
                 Speed={spawned=false,active=false} }
local btnPos = {}

------------------ PROXIMITYPROMPT COOLDOWN -------------------
task.spawn(function()
    while true do
        for _,p in pairs(workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                p.Enabled = true
                p.HoldDuration, p.Cooldown = 0, 0
            end
        end
        task.wait(0.25)
    end
end)

---------------------- UTILIDADES -----------------------------
local function applyFont(o)
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.FontFace = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
    end
    for _,c in ipairs(o:GetChildren()) do applyFont(c) end
end
local function tween(o,g,t) TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),g):Play() end
local function makeDrag(f,h,name)
    local drag,start,pos
    h.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag,start,pos=true,i.Position,f.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false; btnPos[name]=f.Position end end)
        end
    end)
    h.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-start
            f.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
        end
    end)
end
local function organize()
    local list={}
    for n,s in pairs(states) do if s.spawned and s.btn and s.btn.Visible then table.insert(list,s.btn) end end
    table.sort(list,function(a,b) return a.Text<b.Text end)
    for i,b in ipairs(list) do
        if not btnPos[b.Name] then
            b.Position=UDim2.new(1,-b.Size.X.Offset-10,0,100+(i-1)*36)
        end
    end
end

--------------------- FUNÇÕES PRINCIPAIS ----------------------
local function enableFloat()
    if floatPart then return end
    floatPart=Instance.new("Part",workspace)
    floatPart.Size=Vector3.new(PLATFORM_SIZE,PLATFORM_H,PLATFORM_SIZE)
    floatPart.Anchored,floatPart.CanCollide,floatPart.Transparency=true,true,1
    floatPart.Position=root.Position+Vector3.new(0,FLOAT_OFFSET,0)
    local function ascend()
        while states.Float.active and root.Position.Y<floatPart.Position.Y-0.5 do
            root.CFrame+=Vector3.new(0,FLOAT_STEP,0) task.wait()
        end
    end
    ascend()
    floatFollow=RS.Heartbeat:Connect(function()
        if not states.Float.active then return end
        floatPart.Position=Vector3.new(root.Position.X,floatPart.Position.Y,root.Position.Z)
        if root.Position.Y<floatPart.Position.Y-FALL_TOL then ascend() end
    end)
end
local function disableFloat()
    if floatFollow then floatFollow:Disconnect() end
    if floatPart then floatPart:Destroy() floatPart=nil end
end

local function updateGlide()
    if states.Glide.active then
        hum.UseJumpPower=true hum.JumpPower=originalJump*1.25
        if glideHB then glideHB:Disconnect() end
        glideHB=RS.Heartbeat:Connect(function()
            if root.Velocity.Y<-10 then
                root.Velocity=Vector3.new(root.Velocity.X,-10,root.Velocity.Z)
            end
        end)
    else
        hum.JumpPower=originalJump
        if glideHB then glideHB:Disconnect() glideHB=nil end
    end
end
local function updateSpeed()
    if speedHB then speedHB:Disconnect() end
    if states.Speed.active then
        speedHB=RS.Heartbeat:Connect(function()
            hum.WalkSpeed=speedValue
            local d=hum.MoveDirection
            if d.Magnitude>0 then
                root.Velocity=Vector3.new(d.X*speedValue,root.Velocity.Y,d.Z*speedValue)
            end
        end)
    else hum.WalkSpeed=16 end
end

----------------------------- UI ------------------------------
local gui=Instance.new("ScreenGui",plr.PlayerGui)
gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local main=Instance.new("Frame",gui)
main.Size,main.Position=UDim2.new(0,240,0,270),UDim2.new(0.5,-120,0.5,-135)
main.BackgroundColor3=Color3.fromRGB(20,20,20) main.ClipsDescendants=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,4)

local top=Instance.new("Frame",main) top.Size=UDim2.new(1,0,0,34) top.BackgroundColor3=Color3.fromRGB(25,25,25)
Instance.new("UICorner",top).CornerRadius=UDim.new(0,4)

local title=Instance.new("TextLabel",top)
title.Size, title.Position=UDim2.new(1,-60,1,0),UDim2.new(0,8,0,0)
title.BackgroundTransparency=1 title.TextXAlignment=Enum.TextXAlignment.Left
title.TextSize=18 title.Text="STEAL A BRAINROT" title.TextColor3=Color3.fromRGB(235,235,235)

local mini=Instance.new("TextButton",top)
mini.Size,mini.Position=UDim2.new(0,26,0,26),UDim2.new(1,-32,0,4)
mini.BackgroundTransparency=1 mini.TextScaled=true mini.TextColor3=Color3.fromRGB(235,235,235) mini.Text="˅"

makeDrag(main,top,"Main")

local content=Instance.new("Frame",main)
content.Size,content.Position=UDim2.new(1,-16,1,-70),UDim2.new(0,8,0,40)
content.BackgroundTransparency=1
local listLayout=Instance.new("UIListLayout",content) listLayout.Padding=UDim.new(0,4)

local speedFrame=Instance.new("Frame",content)
speedFrame.Size=UDim2.new(1,0,0,32) speedFrame.BackgroundColor3=Color3.fromRGB(30,30,30)
Instance.new("UICorner",speedFrame).CornerRadius=UDim.new(0,4)

local speedBox=Instance.new("TextBox",speedFrame)
speedBox.Size, speedBox.Position=UDim2.new(1,-20,1,0),UDim2.new(0,10,0,0)
speedBox.BackgroundTransparency=1 speedBox.TextColor3=Color3.fromRGB(200,200,200) speedBox.TextSize=16
speedBox.ClearTextOnFocus=false speedBox.Text=tostring(speedValue) speedBox.TextXAlignment=Enum.TextXAlignment.Left
speedBox.FocusLost:Connect(function()
    local v=tonumber(speedBox.Text)
    if v then speedValue=math.clamp(math.floor(v+0.5),SPEED_MIN,SPEED_MAX) end
    speedBox.Text=tostring(speedValue) if states.Speed.active then updateSpeed() end
end)

local sign=Instance.new("TextLabel",main)
sign.Size,sign.Position=UDim2.new(1,-16,0,18),UDim2.new(0,8,1,-22)
sign.BackgroundTransparency=1 sign.TextXAlignment=Enum.TextXAlignment.Left
sign.TextSize=14 sign.TextColor3=Color3.fromRGB(130,130,130) sign.Text="SoyDevWin"

------------------- CRIAÇÃO DOS BOTÕES ------------------------
local function makeSpawner(name,funcToggle)
    local btn=Instance.new("TextButton",content)
    btn.Size=UDim2.new(1,0,0,30) btn.BackgroundColor3=Color3.fromRGB(30,30,30)
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    btn.TextColor3=Color3.fromRGB(200,200,200) btn.TextSize=16 btn.AutoButtonColor=false
    btn.Text=name..": OFF"

    btn.MouseButton1Click:Connect(function()
        local s=states[name]
        s.spawned=not s.spawned btn.Text=name..(s.spawned and ": ON" or ": OFF")
        if s.spawned then
            local f=Instance.new("TextButton",gui) s.btn=f f.Name=name
            f.Size=UDim2.new(0,80,0,28) f.Position=btnPos[name] or UDim2.new(1,-f.Size.X.Offset-10,0,100)
            f.BackgroundColor3=Color3.fromRGB(35,35,35) f.ZIndex=3
            Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
            f.TextColor3=Color3.fromRGB(200,200,200) f.TextSize=14 f.AutoButtonColor=false
            f.Text=name..": OFF"
            makeDrag(f,f,name)

            local function ref()
                f.Text=name..": "..(s.active and "ON" or "OFF")
                f.BackgroundColor3=s.active and Color3.fromRGB(60,100,60) or Color3.fromRGB(35,35,35)
            end
            f.MouseButton1Click:Connect(function()
                s.active=not s.active funcToggle(s.active) ref()
            end)
            applyFont(f) ref() organize()
        else
            if s.btn then btnPos[name]=s.btn.Position s.btn:Destroy() end
            if s.active then funcToggle(false) end s.active=false
        end
    end)
end

makeSpawner("Float",function(on) states.Float.active=on if on then enableFloat() else disableFloat() end end)
makeSpawner("Glide",function(on) states.Glide.active=on updateGlide() end)
makeSpawner("Speed",function(on) states.Speed.active=on updateSpeed() end)

---------------- MINIMIZAR / EXPANDIR -------------------------
local collapsed,minimized=false
mini.MouseButton1Click:Connect(function()
    minimized=not minimized
    if minimized then
        tween(main,{Size=UDim2.new(0,240,0,40)},0.25)
        content.Visible=false sign.Visible=false mini.Text="˄"
    else
        tween(main,{Size=UDim2.new(0,240,0,270)},0.25)
        content.Visible=true sign.Visible=true mini.Text="˅" organize()
    end
end)

--------------------- SHOW / HIDE -----------------------------
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        gui.Enabled=not gui.Enabled
        for _,s in pairs(states) do if s.btn then s.btn.Visible=gui.Enabled end end
        if gui.Enabled then organize() end
    end
end)

------------------ SUPORTE A RESPAWN --------------------------
local function onChar(c)
    char=c hum=char:WaitForChild("Humanoid") root=char:WaitForChild("HumanoidRootPart")
    originalJump=hum.JumpPower
    if states.Float.active then disableFloat() enableFloat() end
    updateGlide() updateSpeed()
end
onChar(plr.Character or plr.CharacterAdded:Wait()) plr.CharacterAdded:Connect(onChar)

----------------- FONTES (aplicar geral) ----------------------
task.defer(function() applyFont(gui) end)
