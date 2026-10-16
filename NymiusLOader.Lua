-- Nymius Rivals v2.3 - Main Loader
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === ЗАГРУЗКА МОДУЛЯ АИМБОТОВ ===
local AIMBOT_MODULE_URL = "https://raw.githubusercontent.com/elenpro366-prog/AimbotModule/refs/heads/main/AimbotModule.lua"

local function loadAimbotModule()
	local success, code = pcall(function()
		return game:HttpGet(AIMBOT_MODULE_URL, true)
	end)
	if success and code then
		local func, err = loadstring(code)
		if func then func() return true
		else warn("️ AimbotModule load error: " .. tostring(err)) end
	else
		warn("️ Failed to fetch AimbotModule: " .. tostring(code))
	end
	return false
end

-- === ПРОВЕРКА ФУНКЦИЙ ===
local hasHookmetamethod = pcall(function() return hookmetamethod end)
local hasDrawing = pcall(function() return Drawing.new end)
local hasSetClipboard = pcall(function() return setclipboard end)
local hasMouseMoveRel = pcall(function() return mousemoverel end)

-- === ТАБЛИЦА СТАФФОВ ===
local staffList = {"RealApplino","8sty","a2rix","Bandites","Blizmid","BobbVX","Brian1KB","Carbonmeister","Chexworldwide","Reallycruz","D_reamz","AtDarktru","DVwastaken","SniperDude9167","enriquebruv","GreatGuyBoom","EHoopie","h0ppy819","KaiMemory","Karfulol","kashycod","swaglord_KAYE","Khxyri","MiloBloxin","SubToMiniBloxia","mixedify","DunkinMud","nekoanims","Nosniy","PixelCat5","philhood","SenseiWarrior","ShadowTrojan","SharkTactics","StefanBloxxxxx","TanqR","viecti","its_we1rd","FluxxyBoiOfficial","StaredSystemized","himochu","xlISinner","PrimeVoxel","GameTestNG","Voltryxe","SoftGB","Solseyy","EreshkigaI","Muzishi","0Skyz","starchip12","Ep1cism","Cardyy","Kurookku","sircfenner","ObscureEntity","don_iie","MarcoXDDDDDD","illac17","XportNz","failedloadinguser","Realinq","Simark72","ILove_YukkiAsuna","61Q_Fr0st","Riptide_Fr0st","kentfla","mrmatash","Pyrixl","LeFouTrolleur","SStormix"}
local staffLower = {}
for _, name in ipairs(staffList) do staffLower[string.lower(name)] = true end

-- === ЦВЕТОВАЯ СХЕМА ===
local colors = {
	mainBg = Color3.fromRGB(25, 25, 35),
	titleBg = Color3.fromRGB(40, 40, 60),
	sectionBg = Color3.fromRGB(35, 35, 50),
	inputBg = Color3.fromRGB(50, 50, 70),
	buttonDefault = Color3.fromRGB(100, 100, 150),
	buttonGreen = Color3.fromRGB(46, 204, 113),
	buttonRed = Color3.fromRGB(231, 76, 60),
	buttonBlue = Color3.fromRGB(52, 152, 219),
	buttonPurple = Color3.fromRGB(155, 89, 182),
	buttonYellow = Color3.fromRGB(241, 196, 15),
	stroke = Color3.fromRGB(100, 100, 255),
	consoleBg = Color3.fromRGB(20, 20, 30),
	fovSilent = Color3.fromRGB(255, 50, 50),
	fovLegit = Color3.fromRGB(50, 200, 255),
	fovMouseAim = Color3.fromRGB(150, 255, 50)
}

-- === СОСТОЯНИЯ ===
local states = {
	espEnabled = false,
	espShowNames = false,
	espShowHP = false,
	silentEnabled = false, silentShowFOV = false, silentFOV = 150,
	flyEnabled = false, flySpeed = 1,
	walkSpeedEnabled = false, walkSpeedValue = 1,
	noclipEnabled = false,
	legitEnabled = false, legitShowFOV = false, legitWallCheck = false,
	legitMode = "always", legitFOV = 200, legitSmoothness = 0.1,
	legitTargetLockEnabled = false, legitTargetLockName = "",
	mouseAimEnabled = false, mouseAimShowFOV = false, mouseAimWallCheck = false,
	mouseAimMode = "always", mouseAimFOV = 200, mouseAimSmoothness = 0.3,
	mouseAimHeadChance = 50,
	mouseAimLegitment = 0,
	rageEnabled = false, rageTargets = {"", "", "", "", ""},
	arcadeRageEnabled = false,
	staffDetectorEnabled = false,
	currentTheme = "Classic",
	repaintDelay = 0.01
}

-- === КЕЙБИНДЫ ===
local keybinds = {
	direct = nil, arcade = nil, esp = nil, toggle = "RightShift",
	silent = nil, fly = nil, noclip = nil,
	legit = nil, legitMode = nil, legitHold = "Mouse2", legitTargetLock = nil,
	mouseAim = nil, mouseAimMode = nil, mouseAimHold = "Mouse2",
	rage = nil, rageRecall = nil,
}

local themes = {Classic = {transparency = 0}, Aero = {transparency = 0.25}}

-- === ОБЩИЙ КОНТЕКСТ ===
getgenv().NymiusShared = {
	Players = Players, UserInputService = UserInputService, RunService = RunService,
	HttpService = HttpService, LocalPlayer = LocalPlayer, Camera = Camera,
	hasHookmetamethod = hasHookmetamethod, hasDrawing = hasDrawing,
	hasMouseMoveRel = hasMouseMoveRel, hasSetClipboard = hasSetClipboard,
	states = states, keybinds = keybinds, colors = colors, themes = themes,
	staffLower = staffLower, keybindActions = {}, keybindButtons = {}, ui = {},
	legitHolding = false, mouseAimHolding = false
}
local shared = getgenv().NymiusShared

-- === BASE64 ===
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64Encode(data)
	return ((data:gsub('.', function(x)
		local r, b = '', x:byte()
		for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
		return r
	end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if #x < 6 then return '' end
		local c = 0
		for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6-i) or 0) end
		return b64chars:sub(c+1, c+1)
	end) .. ({'', '==', '='})[#data % 3 + 1])
end

local function base64Decode(data)
	data = data:gsub('[^'..b64chars..'=]', '')
	return (data:gsub('.', function(x)
		if x == '=' then return '' end
		local r, f = '', (b64chars:find(x) - 1)
		for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if #x ~= 8 then return '' end
		local c = 0
		for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

-- === АВТОЗАГРУЗКА КОНФИГА ===
local initialConfig = _G.Config or (getgenv and getgenv().Config) or Config
if initialConfig and type(initialConfig) == "string" and initialConfig ~= "" then
	pcall(function()
		local decoded = base64Decode(initialConfig)
		local data = HttpService:JSONDecode(decoded)
		if data then
			if data.keybinds then for k, v in pairs(data.keybinds) do keybinds[k] = v end end
			if data.states then for k, v in pairs(data.states) do states[k] = v end end
			if data.colors then
				for name, rgb in pairs(data.colors) do
					if colors[name] then colors[name] = Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end
				end
			end
			print("✅ [Nymius] Автоматически загружен конфиг из переменной Config!")
		end
	end)
end

-- === КОНФИГИ ===
local function getConfigData()
	return {
		keybinds = keybinds, states = states,
		colors = {
			mainBg = {colors.mainBg.R*255, colors.mainBg.G*255, colors.mainBg.B*255},
			titleBg = {colors.titleBg.R*255, colors.titleBg.G*255, colors.titleBg.B*255},
			buttonDefault = {colors.buttonDefault.R*255, colors.buttonDefault.G*255, colors.buttonDefault.B*255},
			stroke = {colors.stroke.R*255, colors.stroke.G*255, colors.stroke.B*255},
			consoleBg = {colors.consoleBg.R*255, colors.consoleBg.G*255, colors.consoleBg.B*255},
			fovSilent = {colors.fovSilent.R*255, colors.fovSilent.G*255, colors.fovSilent.B*255},
			fovLegit = {colors.fovLegit.R*255, colors.fovLegit.G*255, colors.fovLegit.B*255},
			fovMouseAim = {colors.fovMouseAim.R*255, colors.fovMouseAim.G*255, colors.fovMouseAim.B*255}
		},
		version = "2.3"
	}
end

local function applyConfigData(data)
	if data.keybinds then for k, v in pairs(data.keybinds) do keybinds[k] = v end end
	if data.states then for k, v in pairs(data.states) do states[k] = v end end
	if data.colors then
		for name, rgb in pairs(data.colors) do
			if colors[name] then colors[name] = Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end
		end
	end
	if updateAllUIFromStates then updateAllUIFromStates() end
	if updateAllKeybindButtons then updateAllKeybindButtons() end
end

local function generateConfigCode() return base64Encode(HttpService:JSONEncode(getConfigData())) end
local function loadConfigFromCode(code) return pcall(function() applyConfigData(HttpService:JSONDecode(base64Decode(code))) end) end

-- === UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NymiusRivals"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.Visible = false
Overlay.ZIndex = 5
Overlay.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 1140, 0, 850)
MainFrame.Position = UDim2.new(0.5, -570, 0.5, -425)
MainFrame.BackgroundColor3 = colors.mainBg
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = colors.stroke
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = colors.titleBg
Title.Text = "Nymius Rivals v2.3"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.ZIndex = 11
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local ColumnsContainer = Instance.new("Frame")
ColumnsContainer.Size = UDim2.new(1, 0, 1, -45)
ColumnsContainer.Position = UDim2.new(0, 0, 0, 45)
ColumnsContainer.BackgroundTransparency = 1
ColumnsContainer.ZIndex = 11
ColumnsContainer.Parent = MainFrame

-- === UI HELPERS ===
local function createSectionLabel(text, parent, yPos)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0, 25)
	label.Position = UDim2.new(0.05, 0, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = parent
	return label
end

local function createDivider(parent, yPos)
	local div = Instance.new("Frame")
	div.Size = UDim2.new(0.9, 0, 0, 2)
	div.Position = UDim2.new(0.05, 0, 0, yPos)
	div.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	div.ZIndex = 11
	div.Parent = parent
	return div
end

local function createTextBox(parent, pos, size, placeholder, defaultText)
	local tb = Instance.new("TextBox")
	tb.Size = size
	tb.Position = pos
	tb.BackgroundColor3 = colors.inputBg
	tb.TextColor3 = Color3.new(1, 1, 1)
	tb.PlaceholderText = placeholder
	tb.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 13
	tb.ClearTextOnFocus = false
	tb.Text = defaultText or ""
	tb.ZIndex = 11
	tb.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = tb
	return tb
end

local function createButton(parent, pos, size, text, color)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = color or colors.buttonDefault
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.ZIndex = 11
	btn.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	return btn
end

-- === COLUMNS ===
local LeftColumn = Instance.new("ScrollingFrame")
LeftColumn.Size = UDim2.new(0, 378, 1, 0)
LeftColumn.BackgroundTransparency = 1
LeftColumn.ScrollBarThickness = 4
LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 1600)
LeftColumn.ZIndex = 11
LeftColumn.Parent = ColumnsContainer

local MiddleColumn = Instance.new("ScrollingFrame")
MiddleColumn.Size = UDim2.new(0, 378, 1, 0)
MiddleColumn.Position = UDim2.new(0, 381, 0, 0)
MiddleColumn.BackgroundTransparency = 1
MiddleColumn.ScrollBarThickness = 4
MiddleColumn.CanvasSize = UDim2.new(0, 0, 0, 1800)
MiddleColumn.ZIndex = 11
MiddleColumn.Parent = ColumnsContainer

local RightColumn = Instance.new("ScrollingFrame")
RightColumn.Size = UDim2.new(0, 378, 1, 0)
RightColumn.Position = UDim2.new(0, 761, 0, 0)
RightColumn.BackgroundTransparency = 1
RightColumn.ScrollBarThickness = 4
RightColumn.CanvasSize = UDim2.new(0, 0, 0, 1300)
RightColumn.ZIndex = 11
RightColumn.Parent = ColumnsContainer

-- === LOGGING ===
local ConsoleFrame = Instance.new("ScrollingFrame")
ConsoleFrame.Size = UDim2.new(0.9, 0, 0, 500)
ConsoleFrame.Position = UDim2.new(0.05, 0, 0, 605)
ConsoleFrame.BackgroundColor3 = colors.consoleBg
ConsoleFrame.ScrollBarThickness = 6
ConsoleFrame.ZIndex = 11
ConsoleFrame.Parent = RightColumn

local ConsoleLayout = Instance.new("UIListLayout")
ConsoleLayout.Padding = UDim.new(0, 2)
ConsoleLayout.Parent = ConsoleFrame
ConsoleLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ConsoleWindow = Instance.new("Frame")
ConsoleWindow.Size = UDim2.new(0, 400, 0, 300)
ConsoleWindow.Position = UDim2.new(0.5, 400, 0.5, -150)
ConsoleWindow.BackgroundColor3 = colors.consoleBg
ConsoleWindow.Active = true
ConsoleWindow.Draggable = true
ConsoleWindow.Visible = false
ConsoleWindow.ZIndex = 20
ConsoleWindow.Parent = ScreenGui

local ConsoleWindowCorner = Instance.new("UICorner")
ConsoleWindowCorner.CornerRadius = UDim.new(0, 8)
ConsoleWindowCorner.Parent = ConsoleWindow

local ConsoleWindowStroke = Instance.new("UIStroke")
ConsoleWindowStroke.Color = colors.stroke
ConsoleWindowStroke.Thickness = 2
ConsoleWindowStroke.Parent = ConsoleWindow

local ConsoleWindowTitleBar = Instance.new("Frame")
ConsoleWindowTitleBar.Size = UDim2.new(1, 0, 0, 25)
ConsoleWindowTitleBar.BackgroundColor3 = colors.titleBg
ConsoleWindowTitleBar.ZIndex = 21
ConsoleWindowTitleBar.Parent = ConsoleWindow

local ConsoleWindowTitle = Instance.new("TextLabel")
ConsoleWindowTitle.Size = UDim2.new(1, 0, 1, 0)
ConsoleWindowTitle.BackgroundTransparency = 1
ConsoleWindowTitle.Text = "Console"
ConsoleWindowTitle.TextColor3 = Color3.new(1, 1, 1)
ConsoleWindowTitle.Font = Enum.Font.GothamBold
ConsoleWindowTitle.TextSize = 12
ConsoleWindowTitle.ZIndex = 21
ConsoleWindowTitle.Parent = ConsoleWindowTitleBar

local ConsoleWindowCloseBtn = Instance.new("TextButton")
ConsoleWindowCloseBtn.Size = UDim2.new(0, 20, 0, 20)
ConsoleWindowCloseBtn.Position = UDim2.new(1, -22, 0, 2)
ConsoleWindowCloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ConsoleWindowCloseBtn.Text = "X"
ConsoleWindowCloseBtn.TextColor3 = Color3.new(1, 1, 1)
ConsoleWindowCloseBtn.Font = Enum.Font.GothamBold
ConsoleWindowCloseBtn.TextSize = 10
ConsoleWindowCloseBtn.ZIndex = 21
ConsoleWindowCloseBtn.Parent = ConsoleWindowTitleBar

local ConsoleWindowFrame = Instance.new("ScrollingFrame")
ConsoleWindowFrame.Size = UDim2.new(0.95, 0, 1, -35)
ConsoleWindowFrame.Position = UDim2.new(0.025, 0, 0, 30)
ConsoleWindowFrame.BackgroundColor3 = colors.consoleBg
ConsoleWindowFrame.ScrollBarThickness = 6
ConsoleWindowFrame.ZIndex = 21
ConsoleWindowFrame.Parent = ConsoleWindow

local ConsoleWindowLayout = Instance.new("UIListLayout")
ConsoleWindowLayout.Padding = UDim.new(0, 2)
ConsoleWindowLayout.Parent = ConsoleWindowFrame
ConsoleWindowLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function log(message, color)
	color = color or Color3.fromRGB(200, 200, 200)
	local entry = Instance.new("TextLabel")
	entry.Size = UDim2.new(1, 0, 0, 16)
	entry.BackgroundTransparency = 1
	entry.Text = message
	entry.TextColor3 = color
	entry.Font = Enum.Font.Code
	entry.TextSize = 11
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextWrapped = true
	entry.ZIndex = 11
	entry.Parent = ConsoleFrame
	task.wait(0.05)
	ConsoleFrame.CanvasSize = UDim2.new(0, 0, 0, ConsoleLayout.AbsoluteContentSize.Y + 10)
	ConsoleFrame.CanvasPosition = Vector2.new(0, math.max(0, ConsoleFrame.CanvasSize.Y.Offset - ConsoleFrame.AbsoluteSize.Y))
	local children = ConsoleFrame:GetChildren()
	if #children > 80 then
		for i = 1, #children - 80 do
			if children[i]:IsA("TextLabel") then children[i]:Destroy() end
		end
	end
	if ConsoleWindowFrame then
		local entry2 = entry:Clone()
		entry2.ZIndex = 21
		entry2.Parent = ConsoleWindowFrame
		ConsoleWindowFrame.CanvasSize = UDim2.new(0, 0, 0, ConsoleWindowLayout.AbsoluteContentSize.Y + 10)
		ConsoleWindowFrame.CanvasPosition = Vector2.new(0, math.max(0, ConsoleWindowFrame.CanvasSize.Y.Offset - ConsoleWindowFrame.AbsoluteSize.Y))
		local children2 = ConsoleWindowFrame:GetChildren()
		if #children2 > 80 then
			for i = 1, #children2 - 80 do
				if children2[i]:IsA("TextLabel") then children2[i]:Destroy() end
			end
		end
	end
end
shared.log = log

-- === ФУНКЦИЯ СОЗДАНИЯ ЭЛЕМЕНТА СПИСКА ИГРОКОВ ===
local function createPlayerListItem(parent, player, yPos, isRageMode)
	local itemHeight = 50
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Size = UDim2.new(0.9, 0, 0, itemHeight)
	itemFrame.Position = UDim2.new(0.05, 0, 0, yPos)
	itemFrame.BackgroundColor3 = colors.sectionBg
	itemFrame.ZIndex = 11
	itemFrame.Parent = parent
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 6)
	itemCorner.Parent = itemFrame
	
	-- Аватар
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Size = UDim2.new(0, 40, 0, 40)
	avatarFrame.Position = UDim2.new(0, 5, 0.5, -20)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	avatarFrame.ZIndex = 12
	avatarFrame.Parent = itemFrame
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarFrame
	
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ZIndex = 13
	avatarImage.Parent = avatarFrame
	
	-- Загрузка аватара
	task.spawn(function()
		local success, thumbUrl = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success and thumbUrl then
			avatarImage.Image = thumbUrl
		else
			avatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		end
	end)
	
	-- Имена
	local nameFrame = Instance.new("Frame")
	nameFrame.Size = UDim2.new(0, 180, 0, 40)
	nameFrame.Position = UDim2.new(0, 55, 0.5, -20)
	nameFrame.BackgroundTransparency = 1
	nameFrame.ZIndex = 12
	nameFrame.Parent = itemFrame
	
	local displayNameLabel = Instance.new("TextLabel")
	displayNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	displayNameLabel.BackgroundTransparency = 1
	displayNameLabel.Text = player.DisplayName
	displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayNameLabel.Font = Enum.Font.GothamBold
	displayNameLabel.TextSize = 12
	displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayNameLabel.ZIndex = 13
	displayNameLabel.Parent = nameFrame
	
	local userNameLabel = Instance.new("TextLabel")
	userNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	userNameLabel.Position = UDim2.new(0, 0, 0.5, 0)
	userNameLabel.BackgroundTransparency = 1
	userNameLabel.Text = "@" .. player.Name
	userNameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	userNameLabel.Font = Enum.Font.Gotham
	userNameLabel.TextSize = 10
	userNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	userNameLabel.ZIndex = 13
	userNameLabel.Parent = nameFrame
	
	-- Кнопка действия
	local actionBtn
	if isRageMode then
		-- Проверяем, есть ли игрок уже в списке таргетов
		local isInList = false
		for i = 1, 5 do
			if string.lower(states.rageTargets[i]) == string.lower(player.Name) then
				isInList = true
				break
			end
		end
		
		actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 70, 0, 30)
		actionBtn.Position = UDim2.new(1, -75, 0.5, -15)
		actionBtn.BackgroundColor3 = isInList and colors.buttonRed or colors.buttonGreen
		actionBtn.Text = isInList and "Remove" or "Add"
		actionBtn.TextColor3 = Color3.new(1, 1, 1)
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.ZIndex = 13
		actionBtn.Parent = itemFrame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = actionBtn
		
		actionBtn.MouseButton1Click:Connect(function()
			-- Добавляем или удаляем из списка
			local found = false
			for i = 1, 5 do
				if string.lower(states.rageTargets[i]) == string.lower(player.Name) then
					states.rageTargets[i] = ""
					found = true
					actionBtn.Text = "Add"
					actionBtn.BackgroundColor3 = colors.buttonGreen
					log(" Removed " .. player.Name .. " from rage targets", Color3.fromRGB(231, 76, 60))
					break
				end
			end
			
			if not found then
				-- Ищем свободный слот
				for i = 1, 5 do
					if states.rageTargets[i] == "" then
						states.rageTargets[i] = player.Name
						actionBtn.Text = "Remove"
						actionBtn.BackgroundColor3 = colors.buttonRed
						log("✅ Added " .. player.Name .. " to rage targets (slot " .. i .. ")", Color3.fromRGB(46, 204, 113))
						break
					end
				end
			end
			
			-- Обновляем текстбоксы в основной панели
			for i = 1, 5 do
				local targetInput = LeftColumn:FindFirstChild("RageTarget"..i)
				if targetInput then
					targetInput.Text = states.rageTargets[i] or ""
				end
			end
		end)
	else
		-- Direct TP mode - кнопка TP
		actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 50, 0, 30)
		actionBtn.Position = UDim2.new(1, -55, 0.5, -15)
		actionBtn.BackgroundColor3 = colors.buttonBlue
		actionBtn.Text = "TP"
		actionBtn.TextColor3 = Color3.new(1, 1, 1)
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.ZIndex = 13
		actionBtn.Parent = itemFrame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = actionBtn
		
		actionBtn.MouseButton1Click:Connect(function()
			log("🎯 TP to " .. player.Name, Color3.fromRGB(52, 152, 219))
			local success, err = pcall(function()
				local tChar = player.Character
				if not tChar then error("No character") end
				local tRoot = tChar:WaitForChild("HumanoidRootPart", 5)
				if not tRoot then error("No root") end
				local myChar = LocalPlayer.Character
				if not myChar then error("No character") end
				local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)
				if not myRoot then error("No root") end
				myRoot.CFrame = tRoot.CFrame
				Camera.CFrame = tRoot.CFrame
			end)
			if not success then log("❌ TP: " .. tostring(err), Color3.fromRGB(231, 76, 60)) end
		end)
	end
	
	return itemFrame, itemHeight
end

-- === ОКНО СЕЛЕКТОРА ИГРОКОВ ДЛЯ DIRECT TP ===
local TPSelectorWindow = Instance.new("Frame")
TPSelectorWindow.Size = UDim2.new(0, 320, 0, 400)
TPSelectorWindow.Position = UDim2.new(0.5, -160, 0.5, -200)
TPSelectorWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TPSelectorWindow.Active = true
TPSelectorWindow.Draggable = true
TPSelectorWindow.Visible = false
TPSelectorWindow.ZIndex = 20
TPSelectorWindow.Parent = ScreenGui

local TPSelectorCorner = Instance.new("UICorner")
TPSelectorCorner.CornerRadius = UDim.new(0, 8)
TPSelectorCorner.Parent = TPSelectorWindow

local TPSelectorStroke = Instance.new("UIStroke")
TPSelectorStroke.Color = colors.stroke
TPSelectorStroke.Thickness = 2
TPSelectorStroke.Parent = TPSelectorWindow

local TPSelectorTitleBar = Instance.new("Frame")
TPSelectorTitleBar.Size = UDim2.new(1, 0, 0, 30)
TPSelectorTitleBar.BackgroundColor3 = colors.titleBg
TPSelectorTitleBar.ZIndex = 21
TPSelectorTitleBar.Parent = TPSelectorWindow

local TPSelectorTitle = Instance.new("TextLabel")
TPSelectorTitle.Size = UDim2.new(1, -30, 1, 0)
TPSelectorTitle.Position = UDim2.new(0, 10, 0, 0)
TPSelectorTitle.BackgroundTransparency = 1
TPSelectorTitle.Text = "🎯 Direct TP - Select Player"
TPSelectorTitle.TextColor3 = Color3.new(1, 1, 1)
TPSelectorTitle.Font = Enum.Font.GothamBold
TPSelectorTitle.TextSize = 12
TPSelectorTitle.TextXAlignment = Enum.TextXAlignment.Left
TPSelectorTitle.ZIndex = 21
TPSelectorTitle.Parent = TPSelectorTitleBar

local TPSelectorCloseBtn = Instance.new("TextButton")
TPSelectorCloseBtn.Size = UDim2.new(0, 20, 0, 20)
TPSelectorCloseBtn.Position = UDim2.new(1, -22, 0, 5)
TPSelectorCloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
TPSelectorCloseBtn.Text = "X"
TPSelectorCloseBtn.TextColor3 = Color3.new(1, 1, 1)
TPSelectorCloseBtn.Font = Enum.Font.GothamBold
TPSelectorCloseBtn.TextSize = 10
TPSelectorCloseBtn.ZIndex = 21
TPSelectorCloseBtn.Parent = TPSelectorTitleBar

local TPSelectorScroll = Instance.new("ScrollingFrame")
TPSelectorScroll.Size = UDim2.new(0.95, 0, 1, -35)
TPSelectorScroll.Position = UDim2.new(0.025, 0, 0, 35)
TPSelectorScroll.BackgroundTransparency = 1
TPSelectorScroll.ScrollBarThickness = 4
TPSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TPSelectorScroll.ZIndex = 21
TPSelectorScroll.Parent = TPSelectorWindow

local TPSelectorLayout = Instance.new("UIListLayout")
TPSelectorLayout.Padding = UDim.new(0, 4)
TPSelectorLayout.Parent = TPSelectorScroll

local function refreshTPSelector()
	-- Очищаем список
	for _, child in ipairs(TPSelectorScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local yPos = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local item, height = createPlayerListItem(TPSelectorScroll, player, yPos, false)
			yPos = yPos + height + 4
		end
	end
	
	TPSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

TPSelectorCloseBtn.MouseButton1Click:Connect(function()
	TPSelectorWindow.Visible = false
end)

-- === ОКНО СЕЛЕКТОРА ИГРОКОВ ДЛЯ RAGEBOT ===
local RageSelectorWindow = Instance.new("Frame")
RageSelectorWindow.Size = UDim2.new(0, 320, 0, 400)
RageSelectorWindow.Position = UDim2.new(0.5, 200, 0.5, -200)
RageSelectorWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
RageSelectorWindow.Active = true
RageSelectorWindow.Draggable = true
RageSelectorWindow.Visible = false
RageSelectorWindow.ZIndex = 20
RageSelectorWindow.Parent = ScreenGui

local RageSelectorCorner = Instance.new("UICorner")
RageSelectorCorner.CornerRadius = UDim.new(0, 8)
RageSelectorCorner.Parent = RageSelectorWindow

local RageSelectorStroke = Instance.new("UIStroke")
RageSelectorStroke.Color = colors.stroke
RageSelectorStroke.Thickness = 2
RageSelectorStroke.Parent = RageSelectorWindow

local RageSelectorTitleBar = Instance.new("Frame")
RageSelectorTitleBar.Size = UDim2.new(1, 0, 0, 30)
RageSelectorTitleBar.BackgroundColor3 = colors.titleBg
RageSelectorTitleBar.ZIndex = 21
RageSelectorTitleBar.Parent = RageSelectorWindow

local RageSelectorTitle = Instance.new("TextLabel")
RageSelectorTitle.Size = UDim2.new(1, -30, 1, 0)
RageSelectorTitle.Position = UDim2.new(0, 10, 0, 0)
RageSelectorTitle.BackgroundTransparency = 1
RageSelectorTitle.Text = "️ RageBot - Select Targets"
RageSelectorTitle.TextColor3 = Color3.new(1, 1, 1)
RageSelectorTitle.Font = Enum.Font.GothamBold
RageSelectorTitle.TextSize = 12
RageSelectorTitle.TextXAlignment = Enum.TextXAlignment.Left
RageSelectorTitle.ZIndex = 21
RageSelectorTitle.Parent = RageSelectorTitleBar

local RageSelectorCloseBtn = Instance.new("TextButton")
RageSelectorCloseBtn.Size = UDim2.new(0, 20, 0, 20)
RageSelectorCloseBtn.Position = UDim2.new(1, -22, 0, 5)
RageSelectorCloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
RageSelectorCloseBtn.Text = "X"
RageSelectorCloseBtn.TextColor3 = Color3.new(1, 1, 1)
RageSelectorCloseBtn.Font = Enum.Font.GothamBold
RageSelectorCloseBtn.TextSize = 10
RageSelectorCloseBtn.ZIndex = 21
RageSelectorCloseBtn.Parent = RageSelectorTitleBar

local RageSelectorScroll = Instance.new("ScrollingFrame")
RageSelectorScroll.Size = UDim2.new(0.95, 0, 1, -35)
RageSelectorScroll.Position = UDim2.new(0.025, 0, 0, 35)
RageSelectorScroll.BackgroundTransparency = 1
RageSelectorScroll.ScrollBarThickness = 4
RageSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RageSelectorScroll.ZIndex = 21
RageSelectorScroll.Parent = RageSelectorWindow

local RageSelectorLayout = Instance.new("UIListLayout")
RageSelectorLayout.Padding = UDim.new(0, 4)
RageSelectorLayout.Parent = RageSelectorScroll

-- Кнопки Update и Clear All для RageSelector
local RageUpdateBtn = createButton(RageSelectorWindow, UDim2.new(0.05, 0, 1, -30), UDim2.new(0.45, 0, 0, 25), "🔄 Update", colors.buttonBlue)
local RageClearBtn = createButton(RageSelectorWindow, UDim2.new(0.5, 0, 1, -30), UDim2.new(0.45, 0, 0, 25), "🗑️ Clear All", colors.buttonRed)

RageUpdateBtn.MouseButton1Click:Connect(function()
	refreshRageSelector()
	log("🔄 Rage selector updated", Color3.fromRGB(52, 152, 219))
end)

RageClearBtn.MouseButton1Click:Connect(function()
	for i = 1, 5 do
		states.rageTargets[i] = ""
		local targetInput = LeftColumn:FindFirstChild("RageTarget"..i)
		if targetInput then targetInput.Text = "" end
	end
	refreshRageSelector()
	log("🗑️ All rage targets cleared", Color3.fromRGB(231, 76, 60))
end)

local function refreshRageSelector()
	-- Очищаем список
	for _, child in ipairs(RageSelectorScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local yPos = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local item, height = createPlayerListItem(RageSelectorScroll, player, yPos, true)
			yPos = yPos + height + 4
		end
	end
	
	RageSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

RageSelectorCloseBtn.MouseButton1Click:Connect(function()
	RageSelectorWindow.Visible = false
end)

-- === LEFT COLUMN ===
createSectionLabel("Direct Teleport", LeftColumn, 10)
local PlayerInput = createTextBox(LeftColumn, UDim2.new(0.05, 0, 0, 40), UDim2.new(0.55, 0, 0, 35), "Enter player name...")
local TeleportBtn = createButton(LeftColumn, UDim2.new(0.62, 0, 0, 40), UDim2.new(0.15, 0, 0, 35), "TP", colors.buttonGreen)
local DirectKeybindBtn = createButton(LeftColumn, UDim2.new(0.8, 0, 0, 40), UDim2.new(0.15, 0, 0, 35), keybinds.direct or "Key")
local TPSelectorBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 80), UDim2.new(0.9, 0, 0, 30), "👥 Open Player Selector", colors.buttonBlue)

createDivider(LeftColumn, 125)
createSectionLabel("Arcade Teleport", LeftColumn, 135)
local RandomBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 165), UDim2.new(0.6, 0, 0, 40), "Random Teleport", colors.buttonBlue)
local ArcadeKeybindBtn = createButton(LeftColumn, UDim2.new(0.8, 0, 0, 165), UDim2.new(0.15, 0, 0, 40), keybinds.arcade or "Key")

createDivider(LeftColumn, 220)
createSectionLabel("SilentAim", LeftColumn, 230)
local SilentToggleBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 260), UDim2.new(0.4, 0, 0, 35), "Toggle: OFF")
local SilentKeybindBtn = createButton(LeftColumn, UDim2.new(0.5, 0, 0, 260), UDim2.new(0.2, 0, 0, 35), keybinds.silent or "Key")
local SilentShowFOVBtn = createButton(LeftColumn, UDim2.new(0.72, 0, 0, 260), UDim2.new(0.23, 0, 0, 35), "Show FOV: OFF")
local SilentFOVInput = createTextBox(LeftColumn, UDim2.new(0.05, 0, 0, 305), UDim2.new(0.9, 0, 0, 35), "Rage FOV (default: 150)", tostring(states.silentFOV))

createDivider(LeftColumn, 355)
createSectionLabel("Movement", LeftColumn, 365)
local FlyBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 395), UDim2.new(0.4, 0, 0, 35), "Fly: OFF")
local FlyKeybindBtn = createButton(LeftColumn, UDim2.new(0.5, 0, 0, 395), UDim2.new(0.2, 0, 0, 35), keybinds.fly or "Key")
local FlySpeedInput = createTextBox(LeftColumn, UDim2.new(0.72, 0, 0, 395), UDim2.new(0.23, 0, 0, 35), "Fly Speed", tostring(states.flySpeed))
local WalkSpeedInput = createTextBox(LeftColumn, UDim2.new(0.05, 0, 0, 440), UDim2.new(0.4, 0, 0, 35), "WalkSpeed (default: 1)", tostring(states.walkSpeedValue))
local WalkSpeedChangerBtn = createButton(LeftColumn, UDim2.new(0.5, 0, 0, 440), UDim2.new(0.45, 0, 0, 35), "WalkSpeed Changer: OFF")

createDivider(LeftColumn, 490)
createSectionLabel("RageBot", LeftColumn, 500)
local RageToggleBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 530), UDim2.new(0.4, 0, 0, 35), "Toggle: OFF")
local RageKeybindBtn = createButton(LeftColumn, UDim2.new(0.5, 0, 0, 530), UDim2.new(0.2, 0, 0, 35), keybinds.rage or "Key")
local RageRecallKeybindBtn = createButton(LeftColumn, UDim2.new(0.72, 0, 0, 530), UDim2.new(0.23, 0, 0, 35), keybinds.rageRecall or "Key")
local ArcadeRageBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 570), UDim2.new(0.4, 0, 0, 35), "Arcade: OFF")
local RageKillBtn = createButton(LeftColumn, UDim2.new(0.5, 0, 0, 570), UDim2.new(0.45, 0, 0, 35), "Kill", colors.buttonRed)
local RageSelectorBtn = createButton(LeftColumn, UDim2.new(0.05, 0, 0, 610), UDim2.new(0.9, 0, 0, 30), "⚔️ Open Target Selector", colors.buttonPurple)

-- Текстовые поля для таргетов (скрытые, но сохраняются для совместимости)
for i = 1, 5 do
	local targetInput = createTextBox(LeftColumn, UDim2.new(0.05, 0, 0, 645 + (i-1)*40), UDim2.new(0.9, 0, 0, 35), "Target "..i.." name...", states.rageTargets[i] or "")
	targetInput.Name = "RageTarget"..i
	targetInput.Visible = false  -- Скрываем, так как теперь есть селектор
end

-- === MIDDLE COLUMN ===
createSectionLabel("World", MiddleColumn, 10)
local ESPBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 40), UDim2.new(0.25, 0, 0, 30), "ESP: OFF")
local ESPKeybindBtn = createButton(MiddleColumn, UDim2.new(0.32, 0, 0, 40), UDim2.new(0.15, 0, 0, 30), keybinds.esp or "Key")
local ESPNamesBtn = createButton(MiddleColumn, UDim2.new(0.49, 0, 0, 40), UDim2.new(0.22, 0, 0, 30), "Names: OFF")
local ESPHPBtn = createButton(MiddleColumn, UDim2.new(0.73, 0, 0, 40), UDim2.new(0.22, 0, 0, 30), "HP: OFF")

local NoclipBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 75), UDim2.new(0.25, 0, 0, 30), "Noclip: OFF")
local NoclipKeybindBtn = createButton(MiddleColumn, UDim2.new(0.32, 0, 0, 75), UDim2.new(0.15, 0, 0, 30), keybinds.noclip or "Key")
local StaffDetectorBtn = createButton(MiddleColumn, UDim2.new(0.49, 0, 0, 75), UDim2.new(0.46, 0, 0, 30), "Staff Detector: OFF")

createDivider(MiddleColumn, 120)
createSectionLabel("Additional UI", MiddleColumn, 130)
local KeybindsBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 160), UDim2.new(0.2, 0, 0, 35), "Keybinds")
local ProfileBtn = createButton(MiddleColumn, UDim2.new(0.27, 0, 0, 160), UDim2.new(0.2, 0, 0, 35), "Profile")
local NotesBtn = createButton(MiddleColumn, UDim2.new(0.49, 0, 0, 160), UDim2.new(0.2, 0, 0, 35), "Notes")
local ConsoleWindowBtn = createButton(MiddleColumn, UDim2.new(0.71, 0, 0, 160), UDim2.new(0.24, 0, 0, 35), "Console")

createDivider(MiddleColumn, 210)
createSectionLabel("LegitBot", MiddleColumn, 220)
local LegitToggleBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 250), UDim2.new(0.3, 0, 0, 35), "Legit AimBot: OFF")
local LegitKeybindBtn = createButton(MiddleColumn, UDim2.new(0.37, 0, 0, 250), UDim2.new(0.15, 0, 0, 35), keybinds.legit or "Key")
local LegitShowFOVBtn = createButton(MiddleColumn, UDim2.new(0.54, 0, 0, 250), UDim2.new(0.2, 0, 0, 35), "Show FOV: OFF")
local LegitWallCheckBtn = createButton(MiddleColumn, UDim2.new(0.76, 0, 0, 250), UDim2.new(0.19, 0, 0, 35), "Wall: OFF")
local LegitModeBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 290), UDim2.new(0.25, 0, 0, 35), "Mode: Always")
local LegitModeKeybindBtn = createButton(MiddleColumn, UDim2.new(0.32, 0, 0, 290), UDim2.new(0.15, 0, 0, 35), keybinds.legitMode or "Key")
local LegitHoldKeybindBtn = createButton(MiddleColumn, UDim2.new(0.49, 0, 0, 290), UDim2.new(0.15, 0, 0, 35), keybinds.legitHold or "Mouse2")
local LegitTargetLockBtn = createButton(MiddleColumn, UDim2.new(0.66, 0, 0, 290), UDim2.new(0.15, 0, 0, 35), "Lock: OFF")
local LegitTargetLockKeybindBtn = createButton(MiddleColumn, UDim2.new(0.83, 0, 0, 290), UDim2.new(0.12, 0, 0, 35), keybinds.legitTargetLock or "Key")
local LegitTargetInput = createTextBox(MiddleColumn, UDim2.new(0.05, 0, 0, 330), UDim2.new(0.9, 0, 0, 30), "Target Lock name", states.legitTargetLockName)
local LegitFOVInput = createTextBox(MiddleColumn, UDim2.new(0.05, 0, 0, 365), UDim2.new(0.45, 0, 0, 35), "Legit FOV (200)", tostring(states.legitFOV))
local LegitSmoothInput = createTextBox(MiddleColumn, UDim2.new(0.52, 0, 0, 365), UDim2.new(0.43, 0, 0, 35), "Smoothness (0=instant)", tostring(states.legitSmoothness))

createDivider(MiddleColumn, 415)
createSectionLabel("Mouse Aimbot", MiddleColumn, 425)
local MouseAimToggleBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 455), UDim2.new(0.3, 0, 0, 35), "Toggle: OFF")
local MouseAimKeybindBtn = createButton(MiddleColumn, UDim2.new(0.37, 0, 0, 455), UDim2.new(0.15, 0, 0, 35), keybinds.mouseAim or "Key")
local MouseAimWallCheckBtn = createButton(MiddleColumn, UDim2.new(0.54, 0, 0, 455), UDim2.new(0.2, 0, 0, 35), "Wall: OFF")
local MouseAimShowFOVBtn = createButton(MiddleColumn, UDim2.new(0.76, 0, 0, 455), UDim2.new(0.19, 0, 0, 35), "Show FOV: OFF")
local MouseAimModeBtn = createButton(MiddleColumn, UDim2.new(0.05, 0, 0, 495), UDim2.new(0.25, 0, 0, 35), "Mode: Always")
local MouseAimModeKeybindBtn = createButton(MiddleColumn, UDim2.new(0.32, 0, 0, 495), UDim2.new(0.15, 0, 0, 35), keybinds.mouseAimMode or "Key")
local MouseAimHoldKeybindBtn = createButton(MiddleColumn, UDim2.new(0.49, 0, 0, 495), UDim2.new(0.15, 0, 0, 35), keybinds.mouseAimHold or "Mouse2")

local MouseAimHeadChanceInput = createTextBox(MiddleColumn, UDim2.new(0.05, 0, 0, 535), UDim2.new(0.45, 0, 0, 35), "Head Chance % (0-100)", tostring(states.mouseAimHeadChance))
local MouseAimLegitmentInput = createTextBox(MiddleColumn, UDim2.new(0.52, 0, 0, 535), UDim2.new(0.43, 0, 0, 35), "Legitment (0-100)", tostring(states.mouseAimLegitment))
local MouseAimFOVInput = createTextBox(MiddleColumn, UDim2.new(0.05, 0, 0, 575), UDim2.new(0.45, 0, 0, 35), "MouseAim FOV (200)", tostring(states.mouseAimFOV))
local MouseAimSmoothInput = createTextBox(MiddleColumn, UDim2.new(0.52, 0, 0, 575), UDim2.new(0.43, 0, 0, 35), "Smoothness (0=instant)", tostring(states.mouseAimSmoothness))

-- === RIGHT COLUMN ===
createSectionLabel("Information", RightColumn, 10)
local InfoContent = Instance.new("TextLabel")
InfoContent.Size = UDim2.new(0.9, 0, 0, 90)
InfoContent.Position = UDim2.new(0.05, 0, 0, 40)
InfoContent.BackgroundColor3 = colors.sectionBg
InfoContent.TextColor3 = Color3.fromRGB(220, 220, 220)
InfoContent.Font = Enum.Font.Gotham
InfoContent.TextSize = 13
InfoContent.TextXAlignment = Enum.TextXAlignment.Left
InfoContent.TextYAlignment = Enum.TextYAlignment.Top
InfoContent.Text = "Welcome "..LocalPlayer.DisplayName.."!\nAlso Known As "..LocalPlayer.Name..".\n\nVersion: v2.3\nPublished by Zalore Hub."
InfoContent.ZIndex = 11
InfoContent.Parent = RightColumn

createDivider(RightColumn, 145)
createSectionLabel("Settings", RightColumn, 155)
local ToggleKeyBtn = createButton(RightColumn, UDim2.new(0.6, 0, 0, 185), UDim2.new(0.3, 0, 0, 30), keybinds.toggle)
local ThemeBtn = createButton(RightColumn, UDim2.new(0.6, 0, 0, 220), UDim2.new(0.3, 0, 0, 30), states.currentTheme)
local MenuKillBtn = createButton(RightColumn, UDim2.new(0.05, 0, 0, 255), UDim2.new(0.9, 0, 0, 35), "Menu Kill", colors.buttonRed)

createDivider(RightColumn, 305)
createSectionLabel("Configuration Block", RightColumn, 315)
local ConfigCodeInput = createTextBox(RightColumn, UDim2.new(0.05, 0, 0, 345), UDim2.new(0.9, 0, 0, 35), "Paste config code here...")
local LoadConfigBtn = createButton(RightColumn, UDim2.new(0.05, 0, 0, 390), UDim2.new(0.43, 0, 0, 35), "Load Config", colors.buttonBlue)
local GetCodeBtn = createButton(RightColumn, UDim2.new(0.52, 0, 0, 390), UDim2.new(0.43, 0, 0, 35), "Get Code", colors.buttonPurple)
local GeneratedCodeInput = createTextBox(RightColumn, UDim2.new(0.05, 0, 0, 435), UDim2.new(0.9, 0, 0, 35), "Generated code")
local CopyCodeBtn = createButton(RightColumn, UDim2.new(0.05, 0, 0, 480), UDim2.new(0.9, 0, 0, 30), "Copy to Clipboard", colors.buttonGreen)

createDivider(RightColumn, 525)
createSectionLabel("Console", RightColumn, 535)

ConsoleWindowCloseBtn.MouseButton1Click:Connect(function()
	ConsoleWindow.Visible = false
	ConsoleWindowBtn.BackgroundColor3 = colors.buttonDefault
end)

ConsoleWindowBtn.MouseButton1Click:Connect(function()
	ConsoleWindow.Visible = not ConsoleWindow.Visible
	ConsoleWindowBtn.BackgroundColor3 = ConsoleWindow.Visible and colors.buttonGreen or colors.buttonDefault
end)

-- Сохраняем UI элементы
shared.ui = {
	SilentToggleBtn = SilentToggleBtn, SilentKeybindBtn = SilentKeybindBtn, SilentShowFOVBtn = SilentShowFOVBtn, SilentFOVInput = SilentFOVInput,
	LegitToggleBtn = LegitToggleBtn, LegitKeybindBtn = LegitKeybindBtn, LegitShowFOVBtn = LegitShowFOVBtn, LegitWallCheckBtn = LegitWallCheckBtn,
	LegitModeBtn = LegitModeBtn, LegitModeKeybindBtn = LegitModeKeybindBtn, LegitHoldKeybindBtn = LegitHoldKeybindBtn,
	LegitTargetLockBtn = LegitTargetLockBtn, LegitTargetLockKeybindBtn = LegitTargetLockKeybindBtn, LegitTargetInput = LegitTargetInput,
	LegitFOVInput = LegitFOVInput, LegitSmoothInput = LegitSmoothInput,
	MouseAimToggleBtn = MouseAimToggleBtn, MouseAimKeybindBtn = MouseAimKeybindBtn, MouseAimWallCheckBtn = MouseAimWallCheckBtn,
	MouseAimShowFOVBtn = MouseAimShowFOVBtn, MouseAimModeBtn = MouseAimModeBtn, MouseAimModeKeybindBtn = MouseAimModeKeybindBtn,
	MouseAimHoldKeybindBtn = MouseAimHoldKeybindBtn, MouseAimHeadChanceInput = MouseAimHeadChanceInput, MouseAimLegitmentInput = MouseAimLegitmentInput,
	MouseAimFOVInput = MouseAimFOVInput, MouseAimSmoothInput = MouseAimSmoothInput,
	RageToggleBtn = RageToggleBtn, RageKeybindBtn = RageKeybindBtn, RageRecallKeybindBtn = RageRecallKeybindBtn,
	ArcadeRageBtn = ArcadeRageBtn, RageKillBtn = RageKillBtn,
	ESPBtn = ESPBtn, ESPNamesBtn = ESPNamesBtn, ESPHPBtn = ESPHPBtn
}

-- === ТЕЛЕПОРТАЦИЯ ===
local function teleportBehindTarget(targetPlayer)
	local success, err = pcall(function()
		local tChar = targetPlayer.Character
		if not tChar then error("No character") end
		local tRoot = tChar:WaitForChild("HumanoidRootPart", 5)
		if not tRoot then error("No root") end
		local myChar = LocalPlayer.Character
		if not myChar then error("No character") end
		local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)
		if not myRoot then error("No root") end
		myRoot.CFrame = tRoot.CFrame
		Camera.CFrame = tRoot.CFrame
	end)
	if not success then log("❌ TP: "..tostring(err), Color3.fromRGB(231, 76, 60)) end
end

local function performDirectTeleport()
	local n = PlayerInput.Text:gsub("^%s*(.-)%s*$", "%1")
	if n == "" then log("⚠️ Enter name", Color3.fromRGB(241, 196, 15)) return end
	local t = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name):find(string.lower(n)) then t = p break end
	end
	if not t then log("❌ Not found", Color3.fromRGB(231, 76, 60)) return end
	if t == LocalPlayer then log("❌ Self", Color3.fromRGB(231, 76, 60)) return end
	log("🎯 TP to "..t.Name, Color3.fromRGB(52, 152, 219))
	teleportBehindTarget(t)
end

local function performArcadeTeleport()
	local pl = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(pl, p) end
	end
	if #pl == 0 then log("❌ No players", Color3.fromRGB(231, 76, 60)) return end
	local t = pl[math.random(1, #pl)]
	log(" "..t.Name, Color3.fromRGB(52, 152, 219))
	teleportBehindTarget(t)
end

-- === ESP (ПОЛНОСТЬЮ ПЕРЕПИСАННЫЙ) ===
local espHighlights = {}
local espBillboards = {}

local function createESPBillboard(player)
	if espBillboards[player] then 
		-- Если уже существует, просто обновим ссылки
		return espBillboards[player]
	end
	
	local character = player.Character
	if not character then return nil end
	
	local head = character:WaitForChild("Head", 5)
	if not head then return nil end
	
	-- Удаляем старые если есть
	for _, old in ipairs(head:GetChildren()) do
		if old.Name == "NymiusESP" then old:Destroy() end
	end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NymiusESP"
	billboard.Size = UDim2.new(0, 180, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = true
	billboard.Parent = head
	
	-- Ник игрока
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.ZIndex = 100
	nameLabel.Visible = states.espShowNames
	nameLabel.Parent = billboard
	
	-- HP
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
	hpLabel.Position = UDim2.new(0, 0, 0.5, 0)
	hpLabel.BackgroundTransparency = 1
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local currentHP = humanoid and math.floor(humanoid.Health) or 0
	local maxHP = 150
	
	hpLabel.Text = "HP: " .. currentHP .. "/" .. maxHP
	hpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.TextSize = 11
	hpLabel.TextStrokeTransparency = 0.3
	hpLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	hpLabel.ZIndex = 100
	hpLabel.Visible = states.espShowHP
	hpLabel.Parent = billboard
	
	espBillboards[player] = {
		billboard = billboard,
		nameLabel = nameLabel,
		hpLabel = hpLabel,
		head = head
	}
	
	return espBillboards[player]
end

local function updateESPBillboards()
	for player, data in pairs(espBillboards) do
		if player.Character and data.billboard and data.billboard.Parent then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and data.hpLabel then
				local currentHP = math.floor(humanoid.Health)
				local maxHP = 150
				data.hpLabel.Text = "HP: " .. currentHP .. "/" .. maxHP
				
				-- Цвет HP
				local hpPercent = currentHP / maxHP
				if hpPercent > 0.6 then
					data.hpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				elseif hpPercent > 0.3 then
					data.hpLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
				else
					data.hpLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				end
				
				-- Обновляем видимость
				if data.nameLabel then
					data.nameLabel.Visible = states.espShowNames
				end
				if data.hpLabel then
					data.hpLabel.Visible = states.espShowHP
				end
				
				-- Billboard виден если ESP включен И хотя бы один из режимов показывания включен
				data.billboard.Enabled = states.espEnabled and (states.espShowNames or states.espShowHP)
			end
		else
			-- Игрок умер или голова удалена - помечаем для пересоздания
			if player.Character then
				-- Ждём новый character
				task.spawn(function()
					player.CharacterAdded:Wait()
					task.wait(1)
					if states.espEnabled then
						remESP(player)
						addESP(player)
					end
				end)
			end
		end
	end
end

local function addESP(p)
	if p == LocalPlayer or not p.Character then return end
	
	-- Highlight
	if espHighlights[p] then espHighlights[p]:Destroy() end
	local h = Instance.new("Highlight")
	h.Adornee = p.Character
	h.FillColor = Color3.fromRGB(255, 0, 0)
	h.FillTransparency = 0.5
	h.OutlineColor = Color3.new(1, 1, 1)
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = p.Character
	espHighlights[p] = h
	
	-- Billboard
	createESPBillboard(p)
end

local function remESP(p)
	if espHighlights[p] then 
		espHighlights[p]:Destroy() 
		espHighlights[p] = nil 
	end
	if espBillboards[p] then
		if espBillboards[p].billboard then 
			espBillboards[p].billboard:Destroy() 
		end
		espBillboards[p] = nil
	end
end

local function toggleESP()
	states.espEnabled = not states.espEnabled
	ESPBtn.Text = "ESP: "..(states.espEnabled and "ON" or "OFF")
	ESPBtn.BackgroundColor3 = states.espEnabled and colors.buttonGreen or colors.buttonDefault
	if states.espEnabled then
		for _, p in ipairs(Players:GetPlayers()) do 
			if p ~= LocalPlayer then 
				task.spawn(function() addESP(p) end)
			end 
		end
		log("✅ ESP on", Color3.fromRGB(46, 204, 113))
	else
		for p, _ in pairs(espHighlights) do remESP(p) end
		log("❌ ESP off", Color3.fromRGB(231, 76, 60))
	end
end

ESPBtn.MouseButton1Click:Connect(toggleESP)

local function toggleESPNames()
	states.espShowNames = not states.espShowNames
	ESPNamesBtn.Text = "Names: "..(states.espShowNames and "ON" or "OFF")
	ESPNamesBtn.BackgroundColor3 = states.espShowNames and colors.buttonGreen or colors.buttonDefault
	log("📛 ESP Names "..(states.espShowNames and "enabled" or "disabled"), states.espShowNames and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60))
end

ESPNamesBtn.MouseButton1Click:Connect(toggleESPNames)

local function toggleESPHP()
	states.espShowHP = not states.espShowHP
	ESPHPBtn.Text = "HP: "..(states.espShowHP and "ON" or "OFF")
	ESPHPBtn.BackgroundColor3 = states.espShowHP and colors.buttonGreen or colors.buttonDefault
	log("❤️ ESP HP "..(states.espShowHP and "enabled" or "disabled"), states.espShowHP and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60))
end

ESPHPBtn.MouseButton1Click:Connect(toggleESPHP)

Players.PlayerAdded:Connect(function(p)
	if states.espEnabled then
		p.CharacterAdded:Connect(function()
			task.wait(1)
			addESP(p)
		end)
	end
end)

Players.PlayerRemoving:Connect(remESP)

-- Обновление ESP каждый кадр
RunService.RenderStepped:Connect(function()
	if states.espEnabled then
		updateESPBillboards()
	end
end)

-- === NOCLIP ===
local function toggleNoclip()
	states.noclipEnabled = not states.noclipEnabled
	NoclipBtn.Text = "Noclip: "..(states.noclipEnabled and "ON" or "OFF")
	NoclipBtn.BackgroundColor3 = states.noclipEnabled and colors.buttonGreen or colors.buttonDefault
end
NoclipBtn.MouseButton1Click:Connect(toggleNoclip)

RunService.Stepped:Connect(function()
	if states.noclipEnabled then
		local c = LocalPlayer.Character
		if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = false end end end
	end
end)

-- === FLY ===
local bv, bg = nil, nil
local function startFly()
	local c = LocalPlayer.Character
	if not c then return end
	local r = c:FindFirstChild("HumanoidRootPart")
	if not r then return end
	local h = c:FindFirstChild("Humanoid")
	if h then h.PlatformStand = true end
	bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.zero
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Parent = r
	bg = Instance.new("BodyGyro")
	bg.D = 200
	bg.P = 10000
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.Parent = r
end

local function stopFly()
	local c = LocalPlayer.Character
	if c then local h = c:FindFirstChild("Humanoid") if h then h.PlatformStand = false end end
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
end

local function toggleFly()
	states.flyEnabled = not states.flyEnabled
	FlyBtn.Text = "Fly: "..(states.flyEnabled and "ON" or "OFF")
	FlyBtn.BackgroundColor3 = states.flyEnabled and colors.buttonGreen or colors.buttonDefault
	if states.flyEnabled then startFly() log("✅ Fly on", Color3.fromRGB(46, 204, 113)) else stopFly() log("❌ Fly off", Color3.fromRGB(231, 76, 60)) end
end

FlyBtn.MouseButton1Click:Connect(toggleFly)
FlySpeedInput.FocusLost:Connect(function()
	local v = tonumber(FlySpeedInput.Text)
	if v and v > 0 then states.flySpeed = v end
end)

RunService.RenderStepped:Connect(function()
	if states.flyEnabled and bv and bg then
		local cf = Camera.CFrame
		bg.CFrame = cf
		local sp = states.flySpeed * 50
		local md = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md - cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then md = md - Vector3.new(0, 1, 0) end
		bv.Velocity = md.Magnitude > 0 and md.Unit * sp or Vector3.zero
	end
end)

-- === WALKSPEED ===
local function toggleWalkSpeed()
	states.walkSpeedEnabled = not states.walkSpeedEnabled
	WalkSpeedChangerBtn.Text = "WalkSpeed: "..(states.walkSpeedEnabled and "ON" or "OFF")
	WalkSpeedChangerBtn.BackgroundColor3 = states.walkSpeedEnabled and colors.buttonGreen or colors.buttonDefault
	local c = LocalPlayer.Character
	if c then
		local h = c:FindFirstChild("Humanoid")
		if h then h.WalkSpeed = states.walkSpeedEnabled and states.walkSpeedValue * 16 or 16 end
	end
end
WalkSpeedChangerBtn.MouseButton1Click:Connect(toggleWalkSpeed)
WalkSpeedInput.FocusLost:Connect(function()
	local v = tonumber(WalkSpeedInput.Text)
	if v and v > 0 then states.walkSpeedValue = v end
end)

-- === STAFF DETECTOR ===
local StaffWindow = Instance.new("Frame")
StaffWindow.Size = UDim2.new(0, 280, 0, 80)
StaffWindow.Position = UDim2.new(0.5, -140, 0, 60)
StaffWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
StaffWindow.Active = true
StaffWindow.Draggable = true
StaffWindow.Visible = false
StaffWindow.ZIndex = 20
StaffWindow.Parent = ScreenGui

local StaffStatusLabel = Instance.new("TextLabel")
StaffStatusLabel.Size = UDim2.new(0.95, 0, 0, 45)
StaffStatusLabel.Position = UDim2.new(0.025, 0, 0, 30)
StaffStatusLabel.BackgroundTransparency = 1
StaffStatusLabel.Text = "Scanning..."
StaffStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StaffStatusLabel.Font = Enum.Font.GothamBold
StaffStatusLabel.TextSize = 13
StaffStatusLabel.TextWrapped = true
StaffStatusLabel.ZIndex = 21
StaffStatusLabel.Parent = StaffWindow

local function scanForStaff()
	local detected = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and staffLower[string.lower(p.Name)] then
			table.insert(detected, p.DisplayName.." (@"..p.Name..")")
		end
	end
	if #detected == 0 then
		StaffStatusLabel.Text = "✅ No one found"
		StaffStatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
	else
		StaffStatusLabel.Text = "️ Staff:\n"..table.concat(detected, "\n")
		StaffStatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
		log("⚠️ STAFF: "..table.concat(detected, ", "), Color3.fromRGB(231, 76, 60))
	end
end

local function toggleStaffDetector()
	states.staffDetectorEnabled = not states.staffDetectorEnabled
	StaffDetectorBtn.Text = "Staff Detector: "..(states.staffDetectorEnabled and "ON" or "OFF")
	StaffDetectorBtn.BackgroundColor3 = states.staffDetectorEnabled and colors.buttonGreen or colors.buttonDefault
	StaffWindow.Visible = states.staffDetectorEnabled
	if states.staffDetectorEnabled then scanForStaff() end
end
StaffDetectorBtn.MouseButton1Click:Connect(toggleStaffDetector)
task.spawn(function()
	while true do
		task.wait(2)
		if states.staffDetectorEnabled then scanForStaff() end
	end
end)

-- === КОНФИГИ ===
GetCodeBtn.MouseButton1Click:Connect(function()
	GeneratedCodeInput.Text = generateConfigCode()
	log("📋 Code generated", Color3.fromRGB(46, 204, 113))
end)
LoadConfigBtn.MouseButton1Click:Connect(function()
	local code = ConfigCodeInput.Text:gsub("%s+", "")
	if code == "" then log("⚠️ Empty", Color3.fromRGB(241, 196, 15)) return end
	local ok, err = loadConfigFromCode(code)
	if ok then log("✅ Loaded", Color3.fromRGB(46, 204, 113)) else log("❌ "..tostring(err), Color3.fromRGB(231, 76, 60)) end
end)
CopyCodeBtn.MouseButton1Click:Connect(function()
	local code = GeneratedCodeInput.Text
	if code == "" then log("⚠️ Empty", Color3.fromRGB(241, 196, 15)) return end
	if hasSetClipboard then setclipboard(code) log("✅ Copied", Color3.fromRGB(46, 204, 113)) end
end)

-- === ТЕМЫ ===
local function applyTheme(name)
	local theme = themes[name]
	if not theme then return end
	states.currentTheme = name
	ThemeBtn.Text = name
	MainFrame.BackgroundTransparency = theme.transparency
	Title.BackgroundTransparency = theme.transparency
end
ThemeBtn.MouseButton1Click:Connect(function()
	applyTheme(states.currentTheme == "Classic" and "Aero" or "Classic")
end)

-- === ДОПОЛНИТЕЛЬНЫЕ ОКНА ===
local function createMiniWindow(name, size, position)
	local Window = Instance.new("Frame")
	Window.Size = size
	Window.Position = position
	Window.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	Window.Active = true
	Window.Draggable = true
	Window.Visible = false
	Window.ZIndex = 20
	Window.Parent = ScreenGui
	local tb = Instance.new("Frame")
	tb.Size = UDim2.new(1, 0, 0, 25)
	tb.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	tb.ZIndex = 21
	tb.Parent = Window
	local tt = Instance.new("TextLabel")
	tt.Size = UDim2.new(1, 0, 1, 0)
	tt.BackgroundTransparency = 1
	tt.Text = name
	tt.TextColor3 = Color3.new(1, 1, 1)
	tt.Font = Enum.Font.GothamBold
	tt.TextSize = 12
	tt.ZIndex = 21
	tt.Parent = tb
	local cb = Instance.new("TextButton")
	cb.Size = UDim2.new(0, 20, 0, 20)
	cb.Position = UDim2.new(1, -22, 0, 2)
	cb.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
	cb.Text = "X"
	cb.TextColor3 = Color3.new(1, 1, 1)
	cb.Font = Enum.Font.GothamBold
	cb.TextSize = 10
	cb.ZIndex = 21
	cb.Parent = tb
	return Window, cb
end

local KeybindsWindow, KeybindsClose = createMiniWindow("Keybinds", UDim2.new(0, 220, 0, 400), UDim2.new(0, 50, 0.5, -200))
local KeybindsContent = Instance.new("TextLabel")
KeybindsContent.Size = UDim2.new(0.9, 0, 0.85, 0)
KeybindsContent.Position = UDim2.new(0.05, 0, 0.12, 0)
KeybindsContent.BackgroundTransparency = 1
KeybindsContent.TextColor3 = Color3.fromRGB(200, 200, 200)
KeybindsContent.Font = Enum.Font.Gotham
KeybindsContent.TextSize = 10
KeybindsContent.TextXAlignment = Enum.TextXAlignment.Left
KeybindsContent.TextYAlignment = Enum.TextYAlignment.Top
KeybindsContent.ZIndex = 21
KeybindsContent.Parent = KeybindsWindow

local ProfileWindow, ProfileClose = createMiniWindow("Profile", UDim2.new(0, 140, 0, 90), UDim2.new(0, 290, 0.5, -45))
local ProfileContent = Instance.new("TextLabel")
ProfileContent.Size = UDim2.new(0.9, 0, 0.75, 0)
ProfileContent.Position = UDim2.new(0.05, 0, 0.2, 0)
ProfileContent.BackgroundTransparency = 1
ProfileContent.Text = "Username:\n"..LocalPlayer.Name.."\n\nDisplay:\n"..LocalPlayer.DisplayName
ProfileContent.TextColor3 = Color3.fromRGB(200, 200, 200)
ProfileContent.Font = Enum.Font.Gotham
ProfileContent.TextSize = 10
ProfileContent.TextXAlignment = Enum.TextXAlignment.Left
ProfileContent.TextYAlignment = Enum.TextYAlignment.Top
ProfileContent.ZIndex = 21
ProfileContent.Parent = ProfileWindow

local NotesWindow, NotesClose = createMiniWindow("Notes", UDim2.new(0, 150, 0, 125), UDim2.new(0, 450, 0.5, -62))
local NotesTextBox = Instance.new("TextBox")
NotesTextBox.Size = UDim2.new(0.9, 0, 0.75, 0)
NotesTextBox.Position = UDim2.new(0.05, 0, 0.2, 0)
NotesTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
NotesTextBox.TextColor3 = Color3.new(1, 1, 1)
NotesTextBox.PlaceholderText = "Notes..."
NotesTextBox.Font = Enum.Font.Gotham
NotesTextBox.TextSize = 10
NotesTextBox.TextXAlignment = Enum.TextXAlignment.Left
NotesTextBox.TextYAlignment = Enum.TextYAlignment.Top
NotesTextBox.ClearTextOnFocus = false
NotesTextBox.MultiLine = true
NotesTextBox.TextWrapped = true
NotesTextBox.ZIndex = 21
NotesTextBox.Parent = NotesWindow

local function updateKeybindsDisplay()
	local text = ""
	text = text.."Direct TP - "..(keybinds.direct or "no key").."\n"
	text = text.."Arcade TP - "..(keybinds.arcade or "no key").."\n"
	text = text.."ESP - "..(keybinds.esp or "no key").."\n"
	text = text.."Toggle Menu - "..(keybinds.toggle or "no key").."\n"
	text = text.."Silent Aim - "..(keybinds.silent or "no key").."\n"
	text = text.."Fly - "..(keybinds.fly or "no key").."\n"
	text = text.."Noclip - "..(keybinds.noclip or "no key").."\n"
	text = text.."RageBot - "..(keybinds.rage or "no key").."\n"
	text = text.."Rage Recall - "..(keybinds.rageRecall or "no key").."\n"
	text = text.."Legit AimBot - "..(keybinds.legit or "no key").."\n"
	text = text.."Legit Mode - "..(keybinds.legitMode or "no key").."\n"
	text = text.."Legit Hold - "..(keybinds.legitHold or "Mouse2").."\n"
	text = text.."Legit Lock - "..(keybinds.legitTargetLock or "no key").."\n"
	text = text.."Mouse Aim - "..(keybinds.mouseAim or "no key").."\n"
	text = text.."Mouse Mode - "..(keybinds.mouseAimMode or "no key").."\n"
	text = text.."Mouse Hold - "..(keybinds.mouseAimHold or "Mouse2").."\n"
	KeybindsContent.Text = text
end

local keybindsVisible, profileVisible, notesVisible = false, false, false
KeybindsBtn.MouseButton1Click:Connect(function()
	keybindsVisible = not keybindsVisible
	KeybindsWindow.Visible = keybindsVisible
	KeybindsBtn.BackgroundColor3 = keybindsVisible and colors.buttonGreen or colors.buttonDefault
	updateKeybindsDisplay()
end)
KeybindsClose.MouseButton1Click:Connect(function() keybindsVisible = false KeybindsWindow.Visible = false end)

ProfileBtn.MouseButton1Click:Connect(function()
	profileVisible = not profileVisible
	ProfileWindow.Visible = profileVisible
	ProfileBtn.BackgroundColor3 = profileVisible and colors.buttonGreen or colors.buttonDefault
end)
ProfileClose.MouseButton1Click:Connect(function() profileVisible = false ProfileWindow.Visible = false end)

NotesBtn.MouseButton1Click:Connect(function()
	notesVisible = not notesVisible
	NotesWindow.Visible = notesVisible
	NotesBtn.BackgroundColor3 = notesVisible and colors.buttonGreen or colors.buttonDefault
end)
NotesClose.MouseButton1Click:Connect(function() notesVisible = false NotesWindow.Visible = false end)

-- === КЕЙБИНДЫ ===
local waitingForKeybind = nil
local function getKeyDisplayName(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then return "Mouse1" end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then return "Mouse2" end
	if input.UserInputType == Enum.UserInputType.MouseButton3 then return "Mouse3" end
	local kn = input.KeyCode.Name
	if kn ~= "" and kn ~= "Unknown" then return kn end
	return nil
end

local function startKeybindCapture(name, btn)
	waitingForKeybind = name
	btn.Text = "..."
	btn.BackgroundColor3 = colors.buttonYellow
end

local keybindButtonsMap = {
	direct = DirectKeybindBtn, arcade = ArcadeKeybindBtn, esp = ESPKeybindBtn,
	toggle = ToggleKeyBtn, silent = SilentKeybindBtn, fly = FlyKeybindBtn,
	noclip = NoclipKeybindBtn, rage = RageKeybindBtn, rageRecall = RageRecallKeybindBtn,
	legit = LegitKeybindBtn, legitMode = LegitModeKeybindBtn, legitHold = LegitHoldKeybindBtn,
	legitTargetLock = LegitTargetLockKeybindBtn, mouseAim = MouseAimKeybindBtn,
	mouseAimMode = MouseAimModeKeybindBtn, mouseAimHold = MouseAimHoldKeybindBtn,
}

for name, btn in pairs(keybindButtonsMap) do
	btn.MouseButton1Click:Connect(function() startKeybindCapture(name, btn) end)
end

shared.keybindActions = {
	direct = performDirectTeleport,
	arcade = performArcadeTeleport,
	esp = toggleESP,
	toggle = function() MainFrame.Visible = not MainFrame.Visible Overlay.Visible = MainFrame.Visible end,
	fly = toggleFly,
	noclip = toggleNoclip
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local key = getKeyDisplayName(input)
	if not key then return end
	
	if waitingForKeybind then
		keybinds[waitingForKeybind] = key
		local btn = keybindButtonsMap[waitingForKeybind]
		if btn then btn.Text = key btn.BackgroundColor3 = colors.buttonDefault end
		log("✅ "..waitingForKeybind.." → "..key, Color3.fromRGB(46, 204, 113))
		waitingForKeybind = nil
		updateKeybindsDisplay()
		return
	end
	
	for name, action in pairs(shared.keybindActions) do
		if keybinds[name] and key == keybinds[name] then action() end
	end
	
	if keybinds.legitHold and key == keybinds.legitHold then shared.legitHolding = true end
	if keybinds.mouseAimHold and key == keybinds.mouseAimHold then shared.mouseAimHolding = true end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local key = getKeyDisplayName(input)
	if not key then return end
	if keybinds.legitHold and key == keybinds.legitHold then shared.legitHolding = false end
	if keybinds.mouseAimHold and key == keybinds.mouseAimHold then shared.mouseAimHolding = false end
end)

TeleportBtn.MouseButton1Click:Connect(performDirectTeleport)
RandomBtn.MouseButton1Click:Connect(performArcadeTeleport)

-- Кнопки селекторов
TPSelectorBtn.MouseButton1Click:Connect(function()
	TPSelectorWindow.Visible = not TPSelectorWindow.Visible
	if TPSelectorWindow.Visible then
		refreshTPSelector()
	end
end)

RageSelectorBtn.MouseButton1Click:Connect(function()
	RageSelectorWindow.Visible = not RageSelectorWindow.Visible
	if RageSelectorWindow.Visible then
		refreshRageSelector()
	end
end)

MenuKillBtn.MouseButton1Click:Connect(function() log("💀 Menu killed", Color3.fromRGB(231, 76, 60)) ScreenGui:Destroy() end)

for i = 1, 5 do
	local targetInput = LeftColumn:FindFirstChild("RageTarget"..i)
	if targetInput then
		targetInput.FocusLost:Connect(function() states.rageTargets[i] = targetInput.Text end)
	end
end

ArcadeRageBtn.MouseButton1Click:Connect(function()
	states.arcadeRageEnabled = not states.arcadeRageEnabled
	ArcadeRageBtn.Text = "Arcade: "..(states.arcadeRageEnabled and "ON" or "OFF")
	ArcadeRageBtn.BackgroundColor3 = states.arcadeRageEnabled and colors.buttonGreen or colors.buttonDefault
	log(" Arcade Rage "..(states.arcadeRageEnabled and "enabled" or "disabled"), states.arcadeRageEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60))
end)

-- === ЗАГРУЗКА МОДУЛЯ ===
if loadAimbotModule() then
	log("✅ AimbotModule loaded from GitHub", Color3.fromRGB(46, 204, 113))
else
	log("⚠️ AimbotModule failed to load", Color3.fromRGB(241, 196, 15))
end

-- === UI UPDATE ===
function updateAllUIFromStates()
	ESPBtn.Text = "ESP: "..(states.espEnabled and "ON" or "OFF")
	ESPBtn.BackgroundColor3 = states.espEnabled and colors.buttonGreen or colors.buttonDefault
	ESPNamesBtn.Text = "Names: "..(states.espShowNames and "ON" or "OFF")
	ESPNamesBtn.BackgroundColor3 = states.espShowNames and colors.buttonGreen or colors.buttonDefault
	ESPHPBtn.Text = "HP: "..(states.espShowHP and "ON" or "OFF")
	ESPHPBtn.BackgroundColor3 = states.espShowHP and colors.buttonGreen or colors.buttonDefault
	FlyBtn.Text = "Fly: "..(states.flyEnabled and "ON" or "OFF")
	FlyBtn.BackgroundColor3 = states.flyEnabled and colors.buttonGreen or colors.buttonDefault
	WalkSpeedChangerBtn.Text = "WalkSpeed: "..(states.walkSpeedEnabled and "ON" or "OFF")
	WalkSpeedChangerBtn.BackgroundColor3 = states.walkSpeedEnabled and colors.buttonGreen or colors.buttonDefault
	NoclipBtn.Text = "Noclip: "..(states.noclipEnabled and "ON" or "OFF")
	NoclipBtn.BackgroundColor3 = states.noclipEnabled and colors.buttonGreen or colors.buttonDefault
	StaffDetectorBtn.Text = "Staff Detector: "..(states.staffDetectorEnabled and "ON" or "OFF")
	StaffDetectorBtn.BackgroundColor3 = states.staffDetectorEnabled and colors.buttonGreen or colors.buttonDefault
	ThemeBtn.Text = states.currentTheme
	ArcadeRageBtn.Text = "Arcade: "..(states.arcadeRageEnabled and "ON" or "OFF")
	ArcadeRageBtn.BackgroundColor3 = states.arcadeRageEnabled and colors.buttonGreen or colors.buttonDefault
	applyTheme(states.currentTheme)
end

function updateAllKeybindButtons()
	DirectKeybindBtn.Text = keybinds.direct or "Key"
	ArcadeKeybindBtn.Text = keybinds.arcade or "Key"
	ESPKeybindBtn.Text = keybinds.esp or "Key"
	ToggleKeyBtn.Text = keybinds.toggle or "Key"
	FlyKeybindBtn.Text = keybinds.fly or "Key"
	NoclipKeybindBtn.Text = keybinds.noclip or "Key"
	LegitHoldKeybindBtn.Text = keybinds.legitHold or "Mouse2"
	MouseAimHoldKeybindBtn.Text = keybinds.mouseAimHold or "Mouse2"
	RageRecallKeybindBtn.Text = keybinds.rageRecall or "Key"
end

-- === СТАРТ ===
log("🚀 Nymius Rivals v2.3 loaded!", Color3.fromRGB(46, 204, 113))
log("💡 Welcome "..LocalPlayer.DisplayName.."!", Color3.fromRGB(180, 180, 180))
log("💡 Toggle: "..keybinds.toggle, Color3.fromRGB(180, 180, 180))
log("💡 Published by Zalore Hub", Color3.fromRGB(180, 180, 180))
print("✅ Nymius Rivals v2.3 loaded!")