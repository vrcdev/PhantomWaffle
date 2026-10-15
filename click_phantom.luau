local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local run = game:GetService("RunService")
local http_service = game:GetService("HttpService")
local lp = players.LocalPlayer
local vec2 = Vector2.new
local cfr = CFrame.new
local rgb = Color3.fromRGB
local min, max, abs = math.min, math.max, math.abs

local Library = getgenv().Library or Library

local Utility = getgenv().Utility
if Utility and Utility.AddImage then
	pcall(function()
		if makefolder then
			pcall(makefolder, "Abyss") pcall(makefolder, "Abyss/Caches") pcall(makefolder, "Abyss/Assets")
			pcall(makefolder, "Abyss/Assets/UI") pcall(makefolder, "Abyss/Configs") pcall(makefolder, "Abyss/Scripts")
			pcall(makefolder, "Waffle") pcall(makefolder, "Waffle/Assets")
		end
		local T = Library.Theme
		T.Gradient = T.Gradient or Utility.AddImage("Abyss/Assets/UI/Gradient.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/Gradient.png")
		T.Hue = T.Hue or Utility.AddImage("Abyss/Assets/UI/Hue.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/HuePicker.png")
		T.Saturation = T.Saturation or Utility.AddImage("Abyss/Assets/UI/Saturation.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/SaturationPicker.png")
		T.SaturationCursor = T.SaturationCursor or Utility.AddImage("Abyss/Assets/UI/HueCursor.png", "https://raw.githubusercontent.com/mvonwalk/splix-assets/main/Images-cursor.png")
		T.Logo = T.Logo or Utility.AddImage("Waffle/Assets/waffle.png", "https://raw.githubusercontent.com/vrcdev/PhantomWaffle/main/waffle.png")
	end)
end

local PF_G = getrenv and getrenv()._G or _G
local Flags = Library.Flags
local function flag(name, default)
	local v = Flags[name]
	if v == nil then return default end
	return v
end
local CFG = {FOV = 220, Smooth = 0.3, WallCheck = true, AimPart = "h", Chance = 100}

local PF_SKEL = {{"h","c"},{"c","la"},{"c","ra"},{"c","ll"},{"c","rl"}}
local BONE_ATTR = {h = "Head", c = "Torso", la = "Left Arm", ra = "Right Arm", ll = "Left Leg", rl = "Right Leg"}
local BONE_UI = {Head = "h", Torso = "c"}

local wsPlayers = nil
task.spawn(function() wsPlayers = ws:WaitForChild("Players", 10) end)
local function liveParts(name)
	if not wsPlayers then return nil end
	local model = wsPlayers:FindFirstChild(name)
	if not model then return nil end
	local out = {}
	for k, n in pairs(BONE_ATTR) do
		local p = model:FindFirstChild(n, true)
		if p and p:IsA("BasePart") then out[k] = p.Position end
	end
	return out.c and out or nil
end

local ents = {}
local function scanEnts()
	local attrs = ws:GetAttributes()
	local now = {}
	for k, v in pairs(attrs) do
		if type(k) == "string" and k:sub(1, 3) == "pf_" then
			local body = k:sub(4)
			local us = body:find("_", 1, true)
			while us do
				local name, suf = body:sub(1, us - 1), body:sub(us + 1)
				if name ~= "myteam" and name ~= "on" and name ~= "t" and name ~= "tname" and name ~= "bone" and name ~= "chance" and name ~= "hits" and name ~= "nofall" then
					local e = now[name]
					if not e then e = {name = name, parts = {}} now[name] = e end
					if suf == "a" then e.alive = v
					elseif suf == "team" then e.team = v
					elseif suf == "mine" then e.mine = v
					elseif BONE_ATTR[suf] and typeof(v) == "Vector3" then e.parts[suf] = v end
				end
				us = body:find("_", us + 1, true)
			end
		end
	end
	ents = now
end

local function w2s(v3)
	local camera = ws.CurrentCamera
	local sp, on = camera:WorldToViewportPoint(v3)
	return vec2(sp.X, sp.Y), on, sp.Z
end

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.FilterDescendantsInstances = {}
local function rayVisible(fromPos, toPos)
	local d = toPos - fromPos
	local hit = ws:Raycast(fromPos, d, visParams)
	if not hit then return true end
	return hit.Distance > d.Magnitude - 1.5
end

local function mkLine() local l = Drawing.new("Line") l.Thickness = 1.5 l.Visible = false return l end
local function mkText() local t = Drawing.new("Text") t.Size = 13 t.Center = true t.Outline = true t.Visible = false return t end

local function makeESP()
	local e = {
		box = {mkLine(),mkLine(),mkLine(),mkLine()},
		name = mkText(), dist = mkText(),
		tracer = mkLine(),
		arrow = Drawing.new("Triangle"),
		skel = {},
	}
	for i = 1, #PF_SKEL do e.skel[i] = mkLine() end
	return e
end

local PF_DEAD = false
local espPool = {}

local colEnemy = rgb(255, 60, 60)
local colFriend = rgb(80, 200, 255)
local myTeam = nil

local function updateESP(e, ent)
	local camera = ws.CurrentCamera
	local function hideAll()
		for _, l in ipairs(e.box) do l.Visible = false end
		e.name.Visible = false e.dist.Visible = false e.tracer.Visible = false e.arrow.Visible = false
		for _, l in ipairs(e.skel) do l.Visible = false end
	end
	if not e or PF_DEAD or not camera then return end
	local parts = e.rp or ent.parts
	local show = flag("esp_master", true) and ent.alive and not ent.mine and parts.c
	if not show then hideAll() return end
	local isEn = not flag("team_check", true) or ent.team ~= myTeam or myTeam == nil
	local col = isEn and colEnemy or colFriend

	local cPos = parts.c
	local camDist = (camera.CFrame.Position - cPos).Magnitude
	if camDist < 4 then hideAll() return end
	local rootPos, onScreen, depth = w2s(cPos)
	local behind = depth < 0
	local headPos = parts.h or cPos + Vector3.new(0, 1.6, 0)
	local top = w2s(headPos + Vector3.new(0, 0.6, 0))
	local bottom = w2s(cPos - Vector3.new(0, 2.6, 0))
	local height = math.abs(top.Y - bottom.Y)
	if height ~= height or height < 8 or height > 4000 or behind then
		hideAll()
		if flag("esp_arrows", true) and behind then
			local center = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
			local dir = vec2(rootPos.X - center.X, rootPos.Y - center.Y)
			dir = dir.Magnitude > 0 and dir.Unit or vec2(0,-1)
			local tip = center + dir * min(camera.ViewportSize.X, camera.ViewportSize.Y) * 0.42
			local side = vec2(-dir.Y, dir.X) * 10
			e.arrow.PointA = tip e.arrow.PointB = tip - dir * 22 + side
			e.arrow.PointC = tip - dir * 22 - side
			e.arrow.Color = col e.arrow.Filled = true e.arrow.Visible = true
		end
		return
	end
	local width = height * 0.55
	local cx = top.X
	local boxX, boxY = cx - width/2, min(top.Y, bottom.Y)

	if flag("esp_boxes", true) then
		local b = e.box
		b[1].From = vec2(boxX, boxY) b[1].To = vec2(boxX + width, boxY)
		b[2].From = vec2(boxX + width, boxY) b[2].To = vec2(boxX + width, boxY + height)
		b[3].From = vec2(boxX + width, boxY + height) b[3].To = vec2(boxX, boxY + height)
		b[4].From = vec2(boxX, boxY + height) b[4].To = vec2(boxX, boxY)
		for _, l in ipairs(b) do l.Color = col l.Visible = true end
	else for _, l in ipairs(e.box) do l.Visible = false end end

	if flag("esp_names", true) then
		e.name.Text = ent.name
		e.name.Position = vec2(cx, boxY - 16)
		e.name.Color = col e.name.Visible = true
	else e.name.Visible = false end

	if flag("esp_dist", true) then
		e.dist.Text = string.format("%.0fm", camDist * 0.28)
		e.dist.Position = vec2(cx, boxY + height + 2)
		e.dist.Color = Color3.new(1,1,1) e.dist.Visible = true
	else e.dist.Visible = false end

	if flag("esp_skel", true) then
		for i, pair in ipairs(PF_SKEL) do
			local l = e.skel[i]
			local a, b = parts[pair[1]], parts[pair[2]]
			if l and a and b then
				local sa, ona = w2s(a)
				local sb, onb = w2s(b)
				if ona or onb then l.From = sa l.To = sb l.Color = col l.Visible = true
				else l.Visible = false end
			elseif l then l.Visible = false end
		end
	else for _, l in ipairs(e.skel) do l.Visible = false end end

	if flag("esp_tracers", true) and onScreen then
		e.tracer.From = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y)
		e.tracer.To = rootPos e.tracer.Color = col e.tracer.Visible = true
	else e.tracer.Visible = false end

	if flag("esp_arrows", true) and not onScreen and depth < 0 then
		local center = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
		local dir = vec2(rootPos.X - center.X, rootPos.Y - center.Y)
		dir = dir.Magnitude > 0 and dir.Unit or vec2(0,-1)
		local tip = center + dir * min(camera.ViewportSize.X, camera.ViewportSize.Y) * 0.42
		local perp = vec2(-dir.Y, dir.X)
		e.arrow.PointA = tip
		e.arrow.PointB = tip - dir * 18 + perp * 8
		e.arrow.PointC = tip - dir * 18 - perp * 8
		e.arrow.Color = col e.arrow.Filled = true e.arrow.Visible = true
	else e.arrow.Visible = false end
end

local function pickTarget()
	local mPos = uis:GetMouseLocation()
	local cam = ws.CurrentCamera
	local best, bestScore = nil, CFG.FOV
	for _, ent in pairs(ents) do
		if ent.alive and not ent.mine and (not flag("team_check", true) or ent.team ~= myTeam or myTeam == nil) then
			local pp = ent.parts[CFG.AimPart] or ent.parts.h or ent.parts.c
			if pp then
				local sp, on = w2s(pp)
				if on then
					local d = (sp - mPos).Magnitude
					if d < bestScore then
						if flag("wallbang", false) or not CFG.WallCheck or rayVisible(cam.CFrame.Position, pp) then
							best, bestScore = ent, d
						end
					end
				end
			end
		end
	end
	return best
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1 fovCircle.NumSides = 60 fovCircle.Color = rgb(255,255,255)
fovCircle.Filled = false fovCircle.Visible = false

task.spawn(function()
	while not PF_DEAD do
		myTeam = ws:GetAttribute("pf_myteam")
		scanEnts()
		local t = pickTarget()
		if t and t.parts then
			local pp = t.parts[CFG.AimPart] or t.parts.h or t.parts.c
			ws:SetAttribute("pf_t", pp)
			ws:SetAttribute("pf_tname", t.name)
		else
			ws:SetAttribute("pf_t", nil)
			ws:SetAttribute("pf_tname", nil)
		end
		task.wait(0.1)
	end
end)

run.RenderStepped:Connect(function(dt)
	if PF_DEAD then return end
	local alpha = math.clamp(dt * 14, 0, 1)
	local drawn = {}
	if wsPlayers then
		for _, model in ipairs(wsPlayers:GetChildren()) do
			local name = model.Name
			drawn[name] = true
			local ent = ents[name]
			if not ent then
				local plr = players:FindFirstChild(name)
				ent = {name = name, parts = {}, alive = true, mine = plr == lp, team = plr and plr.Team and plr.Team.Name or ''}
				ents[name] = ent
			end
			local live = liveParts(name)
			if live then ent.parts = live end
			local e = espPool[name]
			if not e then e = makeESP() e.rp = {} espPool[name] = e end
			e.rp = ent.parts
			pcall(updateESP, e, ent)
		end
	end
	for name, ent in pairs(ents) do
		if not drawn[name] then
			local e = espPool[name]
			if not e then e = makeESP() e.rp = {} espPool[name] = e end
			local rp = e.rp
			for k, pos in pairs(ent.parts) do
				local cur = rp[k]
				rp[k] = cur and cur:Lerp(pos, alpha) or pos
			end
			pcall(updateESP, e, ent)
		end
	end
	for name, e in pairs(espPool) do
		if not ents[name] then
			for _, l in ipairs(e.box) do l.Visible = false end
			e.name.Visible = false e.dist.Visible = false e.tracer.Visible = false e.arrow.Visible = false
			for _, l in ipairs(e.skel) do l.Visible = false end
		end
	end
	local aimOn = flag("aim_enable", true) and flag("aim_showfov", true)
	fovCircle.Visible = aimOn
	fovCircle.Radius = CFG.FOV
	fovCircle.Position = uis:GetMouseLocation()
end)

local aimBindHeld = false
local function aimHeld()
	return aimBindHeld or uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

run.RenderStepped:Connect(function()
	if PF_DEAD or not flag("cam_aim", false) or not aimHeld() then return end
	local tPos = ws:GetAttribute("pf_t")
	local cam = ws.CurrentCamera
	if typeof(tPos) == "Vector3" and cam then
		local look = (tPos - cam.CFrame.Position).Unit
		local goal = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + look)
		cam.CFrame = CFG.Smooth > 0 and cam.CFrame:Lerp(goal, math.clamp(CFG.Smooth, 0.05, 1)) or goal
	end
end)

task.spawn(function()
	local last = false
	while not PF_DEAD do
		local on = flag("silent_aim", true) and flag("aim_enable", true)
		if on ~= last then ws:SetAttribute("pf_on", on) last = on end
		ws:SetAttribute("pf_bone", BONE_ATTR[CFG.AimPart] or "Head")
		ws:SetAttribute("pf_chance", CFG.Chance)
		ws:SetAttribute("pf_nofall", flag("nofall", false) or nil)
		task.wait(0.2)
	end
end)

local Window = Library.Window("waffle // phantom", vec2(540, 620))
Window.Watermark("waffle")
Window.ToggleAnime(false)

local combat = Window:Tab("combat")
local aimSec = combat:Section("silent aim", "Left")
aimSec:Toggle({Title = "enabled", Flag = "silent_aim", Default = true, Callback = function(v) end})
	:Keybind({Title = "aim key", Flag = "aim_bind", Key = Enum.UserInputType.MouseButton2, StateType = "Hold",
		Callback = function(state) aimBindHeld = state end})
aimSec:Slider({Title = "fov", Flag = "aim_fov", Min = 40, Max = 700, Default = 220, Decimals = 0, Callback = function(v) CFG.FOV = v end})
aimSec:Dropdown({Title = "bone", Flag = "aim_part", List = {"Head", "Torso"}, Default = "Head", Callback = function(v) CFG.AimPart = BONE_UI[v] or "h" end})
aimSec:Slider({Title = "hit chance", Flag = "aim_chance", Min = 10, Max = 100, Default = 100, Decimals = 0, Callback = function(v) CFG.Chance = v end})
aimSec:Toggle({Title = "show fov", Flag = "aim_showfov", Default = true})
aimSec:Toggle({Title = "wall check", Flag = "wall_check", Default = true, Callback = function(v) CFG.WallCheck = v end})
aimSec:Toggle({Title = "wallbang", Flag = "wallbang", Default = false})

local camSec = combat:Section("camera aim", "Right")
camSec:Toggle({Title = "enabled", Flag = "cam_aim", Default = false})
camSec:Slider({Title = "smoothing", Flag = "aim_smooth", Min = 0, Max = 1, Default = 0.3, Decimals = 2, Callback = function(v) CFG.Smooth = v end})

local vis = Window:Tab("visuals")
local espSec = vis:Section("esp", "Left")
espSec:Toggle({Title = "master", Flag = "esp_master", Default = true})
espSec:Toggle({Title = "boxes", Flag = "esp_boxes", Default = true})
espSec:Toggle({Title = "names", Flag = "esp_names", Default = true})
espSec:Toggle({Title = "distance", Flag = "esp_dist", Default = true})
espSec:Toggle({Title = "skeleton", Flag = "esp_skel", Default = true})
espSec:Toggle({Title = "tracers", Flag = "esp_tracers", Default = true})
espSec:Toggle({Title = "offscreen arrows", Flag = "esp_arrows", Default = true})
espSec:Toggle({Title = "team check", Flag = "team_check", Default = true})
local colSec = vis:Section("colors", "Right")
colSec:Colorpicker({Title = "enemy", Flag = "col_enemy", Color = colEnemy, Callback = function(v) colEnemy = v end})
colSec:Colorpicker({Title = "friend", Flag = "col_friend", Color = colFriend, Callback = function(v) colFriend = v end})

local misc = Window:Tab("misc")
local miscSec = misc:Section("gameplay", "Left")
miscSec:Toggle({Title = "no fall damage", Flag = "nofall", Default = false})
local cfgSec = misc:Section("config", "Right")

local function saveCfg()
	pcall(function()
		local out = {}
		for k, v in pairs(Flags) do
			if typeof(v) == "Color3" then out[k] = {__col = v:ToHex()}
			elseif typeof(v) == "EnumItem" then out[k] = {__enum = tostring(v)}
			else out[k] = v end
		end
		if writefile then writefile("pf_cfg.json", http_service:JSONEncode(out)) end
	end)
end
local function loadCfg()
	pcall(function()
		if not (isfile and isfile("pf_cfg.json")) then return end
		local cfg = http_service:JSONDecode(readfile("pf_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then Flags[k] = Color3.fromHex(v.__col)
			elseif type(v) ~= "table" then Flags[k] = v end
		end
		CFG.FOV = flag("aim_fov", 220)
		CFG.AimPart = BONE_UI[flag("aim_part", "Head")] or "h"
		CFG.Chance = flag("aim_chance", 100)
		CFG.Smooth = flag("aim_smooth", 0.3)
		CFG.WallCheck = flag("wall_check", true)
		colEnemy = flag("col_enemy", colEnemy)
		colFriend = flag("col_friend", colFriend)
	end)
end
local function pfUnload()
	if PF_DEAD then return end
	PF_DEAD = true
	ws:SetAttribute("pf_on", false)
	ws:SetAttribute("pf_t", nil)
	ws:SetAttribute("pf_tname", nil)
	for _, e in pairs(espPool) do
		for _, l in ipairs(e.box) do pcall(function() l:Remove() end) end
		pcall(function() e.name:Remove() end) pcall(function() e.dist:Remove() end)
		pcall(function() e.tracer:Remove() end) pcall(function() e.arrow:Remove() end)
		for _, l in ipairs(e.skel) do pcall(function() l:Remove() end) end
	end
	table.clear(espPool)
	pcall(function() fovCircle:Remove() end)
	pcall(function() Library.SelfDestruct() end)
end
PF_G.__pfUnload = pfUnload

cfgSec:Button({Title = "save config", Callback = saveCfg})
cfgSec:Button({Title = "load config", Callback = loadCfg})
cfgSec:Button({Title = "unload", Callback = pfUnload})

uis.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.End then pfUnload() end
end)

Window:AddSettingsTab()
Window:SwitchTab(combat)
loadCfg()
print('[pf] main payload up')
