-- ==================== GLOBAL KILL-SWITCH (ANTI-KEDIP) ====================
if getgenv().KemantapanBot_Active then
    getgenv().KemantapanBot_Active = false
    task.wait(0.5) 
end
getgenv().KemantapanBot_Active = true

-- ==================== SERVICES & VARIABLES ====================
local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled
local lastGeneratorPoint = nil 

local function SendNotification(title, text, duration)
    pcall(function() 
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration or 3, Icon = "rbxassetid://10873923769" }) 
    end)
end

-- ==================== CONFIG SYSTEM ====================
local isRunning = function() return getgenv().KemantapanBot_Active end
local Config = {} 
local ToggleFunctions = {} 
local ConfigFileName = "KemantapanHub_ConfigV30_Final.json"

local function SaveConfig() pcall(function() if writefile then writefile(ConfigFileName, HttpService:JSONEncode(Config)) end end) end
local function LoadConfig() pcall(function() if isfile and isfile(ConfigFileName) then local decoded = HttpService:JSONDecode(readfile(ConfigFileName)); if decoded then for k, v in pairs(decoded) do Config[k] = v end end end end) end
local function ResetConfig() pcall(function() if isfile and isfile(ConfigFileName) then delfile(ConfigFileName) end; Config = {} end) end
LoadConfig()

-- Inisialisasi Config Default
if Config["Auto Skill Check [LEGIT]"] == nil then Config["Auto Skill Check [LEGIT]"] = false end
if Config["Auto Gen (Fire Instan)"] == nil then Config["Auto Gen (Fire Instan)"] = false end
if Config["Auto Gen (Metata)"] == nil then Config["Auto Gen (Metata)"] = false end
if Config["Auto Farm Survivor (Auto Win)"] == nil then Config["Auto Farm Survivor (Auto Win)"] = false end
if Config["Webhook Auto Farm"] == nil then Config["Webhook Auto Farm"] = false end

if CoreGui:FindFirstChild("KemantapanUI") then CoreGui.KemantapanUI:Destroy() end

-- ==================== WEBHOOK SENDER SYSTEM (BRUTE FORCE SCANNER) ====================
local function SendWebhook(webhookUrl, isTest)
    if not webhookUrl or webhookUrl == "" or webhookUrl == "URL_DISINI" then return end
    local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)
    if not requestFunc then SendNotification("Error", "Executor tidak support Webhook.", 3); return end

    -- Smart Scanner: Deteksi data spesifik dari folder, atribut, dan leaderstats
    local function getStat(statName, altNames)
        local namesToCheck = {statName}
        if altNames then for _, v in ipairs(altNames) do table.insert(namesToCheck, v) end end
        
        -- 1. Cek Folder Data Tersembunyi (Sering dipake dev untuk nyimpen currency)
        local hiddenFolders = {"Data", "Stats", "leaderstats", "Currencies", "PlayerStats"}
        for _, folderName in ipairs(hiddenFolders) do
            local folder = LocalPlayer:FindFirstChild(folderName)
            if folder then
                for _, name in ipairs(namesToCheck) do
                    local stat = folder:FindFirstChild(name)
                    if stat then return tostring(stat.Value) end
                end
            end
        end

        -- 2. Cek Attributes
        for _, name in ipairs(namesToCheck) do
            local attr = LocalPlayer:GetAttribute(name)
            if attr ~= nil then return tostring(attr) end
        end

        -- 3. Mode Brutal: Cari kemiripan nama di Attributes
        for attrName, attrValue in pairs(LocalPlayer:GetAttributes()) do
            if attrName:lower():find(statName:lower()) then return tostring(attrValue) end
        end

        -- 4. Mode Brutal: Cari kemiripan nama di semua folder stats
        for _, folderName in ipairs(hiddenFolders) do
            local folder = LocalPlayer:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child.Name:lower():find(statName:lower()) then return tostring(child.Value) end
                end
            end
        end

        return "Tidak Detek"
    end

    local lvl = getStat("Level", {"Lvl", "Rank"})
    local exp = getStat("EXP", {"Exp", "Experience"})
    local gears = getStat("Gears", {"Gear", "Silver", "Koin"})
    local screw = getStat("Screws", {"Screw", "Baut", "Parts"})
    -- Target sin diperluas dengan alias nama developer paling umum
    local sin = getStat("Sin", {"Sins", "TotalSin", "Total Sins", "RedToken", "RedTokens", "RedSkull", "Bloodpoints", "Blood", "Evil", "Merah", "Tengkorak"}) 

    local embedData = {
        ["title"] = isTest and "🔧 TEST WEBHOOK" or "📊 Statistik Auto Farm",
        ["description"] = "Kemantapan Auto Farm System",
        ["color"] = 65280, 
        ["fields"] = {
            {["name"] = "👤 Username", ["value"] = LocalPlayer.Name, ["inline"] = false},
            {["name"] = "📊 Level", ["value"] = lvl, ["inline"] = true},
            {["name"] = "⭐ EXP", ["value"] = exp, ["inline"] = true},
            {["name"] = "⚙️ Gears", ["value"] = gears, ["inline"] = true},
            {["name"] = "🔩 Screws", ["value"] = screw, ["inline"] = true},
            {["name"] = "💀 Total Sin", ["value"] = sin, ["inline"] = false}
        },
        ["footer"] = {["text"] = "Kemantapan Hub Script | Violent District"}
    }

    local payload = HttpService:JSONEncode({content = "", embeds = {embedData}})

    task.spawn(function()
        pcall(function()
            requestFunc({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
        end)
    end)
end

-- ==================== METATABLE HOOKS ====================
if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if isRunning() and method == "FireServer" then
            local remoteName = tostring(self)
            
            if remoteName == "SkillCheckResultEvent" then
                if Config["Auto Gen (Metata)"] or Config["Auto Gen (Fire Instan)"] or Config["Auto Skill Check [LEGIT]"] then
                    args[1], args[2] = "success", 1
                    return oldNamecall(self, unpack(args))
                end
            elseif remoteName == "KingScourgeHit" then
                if Config["Auto Gen (Metata)"] or Config["Auto Gen (Fire Instan)"] or Config["Auto Skill Check [LEGIT]"] then
                    args[2] = "success" 
                    return oldNamecall(self, unpack(args))
                end
            elseif remoteName == "RepairEvent" and args[2] == true and args[1] then
                lastGeneratorPoint = args[1]
            end
        end
        return oldNamecall(self, ...)
    end)

    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and isRunning() and key == "Rotation" then
            if typeof(self) == "Instance" and self.Name == "Line" and self:IsA("GuiObject") then
                if Config["Auto Gen (Fire Instan)"] or Config["Auto Gen (Metata)"] or Config["Auto Skill Check [LEGIT]"] then
                    local goal = self.Parent and self.Parent:FindFirstChild("Goal")
                    if goal and goal:IsA("GuiObject") then return goal.Rotation + 109 end
                end
            end
        end
        return oldIndex(self, key)
    end)
end

local function getSafePos(obj)
    if not obj or not obj.Parent then return Vector3.new(0,0,0) end
    if obj:IsA("Model") then return obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position end
    if obj:IsA("BasePart") then return obj.Position end
    local bp = obj:FindFirstChildWhichIsA("BasePart", true)
    return bp and bp.Position or Vector3.new(0,0,0)
end

-- ==================== MAP SCANNER ====================
local MapObjects = {Generators = {}, Pallets = {}, Windows = {}, Hooks = {}, Gates = {}, Finishlines = {}}

local function RefreshMapObjects()
    if not isRunning() then return end
    local temp = {Generators = {}, Pallets = {}, Windows = {}, Hooks = {}, Gates = {}, Finishlines = {}}
    local processed = {}
    
    pcall(function()
        local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("map")
        if not mapFolder then return end 

        for i, obj in ipairs(mapFolder:GetDescendants()) do
            if i % 1000 == 0 then task.wait() end 
            if not obj or not obj.Parent or processed[obj] then continue end
            
            local name = obj.Name
            if not name then continue end
            local lname = string.lower(name)

            if lname == "levergoal" and obj:IsA("BasePart") then
                local gateModel = obj:FindFirstAncestor("Gate") or (obj.Parent and obj.Parent.Parent)
                if gateModel and not processed[gateModel] then table.insert(temp.Gates, gateModel); processed[gateModel] = true end
            elseif (lname == "fininshline" or lname == "finishline") and obj:IsA("BasePart") then
                if not processed[obj] then table.insert(temp.Finishlines, obj); processed[obj] = true end
            elseif obj:IsA("Model") and (lname == "window" or lname == "windows") then
                local bottomPart = obj:FindFirstChild("Bottom")
                local hasVault = obj:FindFirstChild("VaultTrigger") or obj:FindFirstChild("vaulttrigger")
                if bottomPart and bottomPart:IsA("BasePart") and hasVault and not processed[bottomPart] then
                    table.insert(temp.Windows, bottomPart); processed[bottomPart] = true
                end
            elseif (obj:IsA("Model") and lname == "generator") or (obj:IsA("BasePart") and (lname:find("generator") or lname:find("engine") or lname == "gen") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name ~= "Workspace") then
                local targetGen = obj:IsA("Model") and obj or obj.Parent
                if targetGen and targetGen:IsA("Model") and not processed[targetGen] then
                    local isDup = false
                    local targetPos = getSafePos(targetGen)
                    for _, existingGen in ipairs(temp.Generators) do
                        if (getSafePos(existingGen) - targetPos).Magnitude < 6 then isDup = true; break end
                    end
                    if not isDup then table.insert(temp.Generators, targetGen); processed[targetGen] = true end
                end
            elseif lname:find("palletwrong") then
                local targetPallet = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
                if not processed[targetPallet] then table.insert(temp.Pallets, targetPallet); processed[targetPallet] = true end
            end
        end
    end)
    MapObjects = temp
end

task.spawn(RefreshMapObjects)
task.spawn(function() while isRunning() do task.wait(10); RefreshMapObjects() end end)

local function GetGenProgress(gen)
    local highest = 0
    pcall(function()
        local prompt = gen:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            local num = (prompt.ObjectText or "" .. prompt.ActionText or ""):match("(%d+)%%")
            if num then highest = tonumber(num) end
        end
        if highest == 0 then
            for attr, val in pairs(gen:GetAttributes()) do
                if (string.lower(attr):find("prog") or string.lower(attr):find("percent")) and type(val) == "number" then
                    if val > highest and val <= 100 then highest = math.floor(val) end
                end
            end
        end
    end)
    return highest
end

-- ==================== UI & SERVER HOP SETUP ====================
local isHopping = false

TeleportService.TeleportInitFailed:Connect(function()
    isHopping = false
end)

local function FetchAndHop(mode)
    if isHopping then return end
    isHopping = true
    task.spawn(function()
        local ApiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=" .. (mode == "Small" and "Asc" or "Desc")
        local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)
        if not requestFunc then SendNotification("Error", "Executor tidak support HTTP request.", 3); isHopping = false; return end
        
        local success, response = pcall(function() return requestFunc({Url = ApiUrl, Method = "GET"}) end)
        if success and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                local candidates = {}
                for _, s in ipairs(data.data) do
                    if type(s) == "table" and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                        table.insert(candidates, s)
                    end
                end
                if #candidates > 0 then
                    if mode == "Small" then 
                        table.sort(candidates, function(a, b) return a.playing < b.playing end) 
                    else
                        for i = #candidates, 2, -1 do 
                            local j = math.random(i)
                            candidates[i], candidates[j] = candidates[j], candidates[i] 
                        end
                    end
                    SendNotification("Hopping", "Menyambung ke Server...", 3)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[1].id, LocalPlayer)
                    task.wait(4)
                    isHopping = false 
                    return
                end
            end
        end
        isHopping = false
    end)
end

-- ==================== GUI CREATION ====================
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "KemantapanUI"
ScreenGui.ResetOnSpawn = false

local ToggleR = Instance.new("TextButton", ScreenGui)
ToggleR.Size = UDim2.new(0, 40, 0, 40)
ToggleR.Position = UDim2.new(0.85, 0, 0.1, 0)
ToggleR.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
ToggleR.TextColor3 = Color3.fromRGB(15, 15, 15)
ToggleR.Font = Enum.Font.GothamBold
ToggleR.TextSize = 18
ToggleR.Text = "R"
ToggleR.Active = true
ToggleR.Draggable = true
Instance.new("UICorner", ToggleR).CornerRadius = UDim.new(1, 0)

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 470, 0, 320)
Main.Position = UDim2.new(0.5, -235, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BorderColor3 = Color3.fromRGB(255, 215, 0)
Main.BorderSizePixel = 2
Main.Active = true
Main.Draggable = true

local ConfirmOverlay = Instance.new("Frame", Main)
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 0.2
ConfirmOverlay.ZIndex = 10
ConfirmOverlay.Visible = false

local ConfirmBox = Instance.new("Frame", ConfirmOverlay)
ConfirmBox.Size = UDim2.new(0, 250, 0, 120)
ConfirmBox.Position = UDim2.new(0.5, -125, 0.5, -60)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ConfirmBox.ZIndex = 11
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 8)

local ConfirmTxt = Instance.new("TextLabel", ConfirmBox)
ConfirmTxt.Size = UDim2.new(1, 0, 0, 60)
ConfirmTxt.BackgroundTransparency = 1
ConfirmTxt.Text = "Yakin ingin Reset Config?"
ConfirmTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmTxt.Font = Enum.Font.GothamBold
ConfirmTxt.TextSize = 13
ConfirmTxt.ZIndex = 12

local BtnYes = Instance.new("TextButton", ConfirmBox)
BtnYes.Size = UDim2.new(0, 80, 0, 30)
BtnYes.Position = UDim2.new(0.15, 0, 0.6, 0)
BtnYes.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
BtnYes.Text = "YES"
BtnYes.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnYes.Font = Enum.Font.GothamBold
BtnYes.ZIndex = 12
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 4)

local BtnNo = Instance.new("TextButton", ConfirmBox)
BtnNo.Size = UDim2.new(0, 80, 0, 30)
BtnNo.Position = UDim2.new(0.55, 0, 0.6, 0)
BtnNo.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
BtnNo.Text = "NO"
BtnNo.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnNo.Font = Enum.Font.GothamBold
BtnNo.ZIndex = 12
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 4)

BtnNo.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)
BtnYes.MouseButton1Click:Connect(function() ResetConfig(); ConfirmOverlay.Visible = false; getgenv().KemantapanBot_Active = false; ScreenGui:Destroy() end)

local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -40, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Kemantapan Hub | V31 (WebHook Fix + Delay EXP)"
TitleText.TextColor3 = Color3.fromRGB(15, 15, 15)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 120, 1, -30)
Sidebar.Position = UDim2.new(0, 0, 0, 30)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BorderSizePixel = 0

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -120, 1, -30)
ContentArea.Position = UDim2.new(0, 120, 0, 30)
ContentArea.BackgroundTransparency = 1

ToggleR.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
CloseBtn.MouseButton1Click:Connect(function() getgenv().KemantapanBot_Active = false; ScreenGui:Destroy() end)

local Tabs = {}
local function CreateTab(name, yPos)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.Position = UDim2.new(0, 0, 0, yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.BorderSizePixel = 0
    
    local Page = Instance.new("ScrollingFrame", ContentArea)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 4
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local Layout = Instance.new("UIListLayout", Page)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 5)
    
    table.insert(Tabs, {Btn = Btn, Page = Page, Layout = Layout})
    
    Btn.MouseButton1Click:Connect(function() 
        for _, t in pairs(Tabs) do 
            t.Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            t.Page.Visible = false 
        end
        Btn.TextColor3 = Color3.fromRGB(255, 215, 0)
        Page.Visible = true 
    end)
    return Page
end

-- ==================== UI COMPONENT BUILDERS ====================
local function CreateToggle(parent, title, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 30)
    Container.BackgroundTransparency = 1
    
    local Lbl = Instance.new("TextLabel", Container)
    Lbl.Size = UDim2.new(0.65, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = "  " .. title
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(0, 70, 0, 22)
    Btn.Position = UDim2.new(1, -80, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Text = "OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    Btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    if Config[title] == nil then Config[title] = false end
    
    local function setToggleState(state, skipCallback)
        Config[title] = state
        Btn.Text = state and "ON" or "OFF"
        Btn.BackgroundColor3 = state and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(35, 35, 35)
        Btn.TextColor3 = state and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(255, 100, 100)
        if callback and not skipCallback then pcall(function() callback(state) end) end
    end
    
    ToggleFunctions[title] = setToggleState
    Btn.MouseButton1Click:Connect(function() setToggleState(not Config[title]) end)
    if Config[title] == true then task.spawn(function() setToggleState(true) end) end
end

local function CreateInputToggle(parent, title, defaultInput, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 30)
    Container.BackgroundTransparency = 1
    
    local Lbl = Instance.new("TextLabel", Container)
    Lbl.Size = UDim2.new(0.4, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = "  " .. title
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local InputBox = Instance.new("TextBox", Container)
    InputBox.Size = UDim2.new(0, 40, 0, 22)
    InputBox.Position = UDim2.new(0.45, 0, 0.5, -11)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Text = tostring(Config[title .. " Value"] or defaultInput)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 11
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(0, 70, 0, 22)
    Btn.Position = UDim2.new(1, -80, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Text = "OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    Btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    if Config[title] == nil then Config[title] = false end
    
    local function setInputToggleState(state, val)
        Config[title] = state
        Config[title .. " Value"] = val
        Btn.Text = state and "ON" or "OFF"
        Btn.BackgroundColor3 = state and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(35, 35, 35)
        Btn.TextColor3 = state and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(255, 100, 100)
        if callback then pcall(function() callback(state, val) end) end
    end
    
    Btn.MouseButton1Click:Connect(function() setInputToggleState(not Config[title], tonumber(InputBox.Text) or defaultInput) end)
    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(InputBox.Text)
        if val then 
            Config[title .. " Value"] = val
            if Config[title] and callback then pcall(function() callback(true, val) end) end 
        end
    end)
    if Config[title] == true then task.spawn(function() setInputToggleState(true, tonumber(InputBox.Text) or defaultInput) end) end
end

local function CreateStringInputToggle(parent, title, defaultInput, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 30)
    Container.BackgroundTransparency = 1
    
    local Lbl = Instance.new("TextLabel", Container)
    Lbl.Size = UDim2.new(0.35, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = "  " .. title
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local InputBox = Instance.new("TextBox", Container)
    InputBox.Size = UDim2.new(0, 60, 0, 22)
    InputBox.Position = UDim2.new(0.40, 0, 0.5, -11)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Text = tostring(Config[title .. " Value"] or defaultInput)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 10
    InputBox.TextScaled = true
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(0, 70, 0, 22)
    Btn.Position = UDim2.new(1, -80, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Text = "OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    Btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    if Config[title] == nil then Config[title] = false end
    
    local function setInputToggleState(state, val)
        Config[title] = state
        Config[title .. " Value"] = val
        Btn.Text = state and "ON" or "OFF"
        Btn.BackgroundColor3 = state and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(35, 35, 35)
        Btn.TextColor3 = state and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(255, 100, 100)
        if callback then pcall(function() callback(state, val) end) end
    end
    
    Btn.MouseButton1Click:Connect(function() setInputToggleState(not Config[title], InputBox.Text) end)
    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        Config[title .. " Value"] = InputBox.Text
        if Config[title] and callback then pcall(function() callback(true, InputBox.Text) end) end
    end)
    if Config[title] == true then task.spawn(function() setInputToggleState(true, InputBox.Text) end) end
end

local function CreateScriptButton(parent, title, callback, color)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, -14, 0, 30)
    Btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 35)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Text = title
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    
    local UIPadding = Instance.new("UIPadding", Btn)
    UIPadding.PaddingLeft = UDim.new(0, 10)
    Btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

-- ==================== TAB INITIALIZATION ====================
local TabInfo = CreateTab("Informasi", 0)
local TabSurv = CreateTab("Survivor", 35)
local TabESP  = CreateTab("ESP Menu", 70)
local TabTele = CreateTab("Teleport", 105) 
local TabSet  = CreateTab("Pengaturan", 140)

Tabs[1].Page.Visible = true
Tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 215, 0)

local InfoTxt = Instance.new("TextLabel", TabInfo)
InfoTxt.Size = UDim2.new(1, 0, 0, 70)
InfoTxt.BackgroundTransparency = 1
InfoTxt.Text = "  Player: " .. LocalPlayer.Name .. "\n  Game: Violent District\n  Status: WEBHOOK INTEGRATED & AUTO FARM READY!"
InfoTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTxt.Font = Enum.Font.Gotham
InfoTxt.TextSize = 12
InfoTxt.TextXAlignment = Enum.TextXAlignment.Left

-- ==================== SURVIVOR MENU CONFIG ====================
CreateScriptButton(TabSurv, "🏆 1-Klik Win Survivor (Instan Escape)", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if MapObjects.Finishlines and #MapObjects.Finishlines > 0 then
        hrp.CFrame = CFrame.new(MapObjects.Finishlines[1].Position + Vector3.new(0, 1, 0))
        hrp.Velocity = Vector3.new(0,0,0)
        SendNotification("WIN!", "TP Finishline Berhasil!", 3)
    else
        local map = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("map")
        local found = false
        if map then
            for _, v in ipairs(map:GetDescendants()) do
                if v:IsA("BasePart") and (v.Name:lower() == "fininshline" or v.Name:lower() == "finishline") then
                    hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 1, 0))
                    hrp.Velocity = Vector3.new(0,0,0)
                    SendNotification("WIN!", "TP Finishline Berhasil!", 3)
                    found = true
                    break
                end
            end
        end
        if not found then SendNotification("Error", "Finishline belum siap.", 3) end
    end
end, Color3.fromRGB(40, 160, 40))

CreateToggle(TabSurv, "Auto Farm Survivor (Auto Win)")
CreateStringInputToggle(TabSurv, "Webhook Auto Farm", "URL_DISINI", function(state, value) Config["Webhook Auto Farm Value"] = value end)

CreateScriptButton(TabSurv, "📡 Test Webhook Status", function()
    if Config["Webhook Auto Farm"] and Config["Webhook Auto Farm Value"] and Config["Webhook Auto Farm Value"] ~= "URL_DISINI" then
        SendWebhook(Config["Webhook Auto Farm Value"], true)
        SendNotification("Webhook", "Mengirim Test...", 3)
    else
        SendNotification("Error", "Isi Webhook & Nyalakan!", 3)
    end
end, Color3.fromRGB(50, 100, 180))

CreateToggle(TabSurv, "Auto Gen (Fire Instan)") 
CreateToggle(TabSurv, "Auto Skill Check [LEGIT]")
CreateToggle(TabSurv, "Auto Gen (Metata)") 
CreateToggle(TabSurv, "Anti-Stuck (Auto Cancel on Move)")
CreateToggle(TabSurv, "Noclip (Tembus Tembok)")
CreateInputToggle(TabSurv, "WalkSpeed", 20, function(state, value) Config["WalkSpeed Value"] = value end)

-- ==================== ESP MENU CONFIG ====================
CreateToggle(TabESP, "Set Waktu Siang (12 PM)", function(state) if state then Lighting.ClockTime = 12 end end)
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function() 
    if Config["Set Waktu Siang (12 PM)"] and Lighting.ClockTime ~= 12 then Lighting.ClockTime = 12 end 
end)

CreateToggle(TabESP, "World Visual (No Fog/Shadow)", function(state)
    Lighting.GlobalShadows = not state
    for _, v in ipairs(Lighting:GetDescendants()) do 
        if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v.Enabled = not state end 
    end
end)

CreateInputToggle(TabESP, "Custom Brightness", 3, function(state, value) Lighting.Brightness = state and value or 1 end)
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function() 
    if Config["Custom Brightness"] then 
        local val = tonumber(Config["Custom Brightness Value"]) or 3
        if Lighting.Brightness ~= val then Lighting.Brightness = val end 
    end 
end)

CreateToggle(TabESP, "ESP All-in-One", function(state)
    local espList = {"ESP Survivor", "ESP Killer", "ESP Generator", "ESP Pallet", "ESP Window", "ESP Gate", "Tampilkan Nama Player & Jarak"}
    for _, name in ipairs(espList) do if ToggleFunctions[name] then ToggleFunctions[name](state) end end
end)

CreateToggle(TabESP, "ESP Survivor")
CreateToggle(TabESP, "ESP Killer")
CreateToggle(TabESP, "ESP Generator")
CreateToggle(TabESP, "ESP Pallet")
CreateToggle(TabESP, "ESP Window")
CreateToggle(TabESP, "ESP Gate")
CreateToggle(TabESP, "Tampilkan Nama Player & Jarak")

-- ==================== TELEPORT TAB ====================
local TeleContainer = Instance.new("Frame", TabTele)
TeleContainer.Size = UDim2.new(1, 0, 1, 0)
TeleContainer.BackgroundTransparency = 1

local BoxLeft = Instance.new("Frame", TeleContainer)
BoxLeft.Size = UDim2.new(0.48, 0, 0.95, 0)
BoxLeft.Position = UDim2.new(0, 5, 0, 5)
BoxLeft.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", BoxLeft).CornerRadius = UDim.new(0, 6)

local LblLeft = Instance.new("TextLabel", BoxLeft)
LblLeft.Size = UDim2.new(1, 0, 0, 20)
LblLeft.BackgroundTransparency = 1
LblLeft.Text = "Teleport Pemain"
LblLeft.TextColor3 = Color3.fromRGB(255, 215, 0)
LblLeft.Font = Enum.Font.GothamBold
LblLeft.TextSize = 12

local PlayerScroll = Instance.new("ScrollingFrame", BoxLeft)
PlayerScroll.Size = UDim2.new(1, -10, 1, -25)
PlayerScroll.Position = UDim2.new(0, 5, 0, 25)
PlayerScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.CanvasSize = UDim2.new(0,0,0,0)
PlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local PLayout = Instance.new("UIListLayout", PlayerScroll)
PLayout.Padding = UDim.new(0, 4)
PLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local selectedPlayerToTP = nil

local ActionFrame = Instance.new("Frame", PlayerScroll)
ActionFrame.Size = UDim2.new(1, -4, 0, 85)
ActionFrame.BackgroundTransparency = 1
ActionFrame.LayoutOrder = 9999

local TargetLbl = Instance.new("TextLabel", ActionFrame)
TargetLbl.Size = UDim2.new(1, 0, 0, 18)
TargetLbl.BackgroundTransparency = 1
TargetLbl.Text = "Target: -"
TargetLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLbl.Font = Enum.Font.GothamSemibold
TargetLbl.TextSize = 11

local BtnTPExec = Instance.new("TextButton", ActionFrame)
BtnTPExec.Size = UDim2.new(1, 0, 0, 26)
BtnTPExec.Position = UDim2.new(0, 0, 0, 20)
BtnTPExec.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
BtnTPExec.Text = "TELEPORT"
BtnTPExec.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnTPExec.Font = Enum.Font.GothamBold
BtnTPExec.TextSize = 12
Instance.new("UICorner", BtnTPExec).CornerRadius = UDim.new(0, 4)

local BtnRefreshMap = Instance.new("TextButton", ActionFrame)
BtnRefreshMap.Size = UDim2.new(1, 0, 0, 26)
BtnRefreshMap.Position = UDim2.new(0, 0, 0, 52)
BtnRefreshMap.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
BtnRefreshMap.Text = "🔄 REFRESH MAP LOG"
BtnRefreshMap.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnRefreshMap.Font = Enum.Font.GothamBold
BtnRefreshMap.TextSize = 12
Instance.new("UICorner", BtnRefreshMap).CornerRadius = UDim.new(0, 4)

BtnRefreshMap.MouseButton1Click:Connect(function() 
    MapObjects = {Generators = {}, Pallets = {}, Windows = {}, Hooks = {}, Gates = {}, Finishlines = {}}
    SendNotification("Refresh Map", "Scan ulang map...", 3)
    RefreshMapObjects() 
end)

local function RefreshPlayerList()
    for _, v in ipairs(PlayerScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local PBtn = Instance.new("TextButton", PlayerScroll)
            PBtn.Size = UDim2.new(1, -4, 0, 26)
            PBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            PBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            PBtn.Text = p.DisplayName
            PBtn.Font = Enum.Font.GothamBold
            PBtn.TextSize = 11
            Instance.new("UICorner", PBtn).CornerRadius = UDim.new(0, 4)
            PBtn.MouseButton1Click:Connect(function() 
                selectedPlayerToTP = p
                TargetLbl.Text = "Target: " .. p.DisplayName 
            end)
        end
    end
end

BtnTPExec.MouseButton1Click:Connect(function() 
    if selectedPlayerToTP and selectedPlayerToTP.Character then 
        LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayerToTP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) 
    end 
end)

RefreshPlayerList()
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)

local BoxRight = Instance.new("Frame", TeleContainer)
BoxRight.Size = UDim2.new(0.48, 0, 0.95, 0)
BoxRight.Position = UDim2.new(0.51, 0, 0, 5)
BoxRight.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", BoxRight).CornerRadius = UDim.new(0, 6)

local LblRight = Instance.new("TextLabel", BoxRight)
LblRight.Size = UDim2.new(1, 0, 0, 20)
LblRight.BackgroundTransparency = 1
LblRight.Text = "Teleport Map"
LblRight.TextColor3 = Color3.fromRGB(255, 215, 0)
LblRight.Font = Enum.Font.GothamBold
LblRight.TextSize = 12

local ObjectScroll = Instance.new("ScrollingFrame", BoxRight)
ObjectScroll.Size = UDim2.new(1, -10, 1, -25)
ObjectScroll.Position = UDim2.new(0, 5, 0, 25)
ObjectScroll.BackgroundTransparency = 1
ObjectScroll.BorderSizePixel = 0
ObjectScroll.ScrollBarThickness = 3
ObjectScroll.CanvasSize = UDim2.new(0,0,0,0)
ObjectScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local OLayout = Instance.new("UIListLayout", ObjectScroll)
OLayout.Padding = UDim.new(0, 4)
OLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function AddMapBtn(title, callback)
    local Btn = Instance.new("TextButton", ObjectScroll)
    Btn.Size = UDim2.new(1, -4, 0, 25)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Text = title
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

for i = 1, 7 do 
    AddMapBtn("TP Generator " .. i, function() 
        local gens = {}
        if MapObjects.Generators then for _, v in ipairs(MapObjects.Generators) do table.insert(gens, v) end end
        if #gens == 0 then SendNotification("Kosong", "Gen belum terdeteksi", 3) return end
        
        table.sort(gens, function(a, b) 
            local posA, posB = getSafePos(a), getSafePos(b)
            if math.abs(posA.X - posB.X) < 2 then return posA.Z < posB.Z end
            return posA.X < posB.X 
        end)
        
        local targetGen = gens[i]
        if not targetGen then SendNotification("Info", "Generator ke-" .. i .. " belum terdeteksi.", 3) return end
        
        local pointCFrame = nil
        for _, v in ipairs(targetGen:GetDescendants()) do 
            if v:IsA("BasePart") and v.Name:lower():find("generatorpoint") then 
                pointCFrame = v.CFrame; if v.Name:lower() == "generatorpoint1" then break end 
            end 
        end
        if not pointCFrame and targetGen.Parent and targetGen.Parent ~= Workspace then 
            for _, v in ipairs(targetGen.Parent:GetDescendants()) do 
                if v:IsA("BasePart") and v.Name:lower():find("generatorpoint") and (v.Position - getSafePos(targetGen)).Magnitude < 7 then 
                    pointCFrame = v.CFrame; if v.Name:lower() == "generatorpoint1" then break end 
                end 
            end 
        end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then 
            if pointCFrame then hrp.CFrame = pointCFrame else 
                local tpPart = targetGen:IsA("BasePart") and targetGen or targetGen.PrimaryPart or targetGen:FindFirstChildWhichIsA("BasePart", true)
                if tpPart then hrp.CFrame = CFrame.new(tpPart.Position) end 
            end
            hrp.Velocity = Vector3.new(0,0,0) 
        end 
    end) 
end

for i = 1, 2 do 
    AddMapBtn("TP Gate " .. i, function() 
        local gate = MapObjects.Gates[i]
        if not gate then return end
        local leverGoal = gate:FindFirstChild("LeverGoal", true) or gate:FindFirstChild("levergoal", true)
        local tpPart = leverGoal or gate.PrimaryPart or gate:FindFirstChildWhichIsA("BasePart", true)
        if tpPart and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(tpPart.Position + Vector3.new(0, 3, 0))
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end) 
end

-- PENGATURAN TAB 
CreateScriptButton(TabSet, "💾 Save Config (Manual)", function() SaveConfig() SendNotification("Save", "Config tersimpan", 2) end, Color3.fromRGB(35, 100, 35))
CreateScriptButton(TabSet, "⚠️ Reset Config", function() ConfirmOverlay.Visible = true end, Color3.fromRGB(150, 35, 35))
CreateScriptButton(TabSet, "Rejoin Server Current", function() SendNotification("Rejoin", "Menyambung...", 3); task.wait(0.5); TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
CreateScriptButton(TabSet, "🌐 Find New Server (Fast)", function() FetchAndHop("Normal") end, Color3.fromRGB(40, 40, 150))
CreateScriptButton(TabSet, "📉 Find Small Server (Sepi)", function() FetchAndHop("Small") end, Color3.fromRGB(139, 69, 19))

-- ==================== ENGINE ESP Core ====================
local function DrawESP(obj, color, isEnabled, isPlayer, isGenerator, textNamePlayer, isWindow)
    if not obj or not obj.Parent then return end 
    local targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart or not targetPart.Parent then return end 
    if isWindow then targetPart = obj end

    local useBoxESP = isWindow
    local espVisual = useBoxESP and targetPart:FindFirstChild("KM_ESP_BOX") or (obj:FindFirstChild("KM_ESP") or targetPart:FindFirstChild("KM_ESP"))
    local textLabelGui = targetPart:FindFirstChild("KM_TXT") or obj:FindFirstChild("KM_TXT")

    if isEnabled then
        if not espVisual then 
            if useBoxESP then
                espVisual = Instance.new("BoxHandleAdornment")
                espVisual.Name = "KM_ESP_BOX"
                espVisual.Parent = targetPart
                espVisual.Adornee = targetPart
                espVisual.AlwaysOnTop = true
                espVisual.ZIndex = 10
                espVisual.Size = targetPart.Size + Vector3.new(0.05, 0.05, 0.05)
                espVisual.Transparency = 0.5
            else
                espVisual = Instance.new("Highlight")
                espVisual.Name = "KM_ESP"
                espVisual.FillTransparency = 0.5
                espVisual.Parent = obj:IsA("Model") and obj or targetPart
                espVisual.Adornee = obj:IsA("Model") and obj or targetPart
            end
        end
        if useBoxESP then 
            espVisual.Color3 = color
            espVisual.Visible = true 
        else 
            espVisual.FillColor = color
            espVisual.OutlineColor = color
            espVisual.Enabled = true 
        end

        local showText = false
        local finalText = ""
        if isPlayer and Config["Tampilkan Nama Player & Jarak"] then
            finalText = textNamePlayer
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then finalText = finalText .. " [" .. math.floor((root.Position - targetPart.Position).Magnitude) .. "m]" end
            showText = true 
        elseif isGenerator then
            finalText = GetGenProgress(obj) .. "%"
            showText = true
        end

        if showText then 
            if not textLabelGui then
                textLabelGui = Instance.new("BillboardGui")
                textLabelGui.Name = "KM_TXT"
                textLabelGui.Size = UDim2.new(0, 200, 0, 50)
                textLabelGui.AlwaysOnTop = true
                textLabelGui.Adornee = targetPart
                textLabelGui.Parent = targetPart
                textLabelGui.StudsOffset = Vector3.new(0, isPlayer and 3.5 or 2.5, 0)
                
                local txt = Instance.new("TextLabel", textLabelGui)
                txt.Name = "Text"
                txt.Size = UDim2.new(1,0,1,0)
                txt.BackgroundTransparency = 1
                txt.TextStrokeTransparency = 0
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
            end
            local txtLabel = textLabelGui:FindFirstChild("Text")
            if txtLabel then 
                txtLabel.TextColor3 = color
                txtLabel.Text = finalText 
            end 
            textLabelGui.Enabled = true
        elseif textLabelGui then textLabelGui.Enabled = false end
    else
        if espVisual then espVisual:Destroy() end
        if textLabelGui then textLabelGui:Destroy() end
    end
end

-- ==================== NOCLIP & MOVEMENT ====================
local wasNoclipEnabled = false
RunService.Stepped:Connect(function()
    if not isRunning() then return end
    local char = LocalPlayer.Character
    if not char then return end

    if Config["Noclip (Tembus Tembok)"] then
        wasNoclipEnabled = true
        for _, part in ipairs(char:GetDescendants()) do 
            if part:IsA("BasePart") then 
                local pName = part.Name:lower()
                if not (pName:find("leg") or pName:find("foot") or pName:find("shoe")) then part.CanCollide = false end 
            end 
        end
    elseif wasNoclipEnabled then
        for _, part in ipairs(char:GetDescendants()) do 
            if part:IsA("BasePart") then 
                local pName = part.Name:lower()
                if pName == "humanoidrootpart" or pName:find("torso") or pName:find("head") then part.CanCollide = true end 
            end 
        end
        wasNoclipEnabled = false 
    end
end)

local wasWalkSpeedEnabled = false
RunService.Heartbeat:Connect(function()
    if not isRunning() then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hum then
        if Config["WalkSpeed"] then 
            hum.WalkSpeed = Config["WalkSpeed Value"] or 20
            wasWalkSpeedEnabled = true
        elseif wasWalkSpeedEnabled then 
            hum.WalkSpeed = 16
            wasWalkSpeedEnabled = false 
        end

        if Config["Anti-Stuck (Auto Cancel on Move)"] and hum.MoveDirection.Magnitude > 0 then
            if lastGeneratorPoint then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local genRemote = remotes:FindFirstChild("Generator") and remotes.Generator:FindFirstChild("RepairEvent")
                    local emoteRemote = remotes:FindFirstChild("EmoteHandler")
                    if genRemote then pcall(function() genRemote:FireServer(lastGeneratorPoint, false) end) end
                    if emoteRemote then pcall(function() emoteRemote:FireServer("StopEmote") end) end
                end
                lastGeneratorPoint = nil 
            end
            if hrp and hrp.Anchored then hrp.Anchored = false end
            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.Sit then hum.Sit = false end
            if hum.WalkSpeed == 0 then hum.WalkSpeed = Config["WalkSpeed"] and (Config["WalkSpeed Value"] or 20) or 16 end
        end
    end
end)

-- ==================== THE GOD MODE QTE LOOP (ANTI-GLITCH) ====================
local isClicking = false 

local function ExecuteClickUI()
    local myTeam = LocalPlayer.Team
    local teamName = myTeam and myTeam.Name:lower() or ""
    if teamName:find("lobby") or teamName:find("spectator") or teamName:find("menu") then return end

    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local actionBtn = pg and pg:FindFirstChild("Survivor-mob") and pg["Survivor-mob"]:FindFirstChild("Controls") and pg["Survivor-mob"].Controls:FindFirstChild("action")
        
        if actionBtn then
            if firesignal then
                pcall(function() firesignal(actionBtn.MouseButton1Down); firesignal(actionBtn.MouseButton1Click); firesignal(actionBtn.Activated) end)
            end
        else
            if not isMobile then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.01)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end)
end

local function HandleQTEProcess(ui, isLegitMode)
    if isClicking then return end
    isClicking = true
    task.spawn(function()
        if isLegitMode then
            task.wait(1.2) 
            ExecuteClickUI()
            task.wait(0.35)
        else
            task.wait(0.1) 
            ExecuteClickUI()
            task.wait(0.35)
        end
        isClicking = false
    end)
end

local function MonitorUI(ui)
    if not ui:IsA("GuiObject") then return end
    local uiName = ui.Name:lower()
    if uiName:find("skill") or uiName:find("check") or uiName:find("qte") or uiName:find("circle") or uiName:find("hitpoint") then
        local function triggerLogic()
            local tName = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if tName:find("lobby") or tName:find("spectator") or not (ui.Visible and isRunning()) then return end
            
            if Config["Auto Gen (Metata)"] or Config["Auto Gen (Fire Instan)"] then HandleQTEProcess(ui, false) 
            elseif Config["Auto Skill Check [LEGIT]"] then HandleQTEProcess(ui, true) end
        end
        triggerLogic()
        ui:GetPropertyChangedSignal("Visible"):Connect(triggerLogic)
    end
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, child in ipairs(playerGui:GetDescendants()) do MonitorUI(child) end
playerGui.DescendantAdded:Connect(MonitorUI)

-- ==================== METATA FULL BOT AUTONOMY ====================
local interactDelay = 0
local lastMetataGen = nil
local matchEnded = false 

LocalPlayer.CharacterAdded:Connect(function() matchEnded = false end)

local function TriggerInteractButton()
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local actionBtn = pg and pg:FindFirstChild("Survivor-mob") and pg["Survivor-mob"]:FindFirstChild("Controls") and pg["Survivor-mob"].Controls:FindFirstChild("action")
        if actionBtn then
            if firesignal then pcall(function() firesignal(actionBtn.MouseButton1Down); firesignal(actionBtn.MouseButton1Click); firesignal(actionBtn.Activated); firesignal(actionBtn.TouchTap) end) end
            local cx = actionBtn.AbsolutePosition.X + (actionBtn.AbsoluteSize.X / 2)
            local cy = actionBtn.AbsolutePosition.Y + (actionBtn.AbsoluteSize.Y / 2)
            VirtualInputManager:SendTouchTapEvent(cx, cy, true, game); task.wait(0.05); VirtualInputManager:SendTouchTapEvent(cx, cy, false, game)
        end
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.ActionText:lower():find("repair") then
                if (getSafePos(prompt.Parent) - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 10 then
                    if fireproximityprompt then fireproximityprompt(prompt, 1, true) end
                end
            end
        end
    end)
end

local function TeleportToGen(gen, hrp)
    local points = {}
    for _, v in ipairs(gen:GetDescendants()) do if v:IsA("BasePart") and v.Name:lower():find("generatorpoint") then table.insert(points, v) end end
    if #points == 0 and gen.Parent and gen.Parent ~= Workspace then 
        for _, v in ipairs(gen.Parent:GetDescendants()) do if v:IsA("BasePart") and v.Name:lower():find("generatorpoint") and (v.Position - getSafePos(gen)).Magnitude < 10 then table.insert(points, v) end end 
    end
    
    local bestPt = nil
    for _, pt in ipairs(points) do
        local occupied = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (p.Character.HumanoidRootPart.Position - pt.Position).Magnitude < 2.5 then occupied = true; break end
            end
        end
        if not occupied then bestPt = pt; break end
    end
    if bestPt then hrp.CFrame = bestPt.CFrame; hrp.Velocity = Vector3.new(0,0,0); return true end
    return false 
end

task.spawn(function()
    while task.wait(0.1) do
        if not isRunning() or not Config["Auto Gen (Metata)"] then continue end
        local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("map")
        if not mapFolder then matchEnded = false; continue end

        local teamName = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
        if teamName:find("spectator") or teamName:find("lobby") or teamName:find("menu") then matchEnded = false; continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or matchEnded then continue end

        local checkInterractable = char:FindFirstChild("CheckInterractable")
        local isRepairing = checkInterractable and checkInterractable:GetAttribute("isRepairing") == true
        if isRepairing and lastMetataGen and GetGenProgress(lastMetataGen) >= 100 then isRepairing = false end

        local isKnocked = false
        if (hum.Health > 0 and hum.Health <= 15) or hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown or char:GetAttribute("Knocked") == true or char:GetAttribute("Downed") == true then isKnocked = true end

        local isKillerNear = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local isKiller = p.Team and (p.Team.Name:lower():find("killer") or p.Team.Name:lower():find("murder"))
                if isKiller and (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude < 65 then isKillerNear = true break end
            end
        end

        local completedGens = 0
        local incompleteGens = {}
        if MapObjects.Generators then
            for _, gen in ipairs(MapObjects.Generators) do
                if gen and gen.Parent then if GetGenProgress(gen) >= 100 then completedGens = completedGens + 1 else table.insert(incompleteGens, gen) end end
            end
        end

        if completedGens >= 5 or #incompleteGens == 0 or isKnocked then
            if MapObjects.Finishlines and #MapObjects.Finishlines > 0 then
                local finish = MapObjects.Finishlines[1]
                if finish and (hrp.Position - finish.Position).Magnitude > 5 then
                    hrp.CFrame = CFrame.new(finish.Position + Vector3.new(0, 1, 0)); hrp.Velocity = Vector3.new(0,0,0)
                    matchEnded = true; SendNotification("Bot Info", "Win/Knock terdeteksi. TP ke Finishline.", 3)
                end
            end
            continue 
        end

        if isKillerNear then
            if isRepairing or lastGeneratorPoint then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    if remotes:FindFirstChild("Generator") and remotes.Generator:FindFirstChild("RepairEvent") and lastGeneratorPoint then pcall(function() remotes.Generator.RepairEvent:FireServer(lastGeneratorPoint, false) end) end
                    if remotes:FindFirstChild("EmoteHandler") then pcall(function() remotes.EmoteHandler:FireServer("StopEmote") end) end
                end
                lastGeneratorPoint = nil; if hrp.Anchored then hrp.Anchored = false end
            end
            local safestGen, maxDist = nil, -1
            for _, gen in ipairs(incompleteGens) do
                local distToKiller = 9999
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local isKiller = p.Team and (p.Team.Name:lower():find("killer") or p.Team.Name:lower():find("murder"))
                        if isKiller then
                            local kDist = (p.Character.HumanoidRootPart.Position - getSafePos(gen)).Magnitude
                            if kDist < distToKiller then distToKiller = kDist end
                        end
                    end
                end
                if distToKiller > maxDist then maxDist = distToKiller; safestGen = gen end
            end
            if safestGen and maxDist > 65 then
                if not TeleportToGen(safestGen, hrp) then
                    local backupPt = safestGen:IsA("BasePart") and safestGen or safestGen:FindFirstChildWhichIsA("BasePart", true)
                    if backupPt then hrp.CFrame = CFrame.new(backupPt.Position + Vector3.new(0,2,0)); hrp.Velocity = Vector3.new(0,0,0) end
                end
                lastMetataGen = safestGen; interactDelay = tick() + 1.2 
            end
            continue 
        end

        if not isRepairing and tick() > interactDelay then
            if lastMetataGen and GetGenProgress(lastMetataGen) < 100 then
                if (hrp.Position - getSafePos(lastMetataGen)).Magnitude < 10 then TriggerInteractButton(); interactDelay = tick() + 2; continue end
            end
            table.sort(incompleteGens, function(a, b) return (getSafePos(a) - hrp.Position).Magnitude < (getSafePos(b) - hrp.Position).Magnitude end)
            local foundGen = false
            for _, gen in ipairs(incompleteGens) do
                if TeleportToGen(gen, hrp) then lastMetataGen = gen; interactDelay = tick() + 1.2; foundGen = true; break end
            end
            if not foundGen and #incompleteGens > 0 then
                local backupPt = incompleteGens[1]:IsA("BasePart") and incompleteGens[1] or incompleteGens[1]:FindFirstChildWhichIsA("BasePart", true)
                if backupPt then hrp.CFrame = CFrame.new(backupPt.Position + Vector3.new(0,2,0)); hrp.Velocity = Vector3.new(0,0,0) end
                lastMetataGen = incompleteGens[1]; interactDelay = tick() + 1.2
            end
        end
    end
end)

-- ==================== AUTO FARM SURVIVOR (DELAY EXP FIX) ====================
local autoFarmWaitTime = 0
local autoFarmStatus = "IDLE"

task.spawn(function()
    while task.wait(1) do
        if not isRunning() then break end
        if not Config["Auto Farm Survivor (Auto Win)"] then 
            autoFarmStatus = "IDLE"
            autoFarmWaitTime = 0
            continue 
        end
        
        local myTeam = LocalPlayer.Team
        local teamName = myTeam and myTeam.Name:lower() or ""

        if autoFarmStatus == "HOPPING" then
            if not isHopping then
                if tick() - autoFarmWaitTime >= 2 then
                    autoFarmWaitTime = tick()
                    FetchAndHop("Small")
                end
            end
            continue
        end
        
        if isHopping then continue end 
        
        if autoFarmStatus == "IDLE" or autoFarmStatus == "WAITING_IN_LOBBY" then
            if teamName:find("killer") or teamName:find("murder") then
                SendNotification("Auto Farm", "Role Killer! Hopping...", 3)
                autoFarmStatus = "HOPPING"
                autoFarmWaitTime = tick()
                FetchAndHop("Small")
            elseif teamName:find("survivor") or teamName:find("player") then
                SendNotification("Auto Farm", "Match Survivor! Tunggu 19s...", 3)
                autoFarmStatus = "PREPARING_SURVIVOR"
                autoFarmWaitTime = tick()
            else
                if autoFarmStatus == "IDLE" then
                    SendNotification("Auto Farm", "Menunggu match...", 3)
                    autoFarmStatus = "WAITING_IN_LOBBY"
                    autoFarmWaitTime = tick()
                elseif autoFarmStatus == "WAITING_IN_LOBBY" then
                    if tick() - autoFarmWaitTime >= 120 then
                        SendNotification("Auto Farm", "Timeout! Hopping...", 3)
                        autoFarmStatus = "HOPPING"
                        autoFarmWaitTime = tick()
                        FetchAndHop("Small")
                    end
                end
            end
        elseif autoFarmStatus == "PREPARING_SURVIVOR" then
            if tick() - autoFarmWaitTime >= 19 then 
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and MapObjects.Finishlines and #MapObjects.Finishlines > 0 then
                    local finish = MapObjects.Finishlines[1]
                    hrp.CFrame = CFrame.new(finish.Position + Vector3.new(0, 1, 0))
                    hrp.Velocity = Vector3.new(0,0,0)
                    SendNotification("Auto Farm", "TP Finishline! Cek status...", 3)
                    autoFarmStatus = "WAITING_WIN"
                    autoFarmWaitTime = tick()
                else
                    SendNotification("Auto Farm", "Map blm siap. Tunggu...", 2)
                    autoFarmWaitTime = tick() - 14 
                end
            end
        elseif autoFarmStatus == "WAITING_WIN" then
            if teamName:find("spectator") or teamName:find("lobby") or teamName:find("menu") then
                SendNotification("Auto Farm", "Win! Tunggu 1.5 detik utk EXP...", 3)
                autoFarmStatus = "DELAY_BEFORE_HOP"
                autoFarmWaitTime = tick()
            elseif tick() - autoFarmWaitTime >= 7 then
                SendNotification("Auto Farm", "Bug terdeteksi! Hopping...", 3)
                autoFarmStatus = "HOPPING"
                autoFarmWaitTime = tick()
                FetchAndHop("Small")
            end
        elseif autoFarmStatus == "DELAY_BEFORE_HOP" then
            if tick() - autoFarmWaitTime >= 1.5 then
                if Config["Webhook Auto Farm"] and Config["Webhook Auto Farm Value"] and Config["Webhook Auto Farm Value"] ~= "URL_DISINI" then
                    SendWebhook(Config["Webhook Auto Farm Value"], false)
                end
                SendNotification("Auto Farm", "EXP Masuk! Mengirim Webhook & Hopping...", 3)
                autoFarmStatus = "HOPPING"
                autoFarmWaitTime = tick()
                FetchAndHop("Small")
            end
        end
    end
end)

-- ==================== MAIN AUTOMATION LOOP (GARBAGE COLLECTOR) ====================
local staticUpdateCounter = 0

task.spawn(function()
    while task.wait(0.1) do  
        if not isRunning() then break end 
        staticUpdateCounter = staticUpdateCounter + 1
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local isKiller = p.Team and (p.Team.Name:lower():find("killer") or p.Team.Name:lower():find("murder"))
                if isKiller then DrawESP(p.Character, Color3.fromRGB(255, 0, 0), Config["ESP Killer"], true, false, p.Name.." [KILLER]")
                else DrawESP(p.Character, Color3.fromRGB(0, 255, 0), Config["ESP Survivor"], true, false, p.Name) end
            end
        end

        if MapObjects.Generators then 
            for i = #MapObjects.Generators, 1, -1 do
                local gen = MapObjects.Generators[i]
                if not gen or not gen.Parent then table.remove(MapObjects.Generators, i)
                else DrawESP(gen, Color3.fromRGB(255, 255, 0), Config["ESP Generator"], false, true, "") end
            end 
        end

        if staticUpdateCounter >= 10 then
            staticUpdateCounter = 0
            if MapObjects.Pallets then 
                for i = #MapObjects.Pallets, 1, -1 do
                    local pal = MapObjects.Pallets[i]
                    if not pal or not pal.Parent then table.remove(MapObjects.Pallets, i) else DrawESP(pal, Color3.fromRGB(255, 150, 0), Config["ESP Pallet"], false, false, "") end
                end 
            end
            if MapObjects.Windows then 
                for i = #MapObjects.Windows, 1, -1 do
                    local win = MapObjects.Windows[i]
                    if not win or not win.Parent then table.remove(MapObjects.Windows, i) else DrawESP(win, Color3.fromRGB(0, 255, 255), Config["ESP Window"], false, false, "", true) end
                end 
            end
            if MapObjects.Gates then 
                for i = #MapObjects.Gates, 1, -1 do
                    local gate = MapObjects.Gates[i]
                    if not gate or not gate.Parent then table.remove(MapObjects.Gates, i) else DrawESP(gate, Color3.fromRGB(255, 0, 255), Config["ESP Gate"], false, false, "") end
                end 
            end
            if MapObjects.Finishlines then 
                for i = #MapObjects.Finishlines, 1, -1 do
                    local finish = MapObjects.Finishlines[i]
                    if not finish or not finish.Parent then table.remove(MapObjects.Finishlines, i) end
                end 
            end
        end
    end
end)
