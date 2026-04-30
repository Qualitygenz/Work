wait(10)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local FARM_WORLD = 125804922932357
local SELL_WORLD = 3475397644


local SELL_THRESHOLD = 10000
local autoFarm = true
local flySpeed = 500
local attackDelay = 0.3
local scanRange = 500


local Character, HRP
local noclipEnabled = true
local noclipConnection = nil
local antiAFKEnabled = true
local lastActionTime = tick()
local currentPatrolIndex = 1

local NO_GO_ZONES = {
    {position = Vector3.new(26.3707275, 86.2353973, -736.170044, -0.69808054, 0, 0.716019273, 0, 1, 0, -0.716019273, 0, -0.69808054), radius = 50},
    {position = Vector3.new(-320.14, 88.55, -752.41), radius = 50},
    {position = Vector3.new(1003.19, 308.42, 741.01), radius = 50},
    {position = Vector3.new(1116.72, 203.58, 881.11), radius = 50},
    {position = Vector3.new(-732.75, 864.96, -5321.73), radius = 50},
    {position = Vector3.new(-394.25, 867.27, -5312.38), radius = 50},
}

local itemNames = {
    "KajiFruitFoodModel",
    "EdamameFoodModel", 
    "MistSudachiFoodModel"
}

local checkPositions = {
    Vector3.new(708.289062, 165.476547, -1155.58789, 0.983557045, 0.177314237, 0.0342812724, -0.174947545, 0.982572258, -0.0628090799, -0.0448207743, 0.0557789095, 0.997436464), Vector3.new(-412.850861, 252.776505, -2253.69556, 0.988837421, -0.148353025, 0.0138552776, 0.147153005, 0.986948133, 0.0654163957, -0.0233791582, -0.0626473278, 0.997761846),
    Vector3.new(-1107.5144, 577.245056, -2148.78809, 0.954774439, -0.0488559455, 0.2932899, 0.0515211858, 0.998670995, -0.0013641715, -0.292833507, 0.0164131373, 0.956022561), Vector3.new(367.50528, 614.041138, -4454.04883, 0.200963706, -0.849176347, -0.488377899, -4.1749754e-05, 0.498541594, -0.866865754, 0.979598701, 0.174228951, 0.100153312),
    Vector3.new(-1982.74744, 353.561249, -2168.83911, 0.0341024883, -0.100861162, 0.994315803, 0.0907793269, 0.99109441, 0.0974208713, -0.995286942, 0.0869410262, 0.0429548919), Vector3.new(1330.99109, 862.276917, -4467.93066, -0.284373581, -0.748941362, -0.598513544, -6.60658316e-06, 0.624289691, -0.781192899, 0.958713531, -0.22214666, -0.177536458),
    Vector3.new(-2936.16797, 633.46875, -2983.52734, 0.871456802, 0.0833023414, 0.483346462, 0.0367715023, 0.971601486, -0.233748347, -0.489092022, 0.221474946, 0.843645513), Vector3.new(2031.51306, 551.792542, -3348.64697, -0.973408461, 0.202880397, 0.106374398, 8.05187447e-05, 0.464665174, -0.885486484, -0.229076326, -0.861931443, -0.452325314),
    Vector3.new(-2567.99438, 729.241882, -4164.08154, -0.439318269, 0.70176965, 0.560819566, 1.63359964e-05, 0.624296606, -0.781187475, -0.898331463, -0.343180746, -0.274276316), Vector3.new(1816.99426, 201.543259, -2664.78979, -0.995684803, -0.0780355036, -0.0502226539, 2.93890043e-05, 0.540926695, -0.841069639, 0.0928000733, -0.837441683, -0.538590193),
    Vector3.new(-871.345459, 729.648499, -4265.88428, -0.996277034, -0.0673479885, -0.0538170971, -3.22684923e-06, 0.624290526, -0.781192243, 0.0862092301, -0.778283715, -0.621966541), Vector3.new(2054.2915, 637.171509, -2390.35693, -0.956742585, 0.227606624, 0.181214899, 3.88344642e-06, 0.622879088, -0.782318115, -0.290935755, -0.748476326, -0.595935881),
}


function safeFireSignal(signal)
    if typeof(signal) == "RBXScriptSignal" and firesignal then
        firesignal(signal)
        return true
    end
    return false
end

function safeFireTouch(part1, part2)
    if firetouchinterest then
        firetouchinterest(part1, part2, 0)
        task.wait()
        firetouchinterest(part1, part2, 1)
        return true
    end
    return false
end

function updateLastAction()
    lastActionTime = tick()
end

function isInNoGoZone(pos)
    for _, zone in ipairs(NO_GO_ZONES) do
        local dist = (pos - zone.position).Magnitude
        if dist <= zone.radius then
            return true, zone
        end
    end
    return false, nil
end


local bindCharacter
local enableNoclip
local disableNoclip
local ensureMountedDragon

enableNoclip = function()
    if noclipConnection then 
        noclipConnection:Disconnect()
    end
    
    print(" เปิดใช้งาน Noclip")
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled or not Character then return end
        
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

disableNoclip = function()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

bindCharacter = function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart", 10)
    
    print("🔄 Rebind Character สำเร็จ:", char.Name)
    
    task.wait(2)
    
    if noclipEnabled then
        enableNoclip()
    end
    
    task.spawn(function()
        task.wait(1)
        if ensureMountedDragon then
            pcall(ensureMountedDragon)
        end
    end)
    
    print("✅ ระบบทั้งหมด Rebind เสร็จ - พร้อมทำงานต่อ!")
end

if Player.Character then
    bindCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    print("🆕 ตรวจพบตัวละครใหม่ - กำลัง Rebind...")
    bindCharacter(char)
end)

task.spawn(function()
    task.wait(1)
    enableNoclip()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.N then
        noclipEnabled = not noclipEnabled
        if noclipEnabled then
            enableNoclip()
        else
            disableNoclip()
        end
        print("👻 Noclip: " .. (noclipEnabled and "เปิด ✅" or "ปิด ❌"))
    end
end)


function setupAntiAFK()
    print("🛡️ เปิดใช้งานระบบ Anti-AFK")
    
    local VirtualUser = game:GetService("VirtualUser")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    Player.Idled:Connect(function()
        if antiAFKEnabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            updateLastAction()
        end
    end)
    
    task.spawn(function()
        while antiAFKEnabled do
            task.wait(math.random(300, 600))
            
            if antiAFKEnabled and Character then
                local hrp = Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local randomOffset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                    hrp.CFrame = hrp.CFrame + randomOffset
                    updateLastAction()
                end
            end
        end
    end)
    
    task.spawn(function()
        while antiAFKEnabled do
            task.wait(math.random(180, 420))
            
            if antiAFKEnabled then
                local keys = {Enum.KeyCode.W, Enum.KeyCode.Space}
                local randomKey = keys[math.random(1, #keys)]
                
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
                end)
                
                updateLastAction()
            end
        end
    end)
end

function createGUI()
    if game.CoreGui:FindFirstChild("FarmGUI") then
        game.CoreGui.FarmGUI:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = game.CoreGui
    
    local coinLabel = Instance.new("TextLabel")
    coinLabel.Name = "CoinLabel"
    coinLabel.Size = UDim2.new(0, 250, 0, 60)
    coinLabel.Position = UDim2.new(0.5, -125, 0.05, 0)
    coinLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    coinLabel.BackgroundTransparency = 0.3
    coinLabel.BorderSizePixel = 0
    coinLabel.TextColor3 = Color3.fromRGB(255, 223, 0)
    coinLabel.TextStrokeTransparency = 0.5
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.Text = "💰 Loading..."
    coinLabel.Parent = screenGui
    
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 12)
    coinCorner.Parent = coinLabel
    
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "ItemFrame"
    itemFrame.Size = UDim2.new(0, 280, 0, 150)
    itemFrame.Position = UDim2.new(0.5, -140, 0.15, 0)
    itemFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    itemFrame.BackgroundTransparency = 0.3
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = screenGui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = itemFrame
    
    local resources = {
        {name = "KajiFruit", icon = "🍇", color = Color3.fromRGB(139, 90, 43)},
        {name = "Edamame", icon = "🫛", color = Color3.fromRGB(200, 200, 200)},
        {name = "MistSudachi", icon = "🍉", color = Color3.fromRGB(100, 200, 255)}
    }
    
    for i, resource in ipairs(resources) do
        local label = Instance.new("TextLabel")
        label.Name = resource.name .. "Label"
        label.Size = UDim2.new(1, -20, 0, 40)
        label.Position = UDim2.new(0, 10, 0, (i-1) * 45 + 10)
        label.BackgroundTransparency = 1
        label.TextColor3 = resource.color
        label.TextStrokeTransparency = 0.5
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = resource.icon .. " Loading..."
        label.Parent = itemFrame
    end
    
    task.spawn(function()
        local coinsValue = Player:WaitForChild("Data"):WaitForChild("Currency"):WaitForChild("Coins")
        local lastCoins = coinsValue.Value
        
        while task.wait(0.5) do
            local current = coinsValue.Value
            local diff = current - lastCoins
            
            if diff > 0 then
                coinLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
            elseif diff < 0 then
                coinLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            else
                coinLabel.TextColor3 = Color3.fromRGB(255, 223, 0)
            end
            
            coinLabel.Text = string.format("💰 %s", tostring(current))
            lastCoins = current
        end
    end)
    
    task.spawn(function()
        local resourcesData = Player:WaitForChild("Data"):WaitForChild("Resources")
        
        while task.wait(0.5) do
            for i, resource in ipairs(resources) do
                local val = resourcesData:FindFirstChild(resource.name)
                if val then
                    local label = itemFrame:FindFirstChild(resource.name .. "Label")
                    if label then
                        label.Text = string.format("%s %s: %d", resource.icon, resource.name, val.Value)
                        
                        if val.Value >= SELL_THRESHOLD * 0.8 then
                            label.TextColor3 = Color3.fromRGB(255, 165, 0)
                        elseif val.Value >= SELL_THRESHOLD then
                            label.TextColor3 = Color3.fromRGB(255, 80, 80)
                        else
                            label.TextColor3 = resource.color
                        end
                    end
                end
            end
        end
    end)
end


function sellAllItems()
    print("💰 เริ่มขายไอเทมทั้งหมด...")
    
    task.wait(3)
    
    local success, resources = pcall(function()
        return Player:WaitForChild("Data", 10):WaitForChild("Resources", 10)
    end)
    
    if not success or not resources then
        warn("❌ ไม่สามารถเข้าถึง Resources ได้")
        return
    end
    
    local itemsToSell = {"KajiFruit", "Edamame", "MistSudachi"}
    local soldAny = false
    
    for _, itemName in ipairs(itemsToSell) do
        local val = resources:FindFirstChild(itemName)
        if val and val.Value > 0 then
            local amount = val.Value
            print("🔸 กำลังขาย " .. itemName .. ": " .. amount .. " ชิ้น")
            
            -- ใช้ format ตามที่ Remote Spy แสดง
            local args = {
                {
                    ItemName = itemName,
                    Amount = amount
                }
            }
            
            local ok, err = pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellItemRemote"):FireServer(unpack(args))
            end)
            
            if ok then
                print("✅ ขาย " .. itemName .. " สำเร็จ: " .. amount .. " ชิ้น")
                soldAny = true
            else
                warn("❌ ขาย " .. itemName .. " ล้มเหลว:", err)
            end
            
            task.wait(2)
        else
            print("⚠️ ไม่มี " .. itemName .. " ให้ขาย")
        end
    end
    
    if soldAny then
        print("💰 ขายไอเทมเสร็จสิ้น! รอ 3 วินาที...")
        task.wait(3)
    else
        print("⚠️ ไม่มีไอเทมให้ขาย")
    end
end

function checkInventoryForSell()
    local resources = Player:WaitForChild("Data"):WaitForChild("Resources")
    
    local spirit = resources:FindFirstChild("KajiFruit") and resources.KajiFruit.Value or 0
    local lime = resources:FindFirstChild("Edamame") and resources.Edamame.Value or 0
    local crystal = resources:FindFirstChild("MistSudachi") and resources.MistSudachi.Value or 0
    
    return spirit >= SELL_THRESHOLD or lime >= SELL_THRESHOLD or crystal >= SELL_THRESHOLD
end

function teleportToWorld(placeId)
    print("🌍 วาร์ปไป PlaceId:", placeId)
    
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WorldTeleportRemote"):InvokeServer(placeId, {})
    end)
end

function startWorldChecker()
    task.spawn(function()
        while autoFarm do
            task.wait(2)
            
            local currentPlace = game.PlaceId
            
            if currentPlace == FARM_WORLD then
                if checkInventoryForSell() then
                    print("📦 ไอเทมเต็ม - วาร์ปไปขาย")
                    task.wait(2)
                    teleportToWorld(SELL_WORLD)
                    task.wait(10)
                end
            elseif currentPlace == SELL_WORLD then
                print("💰 ขายของ...")
                task.wait(2)
                sellAllItems()
                task.wait(3)
                teleportToWorld(FARM_WORLD)
                task.wait(10)
            else
                warn("🚫 อยู่นอกโลก - วาร์ปกลับ")
                task.wait(2)
                teleportToWorld(FARM_WORLD)
                task.wait(10)
            end
        end
    end)
end

function TouchFoodModel(model)
    if not model or not model:IsA("Model") then return false end
    
    local handle = model:FindFirstChild("Handle")
    if not handle or not handle:FindFirstChildOfClass("TouchTransmitter") then return false end
    
    if not HRP then return false end
    
    pcall(function()
        safeFireTouch(handle, HRP)
    end)
    
    return true
end

function getAllDroppedItems()
    local items = {}
    if not HRP then return items end
    
    local function scan(parent)
        if not parent then return end
        for _, obj in pairs(parent:GetChildren()) do
            if table.find(itemNames, obj.Name) then
                local pos = nil
                if obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                end
                
                if pos and (pos - HRP.Position).Magnitude <= scanRange then
                    table.insert(items, {instance = obj, pos = pos, distance = (pos - HRP.Position).Magnitude})
                end
            end
        end
    end
    
    scan(workspace)
    scan(workspace:FindFirstChild("Camera"))
    
    table.sort(items, function(a, b) return a.distance < b.distance end)
    return items
end

function collectAllItems()
    local collectedCount = 0
    local maxAttempts = 10
    local attempts = 0
    
    updateLastAction()
    
    while attempts < maxAttempts and autoFarm do
        local items = getAllDroppedItems()
        
        if #items == 0 then break end
        
        for _, itemData in ipairs(items) do
            if itemData.instance and itemData.instance.Parent then
                TouchFoodModel(itemData.instance)
                task.wait(0.1)
                collectedCount = collectedCount + 1
            end
        end
        
        attempts = attempts + 1
        task.wait(0.5)
    end
    
    if collectedCount > 0 then
        updateLastAction()
    end
end


function GetMountedDragon()
    if not Character then return nil end
    
    local Dragons = Character:FindFirstChild("Dragons")
    if not Dragons then return nil end
    
    for _, dragon in pairs(Dragons:GetChildren()) do
        local Seat = dragon:FindFirstChildWhichIsA("VehicleSeat") or dragon:FindFirstChild("Seat")
        if Seat and Seat.Occupant and Seat.Occupant.Parent == Character then
            return dragon
        end
    end
    return nil
end


function findNearestNode()
    local largeFoodNode = workspace:FindFirstChild("Interactions")
        and workspace.Interactions:FindFirstChild("Nodes")
        and workspace.Interactions.Nodes:FindFirstChild("Food")
        and workspace.Interactions.Nodes.Food:FindFirstChild("LargeFoodNode")

    if not largeFoodNode or not HRP then return nil end

    local billboard = largeFoodNode:FindFirstChild("BillboardPart")
    if not billboard then return nil end

    local hp = billboard:FindFirstChild("Health")
    if not hp or hp.Value <= 0 then return nil end

    local nodePos = billboard.Position
    local blocked = isInNoGoZone(nodePos)
    if blocked then return nil end
    if nodePos.Y < 50 then return nil end
    return billboard
end
function flyToPosition(targetPos, speed)
    speed = speed or flySpeed
    
    updateLastAction()
    
    if not Character or not HRP then
        warn("❌ ไม่พบตัวละคร")
        return false
    end
    
    local startTime = tick()
    local maxTime = (targetPos - HRP.Position).Magnitude / speed + 5
    local connection
    
    local function stopFlying()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not HRP or not HRP.Parent then
            stopFlying()
            return
        end
        
        local currentPos = HRP.Position
        local distanceToTarget = (targetPos - currentPos).Magnitude
        
        if distanceToTarget <= 8 then
            stopFlying()
            return
        end
        
        if tick() - startTime > maxTime then
            stopFlying()
            return
        end
        
        local direction = (targetPos - currentPos).Unit
        local moveDistance = speed * deltaTime
        local newPos = currentPos + (direction * moveDistance)
        
        HRP.CFrame = CFrame.lookAt(newPos, targetPos)
        HRP.Velocity = Vector3.zero
        HRP.AssemblyLinearVelocity = Vector3.zero
    end)
    
    repeat
        task.wait()
    until not connection or (HRP.Position - targetPos).Magnitude <= 8
    
    stopFlying()
    updateLastAction()
    task.wait(0.2)
    return true
end


function startFarm()
    print("🚀 เริ่มระบบฟาร์ม")

    task.spawn(function()
        while autoFarm do
            if not Character or not HRP then
                warn("⚠️ รอตัวละคร...")
                task.wait(2)
                continue
            end

            if game.PlaceId ~= FARM_WORLD then
                warn("⚠️ ไม่อยู่ในโลกฟาร์ม")
                task.wait(5)
                continue
            end

            local dragon = GetMountedDragon()

            if not dragon then
                warn("⚠️ ไม่พบมังกร - รอ rebind...")
                task.wait(2)
            else
                local targetNode = findNearestNode()

                if targetNode then
                    local nodePos = targetNode.Position

                    local blocked, zone = isInNoGoZone(nodePos)
                    if blocked then
                        task.wait(0.3)
                        continue
                    end

                    flyToPosition(nodePos + Vector3.new(0, 15, 0), flySpeed)
                    updateLastAction()
                    task.wait(0.3)

                    while targetNode
                        and targetNode:FindFirstChild("Health")
                        and targetNode.Health.Value > 0
                        and autoFarm do

                        if isInNoGoZone(targetNode.Position) then
                            break
                        end

                        if dragon and dragon:FindFirstChild("Remotes") then
                            local remotes = dragon.Remotes

                            if remotes:FindFirstChild("BreathFireRemote") then
                                pcall(function()
                                    remotes.BreathFireRemote:FireServer()
                                end)
                            end

                            if remotes:FindFirstChild("PlaySoundRemote") then
                                pcall(function()
                                    remotes.PlaySoundRemote:FireServer("Breath", "Destructibles", targetNode)
                                end)
                            end
                        end

                        updateLastAction()
                        task.wait(attackDelay)
                    end

                    task.wait(1)
                    collectAllItems()
                    task.wait(1)

                else
                    local nextPos = checkPositions[currentPatrolIndex]

                    if not isInNoGoZone(nextPos) then
                        flyToPosition(nextPos, flySpeed + 20)
                    end

                    currentPatrolIndex = currentPatrolIndex + 1
                    if currentPatrolIndex > #checkPositions then
                        currentPatrolIndex = 1
                    end

                    task.wait(2)
                end
            end

            task.wait(0.5)
        end
    end)
end


local remotes = ReplicatedStorage:WaitForChild("Remotes")

function getAutoDragon()
    if not Character then return nil end
    
    local dragonFolder = workspace:FindFirstChild("Characters")
    if not dragonFolder then return nil end
    
    local playerFolder = dragonFolder:FindFirstChild(Player.Name)
    if not playerFolder then return nil end
    
    local dragons = playerFolder:FindFirstChild("Dragons")
    if not dragons then return nil end
    
    local dragonList = dragons:GetChildren()
    if #dragonList > 0 then
        return dragonList[1]
    end
    return nil
end

function reviveDragon(dragonModel)
    local dragonName = dragonModel.Name
    local deadFlag = dragonModel:FindFirstChild("Data") and dragonModel.Data:FindFirstChild("Dead")

    if deadFlag and deadFlag.Value == true then
        print("💀 ฟื้นมังกร:", dragonName)
        
        pcall(function()
            remotes:WaitForChild("ReviveDragonRemote"):InvokeServer(dragonName, "DragonRevivalHeart")
        end)
        
        task.wait(1)
    end
end

ensureMountedDragon = function()
    if not Character then 
        return 
    end
    
    local dragonModel = getAutoDragon()
    if not dragonModel then
        return
    end

    local targetName = dragonModel.Name

    reviveDragon(dragonModel)

    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local currentSeat = humanoid.SeatPart
    local currentMount = currentSeat and currentSeat:FindFirstAncestorWhichIsA("Model")

    if currentMount and currentMount.Name == targetName then
        return
    end

    local seat = dragonModel:FindFirstChildWhichIsA("Seat", true)
    if seat then
        seat:Sit(humanoid)
        print("🪶 ขี่มังกร:", targetName)

        task.wait(1)
        
        pcall(function()
            local flyBtn = Player.PlayerGui
                :WaitForChild("HUDGui")
                .BottomFrame.CurrentDragonFrame.DragonControlsFrame.Other:FindFirstChild("Fly")

            if flyBtn and flyBtn:FindFirstChild("MouseButton1Down") then
                safeFireSignal(flyBtn.MouseButton1Down)
            end
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        pcall(ensureMountedDragon)
    end
end)


function enableFlyControlUseSpace()
    pcall(function()
        local data = Player:WaitForChild("Data", 5)
        if not data then return end

        local settings = data:WaitForChild("Settings", 5)
        if not settings then return end

        local flyControlValue = settings:FindFirstChild("FlyControlUseSpace")
        if not flyControlValue then return end

        if flyControlValue.Value == true then
            flyControlValue.Value = false
        end
    end)
end

function pressQ()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end

function getDragonFlyingState()
    if not Character then return false end

    local dragonsFolder = Character:FindFirstChild("Dragons")
    if not dragonsFolder then return false end

    for _, dragon in ipairs(dragonsFolder:GetChildren()) do
        if dragon:IsA("Model") then
            local dataFolder = dragon:FindFirstChild("Data")
            if dataFolder then
                local flyingValue = dataFolder:FindFirstChild("Flying")
                if flyingValue and flyingValue.Value ~= nil then
                    return flyingValue.Value
                end
            end
        end
    end

    return false
end

function startFlyingMonitor()
    task.spawn(function()
        while true do
            task.wait(0.5)

            local isFlying = false
            local ok, result = pcall(function()
                return getDragonFlyingState()
            end)

            if ok then
                isFlying = result
            end

            if not isFlying and Character then
                pressQ()
                task.wait(0.1)
                pressQ()
            end
        end
    end)
end


setupAntiAFK()
createGUI()

enableFlyControlUseSpace()
startFlyingMonitor()

local currentPlace = game.PlaceId
print("📍 PlaceId ปัจจุบัน: " .. currentPlace)

if currentPlace == FARM_WORLD then
    print("✅ อยู่ในโลกฟาร์ม - เริ่มฟาร์ม")
    startFarm()
    startWorldChecker()
elseif currentPlace == SELL_WORLD then
  
    task.wait(2)
    sellAllItems()
    task.wait(3)
    teleportToWorld(FARM_WORLD)
else

    task.wait(2)
    teleportToWorld(FARM_WORLD)
end

