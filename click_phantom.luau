local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local http_service = game:GetService("HttpService")
local lp = players.LocalPlayer
local vec2 = Vector2.new
local cfr = CFrame.new
local rgb = Color3.fromRGB
local min, max, abs = math.min, math.max, math.abs
local FL_CONNS = {}
local function flConn(sig, fn)
	local c = sig:Connect(fn)
	table.insert(FL_CONNS, c)
	return c
end

local UI = (function()
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local lp = players.LocalPlayer

local UI = {}
UI.Flags = {}
UI.CBS = {}

local function guiParent()
	if gethui then local ok, h = pcall(gethui) if ok and h then return h end end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return lp:WaitForChild("PlayerGui")
end

local C = {
	bg = Color3.fromRGB(18, 18, 22),
	panel = Color3.fromRGB(26, 26, 33),
	head = Color3.fromRGB(34, 34, 44),
	row = Color3.fromRGB(30, 30, 40),
	rowHot = Color3.fromRGB(44, 40, 60),
	accent = Color3.fromRGB(150, 90, 255),
	accent2 = Color3.fromRGB(110, 200, 255),
	text = Color3.fromRGB(220, 220, 230),
	dim = Color3.fromRGB(140, 140, 155),
	on = Color3.fromRGB(120, 255, 140),
}

local function mk(cls, props, parent)
	local i = Instance.new(cls)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

local function round(i, r) mk("UICorner", {CornerRadius = UDim.new(0, r or 6)}, i) end
local function pad(i, l, r, t, b)
	mk("UIPadding", {PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0)}, i)
end
local function draggable(handle, frame)
	local drag, ds, sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag, ds, sp = true, i.Position, frame.Position
		end
	end)
	uis.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
	uis.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
	end)
end

function UI:Init(title)
	local sg = mk("ScreenGui", {Name = "waffle_clickgui", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true}, guiParent())
	self.sg = sg
	self.x = 80
	self.title = title
	return sg
end

function UI:Category(name)
	local f = mk("Frame", {BackgroundColor3 = C.panel, BorderSizePixel = 0,
		Position = UDim2.new(0, self.x, 0, 90), Size = UDim2.new(0, 230, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y}, self.sg)
	round(f, 8)
	mk("UIStroke", {Color = Color3.fromRGB(60, 55, 80), Thickness = 1, Transparency = 0.3}, f)
	self.x = self.x + 244

	local head = mk("TextLabel", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = C.accent2, Text = name}, f)
	round(head, 8)
	draggable(head, f)

	local list = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 0, 0, 32)}, f)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, list)
	pad(list, 4, 4, 0, 6)

	local cat = {list = list, sg = self.sg}
	return setmetatable(cat, {__index = UI.Cat})
end

UI.Cat = {}
UI.Cat.__index = UI.Cat

local function fire(flag, v)
	local f = UI.CBS[flag]
	if f then pcall(f, v) end
end

local function bindableText(v)
	return type(v) == "string" and v or "MB2"
end

function UI.Cat:Label(text)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. text}, self.list)
	pad(self.list, 0)
end

function UI.Cat:Module(name, flag, def)
	UI.Flags[flag] = def == nil and false or def
	local holder = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y}, self.list)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)}, holder)

	local btn = mk("TextButton", {BackgroundColor3 = C.row, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamSemibold, TextSize = 13,
		TextColor3 = C.text, Text = "  " .. name, TextXAlignment = Enum.TextXAlignment.Left}, holder)
	round(btn, 5)

	local dot = mk("Frame", {BackgroundColor3 = C.dim, Size = UDim2.new(0, 5, 0, 16),
		Position = UDim2.new(1, -12, 0.5, -8)}, btn)
	round(dot, 3)

	local drop = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Visible = false}, holder)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)}, drop)
	pad(drop, 14, 0, 0, 2)

	local mod = {drop = drop, flag = flag, sg = self.sg}
	local function paint()
		local on = UI.Flags[flag]
		btn.TextColor3 = on and C.on or C.text
		btn.BackgroundColor3 = on and C.rowHot or C.row
		dot.BackgroundColor3 = on and C.accent or C.dim
	end
	paint()
	btn.MouseButton1Click:Connect(function()
		UI.Flags[flag] = not UI.Flags[flag]
		fire(flag, UI.Flags[flag])
		paint()
	end)
	btn.MouseButton2Click:Connect(function()
		drop.Visible = not drop.Visible
	end)
	return setmetatable(mod, {__index = UI.Mod})
end

UI.Mod = {}
UI.Mod.__index = UI.Mod

local function settingRow(parent, label)
	local row = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22)}, parent)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.55, 0, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = label}, row)
	return row
end

function UI.Mod:Toggle(name, flag, def)
	UI.Flags[flag] = def == nil and false or def
	local row = settingRow(self.drop, name)
	local box = mk("TextButton", {BackgroundColor3 = C.dim, BorderSizePixel = 0,
		Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -34, 0.5, -8),
		Text = ""}, row)
	round(box, 4)
	local knob = mk("Frame", {BackgroundColor3 = C.text, Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 3, 0.5, -5)}, box)
	round(knob, 5)
	local function paint()
		local on = UI.Flags[flag]
		box.BackgroundColor3 = on and C.accent or C.dim
		knob.Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
	end
	paint()
	box.MouseButton1Click:Connect(function()
		UI.Flags[flag] = not UI.Flags[flag]
		fire(flag, UI.Flags[flag])
		paint()
	end)
end

function UI.Mod:Slider(name, flag, minV, maxV, def, step)
	UI.Flags[flag] = def
	step = step or 1
	local row = settingRow(self.drop, name)
	local val = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0),
		Position = UDim2.new(1, -40, 0, 0), Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = C.accent2, Text = tostring(def), TextXAlignment = Enum.TextXAlignment.Right}, row)
	local bar = mk("Frame", {BackgroundColor3 = C.head, Size = UDim2.new(0.42, 0, 0, 6),
		Position = UDim2.new(0.55, 2, 0.5, -3)}, row)
	round(bar, 3)
	local fill = mk("Frame", {BackgroundColor3 = C.accent, Size = UDim2.new(0, 0, 1, 0)}, bar)
	round(fill, 3)
	local function set(v)
		v = math.clamp(math.floor((v / step) + 0.5) * step, minV, maxV)
		UI.Flags[flag] = v
		val.Text = tostring(v)
		fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
		fire(flag, v)
	end
	set(def)
	local slid = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then slid = true end
	end)
	uis.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then slid = false end
	end)
	uis.InputChanged:Connect(function(i)
		if slid and i.UserInputType == Enum.UserInputType.MouseMovement then
			set(minV + (maxV - minV) * math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))
		end
	end)
end

function UI.Mod:Bind(name, flag, def)
	UI.Flags[flag] = def
	local row = settingRow(self.drop, name)
	local btn = mk("TextButton", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(0, 62, 0, 16), Position = UDim2.new(1, -64, 0.5, -8),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.accent2, Text = bindableText(def)}, row)
	round(btn, 4)
	local binding = false
	btn.MouseButton1Click:Connect(function()
		binding = true
		btn.Text = "..."
		btn.TextColor3 = C.on
	end)
	uis.InputBegan:Connect(function(i, gpe)
		if not binding then return end
		binding = false
		btn.TextColor3 = C.accent2
		if i.UserInputType ~= Enum.UserInputType.Keyboard then
			UI.Flags[flag] = i.UserInputType.Name
		else
			UI.Flags[flag] = i.KeyCode.Name
		end
		btn.Text = UI.Flags[flag]
		fire(flag, UI.Flags[flag])
	end)
end

function UI.Mod:Dropdown(name, flag, values, def)
	UI.Flags[flag] = def
	local row = settingRow(self.drop, name)
	local btn = mk("TextButton", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(1, -102, 0.5, -8),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.accent2, Text = def}, row)
	round(btn, 4)
	btn.MouseButton1Click:Connect(function()
		local idx = table.find(values, UI.Flags[flag]) or 0
		idx = idx % #values + 1
		UI.Flags[flag] = values[idx]
		btn.Text = values[idx]
		fire(flag, values[idx])
	end)
	btn.MouseButton2Click:Connect(function()
		local idx = (table.find(values, UI.Flags[flag]) or 2) - 1
		if idx < 1 then idx = #values end
		UI.Flags[flag] = values[idx]
		btn.Text = values[idx]
		fire(flag, values[idx])
	end)
end

local PALETTE = {
	Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 230, 60),
	Color3.fromRGB(120, 255, 120), Color3.fromRGB(60, 200, 255), Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(150, 90, 255), Color3.fromRGB(255, 100, 200), Color3.fromRGB(255, 255, 255),
}

function UI.Mod:Palette(name, flag, def)
	UI.Flags[flag] = def
	local row = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20)}, self.drop)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = name}, row)
	local holder = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0)}, row)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center}, holder)
	for _, c in ipairs(PALETTE) do
		local b = mk("TextButton", {BackgroundColor3 = c, Size = UDim2.new(0, 14, 0, 14),
			BorderSizePixel = 0, Text = ""}, holder)
		round(b, 3)
		b.MouseButton1Click:Connect(function() UI.Flags[flag] = c fire(flag, c) end)
	end
end

function UI.Cat:Button(name, cb)
	local btn = mk("TextButton", {BackgroundColor3 = C.row, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = C.text, Text = name}, self.list)
	round(btn, 5)
	btn.MouseButton1Click:Connect(function() pcall(cb) end)
end

function UI:Destroy()
	if self.sg then pcall(function() self.sg:Destroy() end) end
end

return UI

end)()

-- ===================== FRONTLINES // devin =====================

local PF_G = getrenv and getrenv()._G or _G
local Flags = UI.Flags
local function flag(name, default)
	local v = Flags[name]
	if v == nil then return default end
	return v
end
local CFG = {FOV = 220, Smooth = 0.3, WallCheck = true, AimPart = "h", Chance = 100}

local PF_PARTS = {"h", "c", "la", "ra", "ll", "rl"}
local PF_SKEL = {{"h","c"},{"c","la"},{"c","ra"},{"c","ll"},{"c","rl"}}
local BONE_ATTR = {h = "Head", c = "Torso", la = "Left Arm", ra = "Right Arm", ll = "Left Leg", rl = "Right Leg"}

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
				if name ~= "myteam" and name ~= "on" and name ~= "t" and name ~= "tname" and name ~= "bone" and name ~= "chance" and name ~= "hits" then
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
	local show = flag("esp_master", true) and ent.alive and not ent.mine and ent.parts.c
	if not show then hideAll() return end
	local isEn = not flag("team_check", true) or ent.team ~= myTeam or myTeam == nil
	local col = isEn and colEnemy or colFriend

	local cPos = ent.parts.c
	local camDist = (camera.CFrame.Position - cPos).Magnitude
	if camDist < 4 then hideAll() return end
	local rootPos, onScreen, depth = w2s(cPos)
	local behind = depth < 0
	local headPos = ent.parts.h or cPos + Vector3.new(0, 1.6, 0)
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
			local a, b = ent.parts[pair[1]], ent.parts[pair[2]]
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
						if flag("wallbang", true) or not CFG.WallCheck or rayVisible(cam.CFrame.Position, pp) then
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

run.RenderStepped:Connect(function()
	if PF_DEAD then return end
	for name, ent in pairs(ents) do
		local e = espPool[name]
		if not e then e = makeESP() espPool[name] = e end
		pcall(updateESP, e, ent)
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

local function aimHeld()
	local kb = Flags["aim_bind"]
	if type(kb) == "table" then return kb.active end
	return uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
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
		task.wait(0.2)
	end
end)

UI:Init("waffle // phantom")
pcall(function() UI.sg.Enabled = false end)
local menuOn = false
local function toggleMenu()
	menuOn = not menuOn
	UI.sg.Enabled = menuOn
end

local pfUnload
pfUnload = function()
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
	for _, c in ipairs(FL_CONNS) do pcall(function() c:Disconnect() end) end
	UI:Destroy()
	PF_G.__pfUnload = nil
end
PF_G.__pfUnload = pfUnload

UI.CBS.aim_fov = function(v) CFG.FOV = v end
UI.CBS.aim_part = function(v) CFG.AimPart = v end
UI.CBS.aim_smooth = function(v) CFG.Smooth = v end
UI.CBS.aim_chance = function(v) CFG.Chance = v end
UI.CBS.col_enemy = function(v) colEnemy = v end
UI.CBS.col_friend = function(v) colFriend = v end

local Combat = UI:Category("combat")
local mAim = Combat:Module("silent aim", "silent_aim", true)
mAim:Toggle("enabled", "aim_enable", true)
mAim:Bind("aim key", "aim_bind", "MouseButton2")
mAim:Slider("fov", "aim_fov", 40, 700, 220, 10)
mAim:Dropdown("bone", "aim_part", {"h","c"}, "h")
mAim:Slider("hit chance", "aim_chance", 10, 100, 100, 5)
mAim:Toggle("show fov", "aim_showfov", true)
mAim:Toggle("wall check", "wall_check", true)
mAim:Toggle("wallbang", "wallbang", true)
local mCam = Combat:Module("camera aim", "cam_aim", false)
mCam:Slider("smoothing", "aim_smooth", 0, 1, 0.3, 0.05)

local Vis = UI:Category("visuals")
local mEsp = Vis:Module("esp", "esp_master", true)
mEsp:Toggle("boxes", "esp_boxes", true)
mEsp:Toggle("names", "esp_names", true)
mEsp:Toggle("distance", "esp_dist", true)
mEsp:Toggle("skeleton", "esp_skel", true)
mEsp:Toggle("tracers", "esp_tracers", true)
mEsp:Toggle("offscreen arrows", "esp_arrows", true)
mEsp:Toggle("team check", "team_check", true)
mEsp:Palette("enemy color", "col_enemy", colEnemy)
mEsp:Palette("friend color", "col_friend", colFriend)

local Misc = UI:Category("misc")
Misc:Button("save config", function()
	pcall(function()
		local out = {}
		for k, v in pairs(Flags) do
			if typeof(v) == "Color3" then out[k] = {__col = v:ToHex()}
			else out[k] = v end
		end
		if writefile then writefile("pf_cfg.json", http_service:JSONEncode(out)) end
	end)
end)
Misc:Button("load config", function()
	pcall(function()
		if not (isfile and isfile("pf_cfg.json")) then return end
		local cfg = http_service:JSONDecode(readfile("pf_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
			Flags[k] = v
			if UI.CBS[k] then pcall(UI.CBS[k], v) end
		end
	end)
end)
Misc:Button("unload", function() pfUnload() end)

flConn(uis.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.Delete then toggleMenu() end
	if input.KeyCode == Enum.KeyCode.End then pfUnload() end
end)
toggleMenu()

pcall(function()
	if isfile and isfile("pf_cfg.json") then
		local cfg = http_service:JSONDecode(readfile("pf_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
			Flags[k] = v
			if UI.CBS[k] then pcall(UI.CBS[k], v) end
		end
	end
end)
print('[pf] main payload up')
