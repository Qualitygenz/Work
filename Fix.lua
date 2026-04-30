Wait(50)
local Plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local FARM_ID, SELL_ID, THRESHOLD = 125804922932357, 3475397644, 10000
local autoFarm, flySpeed, atkDelay, scanRange = true, 500, 0.3, 500
local Char, HRP, noclip, noclipConn, patrolIdx = nil, nil, true, nil, 1
local lastAction = tick()

local ZONES = {
    {Vector3.new(26.37,86.24,-736.17),50},{Vector3.new(-320.14,88.55,-752.41),50},
    {Vector3.new(1003.19,308.42,741.01),50},{Vector3.new(1116.72,203.58,881.11),50},
    {Vector3.new(-732.75,864.96,-5321.73),50},{Vector3.new(-394.25,867.27,-5312.38),50}
}
local ITEMS = {"KajiFruitFoodModel","EdamameFoodModel","MistSudachiFoodModel"}
local PATROL = {
    Vector3.new(708.29,165.48,-1155.59),Vector3.new(-412.85,252.78,-2253.70),
    Vector3.new(-1107.51,577.25,-2148.79),Vector3.new(367.51,614.04,-4454.05),
    Vector3.new(-1982.75,353.56,-2168.84),Vector3.new(1330.99,862.28,-4467.93),
    Vector3.new(-2936.17,633.47,-2983.53),Vector3.new(2031.51,551.79,-3348.65)
}

local function inZone(p)
    for _,z in ipairs(ZONES) do if (p-z[1]).Magnitude<=z[2] then return true end end
    return false
end
local function touch(p1,p2) if firetouchinterest then firetouchinterest(p1,p2,0) task.wait() firetouchinterest(p1,p2,1) end end
local function updAction() lastAction=tick() end

local function enableNC()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = Run.Stepped:Connect(function()
        if not noclip or not Char then return end
        for _,p in pairs(Char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end
local function disableNC()
    if noclipConn then noclipConn:Disconnect() noclipConn=nil end
    if Char then for _,p in pairs(Char:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end
end

local bindChar
bindChar = function(c)
    Char,HRP = c, c:WaitForChild("HumanoidRootPart",10)
    task.wait(2) if noclip then enableNC() end
    task.spawn(function() task.wait(1) pcall(function()
        local folder=workspace.Characters:FindFirstChild(Plr.Name)
        local drg=folder and folder.Dragons:GetChildren()[1]
        if not drg then return end
        if drg.Data:FindFirstChild("Dead") and drg.Data.Dead.Value then
            pcall(function() RS.Remotes.ReviveDragonRemote:InvokeServer(drg.Name,"DragonRevivalHeart") end)
        end
        local hum=Char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.SeatPart then local s=drg:FindFirstChildWhichIsA("Seat",true) if s then s:Sit(hum) end end
    end) end)
end
if Plr.Character then bindChar(Plr.Character) end
Plr.CharacterAdded:Connect(bindChar)
task.spawn(function() task.wait(1) enableNC() end)

UIS.InputBegan:Connect(function(i,gp)
    if gp or i.KeyCode~=Enum.KeyCode.N then return end
    noclip=not noclip if noclip then enableNC() else disableNC() end
end)

-- Anti-AFK
local VU = game:GetService("VirtualUser")
Plr.Idled:Connect(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) updAction() end)
task.spawn(function()
    while true do task.wait(math.random(300,600))
        if Char and HRP then HRP.CFrame*=CFrame.new(math.random(-2,2),0,math.random(-2,2)) updAction() end
    end
end)

-- GUI
if game.CoreGui:FindFirstChild("FarmGUI") then game.CoreGui.FarmGUI:Destroy() end
local gui = Instance.new("ScreenGui",game.CoreGui) gui.Name="FarmGUI" gui.ResetOnSpawn=false
local coin = Instance.new("TextLabel",gui)
coin.Size=UDim2.new(0,250,0,60) coin.Position=UDim2.new(0.5,-125,0.05,0)
coin.BackgroundColor3=Color3.fromRGB(20,20,20) coin.TextColor3=Color3.fromRGB(255,223,0)
coin.Font=Enum.Font.GothamBold coin.Text="Loading..." Instance.new("UICorner",coin).CornerRadius=UDim.new(0,12)
local frame=Instance.new("Frame",gui) frame.Size=UDim2.new(0,280,0,150) frame.Position=UDim2.new(0.5,-140,0.15,0)
frame.BackgroundColor3=Color3.fromRGB(20,20,20) Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
for i,r in ipairs({{n="KajiFruit",c=Color3.fromRGB(139,90,43)},{n="Edamame",c=Color3.fromRGB(200,200,200)},{n="MistSudachi",c=Color3.fromRGB(100,200,255)}}) do
    local l=Instance.new("TextLabel",frame) l.Name=r.n.."Label" l.Size=UDim2.new(1,-20,0,40)
    l.Position=UDim2.new(0,10,0,(i-1)*45+10) l.BackgroundTransparency=1 l.TextColor3=r.c l.Font=Enum.Font.GothamBold l.Text=r.n..": Loading"
end
task.spawn(function()
    local d=Plr:WaitForChild("Data"):WaitForChild("Currency"):WaitForChild("Coins")
    while task.wait(0.5) do coin.Text="Coins: "..tostring(d.Value) end
end)

-- Sell
local function sellAll()
    task.wait(3)
    for _,n in ipairs({"KajiFruit","Edamame","MistSudachi"}) do
        local v=Plr.Data.Resources:FindFirstChild(n)
        if v and v.Value>0 then pcall(function() RS.Remotes.SellItemRemote:FireServer({ItemName=n,Amount=v.Value}) end) task.wait(2) end
    end
end
local function shouldSell()
    local r=Plr.Data.Resources
    return r.KajiFruit.Value>=THRESHOLD or r.Edamame.Value>=THRESHOLD or r.MistSudachi.Value>=THRESHOLD
end
local function teleport(id) pcall(function() RS.Remotes.WorldTeleportRemote:InvokeServer(id,{}) end) end

task.spawn(function()
    while autoFarm do task.wait(2)
        if game.PlaceId==FARM_ID then if shouldSell() then teleport(SELL_ID) task.wait(10) end
        elseif game.PlaceId==SELL_ID then sellAll() teleport(FARM_ID) task.wait(10)
        else teleport(FARM_ID) task.wait(10) end
    end
end)

-- Farm
local function flyTo(t,sp)
    sp=sp or flySpeed updAction()
    local st=tick() local maxT=(t-HRP.Position).Magnitude/sp+5 local conn
    conn=Run.Heartbeat:Connect(function(dt)
        if not HRP or (t-HRP.Position).Magnitude<=8 or tick()-st>maxT then if conn then conn:Disconnect() conn=nil end return end
        HRP.CFrame=CFrame.lookAt(HRP.Position+(t-HRP.Position).Unit*sp*dt,t) HRP.Velocity=Vector3.zero
    end)
    repeat task.wait() until not conn
end
local function collectItems()
    updAction()
    for _=1,10 do
        local found={}
        for _,o in pairs(workspace:GetChildren()) do
            if table.find(ITEMS,o.Name) then
                local p=o:IsA("BasePart") and o.Position or (o:IsA("Model") and o.PrimaryPart and o.PrimaryPart.Position)
                if p and (p-HRP.Position).Magnitude<=scanRange then table.insert(found,{i=o,p=p}) end
            end
        end
        if #found==0 then break end
        for _,it in ipairs(found) do if it.i.Parent then local h=it.i:FindFirstChild("Handle") if h then touch(h,HRP) end task.wait(0.1) end end
        task.wait(0.5)
    end
end
local function getMountedDragon()
    local drgs=Char:FindFirstChild("Dragons") if not drgs then return nil end
    for _,d in pairs(drgs:GetChildren()) do
        local s=d:FindFirstChildWhichIsA("VehicleSeat") or d:FindFirstChild("Seat")
        if s and s.Occupant and s.Occupant.Parent==Char then return d end
    end
end
local function findNode()
    local n=workspace:FindFirstChild("Interactions") and workspace.Interactions.Nodes.Food:FindFirstChild("LargeFoodNode")
    local b=n and n:FindFirstChild("BillboardPart")
    if b and b.Health.Value>0 and not inZone(b.Position) and b.Position.Y>=50 then return b end
end

task.spawn(function()
    while autoFarm do
        if not Char or not HRP or game.PlaceId~=FARM_ID then task.wait(2) continue end
        local drg=getMountedDragon()
        if drg then
            local node=findNode()
            if node then
                flyTo(node.Position+Vector3.new(0,15,0))
                while node and node.Health.Value>0 and autoFarm do
                    if drg:FindFirstChild("Remotes") then pcall(function() drg.Remotes.BreathFireRemote:FireServer() end) end
                    task.wait(atkDelay)
                end
                task.wait(1) collectItems()
            else
                local p=PATROL[patrolIdx]
                if not inZone(p) then flyTo(p,flySpeed+20) end
                patrolIdx=patrolIdx%#PATROL+1 task.wait(2)
            end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do task.wait(1) pcall(function()
        if not Char then return end
        local folder=workspace.Characters:FindFirstChild(Plr.Name)
        local drg=folder and folder.Dragons:GetChildren()[1] if not drg then return end
        if drg.Data:FindFirstChild("Dead") and drg.Data.Dead.Value then
            pcall(function() RS.Remotes.ReviveDragonRemote:InvokeServer(drg.Name,"DragonRevivalHeart") end)
        end
        local hum=Char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.SeatPart then local s=drg:FindFirstChildWhichIsA("Seat",true) if s then s:Sit(hum) end end
    end) end
end)
