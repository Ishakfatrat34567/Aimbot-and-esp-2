local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local MENU_NAME = "MvpMenuPrototype"

local defaultState = {
    menuOpen = true,
    activeTab = "Aimbot",
    aimbot = {
        enabled = false,
        targetSelection = "Closest to cursor",
        targetPart = "Head",
        fov = 120,
        smoothing = 0.35,
        distanceLimit = 500,
        teamCheck = true,
        visibilityCheck = true,
    },
    esp = {
        enabled = false,
        box = true,
        name = true,
        distance = true,
        health = true,
        teamColors = true,
        tracers = false,
        maxRenderDistance = 600,
    },
    config = {
        selectedName = "Default",
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local clone = {}
    for key, nestedValue in pairs(value) do
        clone[key] = deepCopy(nestedValue)
    end
    return clone
end

local state = deepCopy(defaultState)
local savedConfigs = {
    Default = deepCopy(defaultState),
    Smooth = {
        menuOpen = true,
        activeTab = "Aimbot",
        aimbot = {
            enabled = false,
            targetSelection = "Closest player",
            targetPart = "Head",
            fov = 90,
            smoothing = 0.65,
            distanceLimit = 450,
            teamCheck = true,
            visibilityCheck = true,
        },
        esp = {
            enabled = false,
            box = true,
            name = true,
            distance = false,
            health = true,
            teamColors = true,
            tracers = false,
            maxRenderDistance = 450,
        },
        config = {
            selectedName = "Smooth",
        },
    },
    Aggressive = {
        menuOpen = true,
        activeTab = "ESP",
        aimbot = {
            enabled = false,
            targetSelection = "Closest to cursor",
            targetPart = "HumanoidRootPart",
            fov = 180,
            smoothing = 0.2,
            distanceLimit = 700,
            teamCheck = false,
            visibilityCheck = false,
        },
        esp = {
            enabled = false,
            box = true,
            name = true,
            distance = true,
            health = true,
            teamColors = false,
            tracers = true,
            maxRenderDistance = 900,
        },
        config = {
            selectedName = "Aggressive",
        },
    },
}

local ui = {
    tabs = {},
    tabButtons = {},
    sections = {},
    infoLabels = {},
    configButtons = {},
    statusLabel = nil,
    menuFrame = nil,
}

local function formatStateForDisplay()
    return HttpService:JSONEncode({
        prototype = true,
        note = "UI/config prototype only; no automation or overlay logic is implemented.",
        activeTab = state.activeTab,
        aimbot = state.aimbot,
        esp = state.esp,
        selectedConfig = state.config.selectedName,
    })
end

local function setStatus(message)
    if ui.statusLabel then
        ui.statusLabel.Text = message
    end
end

local function create(instanceType, properties)
    local instance = Instance.new(instanceType)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    return instance
end

local function createCorner(parent, radius)
    local corner = create("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
    return corner
end

local function createStroke(parent, color)
    local stroke = create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = 0.15,
        Parent = parent,
    })
    return stroke
end

local function refreshTabVisibility()
    for tabName, frame in pairs(ui.tabs) do
        local isActive = tabName == state.activeTab
        frame.Visible = isActive

        local button = ui.tabButtons[tabName]
        if button then
            button.BackgroundColor3 = isActive and Color3.fromRGB(74, 144, 226) or Color3.fromRGB(34, 39, 47)
        end
    end
end

local function updateInfoLabels()
    if ui.infoLabels.Aimbot then
        ui.infoLabels.Aimbot.Text = string.format(
            "Prototype controls only\nEnabled: %s\nMode: %s\nPart: %s\nFOV: %d\nSmooth: %.2f\nDistance: %d\nTeam Check: %s\nVisibility: %s",
            tostring(state.aimbot.enabled),
            state.aimbot.targetSelection,
            state.aimbot.targetPart,
            state.aimbot.fov,
            state.aimbot.smoothing,
            state.aimbot.distanceLimit,
            tostring(state.aimbot.teamCheck),
            tostring(state.aimbot.visibilityCheck)
        )
    end

    if ui.infoLabels.ESP then
        ui.infoLabels.ESP.Text = string.format(
            "Prototype controls only\nEnabled: %s\nBox: %s\nName: %s\nDistance: %s\nHealth: %s\nTeam Colors: %s\nTracers: %s\nRender Distance: %d",
            tostring(state.esp.enabled),
            tostring(state.esp.box),
            tostring(state.esp.name),
            tostring(state.esp.distance),
            tostring(state.esp.health),
            tostring(state.esp.teamColors),
            tostring(state.esp.tracers),
            state.esp.maxRenderDistance
        )
    end

    if ui.infoLabels.Config then
        ui.infoLabels.Config.Text = string.format(
            "Selected: %s\n\nSaved presets: %s\n\nSnapshot:\n%s",
            state.config.selectedName,
            table.concat((function()
                local names = {}
                for name in pairs(savedConfigs) do
                    table.insert(names, name)
                end
                table.sort(names)
                return names
            end)(), ", "),
            formatStateForDisplay()
        )
    end
end

local function applyConfig(configName)
    local config = savedConfigs[configName]
    if not config then
        setStatus(string.format("Config '%s' was not found.", configName))
        return
    end

    state = deepCopy(config)
    state.menuOpen = true
    state.activeTab = state.activeTab or "Aimbot"
    state.config.selectedName = configName
    refreshTabVisibility()
    updateInfoLabels()
    setStatus(string.format("Loaded '%s' preset.", configName))
end

local function saveCurrentConfig(configName)
    local snapshot = deepCopy(state)
    snapshot.config.selectedName = configName
    savedConfigs[configName] = snapshot
    state.config.selectedName = configName
    updateInfoLabels()
    setStatus(string.format("Saved '%s' preset.", configName))
end

local function resetDefaults()
    state = deepCopy(defaultState)
    refreshTabVisibility()
    updateInfoLabels()
    setStatus("Reset all prototype values to defaults.")
end

local function addSectionTitle(parent, text, order)
    local label = create("TextLabel", {
        Name = text:gsub("%s+", "") .. "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        Parent = parent,
    })
    return label
end

local function addButton(parent, text, order, callback)
    local button = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 14,
        AutoButtonColor = true,
        LayoutOrder = order,
        Parent = parent,
    })
    createCorner(button, 8)
    createStroke(button, Color3.fromRGB(88, 99, 116))
    button.Activated:Connect(callback)
    return button
end

local function addChoiceRow(parent, labelText, order, values, getter, setter)
    local frame = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        LayoutOrder = order,
        Parent = parent,
    })

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = labelText,
        TextColor3 = Color3.fromRGB(189, 198, 208),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local button = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 14,
        Parent = frame,
    })
    createCorner(button, 8)
    createStroke(button, Color3.fromRGB(88, 99, 116))

    local currentIndex = 1
    local function syncButtonText()
        local currentValue = getter()
        for index, value in ipairs(values) do
            if value == currentValue then
                currentIndex = index
                break
            end
        end
        button.Text = tostring(values[currentIndex])
    end

    button.Activated:Connect(function()
        currentIndex += 1
        if currentIndex > #values then
            currentIndex = 1
        end
        setter(values[currentIndex])
        syncButtonText()
        updateInfoLabels()
    end)

    syncButtonText()
    return frame
end

local function addToggleRow(parent, labelText, order, getter, setter)
    return addChoiceRow(parent, labelText, order, {true, false}, getter, function(value)
        setter(value)
        setStatus(string.format("Updated %s to %s.", labelText, tostring(value)))
    end)
end

local function addStepperRow(parent, labelText, order, getter, setter, step, minimum, maximum, formatter)
    local frame = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        LayoutOrder = order,
        Parent = parent,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = labelText,
        TextColor3 = Color3.fromRGB(189, 198, 208),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local minusButton = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(0, 38, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 18,
        Parent = frame,
    })
    createCorner(minusButton, 8)
    createStroke(minusButton, Color3.fromRGB(88, 99, 116))

    local valueButton = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Position = UDim2.new(0, 44, 0, 22),
        Size = UDim2.new(1, -88, 0, 32),
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 14,
        Parent = frame,
    })
    createCorner(valueButton, 8)
    createStroke(valueButton, Color3.fromRGB(88, 99, 116))

    local plusButton = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Position = UDim2.new(1, -38, 0, 22),
        Size = UDim2.new(0, 38, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "+",
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 18,
        Parent = frame,
    })
    createCorner(plusButton, 8)
    createStroke(plusButton, Color3.fromRGB(88, 99, 116))

    local function sync()
        local value = getter()
        valueButton.Text = formatter and formatter(value) or tostring(value)
    end

    local function updateValue(direction)
        local nextValue = getter() + (step * direction)
        nextValue = math.clamp(nextValue, minimum, maximum)
        setter(nextValue)
        sync()
        updateInfoLabels()
        setStatus(string.format("Updated %s to %s.", labelText, tostring(nextValue)))
    end

    minusButton.Activated:Connect(function()
        updateValue(-1)
    end)

    plusButton.Activated:Connect(function()
        updateValue(1)
    end)

    valueButton.Activated:Connect(function()
        sync()
        setStatus(string.format("%s is currently %s.", labelText, tostring(getter())))
    end)

    sync()
    return frame
end

local existingGui = playerGui:FindFirstChild(MENU_NAME)
if existingGui then
    existingGui:Destroy()
end

local screenGui = create("ScreenGui", {
    Name = MENU_NAME,
    ResetOnSpawn = false,
    Parent = playerGui,
})

local menuFrame = create("Frame", {
    Name = "MenuFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 720, 0, 470),
    BackgroundColor3 = Color3.fromRGB(20, 24, 31),
    Parent = screenGui,
})
ui.menuFrame = menuFrame
createCorner(menuFrame, 14)
createStroke(menuFrame, Color3.fromRGB(88, 99, 116))

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, 16),
    Size = UDim2.new(1, -36, 0, 26),
    Font = Enum.Font.GothamBold,
    Text = "Roblox MVP Menu Prototype",
    TextColor3 = Color3.fromRGB(240, 244, 248),
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = menuFrame,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, 42),
    Size = UDim2.new(1, -36, 0, 20),
    Font = Enum.Font.Gotham,
    Text = "Safe UI/config scaffold with real-time state updates only.",
    TextColor3 = Color3.fromRGB(155, 165, 178),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = menuFrame,
})

local tabBar = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, 78),
    Size = UDim2.new(1, -36, 0, 36),
    Parent = menuFrame,
})

local tabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding = UDim.new(0, 8),
    Parent = tabBar,
})

local contentFrame = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, 126),
    Size = UDim2.new(1, -36, 1, -184),
    Parent = menuFrame,
})

local function createTab(tabName)
    local button = create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(34, 39, 47),
        Size = UDim2.new(0, 120, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = tabName,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        TextSize = 14,
        Parent = tabBar,
    })
    createCorner(button, 8)
    createStroke(button, Color3.fromRGB(88, 99, 116))
    ui.tabButtons[tabName] = button

    local tabFrame = create("ScrollingFrame", {
        Name = tabName .. "Tab",
        BackgroundColor3 = Color3.fromRGB(26, 31, 39),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Visible = false,
        Parent = contentFrame,
    })
    createCorner(tabFrame, 12)
    createStroke(tabFrame, Color3.fromRGB(88, 99, 116))

    local padding = create("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        Parent = tabFrame,
    })

    local listLayout = create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabFrame,
    })

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 28)
    end)

    button.Activated:Connect(function()
        state.activeTab = tabName
        refreshTabVisibility()
        updateInfoLabels()
        setStatus(string.format("Opened %s tab.", tabName))
    end)

    ui.tabs[tabName] = tabFrame
    ui.sections[tabName] = tabFrame
end

createTab("Aimbot")
createTab("ESP")
createTab("Config")

addSectionTitle(ui.sections.Aimbot, "Targeting Controls", 1)
addToggleRow(ui.sections.Aimbot, "Enabled", 2, function()
    return state.aimbot.enabled
end, function(value)
    state.aimbot.enabled = value
end)
addChoiceRow(ui.sections.Aimbot, "Target selection", 3, {"Closest to cursor", "Closest player"}, function()
    return state.aimbot.targetSelection
end, function(value)
    state.aimbot.targetSelection = value
    setStatus("Updated target selection.")
end)
addChoiceRow(ui.sections.Aimbot, "Target part", 4, {"Head", "HumanoidRootPart"}, function()
    return state.aimbot.targetPart
end, function(value)
    state.aimbot.targetPart = value
    setStatus("Updated target part.")
end)
addStepperRow(ui.sections.Aimbot, "FOV", 5, function()
    return state.aimbot.fov
end, function(value)
    state.aimbot.fov = value
end, 10, 30, 360)
addStepperRow(ui.sections.Aimbot, "Smoothing", 6, function()
    return state.aimbot.smoothing
end, function(value)
    state.aimbot.smoothing = math.round(value * 100) / 100
end, 0.05, 0.05, 1, function(value)
    return string.format("%.2f", value)
end)
addStepperRow(ui.sections.Aimbot, "Distance limit", 7, function()
    return state.aimbot.distanceLimit
end, function(value)
    state.aimbot.distanceLimit = value
end, 25, 50, 2000)
addToggleRow(ui.sections.Aimbot, "Team check", 8, function()
    return state.aimbot.teamCheck
end, function(value)
    state.aimbot.teamCheck = value
end)
addToggleRow(ui.sections.Aimbot, "Visibility check", 9, function()
    return state.aimbot.visibilityCheck
end, function(value)
    state.aimbot.visibilityCheck = value
end)
ui.infoLabels.Aimbot = create("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(16, 20, 26),
    Size = UDim2.new(1, 0, 0, 150),
    Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(149, 255, 193),
    TextSize = 14,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 10,
    Parent = ui.sections.Aimbot,
})
createCorner(ui.infoLabels.Aimbot, 10)
createStroke(ui.infoLabels.Aimbot, Color3.fromRGB(88, 99, 116))

addSectionTitle(ui.sections.ESP, "Visualization Controls", 1)
addToggleRow(ui.sections.ESP, "Enabled", 2, function()
    return state.esp.enabled
end, function(value)
    state.esp.enabled = value
end)
addToggleRow(ui.sections.ESP, "Box ESP", 3, function()
    return state.esp.box
end, function(value)
    state.esp.box = value
end)
addToggleRow(ui.sections.ESP, "Name ESP", 4, function()
    return state.esp.name
end, function(value)
    state.esp.name = value
end)
addToggleRow(ui.sections.ESP, "Distance ESP", 5, function()
    return state.esp.distance
end, function(value)
    state.esp.distance = value
end)
addToggleRow(ui.sections.ESP, "Health ESP", 6, function()
    return state.esp.health
end, function(value)
    state.esp.health = value
end)
addToggleRow(ui.sections.ESP, "Team colors", 7, function()
    return state.esp.teamColors
end, function(value)
    state.esp.teamColors = value
end)
addToggleRow(ui.sections.ESP, "Tracers", 8, function()
    return state.esp.tracers
end, function(value)
    state.esp.tracers = value
end)
addStepperRow(ui.sections.ESP, "Max render distance", 9, function()
    return state.esp.maxRenderDistance
end, function(value)
    state.esp.maxRenderDistance = value
end, 50, 100, 2500)
ui.infoLabels.ESP = create("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(16, 20, 26),
    Size = UDim2.new(1, 0, 0, 150),
    Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(149, 255, 193),
    TextSize = 14,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 10,
    Parent = ui.sections.ESP,
})
createCorner(ui.infoLabels.ESP, 10)
createStroke(ui.infoLabels.ESP, Color3.fromRGB(88, 99, 116))

addSectionTitle(ui.sections.Config, "Configuration Management", 1)
addButton(ui.sections.Config, "Load Default", 2, function()
    applyConfig("Default")
end)
addButton(ui.sections.Config, "Load Smooth", 3, function()
    applyConfig("Smooth")
end)
addButton(ui.sections.Config, "Load Aggressive", 4, function()
    applyConfig("Aggressive")
end)
addButton(ui.sections.Config, "Save Current -> Default", 5, function()
    saveCurrentConfig("Default")
end)
addButton(ui.sections.Config, "Save Current -> Smooth", 6, function()
    saveCurrentConfig("Smooth")
end)
addButton(ui.sections.Config, "Save Current -> Aggressive", 7, function()
    saveCurrentConfig("Aggressive")
end)
addButton(ui.sections.Config, "Reset to Defaults", 8, function()
    resetDefaults()
end)
ui.infoLabels.Config = create("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(16, 20, 26),
    Size = UDim2.new(1, 0, 0, 210),
    Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(149, 255, 193),
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 9,
    Parent = ui.sections.Config,
})
createCorner(ui.infoLabels.Config, 10)
createStroke(ui.infoLabels.Config, Color3.fromRGB(88, 99, 116))

ui.statusLabel = create("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(26, 31, 39),
    Position = UDim2.new(0, 18, 1, -46),
    Size = UDim2.new(1, -36, 0, 28),
    Font = Enum.Font.Gotham,
    Text = "Ready. Press RightShift to hide/show the prototype menu.",
    TextColor3 = Color3.fromRGB(216, 222, 233),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = menuFrame,
})
createCorner(ui.statusLabel, 8)
createStroke(ui.statusLabel, Color3.fromRGB(88, 99, 116))

refreshTabVisibility()
updateInfoLabels()

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.RightShift then
        state.menuOpen = not state.menuOpen
        ui.menuFrame.Visible = state.menuOpen
        setStatus(state.menuOpen and "Menu shown." or "Menu hidden. Press RightShift to show again.")
    end
end)

setStatus("Prototype menu loaded. UI values update immediately, but no gameplay automation is included.")
