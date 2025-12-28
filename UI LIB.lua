local SpecialHub = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        task.spawn(function()
            task.wait(0.1)
            if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                task.wait(0.05)
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        task.spawn(function()
            task.wait(0.1)
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseIconEnabled = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
    end
end)

local function PreventMultipleGUI()
    local gui = PlayerGui:FindFirstChild("SpecialHub")
    if gui then
        gui:Destroy()
        task.wait(0.1)
    end
end

SpecialHub.ConfigSystem = {
    FolderName = nil,
    ConfigFileName = "config.json",
    AutoSave = false,
    ElementCallbacks = {}
}

function SpecialHub.ConfigSystem:SetFolder(folderName)
    self.FolderName = folderName
    if folderName and folderName ~= "" then
        self.ConfigFileName = folderName .. "/config.json"
        if not isfolder(folderName) then
            makefolder(folderName)
        end
    end
end

function SpecialHub.ConfigSystem:SaveConfig(data)
    if not self.AutoSave then
        return false
    end
    return pcall(function()
        writefile(self.ConfigFileName, HttpService:JSONEncode(data))
    end)
end

function SpecialHub.ConfigSystem:LoadConfig()
    local success, content = pcall(function()
        return readfile(self.ConfigFileName)
    end)

    if success and content ~= "" then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if ok then
            return decoded
        end
    end
    return {}
end

function SpecialHub.ConfigSystem:RegisterCallback(key, callback)
    self.ElementCallbacks[key] = callback
end

function SpecialHub.ConfigSystem:ApplyCallbacks(configData)
    for key, value in pairs(configData) do
        if self.ElementCallbacks[key] then
            task.spawn(function()
                self.ElementCallbacks[key](value)
            end)
        end
    end
end

local THEME = {
    Main = Color3.fromRGB(18, 18, 21),
    Background = Color3.fromRGB(22, 22, 26),
    Content = Color3.fromRGB(26, 26, 31),
    TabBg = Color3.fromRGB(20, 20, 24),
    ActiveTab = Color3.fromRGB(30, 30, 36),
    Text = Color3.fromRGB(235, 235, 245),
    Muted = Color3.fromRGB(145, 145, 160),
    Accent = Color3.fromRGB(110, 120, 250),
    AccentDark = Color3.fromRGB(85, 95, 225),
    Line = Color3.fromRGB(35, 35, 42),
    ToggleOn = Color3.fromRGB(110, 120, 250),
    ToggleOff = Color3.fromRGB(50, 50, 58),
    Button = Color3.fromRGB(110, 120, 250),
    ButtonHover = Color3.fromRGB(125, 135, 255),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(255, 170, 25),
    Danger = Color3.fromRGB(250, 70, 70),
    InputBg = Color3.fromRGB(28, 28, 34),
    InputStroke = Color3.fromRGB(45, 45, 55)
}

local ANIMATIONS = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
    Elastic = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function CreateRoundedRect(parent, radius)
    return CreateInstance("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 8)
    })
end

local function AnimateHover(object, hoverColor, normalColor)
    object.MouseEnter:Connect(function()
        TweenService:Create(object, ANIMATIONS.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)

    object.MouseLeave:Connect(function()
        TweenService:Create(object, ANIMATIONS.Fast, {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

function SpecialHub:CreateWindow(options)
    options = options or {}

    local windowName = options.Name or "Special Hub"
    local windowSize = options.Size or UDim2.new(0, 380, 0, 320)
    local toggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightShift

    if options.AutoSave ~= nil then
        self.ConfigSystem.AutoSave = options.AutoSave
    end

    if options.FolderName then
        self.ConfigSystem:SetFolder(options.FolderName)
    end

    PreventMultipleGUI()

    local Window = {
        Tabs = {},
        CurrentTab = nil,
        ConfigData = {}
    }

    function Window:LoadConfigData()
        self.ConfigData = SpecialHub.ConfigSystem:LoadConfig()
    end

    function Window:SaveConfigData()
        return SpecialHub.ConfigSystem:SaveConfig(self.ConfigData)
    end

    function Window:UpdateConfig(key, value)
        self.ConfigData[key] = value
        self:SaveConfigData()
    end

    function Window:GetConfigValue(key, default)
        return self.ConfigData[key] ~= nil and self.ConfigData[key] or default
    end

    Window:LoadConfigData()

    task.defer(function()
        task.wait(0.3)
        SpecialHub.ConfigSystem:ApplyCallbacks(Window.ConfigData)
    end)

    return Window
end

return SpecialHub
