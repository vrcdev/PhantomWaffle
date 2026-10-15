local BASE = "https://raw.githubusercontent.com/vrcdev/PhantomWaffle/main/"

local function fetch(path)
	local ok, res = pcall(function() return game:HttpGet(BASE .. path) end)
	if ok and type(res) == "string" then return res end
	if ok and typeof(res) == "Instance" then
		local ok2, txt = pcall(function() return res.Text end)
		if ok2 and type(txt) == "string" then return txt end
	end
	if httpget then
		local ok3, r3 = pcall(httpget, BASE .. path)
		if ok3 and type(r3) == "string" then return r3 end
	end
	if request then
		local ok4, r4 = pcall(request, {Url = BASE .. path, Method = "GET"})
		if ok4 and type(r4) == "table" and type(r4.Body) == "string" then return r4.Body end
	end
	return nil
end

local libSrc = fetch("abyss_lib.lua")
if libSrc then
	local f, e = loadstring(libSrc)
	if f then pcall(f) else warn("[pf] lib compile:", e) end
else
	warn("[pf] lib fetch failed")
	return
end

local actorSrc = fetch("pf_actor.luau")
if actorSrc then
	for _, t in ipairs(getactorthreads()) do
		run_on_thread(t, actorSrc)
	end
else
	warn("[pf] actor fetch failed")
end

local mainSrc = fetch("click_phantom.luau")
if mainSrc then
	local f, e = loadstring(mainSrc)
	if f then
		local ok, err = pcall(f)
		print("[pf] main-run:", ok, err)
	else
		warn("[pf] compile err:", e)
	end
else
	warn("[pf] main fetch failed")
end
