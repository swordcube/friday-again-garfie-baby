local fs = love.filesystem

--- @class funkin.scripting.Script : comet.util.Class
local Script = Class("Script", ...)

local closedEnv = setmetatable({}, {
	__index = function() error("You cannot use a closed script!") end,
	__newindex = function() error("You cannot use a closed script!") end,
})
local function errformat(s, thread)
	local i = debug.getinfo(thread or 3, "Sln")
	print(("%s: %i: %s not allowed"):format(i.short_src, i.currentline, s))
end
local n = function() end
local nindex = setmetatable({}, {__call = n, __index = n, __newindex = n})

local function deny(name, toReturn)
	return function()
		errformat(name)
        return toReturn or nindex
	end
end
local function noindex(module)
	return setmetatable({}, {
		__index = function(_, k) return deny(module .. "." .. k) end,
	})
end
local function limitindex(name, blocklist)
	local mt = {
		__index = function(_, k)
			if _G[name][k] then
				if blocklist and blocklist[k] then
					return blocklist[k]
				end
			end
			return _G[name][k]
		end,
		__newindex = deny(name .. " new indexing")
	}
	if name == "Script" then
		mt.__call = function(_, ...) return Script:new(...) end
	end
	return setmetatable({}, mt)
end
local blocklist = {
    "dofile", "loadfile", "loadstring", "load", "module",
	"rawset", "rawget", "rawequal", "setfenv", "getfenv", "newproxy"
}
local modules = {
    debug = noindex("debug"),
	package = noindex("package"),
	io = noindex("io"),
	jit = noindex("jit"),
	ffi = noindex("ffi"),

	math = limitindex("math"),
	table = limitindex("table"),
	coroutine = limitindex("coroutine"),

	love = limitindex("love"),
    comet = limitindex("comet"),

	os = limitindex("os", {
		execute = deny("os.execute", false),
		remove = deny("os.remove", false),
		rename = deny("os.rename", false),
		tmpname = deny("os.tmpname", false),
		setenv = deny("os.setenv", false),
		getenv = deny("os.getenv", false),
		setlocale = deny("os.setlocale", false)
	}),
	string = limitindex("string", {
		dump = deny("string.dump", "")
	}),
    require = function(path)
        path = "classes/" .. path:gsub("%.", "/")
        if fs.getInfo(Paths.getPath(path), "directory") and fs.getInfo(Paths.getPath(path .. "/init.lua"), "file") then
            return Script:new(Paths.script(path .. "/init.lua")).chunk()
        end
        return Script:new(Paths.script(path)).chunk()
    end,
	Script = limitindex("Script", {
		addToEnv = deny("Script:addToEnv()")
	})
}
local mtEnv = {
    __index = function(_, k)
		if table.contains(blocklist, k) then
			return deny(k)
		end
		return modules[k] or _G[k]
	end
}

function Script:__init__(path)
    self.path = path --- @type string
    self.chunk = nil --- @type function

    self.variables = {}
    self.closed = false

	self.linkedObject = nil --- @type any
    self.__failedfunc = {} --- @protected

    local s, err = pcall(function()
        local vars = self.variables
        local chunk = fs.load(self.path)
        if chunk then
            -- preset vars/funcs`
			self:set("game", PlayScreen.instance)
			self:set("print", function(...)
				local info = debug.getinfo(2, "Sln")
				print(("%s:%s: %s"):format(info.short_src, info.currentline, table.concat(table.pack(...), ", ")))
			end)
            self:set("close", function() self:close() end)

            -- sandbox the chunk then run it
            setfenv(chunk, setmetatable(vars, mtEnv))
            chunk()
        else
            FLog.warn(("Script not found at %s"):format(self.path))
            self:close()
            return
        end
        self.chunk = chunk
    end)
    if not s then
        FLog.error(("Failed to load %s: %s"):format(self.path, err))
        self:close()
    end
end

function Script:get(var)
    if self.closed then return nil end
    return rawget(self.variables, var)
end

function Script:set(var, value)
	if self.closed then return end
	rawset(self.variables, var, value)
end


function Script:linkObject(link)
	local cur = getmetatable(self.variables)
	self.linkedObject = link

	local s = self.variables
	if not s then return end
	local new = {
		__index = function(_, k)
			if link[k] ~= nil then
				if type(link[k]) == "function" then
					return function(...)
						return link[k](link, ...)
					end
				end
				return link[k]
			end
			return type(cur.__index) == "table" and cur.__index[k] or cur.__index(s, k)
		end,
		__newindex = function(_, k, v)
			if k ~= nil and link[k] ~= nil and type(link[k]) ~= "function" then
				link[k] = v
                return
			end
			return cur.__newindex and cur.__newindex(s, k, v) or rawset(s, k, v)
		end
	}
	setmetatable(self.variables, new)
end

function Script:call(func, ...)
	if self.closed then return true end
	if self.__failedfunc[func] then return end

	local f = rawget(self.variables, func)
	if f and type(f) == "function" then
		local s, err = pcall(f, ...)
		if s then
			if err ~= nil and pcall(type, err) then
				return err
			end
			return true
		else
			FLog.error(('%s failed at %s: %s'):format(self.path, func, err))
            self.__failedfunc[func] = true
		end
	end
end

function Script:close()
    if self.closed then
        return
    end
	self:call("onClose")
    self.closed = true

    if self.chunk then
        setfenv(self.chunk, closedEnv)
    end
    self.variables = nil
    self.chunk = nil
end

return Script