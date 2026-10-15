local env = getrenv()
local req = env.shared and env.shared.require
if not req then return end
local ws = game:GetService('Workspace')
local Players = game:GetService('Players')
local lp = Players.LocalPlayer

local okN, networkClient = pcall(req, 'NetworkClient')
local okR, replicationInterface = pcall(req, 'ReplicationInterface')
local okW, weaponController = pcall(req, 'WeaponControllerInterface')
if not (okN and okR) then
	print('[pf] module fail: net=' .. tostring(okN) .. ' repl=' .. tostring(okR))
	return
end

local gravity = Vector3.yAxis * ws.Gravity

local function bulletSpeed()
	local ok, c = pcall(weaponController.getController)
	if not ok or not c then return 2000 end
	local ok2, w = pcall(function() return c:getActiveWeapon() end)
	if not ok2 or not w then return 2000 end
	local ok3, s = pcall(function() return w:getWeaponStat('bulletspeed') end)
	return (ok3 and type(s) == 'number') and s or 2000
end

local function getTrajectory(direction, speed)
	local a = gravity:Dot(gravity) * 0.25
	local b = gravity:Dot(direction) - speed * speed
	local c = direction:Dot(direction)
	local disc = b * b - 4 * a * c
	if disc < 0 then return direction.Unit end
	local root = ((-b - disc ^ 0.5) / (2 * a)) ^ 0.5
	return (direction / root + 0.5 * gravity * root).Unit
end

local function findEntry(name)
	local found
	local ok = pcall(function()
		replicationInterface.operateOnAllEntries(function(player, entry)
			if player and player.Name == name then found = entry end
		end)
	end)
	return ok and found or nil
end

if env._G.__pfUnhook then pcall(env._G.__pfUnhook) env._G.__pfUnhook = nil end
local oldSend = networkClient.send
env._G.__pfUnhook = function() networkClient.send = oldSend end

networkClient.send = function(self, name, ...)
	local args = {...}
	if name == 'newbullets' and ws:GetAttribute('pf_on') then
		local tPos = ws:GetAttribute('pf_t')
		local tName = ws:GetAttribute('pf_tname')
		local chance = ws:GetAttribute('pf_chance') or 100
		if typeof(tPos) == 'Vector3' and type(tName) == 'string' then
			local entry = findEntry(tName)
			if entry then
				local uniqueID, data, fireTime = args[1], args[2], args[3]
				if type(data) == 'table' and type(data.bullets) == 'table' and typeof(data.firepos) == 'Vector3' then
					local spd = bulletSpeed()
					for _, b in ipairs(data.bullets) do
						if typeof(b[1]) == 'Vector3' then
							b[1] = getTrajectory(tPos - data.firepos, spd)
						end
					end
					oldSend(self, name, uniqueID, data, fireTime)
					if math.random(1, 100) <= chance then
						local bone = ws:GetAttribute('pf_bone') or 'Head'
						for _, b in ipairs(data.bullets) do
							pcall(oldSend, self, 'bullethit', uniqueID, entry._player, tPos, bone, b[2], fireTime)
						end
					end
					return
				end
			end
		end
	elseif name == 'bullethit' and ws:GetAttribute('pf_on') then
		return
	end
	return oldSend(self, name, ...)
end
print('[pf] send hook on')

local BONES = {'Head', 'Torso', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}
local BKEYS = {'h', 'c', 'la', 'ra', 'll', 'rl'}
task.spawn(function()
	local seen = {}
	while true do
		local now = {}
		local myTeam = lp and lp.Team and lp.Team.Name
		if myTeam then ws:SetAttribute('pf_myteam', myTeam) end
		pcall(function()
			replicationInterface.operateOnAllEntries(function(player, entry)
				if not (player and player.Name) then return end
				local n = player.Name
				now[n] = true
				local pre = 'pf_' .. n .. '_'
				local alive, tpo
				pcall(function() alive = entry:isAlive() end)
				pcall(function() tpo = entry:getThirdPersonObject() end)
				ws:SetAttribute(pre .. 'a', alive == true)
				ws:SetAttribute(pre .. 'team', player.Team and player.Team.Name or '')
				ws:SetAttribute(pre .. 'mine', player == lp)
				if tpo then
					for i, bn in ipairs(BONES) do
						local ok, part = pcall(function() return tpo:getBodyPart(bn) end)
						if ok and part and typeof(part.Position) == 'Vector3' then
							ws:SetAttribute(pre .. BKEYS[i], part.Position)
						end
					end
				end
			end)
		end)
		for n in pairs(seen) do
			if not now[n] then
				local pre = 'pf_' .. n .. '_'
				ws:SetAttribute(pre .. 'a', nil)
				ws:SetAttribute(pre .. 'team', nil)
				for _, bk in ipairs(BKEYS) do ws:SetAttribute(pre .. bk, nil) end
			end
		end
		seen = now
		task.wait(0.3)
	end
end)
print('[pf] actor mirror running')
