-- macele fofa | Flee the Facility | Xeno | v2.2
-- Interface local. ESP, Anti-Fail, Crawl, Camera, Staff.
-- Sem codigo externo ou APIs de hook. Desative/feche para parar as funcoes.
-- Algumas funcoes dependem de sinais replicados pelo servidor e exigem teste.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn("[macele fofa] Execute esta interface no cliente, em um LocalScript.")
    return
end

local player = Players.LocalPlayer
if not player then
    warn("[macele fofa] LocalPlayer ainda nao esta disponivel.")
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[macele fofa] PlayerGui nao ficou disponivel. Aguarde o jogo carregar.")
    return
end
local GUI_NAME = "SHY_Hub_Base_Interface_UI"
local RUN_ID = game:GetService("HttpService"):GenerateGUID(false)
local WIDTH, HEIGHT = 640, 460
-- Usernames exatos; UserIds resolvidos uma unica vez em segundo plano.
local SPECIAL_USERNAMES = { "or3orw" }
local SPECIAL_USERNAME_SET = { or3orw = true }
local STAFF_GROUP_ID = 3182154 -- Grupo oficial A.W. Apps
local BUBBLE_SIZE, MARGIN, DRAG_THRESHOLD = 54, 8, 6

local C = {
    window = Color3.fromRGB(19, 20, 28),
    sidebar = Color3.fromRGB(23, 24, 33),
    panel = Color3.fromRGB(26, 27, 37),
    line = Color3.fromRGB(47, 48, 63),
    text = Color3.fromRGB(239, 239, 247),
    muted = Color3.fromRGB(143, 145, 164),
    accent = Color3.fromRGB(181, 164, 255),
    selected = Color3.fromRGB(47, 40, 68),
    hover = Color3.fromRGB(35, 36, 48),
    danger = Color3.fromRGB(103, 43, 59),
}

local F = {
    title = Enum.Font.Michroma,
    body = Enum.Font.BuilderSans,
    medium = Enum.Font.BuilderSansMedium,
    bold = Enum.Font.BuilderSansBold,
}

local connections = {}
local alive = true
local state = "open"
local initialized = false
local activeDrag = nil
local lastBubblePress = nil
local bubbleWasDragged = true

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", parent, { CornerRadius = UDim.new(0, radius) })
end

local function outline(parent, color, transparency)
    return make("UIStroke", parent, {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function frame(parent, name, position, size, color)
    return make("Frame", parent, {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = color or C.panel,
        BorderSizePixel = 0,
    })
end

local function label(parent, name, text, position, size, textSize, color, font)
    return make("TextLabel", parent, {
        Name = name,
        Text = text,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = textSize or 14,
        TextColor3 = color or C.text,
        Font = font or F.body,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Active = false,
    })
end

local function button(parent, name, position, size, color)
    return make("TextButton", parent, {
        Name = name,
        Position = position,
        Size = size,
        Text = "",
        BackgroundColor3 = color or C.panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
    })
end

local gui = make("ScreenGui", nil, {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
})

-- Root permanece visivel: janela e bolinha sao IRMAS, nao pai e filha.
local root = frame(gui, "Root", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
root.BackgroundTransparency = 1
root.Active = false

local window = frame(root, "Window", UDim2.fromOffset(0, 0), UDim2.fromOffset(WIDTH, HEIGHT), C.window)
window.Visible = false
window.Active = true
corner(window, 16)
outline(window, C.line)
local windowScale = make("UIScale", window, { Scale = 1 })

-- O alvo de arraste termina ANTES dos botoes de minimizar e fechar.
local dragHandle = button(window, "DragHandle", UDim2.fromOffset(0, 0), UDim2.new(1, -108, 0, 72))
dragHandle.BackgroundTransparency = 1
dragHandle.Selectable = false
dragHandle.Modal = false -- Modal sera ligado apenas com o menu aberto.

local brand = frame(dragHandle, "Brand", UDim2.fromOffset(20, 18), UDim2.fromOffset(36, 36), C.selected)
corner(brand, 11)
local brandLetter = label(brand, "Letter", "♥", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), 21, C.accent, F.bold)
brandLetter.TextXAlignment = Enum.TextXAlignment.Center
label(dragHandle, "Title", "macele fofa", UDim2.fromOffset(68, 22), UDim2.fromOffset(280, 30), 19, C.text, F.title)

local minimizeButton = button(window, "Minimize", UDim2.new(1, -96, 0, 21), UDim2.fromOffset(32, 30), C.panel)
local closeButton = button(window, "Close", UDim2.new(1, -54, 0, 21), UDim2.fromOffset(32, 30), C.panel)
corner(minimizeButton, 8)
corner(closeButton, 8)
frame(minimizeButton, "Minus", UDim2.fromOffset(10, 15), UDim2.fromOffset(12, 2), C.muted)
for _, angle in ipairs({ 45, -45 }) do
    local line = frame(closeButton, "Cross", UDim2.fromOffset(16, 15), UDim2.fromOffset(13, 2), C.muted)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Rotation = angle
end

frame(window, "HeaderLine", UDim2.fromOffset(20, 71), UDim2.new(1, -40, 0, 1), C.line)

local sidebar = frame(window, "Sidebar", UDim2.fromOffset(14, 86), UDim2.new(0, 154, 1, -130), C.sidebar)
corner(sidebar, 12)

local content = frame(window, "Content", UDim2.fromOffset(184, 87), UDim2.new(1, -204, 1, -108))
content.BackgroundTransparency = 1
local pageTitle = label(content, "PageTitle", "Visual", UDim2.fromOffset(0, 1), UDim2.new(1, 0, 0, 30), 24, C.text, F.bold)

-- Cada aba tem seu proprio Frame vazio para receber futuras opcoes.
local pagesHolder = frame(content, "Pages", UDim2.fromOffset(0, 45), UDim2.new(1, 0, 1, -45), C.panel)
corner(pagesHolder, 12)
outline(pagesHolder, C.line, 0.35)


local tabNames = { "Visual", "Survivor", "Beast", "Extras" }
local tabs = {}
local pages = {}
local selectedTab = nil

local function setTabActive(name, selected)
    local tab = tabs[name]
    tab.button.BackgroundColor3 = selected and C.selected or C.sidebar
    tab.title.TextColor3 = selected and C.text or C.muted
    tab.marker.Visible = selected
    pages[name].Visible = selected
end

local function selectTab(name)
    if not alive or not pages[name] or selectedTab == name then
        return
    end
    if selectedTab then
        setTabActive(selectedTab, false)
    end
    selectedTab = name
    pageTitle.Text = name
    setTabActive(name, true)
end

for index, name in ipairs(tabNames) do
    local tabButton = button(sidebar, name .. "Tab", UDim2.fromOffset(8, 14 + (index - 1) * 49), UDim2.new(1, -16, 0, 41), C.sidebar)
    corner(tabButton, 8)
    local marker = frame(tabButton, "Marker", UDim2.fromOffset(0, 12), UDim2.fromOffset(3, 17), C.accent)
    corner(marker, 2)
    marker.Visible = false
    local title = label(tabButton, "Title", name, UDim2.fromOffset(16, 0), UDim2.new(1, -26, 1, 0), 15, C.muted, F.medium)
    local page = frame(pagesHolder, name .. "Page", UDim2.fromOffset(14, 14), UDim2.new(1, -28, 1, -28))
    page.BackgroundTransparency = 1
    page.Visible = false
    pages[name] = page
    tabs[name] = { button = tabButton, title = title, marker = marker }

    connect(tabButton.Activated, function()
        selectTab(name)
    end)
    connect(tabButton.MouseEnter, function()
        if selectedTab ~= name then
            tabButton.BackgroundColor3 = C.hover
        end
    end)
    connect(tabButton.MouseLeave, function()
        if selectedTab ~= name then
            tabButton.BackgroundColor3 = C.sidebar
        end
    end)
end

local bubble = button(root, "Bubble", UDim2.fromOffset(MARGIN, MARGIN), UDim2.fromOffset(BUBBLE_SIZE, BUBBLE_SIZE), C.selected)
bubble.Visible = false
bubble.Modal = false -- A bolinha nao pode liberar o mouse da Beast.
bubble.Text = "♥"
bubble.TextSize = 25
bubble.Font = F.bold
bubble.TextColor3 = C.accent
corner(bubble, BUBBLE_SIZE / 2)
outline(bubble, C.accent, 0.15)

local function hover(target, baseColor, hoverColor)
    connect(target.MouseEnter, function()
        target.BackgroundColor3 = hoverColor
    end)
    connect(target.MouseLeave, function()
        target.BackgroundColor3 = baseColor
    end)
end
hover(minimizeButton, C.panel, C.hover)
hover(closeButton, C.panel, C.danger)
hover(bubble, C.selected, Color3.fromRGB(62, 51, 90))

local function dimensions(target)
    if target == window then
        return WIDTH * windowScale.Scale, HEIGHT * windowScale.Scale
    end
    return BUBBLE_SIZE, BUBBLE_SIZE
end

local function place(target, x, y)
    local available = root.AbsoluteSize
    local width, height = dimensions(target)
    x = math.clamp(x, MARGIN, math.max(MARGIN, available.X - width - MARGIN))
    y = math.clamp(y, MARGIN, math.max(MARGIN, available.Y - height - MARGIN))
    -- Na borda da tela, nao reescreve a mesma posicao a cada movimento.
    local position = target.Position
    if position.X.Offset ~= x or position.Y.Offset ~= y then
        target.Position = UDim2.fromOffset(x, y)
    end
end

local function cancelAllDrags()
    activeDrag = nil
    lastBubblePress = nil
    bubbleWasDragged = true
end

local function syncVisibility()
    window.Visible = alive and initialized and state == "open"
    bubble.Visible = alive and initialized and state == "minimized"
    -- Na janela aberta o mouse fica livre para mexer nos botoes.
    -- Minimizando, nenhum GuiButton modal deve destravar a mira da Beast.
    dragHandle.Modal = window.Visible
    bubble.Modal = false
end

local function fitToScreen()
    if not alive then
        return
    end
    local available = root.AbsoluteSize
    if available.X <= MARGIN * 2 or available.Y <= MARGIN * 2 then
        return
    end
    cancelAllDrags()
    windowScale.Scale = math.min(1, (available.X - MARGIN * 2) / WIDTH, (available.Y - MARGIN * 2) / HEIGHT)
    if not initialized then
        local width, height = dimensions(window)
        place(window, (available.X - width) / 2, (available.Y - height) / 2)
        place(bubble, window.Position.X.Offset, window.Position.Y.Offset)
        initialized = true
    else
        place(window, window.Position.X.Offset, window.Position.Y.Offset)
        place(bubble, bubble.Position.X.Offset, bubble.Position.Y.Offset)
    end
    syncVisibility()
end

local bubblePositioned = false
local function minimize()
    if not alive or not initialized or state ~= "open" then
        return
    end
    cancelAllDrags()
    if not bubblePositioned then
        place(bubble, window.Position.X.Offset, window.Position.Y.Offset)
        bubblePositioned = true
    end
    state = "minimized"
    syncVisibility()
end

local function restore()
    if not alive or state ~= "minimized" then
        return
    end
    cancelAllDrags()
    place(window, window.Position.X.Offset, window.Position.Y.Offset)
    state = "open"
    syncVisibility()
end

-- Um unico conjunto de eventos globais atende os dois alvos.
-- Nenhum loop, Heartbeat ou RenderStepped para mover a interface.
local function draggable(handle, target)
    connect(handle.InputBegan, function(input)
        local kind = input.UserInputType
        if not alive or not target.Visible or activeDrag then
            return
        end
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
            return
        end
        activeDrag = {
            input = input,
            target = target,
            mouse = kind == Enum.UserInputType.MouseButton1,
            startX = input.Position.X,
            startY = input.Position.Y,
            x = target.Position.X.Offset,
            y = target.Position.Y.Offset,
            moved = false,
        }
        if target == bubble then
            lastBubblePress = input
            bubbleWasDragged = false
        end
    end)
end

draggable(dragHandle, window)
draggable(bubble, bubble)

connect(UserInputService.InputChanged, function(input)
    local drag = activeDrag
    if not alive or not drag or not drag.target.Visible then
        return
    end
    if (drag.mouse and input.UserInputType ~= Enum.UserInputType.MouseMovement)
        or (not drag.mouse and input ~= drag.input) then
        return
    end
    local dx, dy = input.Position.X - drag.startX, input.Position.Y - drag.startY
    if not drag.moved and dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then
        return
    end
    drag.moved = true
    if drag.target == bubble then
        bubbleWasDragged = true
    end
    place(drag.target, drag.x + dx, drag.y + dy)
end)

connect(UserInputService.InputEnded, function(input)
    local drag = activeDrag
    if not drag then
        return
    end
    if input == drag.input or (drag.mouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
        if input.UserInputState == Enum.UserInputState.Cancel and drag.target == bubble then
            bubbleWasDragged = true
        end
        activeDrag = nil
    end
end)

connect(UserInputService.WindowFocusReleased, cancelAllDrags)

-- O bloqueio permanece depois de soltar: arrastar a bolinha nao a abre.
-- Funciona com Activated vindo antes ou depois de InputEnded.
local function bubbleCanActivate(input)
    if input and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
        if not lastBubblePress or bubbleWasDragged then
            return false
        end
        return input.UserInputType ~= Enum.UserInputType.Touch or input == lastBubblePress
    end
    return true
end

-- VISUAL ESP: leitura local; nao envia eventos nem altera PCs/jogadores.
-- Adaptador FTF: ComputerTable/Screen e TempPlayerStatsModule/IsBeast.
-- Amarelo: interacao/progresso quando replicados; fallback por digitacao
-- ou personagem ancorado, livre e voltado para um PC proximo (estimativa).
-- Sem dados de uso, nao usa somente proximidade para amarelo.
local function createVisualESP()
    local Workspace = game:GetService("Workspace")
    local UPDATE_INTERVAL = 0.35
    local colors = {
        survivor = Color3.fromRGB(70, 230, 128),
        beast = Color3.fromRGB(255, 72, 87),
        idle = Color3.fromRGB(72, 150, 255),
        failed = Color3.fromRGB(255, 72, 87),
        hacking = Color3.fromRGB(255, 210, 70),
        complete = Color3.fromRGB(70, 230, 128),
    }
    local enabled = { players = false, computers = false }
    local specialUserIds = {}
    local destroyed = false
    task.spawn(function()
        for _, username in ipairs(SPECIAL_USERNAMES) do
            if destroyed then return end
            local ok, id = pcall(function()
                return Players:GetUserIdFromNameAsync(username)
            end)
            if ok and type(id) == "number" and id > 0 then
                specialUserIds[id] = true
            end
        end
    end)
    local folder, timer, scanTimer = nil, nil, nil
    local generation, scanGeneration = 0, 0
    local playersESP, computers, progressByPlayer = {}, {}, {}
    local computerAdded, computerRemoved = nil, nil

    local function destroyObject(object)
        if object then object:Destroy() end
    end

    local function cancelTask(thread)
        if thread then pcall(task.cancel, thread) end
    end

    local function getFolder()
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "macele_VisualESP"
            folder.Parent = Workspace
        end
        return folder
    end

    local function highlight(target, color)
        local object = Instance.new("Highlight")
        object.Name = "macele_Outline"
        object.Adornee = target
        object.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        object.FillTransparency = 1
        object.OutlineTransparency = 0.2
        object.OutlineColor = color
        object.Parent = getFolder()
        return object
    end

    local function readValue(parent, name, className)
        local value = parent and parent:FindFirstChild(name)
        if value and value:IsA(className) then return value.Value end
        return nil
    end

    local function beastFlag(subject, stats)
        local value = readValue(stats, "IsBeast", "BoolValue")
        if value ~= nil then return value end
        local character = subject.Character
        return character and character:FindFirstChild("BeastPowers") ~= nil or false
    end

    local function isSpecialPlayer(subject)
        return specialUserIds[subject.UserId] == true
            or SPECIAL_USERNAME_SET[string.lower(subject.Name)] == true
    end

    local function createBadge(character, adornee, title, isHeart)
        local badge = Instance.new("BillboardGui")
        badge.Name = isHeart and "macele_Heart" or "macele_Name"
        badge.Adornee = adornee
        badge.AlwaysOnTop = true
        badge.LightInfluence = 0
        badge.MaxDistance = 2500
        badge.Size = isHeart and UDim2.fromOffset(58, 56) or UDim2.fromOffset(210, 32)
        badge.StudsOffset = isHeart and Vector3.new(0, 0.15, 0) or Vector3.new(0, 2.6, 0)
        badge.Parent = getFolder()
        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.fromScale(1, 1)
        txt.Text = title
        txt.TextScaled = false
        txt.TextSize = isHeart and 35 or 17
        txt.Font = Enum.Font.GothamBold
        txt.TextColor3 = Color3.fromRGB(179, 105, 255)
        txt.TextStrokeTransparency = 0.25
        txt.TextStrokeColor3 = Color3.fromRGB(18, 10, 28)
        txt.Parent = badge
        return badge
    end

    local function destroyPlayerEntry(entry)
        if not entry then return end
        destroyObject(entry.highlight)
        destroyObject(entry.nameBadge)
        destroyObject(entry.heartBadge)
    end

    local function computerFromReference(reference)
        while reference and reference ~= Workspace do
            if computers[reference] then return reference end
            reference = reference.Parent
        end
        return nil
    end

    local function computerScreen(model)
        local screen = model:FindFirstChild("Screen", true)
        return screen and screen:IsA("BasePart") and screen or nil
    end

    local function removeComputer(model)
        local entry = computers[model]
        if not entry then return end
        computers[model] = nil
        destroyObject(entry.highlight)
    end

    local function addComputer(model)
        if destroyed or not enabled.computers or computers[model]
            or model.Name ~= "ComputerTable"
            or not (model:IsA("Model") or model:IsA("BasePart"))
            or not model:IsDescendantOf(Workspace) then
            return
        end
        computers[model] = {
            highlight = highlight(model, colors.idle),
            screen = computerScreen(model),
            activeUntil = 0,
        }
    end

    local function updatePlayers(list)
        local seen = {}
        for _, subject in ipairs(list) do
            local character = subject.Character
            local special = isSpecialPlayer(subject)
            -- O proprio jogador so recebe ESP quando estiver na lista especial.
            if (subject ~= player or special) and character and character:IsDescendantOf(Workspace) then
                seen[subject] = true
                local entry = playersESP[subject]
                local stats = subject:FindFirstChild("TempPlayerStatsModule")
                local color = special and Color3.fromRGB(179, 105, 255)
                    or (beastFlag(subject, stats) and colors.beast or colors.survivor)
                if not entry or entry.character ~= character then
                    destroyPlayerEntry(entry)
                    entry = { character = character, highlight = highlight(character, color) }
                    playersESP[subject] = entry
                end
                if entry.highlight.OutlineColor ~= color then
                    entry.highlight.OutlineColor = color
                end
                if special then
                    local head = character:FindFirstChild("Head")
                    local torso = character:FindFirstChild("UpperTorso")
                        or character:FindFirstChild("Torso")
                        or character:FindFirstChild("HumanoidRootPart")
                    if head and not entry.nameBadge then
                        entry.nameBadge = createBadge(character, head, subject.Name, false)
                    end
                    if torso and not entry.heartBadge then
                        entry.heartBadge = createBadge(character, torso, "♥", true)
                    end
                else
                    destroyObject(entry.nameBadge)
                    destroyObject(entry.heartBadge)
                    entry.nameBadge, entry.heartBadge = nil, nil
                end
            end
        end
        for subject, entry in pairs(playersESP) do
            if not seen[subject] then
                destroyPlayerEntry(entry)
                playersESP[subject] = nil
            end
        end
    end

    local function nearTypingComputer(character, typing)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if not rootPart or not rootPart:IsA("BasePart") then return nil end
        local anchored = rootPart.Anchored or (torso and torso:IsA("BasePart") and torso.Anchored)
        if not typing and not anchored then return nil end
        local nearest, nearestDistance = nil, 9
        for model, entry in pairs(computers) do
            local screen = entry.screen
            if screen and screen:IsDescendantOf(model) then
                local delta = screen.Position - rootPart.Position
                local distance = delta.Magnitude
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                local facing = horizontal.Magnitude < 0.1
                    or rootPart.CFrame.LookVector:Dot(horizontal.Unit) >= 0.35
                if distance < nearestDistance and math.abs(delta.Y) < 5 and facing then
                    nearest, nearestDistance = model, distance
                end
            end
        end
        return nearest
    end

    local function findActiveComputers(list, now)
        local active, present = {}, {}
        for _, subject in ipairs(list) do
            present[subject] = true
            local character = subject.Character
            local stats = subject:FindFirstChild("TempPlayerStatsModule")
            local inGame = readValue(stats, "IsInGame", "BoolValue")
            local captured = readValue(stats, "Captured", "BoolValue")
            local ragdoll = readValue(stats, "Ragdoll", "BoolValue")
            local health = readValue(stats, "Health", "NumberValue")
            if character and character:IsDescendantOf(Workspace) and not beastFlag(subject, stats)
                and not captured and not ragdoll and inGame ~= false and (not health or health > 0) then
                local action = readValue(stats, "ActionEvent", "ObjectValue")
                local linked = computerFromReference(action)
                local animation = string.lower(tostring(readValue(stats, "CurrentAnimation", "StringValue") or ""))
                local typing = animation == "typing" or animation == "hacking" or animation == "hack"
                local input = readValue(stats, "ActionInput", "BoolValue")
                local progress = readValue(stats, "ActionProgress", "NumberValue")
                local previous = progressByPlayer[subject]
                if not previous or previous.action ~= action then
                    previous = { action = action, value = progress, untilTime = 0 }
                    progressByPlayer[subject] = previous
                end
                if linked and type(progress) == "number" and type(previous.value) == "number"
                    and progress > previous.value then
                    previous.untilTime = now + 0.6
                elseif type(progress) == "number" and type(previous.value) == "number"
                    and progress < previous.value then
                    previous.untilTime = 0
                end
                previous.value = progress
                if linked and (typing or input == true or previous.untilTime > now) then
                    active[linked] = true
                elseif not action then
                    -- Ancoragem e orientacao sao fallback, nao confirmacao do servidor.
                    local nearby = nearTypingComputer(character, typing)
                    if nearby then active[nearby] = true end
                end
            else
                progressByPlayer[subject] = nil
            end
        end
        for subject in pairs(progressByPlayer) do
            if not present[subject] then progressByPlayer[subject] = nil end
        end
        return active
    end

    local function updateComputers(list, now)
        for model, entry in pairs(computers) do
            if not model:IsDescendantOf(Workspace) then
                removeComputer(model)
            elseif not entry.screen or not entry.screen:IsDescendantOf(model) then
                entry.screen = computerScreen(model)
            end
        end
        local active = findActiveComputers(list, now)
        for model, entry in pairs(computers) do
            -- Progresso direto, quando existir; nao presume escala 0-1 ou 0-100.
            local progress = model:FindFirstChild("Progress") or model:FindFirstChild("HackProgress")
            if progress and (progress:IsA("NumberValue") or progress:IsA("IntValue")) then
                local value = progress.Value
                if entry.progressObject == progress and entry.progress ~= nil and value > entry.progress then
                    entry.activeUntil = now + 0.6
                elseif entry.progressObject ~= progress or (entry.progress and value < entry.progress) then
                    entry.activeUntil = 0
                end
                entry.progressObject, entry.progress = progress, value
            else
                entry.progressObject, entry.progress, entry.activeUntil = nil, nil, 0
            end
            local color = colors.idle
            local screen = entry.screen
            local complete, failed = false, false
            if screen then
                local hue, saturation, value = screen.Color:ToHSV()
                local colored = saturation > 0.45 and value > 0.1
                complete = colored and hue >= 0.22 and hue <= 0.45
                failed = colored and (hue < 0.07 or hue > 0.93)
            end
            -- Prioridade: completo > erro > em uso > disponivel.
            if complete then color = colors.complete
            elseif failed then color = colors.failed
            elseif active[model] or entry.activeUntil > now then color = colors.hacking end
            if entry.highlight.OutlineColor ~= color then entry.highlight.OutlineColor = color end
        end
    end

    local function stopComputers()
        scanGeneration = scanGeneration + 1
        cancelTask(scanTimer)
        scanTimer = nil
        if computerAdded then computerAdded:Disconnect() computerAdded = nil end
        if computerRemoved then computerRemoved:Disconnect() computerRemoved = nil end
        for model in pairs(computers) do removeComputer(model) end
        table.clear(progressByPlayer)
    end

    local function startComputers()
        computerAdded = Workspace.DescendantAdded:Connect(addComputer)
        computerRemoved = Workspace.DescendantRemoving:Connect(removeComputer)
        scanGeneration = scanGeneration + 1
        local token, stack = scanGeneration, { Workspace }
        local function batch()
            scanTimer = nil
            if destroyed or not enabled.computers or token ~= scanGeneration then return end
            -- Descoberta em lotes; depois acompanha entrada/saida de objetos.
            for _ = 1, 100 do
                local object = table.remove(stack)
                if not object then return end
                if object ~= folder then
                    addComputer(object)
                    for _, child in ipairs(object:GetChildren()) do stack[#stack + 1] = child end
                end
            end
            if #stack > 0 then scanTimer = task.delay(0.02, batch) end
        end
        scanTimer = task.defer(batch)
    end

    local function startTimer()
        if timer then return end
        generation = generation + 1
        local token = generation
        local function tick()
            timer = nil
            if destroyed or token ~= generation or not (enabled.players or enabled.computers) then return end
            local list = Players:GetPlayers()
            if enabled.players then updatePlayers(list) end
            if enabled.computers then updateComputers(list, os.clock()) end
            timer = task.delay(UPDATE_INTERVAL, tick)
        end
        timer = task.defer(tick)
    end

    local controller = {}
    function controller:Set(kind, value)
        if destroyed or enabled[kind] == nil or enabled[kind] == value then return end
        enabled[kind] = value
        if kind == "computers" then
            if value then startComputers() else stopComputers() end
        elseif not value then
            for subject, entry in pairs(playersESP) do
                destroyPlayerEntry(entry)
                playersESP[subject] = nil
            end
        end
        if enabled.players or enabled.computers then
            startTimer()
        else
            generation = generation + 1
            cancelTask(timer)
            timer = nil
            destroyObject(folder)
            folder = nil
        end
    end

    function controller:Destroy()
        if destroyed then return end
        destroyed = true
        enabled.players, enabled.computers = false, false
        generation = generation + 1
        cancelTask(timer)
        timer = nil
        stopComputers()
        destroyObject(folder)
        folder = nil
        for subject, entry in pairs(playersESP) do
            destroyPlayerEntry(entry)
            playersESP[subject] = nil
        end
    end
    return controller
end

local visualESP = createVisualESP()

local function addVisualToggle(name, title, description, y, height, kind)
    local row = button(pages.Visual, name, UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, height), C.sidebar)
    corner(row, 9)
    label(row, "Title", title, UDim2.fromOffset(12, 10), UDim2.new(1, -82, 0, 23), 15, C.text, F.bold)
    local desc = label(row, "Description", description, UDim2.fromOffset(12, 35), UDim2.new(1, -82, 0, height - 42), 11, C.muted)
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    local track = frame(row, "Switch", UDim2.new(1, -54, 0.5, -11), UDim2.fromOffset(40, 22), C.line)
    corner(track, 11)
    local knob = frame(track, "Knob", UDim2.fromOffset(4, 4), UDim2.fromOffset(14, 14), C.muted)
    corner(knob, 7)
    local on = false
    connect(row.Activated, function()
        if not alive then return end
        on = not on
        visualESP:Set(kind, on)
        knob.Position = UDim2.fromOffset(on and 22 or 4, 4)
        knob.BackgroundColor3 = on and C.accent or C.muted
        track.BackgroundColor3 = on and C.selected or C.line
    end)
end

addVisualToggle("PlayerESP", "ESP Player", "Verde: Survivor  •  Vermelho: Beast  •  Roxo: or3orw ♥", 0, 74, "players")
addVisualToggle("ComputerESP", "ESP Computers", "Azul: livre  •  Amarelo: em uso  •  Vermelho: erro  •  Verde: pronto", 84, 82, "computers")


-- COMPUTER ANTI-FAIL | XENO COMPATIVEL (sem hooks/metatables)
-- Metodo observado em scripts publicos do Flee the Facility:
-- RemoteEvent:FireServer("SetPlayerMinigameResult", true) repetidamente.
-- O cliente nao consegue comprovar sozinho que o servidor aceitou a mensagem.
-- Evita tarefas duplicadas, pausa fora da partida e encerra ao desativar.
local function createComputerAntiFail()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local enabled, destroyed = false, false
    local generation, sent, errors = 0, 0, 0
    local statusCallback = nil
    local lastStatus, lastMessage = 0, nil

    local function setStatus(message, force)
        local now = os.clock()
        if statusCallback and (force or now - lastStatus >= 1.0) then
            lastStatus, lastMessage = now, message
            statusCallback(message)
        end
    end

    local function readBool(stats, name)
        local object = stats and stats:FindFirstChild(name)
        if object and object:IsA("BoolValue") then
            return object.Value
        end
        return nil
    end

    local function allowedToSend()
        local stats = player:FindFirstChild("TempPlayerStatsModule")
        if readBool(stats, "IsInGame") == false then
            return false
        end
        if readBool(stats, "Captured") == true then
            return false
        end
        if readBool(stats, "IsBeast") == true then
            return false
        end
        local character = player.Character
        if character and character:FindFirstChild("BeastPowers") then
            return false
        end
        return true
    end

    local controller = {}

    function controller:OnStatus(callback)
        statusCallback = callback
    end

    function controller:SetEnabled(value)
        if destroyed then
            return false, "A interface foi encerrada."
        end
        if not value then
            enabled = false
            generation = generation + 1
            setStatus("Desligado. Nenhum resultado extra sera enviado.", true)
            return true
        end
        if enabled then
            return true
        end

        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if not remote or not remote:IsA("RemoteEvent") then
            return false, "RemoteEvent nao encontrado. Entre no FTF e aguarde carregar."
        end

        enabled = true
        generation = generation + 1
        local token = generation
        sent, errors = 0, 0
        setStatus("Ativo. Aguardando minigames na partida...", true)

        task.spawn(function()
            while enabled and not destroyed and token == generation do
                local current = ReplicatedStorage:FindFirstChild("RemoteEvent")
                if not current or not current:IsA("RemoteEvent") then
                    setStatus("Ativo, mas RemoteEvent indisponivel.")
                elseif not allowedToSend() then
                    setStatus("Ativo. Pausado fora do jogo / como Beast.")
                else
                    -- Nao depende de hookmetamethod, newcclosure ou getgenv.
                    local success, problem = pcall(function()
                        current:FireServer("SetPlayerMinigameResult", true)
                    end)
                    if success then
                        sent = sent + 1
                        setStatus("Ativo | resultados enviados: " .. sent .. " | erros: " .. errors)
                    else
                        errors = errors + 1
                        warn("[macele fofa] Anti-Fail FireServer: " .. tostring(problem))
                        setStatus("Falha no envio (" .. errors .. "). Verifique console F9.", true)
                        task.wait(0.65)
                    end
                end
                task.wait(0.1)
            end
        end)
        return true
    end

    function controller:Destroy()
        if destroyed then return end
        enabled = false
        generation = generation + 1
        destroyed = true
        statusCallback = nil
    end

    return controller
end

local computerAntiFail = createComputerAntiFail()
do
    local row = button(pages.Survivor, "ComputerAntiFail", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 74), C.sidebar)
    corner(row, 9)
    label(row, "Title", "Computer Anti-Fail", UDim2.fromOffset(12, 10), UDim2.new(1, -82, 0, 23), 15, C.text, F.bold)
    local description = label(row, "Description", "Impede o erro do PC (Xeno).", UDim2.fromOffset(12, 35), UDim2.new(1, -82, 0, 36), 11, C.muted)
    description.TextWrapped = true
    description.TextYAlignment = Enum.TextYAlignment.Top
    local track = frame(row, "Switch", UDim2.new(1, -54, 0.5, -11), UDim2.fromOffset(40, 22), C.line)
    corner(track, 11)
    local knob = frame(track, "Knob", UDim2.fromOffset(4, 4), UDim2.fromOffset(14, 14), C.muted)
    corner(knob, 7)
    local on = false

    computerAntiFail:OnStatus(function(message)
        if alive and on then
            -- Status tecnico vai ao console, sem encher a interface.
            if string.find(message, "Falha") or string.find(message, "indisponivel") then
                description.Text = message
                description.TextColor3 = Color3.fromRGB(255, 136, 149)
            end
        end
    end)

    connect(row.Activated, function()
        if not alive then return end
        local requested = not on
        local success, reason = computerAntiFail:SetEnabled(requested)
        if not success then
            description.Text = reason
            description.TextColor3 = Color3.fromRGB(255, 136, 149)
            return
        end
        on = requested
        knob.Position = UDim2.fromOffset(on and 22 or 4, 4)
        knob.BackgroundColor3 = on and C.accent or C.muted
        track.BackgroundColor3 = on and C.selected or C.line
        if not on then
            description.Text = "Impede o erro do PC (Xeno)."
        else
            description.Text = "Ligado"
        end
        description.TextColor3 = C.muted
    end)
end


-- Notificacoes discretas, compartilhadas pelas abas Survivor e Extras.
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local notifications = frame(root, "Notificacoes", UDim2.new(1, -16, 1, -14), UDim2.fromOffset(296, 285))
notifications.AnchorPoint = Vector2.new(1, 1)
notifications.BackgroundTransparency = 1
notifications.ZIndex = 25
local stack = make("UIListLayout", notifications, {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})
local notificationOrder = 0
local function toast(icon, title, body, tint)
    if not alive then return end
    notificationOrder = notificationOrder + 1
    local toastFrame = frame(notifications, "Toast", UDim2.fromOffset(0, 0), UDim2.fromOffset(296, 68), C.sidebar)
    toastFrame.LayoutOrder = notificationOrder
    toastFrame.ZIndex = 26
    toastFrame.BackgroundTransparency = 1
    corner(toastFrame, 11)
    outline(toastFrame, C.line, 0.15)
    local left = frame(toastFrame, "Color", UDim2.fromOffset(0, 8), UDim2.new(0, 4, 1, -16), tint or C.accent)
    left.ZIndex = 27
    corner(left, 2)
    local glyph = label(toastFrame, "Symbol", icon, UDim2.fromOffset(15, 13), UDim2.fromOffset(36, 42), 24, tint or C.accent, F.bold)
    glyph.TextXAlignment = Enum.TextXAlignment.Center
    glyph.ZIndex = 27
    local titleLabel = label(toastFrame, "Title", title, UDim2.fromOffset(56, 10), UDim2.fromOffset(226, 21), 14, C.text, F.bold)
    titleLabel.ZIndex = 27
    local subtitle = label(toastFrame, "Body", body, UDim2.fromOffset(56, 32), UDim2.fromOffset(226, 29), 11, C.muted)
    subtitle.TextWrapped = true
    subtitle.ZIndex = 27
    pcall(function()
        TweenService:Create(toastFrame, TweenInfo.new(0.22), {BackgroundTransparency = 0}):Play()
    end)
    task.delay(5.2, function()
        if toastFrame.Parent then
            pcall(function()
                TweenService:Create(toastFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            end)
            task.wait(0.28)
            if toastFrame.Parent then toastFrame:Destroy() end
        end
    end)
end

local function getStat(subject, key)
    local stats = subject and subject:FindFirstChild("TempPlayerStatsModule")
    local obj = stats and stats:FindFirstChild(key)
    if obj and obj:IsA("ValueBase") then return obj.Value end
    return nil
end
-- Papel local em cache: evita procurar todos os jogadores a cada quadro.
local cachedLocalBeast = false
local lastLocalBeastRead = -math.huge
local function isLocalBeast()
    local now = os.clock()
    if now - lastLocalBeastRead >= 0.20 then
        lastLocalBeastRead = now
        local role = getStat(player, "IsBeast")
        local character = player.Character
        cachedLocalBeast = role == true
            or (character ~= nil and character:FindFirstChild("BeastPowers") ~= nil)
    end
    return cachedLocalBeast
end

local function addCompactToggle(page, name, title, detail, y, changed)
    local row = button(pages[page], name, UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, 74), C.sidebar)
    corner(row, 9)
    label(row, "Title", title, UDim2.fromOffset(12, 10), UDim2.new(1, -76, 0, 23), 15, C.text, F.bold)
    local desc = label(row, "Description", detail, UDim2.fromOffset(12, 35), UDim2.new(1, -78, 0, 33), 11, C.muted)
    desc.TextWrapped = true
    local track = frame(row, "Switch", UDim2.new(1, -54, 0.5, -11), UDim2.fromOffset(40, 22), C.line)
    corner(track, 11)
    local knob = frame(track, "Knob", UDim2.fromOffset(4, 4), UDim2.fromOffset(14, 14), C.muted)
    corner(knob, 7)
    local enabled = false
    connect(row.Activated, function()
        if not alive then return end
        local wanted = not enabled
        local ok, result, reason = pcall(changed, wanted)
        if not ok or result == false then
            desc.Text = tostring((ok and reason) or result)
            desc.TextColor3 = Color3.fromRGB(255, 136, 149)
            return
        end
        enabled = wanted
        desc.Text = enabled and "Ligado" or detail
        desc.TextColor3 = C.muted
        knob.Position = UDim2.fromOffset(enabled and 22 or 4, 4)
        knob.BackgroundColor3 = enabled and C.accent or C.muted
        track.BackgroundColor3 = enabled and C.selected or C.line
    end)
    return row, desc
end

-- O FTF usa SHIFT para rastejar. A versao 2.0 erroneamente so atuava em Ragdoll.
-- Aprimorado pelo principio de WalkSpeed Lock (YAFTFEM), sem mudar speed em pe.
local function createNormalCrawl()
    local enabled, destroyed, generation = false, false, 0
    local normalSpeed = nil
    local observedHum, crawlSpeed = nil, nil
    local lastCrawling = false

    local function isCrawling(char, hum)
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if shift then return true end
        local stats = player:FindFirstChild("TempPlayerStatsModule")
        local holders = {}
        if stats then holders[#holders + 1] = stats end
        if char then holders[#holders + 1] = char end
        if hum then holders[#holders + 1] = hum end
        for _, holder in ipairs(holders) do
            if holder then
                for _, key in ipairs({"Crawling", "IsCrawling", "Crawl", "Crouching", "IsCrouching"}) do
                    local obj = holder:FindFirstChild(key)
                    if obj and obj:IsA("BoolValue") and obj.Value then return true end
                    if holder:GetAttribute(key) == true then return true end
                end
            end
        end
        return getStat(player, "Ragdoll") == true
    end

    local function update()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or getStat(player, "IsBeast") == true
            or (char and char:FindFirstChild("BeastPowers")) then
            observedHum, normalSpeed, crawlSpeed, lastCrawling = nil, nil, nil, false
            return
        end
        if observedHum ~= hum then
            observedHum, normalSpeed, crawlSpeed, lastCrawling = hum, nil, nil, false
        end
        local captured = getStat(player, "Captured") == true
        local crawling = not captured and isCrawling(char, hum)
        if not crawling then
            lastCrawling, crawlSpeed = false, nil
            -- Guarda a velocidade REAL de pe e nao um numero fixo arbitrario.
            if hum.WalkSpeed >= 10 then normalSpeed = hum.WalkSpeed end
            return
        end
        if not lastCrawling then
            crawlSpeed = hum.WalkSpeed
            lastCrawling = true
        end
        -- Se ligado ja agachado, 16 e apenas o fallback padrao do Roblox.
        local target = math.clamp(normalSpeed or 16, 10, 32)
        if hum.WalkSpeed < target then hum.WalkSpeed = target end
    end

    local controller = {}
    function controller:SetEnabled(value)
        if destroyed then return false, "Interface encerrada" end
        generation = generation + 1
        enabled = value
        if not value then
            if observedHum and observedHum.Parent and lastCrawling and crawlSpeed then
                pcall(function() observedHum.WalkSpeed = crawlSpeed end)
            end
            observedHum, normalSpeed, crawlSpeed, lastCrawling = nil, nil, nil, false
        else
            local token = generation
            task.spawn(function()
                while enabled and not destroyed and token == generation do
                    local ok, err = pcall(update)
                    if not ok then warn("[macele fofa] Crawl: " .. tostring(err)) end
                    task.wait(0.08)
                end
            end)
        end
        return true
    end
    function controller:Destroy() self:SetEnabled(false) destroyed = true end
    return controller
end

-- Terceira pessoa da Beast, com lock do mouse separado da camera.
local function createThirdPerson()
    local enabled, destroyed = false, false
    local stepName = "macele_ThirdPerson_" .. RUN_ID
    local oldMode, oldMin, oldMax = nil, nil, nil
    local distance = 10
    local controller = {}
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    local filteredCharacter = nil

    local function render()
        if not alive or not enabled or not isLocalBeast() then return end
        local camera = Workspace.CurrentCamera
        local char = player.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if not camera or not rootPart then return end
        if player.CameraMode ~= Enum.CameraMode.Classic then
            pcall(function() player.CameraMode = Enum.CameraMode.Classic end)
        end
        -- A CameraModule continua recebendo o movimento do mouse.
        local rotation = camera.CFrame.Rotation
        local forward = camera.CFrame.LookVector
        local focus = rootPart.Position + Vector3.new(0, 1.65, 0)
        local goal = focus - forward * distance
        if filteredCharacter ~= char then
            filteredCharacter = char
            rayParams.FilterDescendantsInstances = {char}
        end
        local hit = Workspace:Raycast(focus, goal - focus, rayParams)
        local target = hit and (hit.Position + forward * 0.35) or goal
        camera.CFrame = CFrame.new(target) * rotation
        camera.Focus = CFrame.new(focus)
    end
    function controller:SetEnabled(value)
        if destroyed then return false, "Interface encerrada" end
        if value == enabled then return true end
        enabled = value
        if value then
            oldMode, oldMin, oldMax = player.CameraMode, player.CameraMinZoomDistance, player.CameraMaxZoomDistance
            pcall(function()
                player.CameraMode = Enum.CameraMode.Classic
                player.CameraMaxZoomDistance = 25
                player.CameraMinZoomDistance = 0.5
            end)
            RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 5, render)
        else
            pcall(function() RunService:UnbindFromRenderStep(stepName) end)
            pcall(function()
                if oldMode then player.CameraMode = oldMode end
                if oldMax then player.CameraMaxZoomDistance = oldMax end
                if oldMin then player.CameraMinZoomDistance = oldMin end
            end)
        end
        return true
    end
    function controller:Destroy() self:SetEnabled(false) destroyed = true end
    return controller
end

-- Sempre que a Beast estiver jogando e o menu estiver minimizado,
-- recaptura o cursor APOS o camera script. A tela de configuracoes do Roblox
-- ou um TextBox em foco prevalecem (nao prender o mouse no menu do jogo).
local GuiService = game:GetService("GuiService")
local lockStepName = "macele_BeastMouse_" .. RUN_ID
local wasBeast = false
RunService:BindToRenderStep(lockStepName, Enum.RenderPriority.Camera.Value + 60, function()
    if not alive then return end
    local isBeast = isLocalBeast()
    -- Entrou na rodada como Beast: esconde o menu para nao soltar a mira.
    if isBeast and not wasBeast and state == "open" then minimize() end
    wasBeast = isBeast
    if state ~= "minimized" or not isBeast then return end
    if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return end
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

-- F4 alterna menu e bolinha, permitindo usar os controles quando necessario.
-- O mouse sera livre somente durante a configuracao da janela aberta.
connect(UserInputService.InputBegan, function(input, gameProcessed)
    if not alive or gameProcessed or input.KeyCode ~= Enum.KeyCode.F4 then return end
    if state == "open" then minimize() elseif state == "minimized" then restore() end
end)

-- Staff: apenas MOD / Admin do grupo oficial A.W. Apps.
-- Testadores, devs e moderadores gerais do Roblox nao sao includos.
local function createStaffDetector()
    local enabled, destroyed, generation = false, false, 0
    local addedConnection, removedConnection = nil, nil
    local reported = {}
    local function check(subject, token)
        if subject == player then return end
        local ok, role = pcall(function()
            return subject:GetRoleInGroup(STAFF_GROUP_ID)
        end)
        if not ok or token ~= generation or not enabled or destroyed then return end
        local name = string.lower(tostring(role or ""))
        local moderator = name:find("moderator", 1, true) or name == "mod" or name:find("[mod]", 1, true)
        local admin = name:find("admin", 1, true)
        if (moderator or admin) and not reported[subject.UserId] then
            reported[subject.UserId] = true
            toast("⚠", "Staff do Flee the Facility", subject.Name .. " • " .. tostring(role), Color3.fromRGB(255, 192, 91))
        end
    end
    local controller = {}
    function controller:SetEnabled(value)
        if destroyed then return false, "Interface encerrada" end
        generation = generation + 1
        enabled = value
        if addedConnection then addedConnection:Disconnect() addedConnection = nil end
        if removedConnection then removedConnection:Disconnect() removedConnection = nil end
        table.clear(reported)
        if value then
            local token = generation
            addedConnection = Players.PlayerAdded:Connect(function(subject)
                task.spawn(check, subject, token)
            end)
            removedConnection = Players.PlayerRemoving:Connect(function(subject)
                reported[subject.UserId] = nil
            end)
            for _, subject in ipairs(Players:GetPlayers()) do
                task.spawn(check, subject, token)
            end
        end
        return true
    end
    function controller:Destroy() self:SetEnabled(false) destroyed = true end
    return controller
end

local normalCrawl = createNormalCrawl()
local thirdPerson = createThirdPerson()
local staffDetector = createStaffDetector()

addCompactToggle("Survivor", "NormalCrawl", "Normal Crawl Speed", "Mantem WalkSpeed normal ao agachar ou rastejar.", 84,
    function(on) return normalCrawl:SetEnabled(on) end)
addCompactToggle("Beast", "ThirdPerson", "Third Person Beast", "Camera da Beast; F4 abre/fecha o menu.", 0,
    function(on) return thirdPerson:SetEnabled(on) end)
addCompactToggle("Extras", "StaffDetector", "Admin / Moderator Detector", "Somente moderadores e admins do FTF.", 0,
    function(on) return staffDetector:SetEnabled(on) end)

local function cleanup()
    if not alive then
        return
    end
    alive = false
    state = "closed"
    visualESP:Destroy()
    computerAntiFail:Destroy()
    normalCrawl:Destroy()
    thirdPerson:Destroy()
    pcall(function() RunService:UnbindFromRenderStep(lockStepName) end)
    staffDetector:Destroy()
    cancelAllDrags()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function close()
    cleanup()
    gui:Destroy()
end

local disposer = make("BindableFunction", gui, { Name = "Dispose" })
-- Retorna antes de o chamador destruir o BindableFunction.
disposer.OnInvoke = cleanup

connect(gui.Destroying, cleanup)
connect(minimizeButton.Activated, minimize)
connect(closeButton.Activated, close)
connect(bubble.Activated, function(input)
    if bubbleCanActivate(input) then
        restore()
    end
end)
connect(root:GetPropertyChangedSignal("AbsoluteSize"), fitToScreen)

selectTab("Visual")

-- A nova interface fica pronta antes de substituir a anterior.
-- Reexecutar limpa apenas outra copia DESTA base.
local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then
    local oldDisposer = previous:FindFirstChild("Dispose")
    if oldDisposer and oldDisposer:IsA("BindableFunction") then
        pcall(function()
            oldDisposer:Invoke()
        end)
    end
    previous:Destroy()
end
gui.Parent = playerGui
fitToScreen()

-- Ponto de extensao: pages.Visual, pages.Survivor, pages.Beast, pages.Extras.
-- Todas as opcoes iniciam desligadas. Xeno; nenhuma biblioteca externa.
return {
    Gui = gui,
    Pages = pages,
    SelectTab = selectTab,
    Minimize = minimize,
    Restore = restore,
    Destroy = close,
}
