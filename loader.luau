--!nocheck

-- Veltrax external key loader.
-- Recommended use: host this file publicly (for example on GitHub) and load
-- it first. It validates a key, stores it in getgenv().SCRIPT_KEY, then
-- requests the protected Veltrax Hub payload from JNKIE.

local SCRIPT_ID = "e655663b2a0c335d0dfaf711b448f1f0230e040ef683d3c1d5032dfbce6f9aa7"
local PUBLIC_SCRIPT_URL = "https://api.jnkie.com/api/v1/luascripts/public/"
    .. SCRIPT_ID
    .. "/download"
local SDK_URL = "https://jnkie.com/sdk/library.lua"
local SERVICE_NAME = "VeltraxHub"
local PROVIDER_NAME = "Veltrax Free"
local JNKIE_IDENTIFIER = "1189201"
local KEY_FOLDER = "VeltraxHub"
local KEY_FILE = KEY_FOLDER .. "/jnkie_key.txt"

local environment = getgenv and getgenv() or _G
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local function systemMessage(message, duration)
    local text = tostring(message)
    warn("[Veltrax Loader] " .. text)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Veltrax Hub",
            Text = text,
            Duration = duration or 8,
        })
    end)
end

if type(loadstring) ~= "function" then
    systemMessage("Executor incompatibil: functia loadstring nu este disponibila.", 12)
    return
end

local previousGui = environment.__VELTRAX_KEY_GUI
if typeof(previousGui) == "Instance" then
    pcall(function()
        previousGui:Destroy()
    end)
end

local sdkRequestOk, sdkSource = pcall(function()
    return game:HttpGet(SDK_URL)
end)

if not sdkRequestOk or type(sdkSource) ~= "string" or sdkSource == "" then
    systemMessage(
        "Eroare de retea: SDK-ul JNKIE nu a putut fi descarcat. Verifica internetul sau executorul.",
        12
    )
    return
end

local sdkCompileOk, sdkChunk = pcall(loadstring, sdkSource)
if not sdkCompileOk or type(sdkChunk) ~= "function" then
    systemMessage("Executor incompatibil: SDK-ul JNKIE nu poate fi compilat.", 12)
    return
end

local sdkRunOk, Junkie = pcall(sdkChunk)
if not sdkRunOk or type(Junkie) ~= "table" then
    systemMessage("SDK-ul JNKIE nu a pornit corect. Incearca din nou mai tarziu.", 12)
    return
end

if type(Junkie.check_key) ~= "function" or type(Junkie.get_key_link) ~= "function" then
    systemMessage("SDK-ul JNKIE este incomplet sau incompatibil cu acest executor.", 12)
    return
end

Junkie.service = SERVICE_NAME
Junkie.identifier = JNKIE_IDENTIFIER
Junkie.provider = PROVIDER_NAME
Junkie.script_id = SCRIPT_ID

local validated = false
local closed = false
local busy = false
local connections = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local gui = create("ScreenGui", {
    Name = "VeltraxKeySystem",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif protectgui then
        protectgui(gui)
    end
end)

local guiParent = CoreGui
pcall(function()
    if type(gethui) == "function" then
        guiParent = gethui()
    end
end)
gui.Parent = guiParent
environment.__VELTRAX_KEY_GUI = gui

local overlay = create("Frame", {
    Name = "Overlay",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(5, 5, 9),
    BackgroundTransparency = 0.28,
    BorderSizePixel = 0,
}, gui)

local main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(430, 300),
    BackgroundColor3 = Color3.fromRGB(17, 15, 25),
    BorderSizePixel = 0,
    Active = true,
}, overlay)
create("UICorner", { CornerRadius = UDim.new(0, 13) }, main)
create("UIStroke", {
    Color = Color3.fromRGB(137, 78, 224),
    Transparency = 0.3,
    Thickness = 1.3,
}, main)

local topBar = create("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(24, 19, 37),
    BorderSizePixel = 0,
    Active = true,
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 13) }, topBar)

create("Frame", {
    Position = UDim2.new(0, 0, 1, -13),
    Size = UDim2.new(1, 0, 0, 13),
    BackgroundColor3 = topBar.BackgroundColor3,
    BorderSizePixel = 0,
}, topBar)

create("TextLabel", {
    Position = UDim2.fromOffset(20, 9),
    Size = UDim2.new(1, -80, 0, 25),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "VELTRAX HUB",
    TextColor3 = Color3.fromRGB(235, 228, 255),
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

create("TextLabel", {
    Position = UDim2.fromOffset(20, 32),
    Size = UDim2.new(1, -80, 0, 17),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "JNKIE access verification",
    TextColor3 = Color3.fromRGB(153, 142, 176),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local closeButton = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Color3.fromRGB(40, 31, 56),
    BorderSizePixel = 0,
    AutoButtonColor = true,
    Font = Enum.Font.GothamBold,
    Text = "X",
    TextColor3 = Color3.fromRGB(220, 211, 235),
    TextSize = 13,
}, topBar)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, closeButton)

create("TextLabel", {
    Position = UDim2.fromOffset(24, 77),
    Size = UDim2.new(1, -48, 0, 34),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Obține cheia de 24 de ore, apoi introdu-o mai jos.",
    TextColor3 = Color3.fromRGB(187, 179, 204),
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local keyBox = create("TextBox", {
    Position = UDim2.fromOffset(24, 121),
    Size = UDim2.new(1, -48, 0, 47),
    BackgroundColor3 = Color3.fromRGB(27, 23, 38),
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    PlaceholderText = "Introdu cheia JNKIE...",
    PlaceholderColor3 = Color3.fromRGB(112, 104, 130),
    Text = "",
    TextColor3 = Color3.fromRGB(238, 234, 246),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 9) }, keyBox)
create("UIPadding", {
    PaddingLeft = UDim.new(0, 14),
    PaddingRight = UDim.new(0, 14),
}, keyBox)
create("UIStroke", {
    Color = Color3.fromRGB(69, 55, 92),
    Transparency = 0.25,
    Thickness = 1,
}, keyBox)

local getKeyButton = create("TextButton", {
    Position = UDim2.fromOffset(24, 181),
    Size = UDim2.new(0.5, -30, 0, 43),
    BackgroundColor3 = Color3.fromRGB(45, 36, 61),
    BorderSizePixel = 0,
    AutoButtonColor = true,
    Font = Enum.Font.GothamSemibold,
    Text = "GET KEY",
    TextColor3 = Color3.fromRGB(221, 212, 238),
    TextSize = 13,
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 9) }, getKeyButton)

local verifyButton = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -24, 0, 181),
    Size = UDim2.new(0.5, -30, 0, 43),
    BackgroundColor3 = Color3.fromRGB(130, 71, 218),
    BorderSizePixel = 0,
    AutoButtonColor = true,
    Font = Enum.Font.GothamBold,
    Text = "VERIFY KEY",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
}, main)
create("UICorner", { CornerRadius = UDim.new(0, 9) }, verifyButton)
create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 76, 231)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(104, 61, 201)),
    }),
}, verifyButton)

local statusLabel = create("TextLabel", {
    Position = UDim2.fromOffset(24, 238),
    Size = UDim2.new(1, -48, 0, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Pregătit pentru verificare.",
    TextColor3 = Color3.fromRGB(147, 137, 165),
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, main)

local function setStatus(message, color)
    statusLabel.Text = tostring(message)
    statusLabel.TextColor3 = color or Color3.fromRGB(147, 137, 165)
end

local function copyToClipboard(value)
    local clipboardFunction = setclipboard or toclipboard
    if not clipboardFunction and syn then
        clipboardFunction = syn.write_clipboard
    end

    if type(clipboardFunction) ~= "function" then
        return false
    end

    return pcall(clipboardFunction, value)
end

local errorMessages = {
    KEY_INVALID = "Cheia nu este validă. Verifică textul introdus.",
    KEY_EXPIRED = "Cheia a expirat. Apasă GET KEY pentru una nouă.",
    HWID_BANNED = "Acest dispozitiv este blocat.",
    KEY_INVALIDATED = "Cheia a fost dezactivată de provider.",
    ALREADY_USED = "Cheia de unică folosință a fost deja utilizată.",
    HWID_MISMATCH = "Limita HWID a fost atinsă sau cheia aparține altui dispozitiv.",
    SERVICE_NOT_FOUND = "Serviciul JNKIE nu a fost găsit. Anunță providerul.",
    SERVICE_MISMATCH = "Cheia aparține altui serviciu.",
    PREMIUM_REQUIRED = "Acest serviciu necesită o cheie premium.",
    RATE_LIMITTED = "Ai cerut recent un link. Așteaptă aproximativ 5 minute.",
    RATE_LIMITED = "Ai cerut recent un link. Așteaptă aproximativ 5 minute.",
    ERROR = "Eroare de rețea. Verifică internetul și încearcă din nou.",
}

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local canPersist = type(readfile) == "function" and type(writefile) == "function"

local function ensureKeyFolder()
    if type(makefolder) ~= "function" then
        return
    end

    local exists = false
    if type(isfolder) == "function" then
        local ok, result = pcall(isfolder, KEY_FOLDER)
        exists = ok and result == true
    end

    if not exists then
        pcall(makefolder, KEY_FOLDER)
    end
end

local function saveKey(key)
    environment.SCRIPT_KEY = key

    if not canPersist then
        return false
    end

    ensureKeyFolder()
    return pcall(writefile, KEY_FILE, key)
end

local function readSavedKey()
    local sessionKey = trim(environment.SCRIPT_KEY)
    if sessionKey ~= "" then
        return sessionKey, "session"
    end

    if not canPersist then
        return nil
    end

    if type(isfile) == "function" then
        local existsOk, exists = pcall(isfile, KEY_FILE)
        if not existsOk or not exists then
            return nil
        end
    end

    local readOk, value = pcall(readfile, KEY_FILE)
    value = readOk and trim(value) or ""
    if value == "" then
        return nil
    end

    return value, "file"
end

local function clearSavedKey()
    environment.SCRIPT_KEY = nil

    if canPersist then
        ensureKeyFolder()
        pcall(writefile, KEY_FILE, "")
    end
end

local function describeError(reason)
    reason = tostring(reason or "ERROR")

    if errorMessages[reason] then
        return errorMessages[reason]
    end

    local statusCode = reason:match("[Hh][Tt][Tt][Pp]%s*(%d+)")
    if statusCode then
        if statusCode == "429" then
            return "Prea multe cereri. Așteaptă câteva minute și încearcă din nou."
        end

        return "Serverul JNKIE a răspuns cu eroarea HTTP " .. statusCode .. "."
    end

    return "Verificarea a eșuat: " .. reason
end

local terminalKeyErrors = {
    KEY_INVALID = true,
    KEY_EXPIRED = true,
    KEY_INVALIDATED = true,
    ALREADY_USED = true,
    HWID_MISMATCH = true,
    SERVICE_MISMATCH = true,
}

local function verifyKey(key, automatic)
    key = trim(key)
    if key == "" then
        setStatus("Introdu o cheie înainte de verificare.", Color3.fromRGB(240, 159, 83))
        return
    end

    if busy then
        return
    end

    busy = true
    verifyButton.Text = "VERIFYING..."
    setStatus(
        automatic and "Cheia salvată este verificată automat..." or "Cheia este verificată...",
        Color3.fromRGB(188, 157, 238)
    )

    local ok, response = pcall(function()
        return Junkie.check_key(key)
    end)

    if closed then
        busy = false
        return
    end

    if ok and type(response) == "table" and response.valid == true then
        local persisted = saveKey(key)
        validated = true
        setStatus(
            persisted
                and "Cheie validă și salvată. Veltrax Hub pornește..."
                or "Cheie validă. Hubul pornește; executorul nu poate salva cheia.",
            Color3.fromRGB(105, 223, 143)
        )
    else
        local reason
        if not ok then
            reason = "ERROR"
        elseif type(response) == "table" then
            reason = response.error or response.message or "ERROR"
        else
            reason = "ERROR"
        end

        reason = tostring(reason or "ERROR")
        if terminalKeyErrors[reason] then
            clearSavedKey()
        end

        local prefix = automatic and "Cheia salvată a fost respinsă. " or ""
        setStatus(prefix .. describeError(reason), Color3.fromRGB(235, 103, 117))
    end

    busy = false
    verifyButton.Text = "VERIFY KEY"
end

connect(getKeyButton.MouseButton1Click, function()
    if busy then
        return
    end

    busy = true
    getKeyButton.Text = "GENERATING..."
    setStatus("Se generează linkul LootLabs...", Color3.fromRGB(188, 157, 238))

    task.spawn(function()
        local ok, link, linkError = pcall(function()
            return Junkie.get_key_link()
        end)

        if ok and type(link) == "string" and link ~= "" then
            if copyToClipboard(link) then
                setStatus("Linkul a fost copiat. Deschide-l în browser.", Color3.fromRGB(105, 223, 143))
            else
                setStatus("Executorul nu oferă clipboard. Link: " .. link, Color3.fromRGB(240, 159, 83))
            end
        else
            local reason = ok and (linkError or link or "ERROR") or "ERROR"
            setStatus("Link indisponibil. " .. describeError(reason), Color3.fromRGB(235, 103, 117))
        end

        busy = false
        getKeyButton.Text = "GET KEY"
    end)
end)

connect(verifyButton.MouseButton1Click, function()
    task.spawn(verifyKey, keyBox.Text)
end)

connect(keyBox.FocusLost, function(enterPressed)
    if enterPressed then
        task.spawn(verifyKey, keyBox.Text)
    end
end)

local savedKey = readSavedKey()
if savedKey then
    keyBox.Text = savedKey
    setStatus("Cheie salvată găsită. Verificare automată...", Color3.fromRGB(188, 157, 238))
    task.defer(verifyKey, savedKey, true)
elseif not canPersist then
    setStatus(
        "Pregătit. Executorul nu oferă readfile/writefile; cheia va rămâne doar în sesiunea curentă.",
        Color3.fromRGB(240, 159, 83)
    )
end

local dragging = false
local dragInput
local dragStart
local startPosition

connect(topBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        connect(input.Changed, function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

connect(topBar.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragInput = input
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

local function cleanup()
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(connections)

    if environment.__VELTRAX_KEY_GUI == gui then
        environment.__VELTRAX_KEY_GUI = nil
    end

    pcall(function()
        gui:Destroy()
    end)
end

connect(closeButton.MouseButton1Click, function()
    closed = true
    cleanup()
end)

while not validated and not closed do
    task.wait(0.1)
end

if validated then
    task.wait(0.35)
    cleanup()

    local loadOk, loadError = pcall(function()
        if type(Junkie.load_script) == "function" then
            Junkie.load_script()
            return
        end

        local source = game:HttpGet(PUBLIC_SCRIPT_URL)
        local chunk = loadstring(source)
        assert(type(chunk) == "function", "payload-ul protejat nu poate fi compilat")
        chunk()
    end)

    if not loadOk then
        systemMessage(
            "Eroare de rețea la încărcarea Veltrax Hub: " .. tostring(loadError),
            12
        )
    end
end
