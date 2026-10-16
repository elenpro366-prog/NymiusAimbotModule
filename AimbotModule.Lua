-- Nymius Rivals v2.2 - AimbotModule
local shared = getgenv().NymiusShared
if not shared then
	warn("❌ NymiusShared not found")
	return
end

local Players = shared.Players
local UserInputService = shared.UserInputService
local RunService = shared.RunService
local LocalPlayer = shared.LocalPlayer
local Camera = shared.Camera
local states = shared.states
local keybinds = shared.keybinds
local colors = shared.colors
local ui = shared.ui
local log = shared.log

local hasHookmetamethod = shared.hasHookmetamethod
local hasDrawing = shared.hasDrawing
local hasMouseMoveRel = shared.hasMouseMoveRel

-- === SILENT AIM ===
local silentHookActive = false
local oldNamecall = nil

if hasHookmetamethod then
	local success, err = pcall(function()
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if states.silentEnabled and (method == "Raycast" or method == "FindPartOnRay") then
				local myChar = LocalPlayer.Character
				if myChar and myChar:FindFirstChild("Head") then
					local myHead = myChar:FindFirstChild("Head")
					local closest, closestDist = nil, states.silentFOV
					local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
					
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and p.Character then
							local head = p.Character:FindFirstChild("Head")
							if head then
								local sp, os = Camera:WorldToViewportPoint(head.Position)
								if os then
									local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
									if d < closestDist then closestDist = d closest = head end
								end
							end
						end
					end
					
					if closest then
						local args = {...}
						if method == "Raycast" then
							local origin, direction = args[1], args[2]
							if origin and direction then
								return oldNamecall(self, origin, (closest.Position - origin).Unit * direction.Magnitude, select(3, ...))
							end
						end
					end
				end
			end
			return oldNamecall(self, ...)
		end)
		silentHookActive = true
	end)
	if not success then log("⚠️ Silent hook failed: "..tostring(err), Color3.fromRGB(241, 196, 15)) end
else
	log("⚠️ Silent Aim not available", Color3.fromRGB(241, 196, 15))
end

local function toggleSilent()
	if not silentHookActive then
		log("❌ Silent Aim not available", Color3.fromRGB(231, 76, 60))
		return
	end
	states.silentEnabled = not states.silentEnabled
	ui.SilentToggleBtn.Text = "Toggle: "..(states.silentEnabled and "ON" or "OFF")
	ui.SilentToggleBtn.BackgroundColor3 = states.silentEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	log(states.silentEnabled and "✅ Silent Aim on" or "❌ Silent Aim off", states.silentEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60))
end

ui.SilentToggleBtn.MouseButton1Click:Connect(toggleSilent)
ui.SilentShowFOVBtn.MouseButton1Click:Connect(function()
	states.silentShowFOV = not states.silentShowFOV
	ui.SilentShowFOVBtn.Text = "Show FOV: "..(states.silentShowFOV and "ON" or "OFF")
	ui.SilentShowFOVBtn.BackgroundColor3 = states.silentShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.SilentFOVInput.FocusLost:Connect(function()
	local v = tonumber(ui.SilentFOVInput.Text)
	if v and v > 0 then states.silentFOV = v end
end)

-- === LEGITBOT ===
local function findLegitTarget()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("Head") then return nil end
	local myHead = myChar:FindFirstChild("Head")
	local closest, closestDist = nil, states.legitFOV
	local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	
	if states.legitTargetLockEnabled and states.legitTargetLockName ~= "" then
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == string.lower(states.legitTargetLockName) and p ~= LocalPlayer and p.Character then
				local head = p.Character:FindFirstChild("Head")
				if head then
					local sp, os = Camera:WorldToViewportPoint(head.Position)
					if os then
						local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
						if d < closestDist then
							if states.legitWallCheck then
								local rp = RaycastParams.new()
								rp.FilterDescendantsInstances = {myChar}
								rp.FilterType = Enum.RaycastFilterType.Blacklist
								local r = workspace:Raycast(myHead.Position, (head.Position - myHead.Position), rp)
								if r and r.Instance and r.Instance:IsDescendantOf(p.Character) then return head end
							else
								return head
							end
						end
					end
				end
			end
		end
		return nil
	end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local sp, os = Camera:WorldToViewportPoint(head.Position)
				if os then
					local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
					if d < closestDist then
						if states.legitWallCheck then
							local rp = RaycastParams.new()
							rp.FilterDescendantsInstances = {myChar}
							rp.FilterType = Enum.RaycastFilterType.Blacklist
							local r = workspace:Raycast(myHead.Position, (head.Position - myHead.Position), rp)
							if r and r.Instance and r.Instance:IsDescendantOf(p.Character) then closestDist = d closest = head end
						else
							closestDist = d closest = head
						end
					end
				end
			end
		end
	end
	return closest
end

local function toggleLegit()
	states.legitEnabled = not states.legitEnabled
	ui.LegitToggleBtn.Text = "Legit: "..(states.legitEnabled and "ON" or "OFF")
	ui.LegitToggleBtn.BackgroundColor3 = states.legitEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end

ui.LegitToggleBtn.MouseButton1Click:Connect(toggleLegit)
ui.LegitShowFOVBtn.MouseButton1Click:Connect(function()
	states.legitShowFOV = not states.legitShowFOV
	ui.LegitShowFOVBtn.Text = "Show FOV: "..(states.legitShowFOV and "ON" or "OFF")
	ui.LegitShowFOVBtn.BackgroundColor3 = states.legitShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.LegitWallCheckBtn.MouseButton1Click:Connect(function()
	states.legitWallCheck = not states.legitWallCheck
	ui.LegitWallCheckBtn.Text = "Wall: "..(states.legitWallCheck and "ON" or "OFF")
	ui.LegitWallCheckBtn.BackgroundColor3 = states.legitWallCheck and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.LegitModeBtn.MouseButton1Click:Connect(function()
	states.legitMode = states.legitMode == "always" and "hold" or "always"
	ui.LegitModeBtn.Text = "Mode: "..(states.legitMode == "always" and "Always" or "Hold")
end)
ui.LegitTargetLockBtn.MouseButton1Click:Connect(function()
	states.legitTargetLockEnabled = not states.legitTargetLockEnabled
	ui.LegitTargetLockBtn.Text = "Lock: "..(states.legitTargetLockEnabled and "ON" or "OFF")
	ui.LegitTargetLockBtn.BackgroundColor3 = states.legitTargetLockEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.LegitTargetInput.FocusLost:Connect(function() states.legitTargetLockName = ui.LegitTargetInput.Text end)
ui.LegitFOVInput.FocusLost:Connect(function()
	local v = tonumber(ui.LegitFOVInput.Text)
	if v and v > 0 then states.legitFOV = v end
end)
ui.LegitSmoothInput.FocusLost:Connect(function()
	local v = tonumber(ui.LegitSmoothInput.Text)
	if v and v >= 0 then states.legitSmoothness = v end
end)

shared.legitHolding = false
RunService.RenderStepped:Connect(function()
	if not states.legitEnabled then return end
	local sa = states.legitMode == "always" or (states.legitMode == "hold" and shared.legitHolding)
	if sa then
		local t = findLegitTarget()
		if t then
			local tc = CFrame.new(Camera.CFrame.Position, t.Position)
			local sm = math.clamp(states.legitSmoothness, 0, 1)
			Camera.CFrame = sm == 0 and tc or Camera.CFrame:Lerp(tc, 1 - sm)
		end
	end
end)

-- === MOUSE AIMBOT ===
shared.mouseAimHolding = false

local function findMouseAimTarget()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("Head") then return nil end
	local myHead = myChar:FindFirstChild("Head")
	local closest, closestDist = nil, states.mouseAimFOV
	local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local roll = math.random(1, 100)
			local targetPartName = (roll <= states.mouseAimHeadChance) and "Head" or "HumanoidRootPart"
			local tp = p.Character:FindFirstChild(targetPartName) or p.Character:FindFirstChild("Head")
			
			if tp then
				local sp, os = Camera:WorldToViewportPoint(tp.Position)
				if os then
					local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
					if d < closestDist then
						if states.mouseAimWallCheck then
							local rp = RaycastParams.new()
							rp.FilterDescendantsInstances = {myChar}
							rp.FilterType = Enum.RaycastFilterType.Blacklist
							local r = workspace:Raycast(myHead.Position, (tp.Position - myHead.Position), rp)
							if r and r.Instance and r.Instance:IsDescendantOf(p.Character) then 
								closestDist = d 
								closest = {part = tp, pos = tp.Position} 
							end
						else
							closestDist = d 
							closest = {part = tp, pos = tp.Position}
						end
					end
				end
			end
		end
	end
	return closest
end

local function toggleMouseAim()
	states.mouseAimEnabled = not states.mouseAimEnabled
	ui.MouseAimToggleBtn.Text = "Toggle: "..(states.mouseAimEnabled and "ON" or "OFF")
	ui.MouseAimToggleBtn.BackgroundColor3 = states.mouseAimEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end

ui.MouseAimToggleBtn.MouseButton1Click:Connect(toggleMouseAim)
ui.MouseAimWallCheckBtn.MouseButton1Click:Connect(function()
	states.mouseAimWallCheck = not states.mouseAimWallCheck
	ui.MouseAimWallCheckBtn.Text = "Wall: "..(states.mouseAimWallCheck and "ON" or "OFF")
	ui.MouseAimWallCheckBtn.BackgroundColor3 = states.mouseAimWallCheck and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.MouseAimShowFOVBtn.MouseButton1Click:Connect(function()
	states.mouseAimShowFOV = not states.mouseAimShowFOV
	ui.MouseAimShowFOVBtn.Text = "Show FOV: "..(states.mouseAimShowFOV and "ON" or "OFF")
	ui.MouseAimShowFOVBtn.BackgroundColor3 = states.mouseAimShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end)
ui.MouseAimModeBtn.MouseButton1Click:Connect(function()
	states.mouseAimMode = states.mouseAimMode == "always" and "hold" or "always"
	ui.MouseAimModeBtn.Text = "Mode: "..(states.mouseAimMode == "always" and "Always" or "Hold")
end)

ui.MouseAimHeadChanceInput.FocusLost:Connect(function()
	local v = tonumber(ui.MouseAimHeadChanceInput.Text)
	if v and v >= 0 and v <= 100 then states.mouseAimHeadChance = v end
end)

ui.MouseAimLegitmentInput.FocusLost:Connect(function()
	local v = tonumber(ui.MouseAimLegitmentInput.Text)
	if v and v >= 0 and v <= 100 then states.mouseAimLegitment = v end
end)

ui.MouseAimFOVInput.FocusLost:Connect(function()
	local v = tonumber(ui.MouseAimFOVInput.Text)
	if v and v > 0 then states.mouseAimFOV = v end
end)

ui.MouseAimSmoothInput.FocusLost:Connect(function()
	local v = tonumber(ui.MouseAimSmoothInput.Text)
	if v and v >= 0 then states.mouseAimSmoothness = v end
end)

RunService.RenderStepped:Connect(function()
	if not states.mouseAimEnabled then return end
	if not hasMouseMoveRel then return end
	local sa = states.mouseAimMode == "always" or (states.mouseAimMode == "hold" and shared.mouseAimHolding)
	if sa then
		local t = findMouseAimTarget()
		if t then
			local sp, os = Camera:WorldToViewportPoint(t.pos)
			if os then
				local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
				local rawDelta = Vector2.new(sp.X, sp.Y) - sc
				local distance = rawDelta.Magnitude
				
				local smoothness = math.clamp(states.mouseAimSmoothness, 0, 1)
				local moveFactor = 1
				
				if smoothness > 0 then
					local baseSmooth = 1 - (smoothness * 0.85)
					local distEasing = math.clamp(distance / 400, 0.15, 1)
					moveFactor = baseSmooth * distEasing
				end
				
				local smoothedDelta = rawDelta * moveFactor
				
				local legitment = math.clamp(states.mouseAimLegitment, 0, 100)
				if legitment > 0 then
					local maxPixelScatter = (legitment / 100) * 18
					local scatterX = math.random() * maxPixelScatter * 2 - maxPixelScatter
					local scatterY = math.random() * maxPixelScatter * 2 - maxPixelScatter
					smoothedDelta = smoothedDelta + Vector2.new(scatterX, scatterY)
				end
				
				if smoothedDelta.Magnitude < 2.5 then return end
				
				local maxSpeed = 40
				if smoothedDelta.Magnitude > maxSpeed then
					smoothedDelta = smoothedDelta.Unit * maxSpeed
				end
				
				pcall(function()
					mousemoverel(smoothedDelta.X, smoothedDelta.Y)
				end)
			end
		end
	end
end)

-- === RAGE BOT (ОБНОВЛЕННЫЙ) ===
local safePositionCFrame = nil
local isAtSafePosition = false
local currentArcadeTarget = nil

local function teleportToSafe()
	local myChar = LocalPlayer.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	local humanoid = myChar:FindFirstChild("Humanoid")
	if not myRoot or not humanoid then return end

	local safeY = math.max(myRoot.Position.Y, 300) + 200
	safePositionCFrame = CFrame.new(myRoot.Position.X, safeY, myRoot.Position.Z)

	myRoot.Anchored = true
	humanoid.PlatformStand = true
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	end)

	myRoot.CFrame = safePositionCFrame
	isAtSafePosition = true
end

local function teleportToPlayer(targetPlayer)
	local myChar = LocalPlayer.Character
	if not myChar then return false end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	local humanoid = myChar:FindFirstChild("Humanoid")
	if not myRoot or not humanoid then return false end

	local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return false end

	myRoot.Anchored = false
	humanoid.PlatformStand = false
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
	end)

	myRoot.CFrame = targetRoot.CFrame
	Camera.CFrame = targetRoot.CFrame
	isAtSafePosition = false

	return true
end

local function findRageTarget()
	-- ARCADE MODE: без лимита расстояния, таргетим одного пока не умрет
	if states.arcadeRageEnabled then
		if currentArcadeTarget and currentArcadeTarget.Character then
			local humanoid = currentArcadeTarget.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				return currentArcadeTarget
			end
		end
		
		currentArcadeTarget = nil
		local alivePlayers = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local h = p.Character:FindFirstChild("Humanoid")
				if h and h.Health > 0 then
					table.insert(alivePlayers, p)
				end
			end
		end
		if #alivePlayers > 0 then
			currentArcadeTarget = alivePlayers[math.random(1, #alivePlayers)]
			log(" New arcade target: " .. currentArcadeTarget.Name, Color3.fromRGB(52, 152, 219))
			return currentArcadeTarget
		end
		return nil
	end
	
	-- LOCK MODE
	local aliveTargets = {}
	for _, targetName in ipairs(states.rageTargets) do
		if targetName ~= "" then
			for _, p in ipairs(Players:GetPlayers()) do
				if string.lower(p.Name) == string.lower(targetName) and p ~= LocalPlayer then
					if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						local h = p.Character:FindFirstChild("Humanoid")
						if h and h.Health > 0 then table.insert(aliveTargets, p) end
					end
				end
			end
		end
	end
	
	if #aliveTargets == 0 then return nil end
	return aliveTargets[math.random(1, #aliveTargets)]
end

local function performRageKill()
	if not states.rageEnabled then return end
	
	local target = findRageTarget()
	if not target then
		log("⚠️ No valid rage target", Color3.fromRGB(241, 196, 15))
		return
	end
	
	if not teleportToPlayer(target) then
		log("❌ Failed to teleport to target", Color3.fromRGB(231, 76, 60))
		return
	end
	
	log("⚔️ Attacking " .. target.Name, Color3.fromRGB(52, 152, 219))
	
	if hasMouseMoveRel then
		pcall(function() 
			mouse1press() 
			task.wait(0.05) 
			mouse1release() 
		end)
	end
	
	task.delay(0.5, function()
		teleportToSafe()
	end)
end

-- НОВАЯ ФУНКЦИЯ: Отзыв RageBot
local function recallRage()
	if not states.rageEnabled then
		log("⚠️ RageBot not enabled", Color3.fromRGB(241, 196, 15))
		return
	end
	
	teleportToSafe()
	currentArcadeTarget = nil
	log("🛡️ RageBot recalled to safe position", Color3.fromRGB(52, 152, 219))
end

local function toggleRage()
	states.rageEnabled = not states.rageEnabled
	ui.RageToggleBtn.Text = "Toggle: "..(states.rageEnabled and "ON" or "OFF")
	ui.RageToggleBtn.BackgroundColor3 = states.rageEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local humanoid = myChar and myChar:FindFirstChild("Humanoid")

	if states.rageEnabled then
		teleportToSafe()
		log("✅ RageBot enabled", Color3.fromRGB(46, 204, 113))
	else
		if myRoot and humanoid and isAtSafePosition then
			myRoot.Anchored = false
			humanoid.PlatformStand = false
			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			end)
			log("❌ RageBot disabled", Color3.fromRGB(231, 76, 60))
		end
		currentArcadeTarget = nil
		isAtSafePosition = false
	end
end

ui.RageToggleBtn.MouseButton1Click:Connect(toggleRage)
ui.RageKillBtn.MouseButton1Click:Connect(function()
	local h = LocalPlayer.Character:FindFirstChild("Humanoid")
	if h then h.Health = 0 end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and states.rageEnabled then
		performRageKill()
	end
end)

-- === FOV CIRCLES ===
local silentFOVCircle, legitFOVCircle, mouseAimFOVCircle = nil, nil, nil

if hasDrawing then
	pcall(function()
		silentFOVCircle = Drawing.new("Circle")
		silentFOVCircle.Thickness = 1.5
		silentFOVCircle.NumSides = 60
		silentFOVCircle.Radius = 150
		silentFOVCircle.Filled = false
		silentFOVCircle.Color = colors.fovSilent
		silentFOVCircle.Visible = false
		silentFOVCircle.Transparency = 0.8
		
		legitFOVCircle = Drawing.new("Circle")
		legitFOVCircle.Thickness = 1.5
		legitFOVCircle.NumSides = 60
		legitFOVCircle.Radius = 200
		legitFOVCircle.Filled = false
		legitFOVCircle.Color = colors.fovLegit
		legitFOVCircle.Visible = false
		legitFOVCircle.Transparency = 0.8
		
		mouseAimFOVCircle = Drawing.new("Circle")
		mouseAimFOVCircle.Thickness = 1.5
		mouseAimFOVCircle.NumSides = 60
		mouseAimFOVCircle.Radius = 200
		mouseAimFOVCircle.Filled = false
		mouseAimFOVCircle.Color = colors.fovMouseAim
		mouseAimFOVCircle.Visible = false
		mouseAimFOVCircle.Transparency = 0.8
	end)
end

RunService.RenderStepped:Connect(function()
	local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	if silentFOVCircle then pcall(function() silentFOVCircle.Position = center silentFOVCircle.Radius = states.silentFOV silentFOVCircle.Visible = states.silentShowFOV end) end
	if legitFOVCircle then pcall(function() legitFOVCircle.Position = center legitFOVCircle.Radius = states.legitFOV legitFOVCircle.Visible = states.legitShowFOV end) end
	if mouseAimFOVCircle then pcall(function() mouseAimFOVCircle.Position = center mouseAimFOVCircle.Radius = states.mouseAimFOV mouseAimFOVCircle.Visible = states.mouseAimShowFOV end) end
end)

-- === РЕГИСТРАЦИЯ КЕЙБИНДОВ ===
shared.keybindActions.silent = toggleSilent
shared.keybindActions.legit = toggleLegit
shared.keybindActions.mouseAim = toggleMouseAim
shared.keybindActions.rage = toggleRage
shared.keybindActions.rageRecall = recallRage

shared.keybindActions.legitMode = function()
	states.legitMode = states.legitMode == "always" and "hold" or "always"
	ui.LegitModeBtn.Text = "Mode: "..(states.legitMode == "always" and "Always" or "Hold")
end

shared.keybindActions.legitTargetLock = function()
	states.legitTargetLockEnabled = not states.legitTargetLockEnabled
	ui.LegitTargetLockBtn.Text = "Lock: "..(states.legitTargetLockEnabled and "ON" or "OFF")
	ui.LegitTargetLockBtn.BackgroundColor3 = states.legitTargetLockEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
end

shared.keybindActions.mouseAimMode = function()
	states.mouseAimMode = states.mouseAimMode == "always" and "hold" or "always"
	ui.MouseAimModeBtn.Text = "Mode: "..(states.mouseAimMode == "always" and "Always" or "Hold")
end

-- === UI UPDATE ===
function updateAllUIFromStates()
	ui.SilentToggleBtn.Text = "Toggle: "..(states.silentEnabled and "ON" or "OFF")
	ui.SilentToggleBtn.BackgroundColor3 = states.silentEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.SilentShowFOVBtn.Text = "Show FOV: "..(states.silentShowFOV and "ON" or "OFF")
	ui.SilentShowFOVBtn.BackgroundColor3 = states.silentShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.SilentFOVInput.Text = tostring(states.silentFOV)
	
	ui.LegitToggleBtn.Text = "Legit: "..(states.legitEnabled and "ON" or "OFF")
	ui.LegitToggleBtn.BackgroundColor3 = states.legitEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.LegitShowFOVBtn.Text = "Show FOV: "..(states.legitShowFOV and "ON" or "OFF")
	ui.LegitShowFOVBtn.BackgroundColor3 = states.legitShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.LegitWallCheckBtn.Text = "Wall: "..(states.legitWallCheck and "ON" or "OFF")
	ui.LegitWallCheckBtn.BackgroundColor3 = states.legitWallCheck and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.LegitModeBtn.Text = "Mode: "..(states.legitMode == "always" and "Always" or "Hold")
	ui.LegitTargetLockBtn.Text = "Lock: "..(states.legitTargetLockEnabled and "ON" or "OFF")
	ui.LegitTargetLockBtn.BackgroundColor3 = states.legitTargetLockEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.LegitTargetInput.Text = states.legitTargetLockName
	ui.LegitFOVInput.Text = tostring(states.legitFOV)
	ui.LegitSmoothInput.Text = tostring(states.legitSmoothness)
	
	ui.MouseAimToggleBtn.Text = "Toggle: "..(states.mouseAimEnabled and "ON" or "OFF")
	ui.MouseAimToggleBtn.BackgroundColor3 = states.mouseAimEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.MouseAimWallCheckBtn.Text = "Wall: "..(states.mouseAimWallCheck and "ON" or "OFF")
	ui.MouseAimWallCheckBtn.BackgroundColor3 = states.mouseAimWallCheck and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.MouseAimShowFOVBtn.Text = "Show FOV: "..(states.mouseAimShowFOV and "ON" or "OFF")
	ui.MouseAimShowFOVBtn.BackgroundColor3 = states.mouseAimShowFOV and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.MouseAimModeBtn.Text = "Mode: "..(states.mouseAimMode == "always" and "Always" or "Hold")
	ui.MouseAimHeadChanceInput.Text = tostring(states.mouseAimHeadChance)
	ui.MouseAimLegitmentInput.Text = tostring(states.mouseAimLegitment)
	ui.MouseAimFOVInput.Text = tostring(states.mouseAimFOV)
	ui.MouseAimSmoothInput.Text = tostring(states.mouseAimSmoothness)
	
	ui.RageToggleBtn.Text = "Toggle: "..(states.rageEnabled and "ON" or "OFF")
	ui.RageToggleBtn.BackgroundColor3 = states.rageEnabled and Color3.fromRGB(46, 204, 113) or colors.buttonDefault
	ui.RageRecallKeybindBtn.Text = keybinds.rageRecall or "Key"
end

function updateAllKeybindButtons()
	ui.SilentKeybindBtn.Text = keybinds.silent or "Key"
	ui.LegitKeybindBtn.Text = keybinds.legit or "Key"
	ui.LegitModeKeybindBtn.Text = keybinds.legitMode or "Key"
	ui.LegitHoldKeybindBtn.Text = keybinds.legitHold or "Mouse2"
	ui.LegitTargetLockKeybindBtn.Text = keybinds.legitTargetLock or "Key"
	ui.MouseAimKeybindBtn.Text = keybinds.mouseAim or "Key"
	ui.MouseAimModeKeybindBtn.Text = keybinds.mouseAimMode or "Key"
	ui.MouseAimHoldKeybindBtn.Text = keybinds.mouseAimHold or "Mouse2"
	ui.RageKeybindBtn.Text = keybinds.rage or "Key"
	ui.RageRecallKeybindBtn.Text = keybinds.rageRecall or "Key"
end

print("✅ AimbotModule v2.2 loaded!")