local utf8 = require("utf8")

--- @class funkin.backend.CrashHandler
local CrashHandler = {}

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

local function errorhandler(msg)
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end
	love.window.setMode(1280, 720, {resizable = false, vsync = true})

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()
	love.graphics.setFont(love.graphics.newFont("assets/fonts/jetbrains-mono/regular.ttf", 15, "light"))

	local trace = debug.traceback()
	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	local quotes = {
		"Uncaught Error",
		"Oops! That wasn't supposed to happen, was it..",
		"Whoops! You need to put the CD in your computer",
		"i think you messed up somewhere idk man",
		"Codebase bomb go!!!!!",
		"Damn. Not Here.",
		"glup",
		"uh oh that's probably bad",
		"Well Well Well",
		"subscribe to technoblade",
		"mondays am i right" .. (os.date("%A") ~= "Monday" and "Wait it's not even a monday god damn it dude" or ""),
		"help me i'm unda da water ooohhhh",
		"woper",
		"bim cAc",
		"60fps spinning mozzarella sticks gif",
		"AFGHHGHG THERE'S SO MANY BEES GET THEM OFF AHGAHGAHG",
		"YOU DIED",
		"..did you forget to save the file?",
		"give it another shot! don't be an early quitter!",
		"darnless bf mix -my bestie 2024",
		"This is what i want. Making fuck.",
		"This is what i want. Making error.",
		"TRIGGER WARNING: SEX",
		"TRIGGER WARNING: ERROR",
		"Command 'greg' not found, did you mean:",
		"clippy nation ftw",
		"me and the homies hate ai art",
		"i think i need to drunk",
		"AMERICAN MEGATRENDS !!",
		"Frutiger Elmo",
		"why did my nose make a phone",
		"5 DOLLAR SRIMP SPECIAL",
		"Whoops! You need to put the CD up your ass",
		"bjoner so big i float up like a hot air balloon #liftoff",
		"we slurping sea monkeys by the gallon my tummy feel crazy",
		"Chat Invitation to Fuck",
		"Fuck",
		"WHAT THIS IS COCK",
		"NEBULA >:)" -- inside joke literally nobody but a specific friend group will get
	}
	table.insert(err, quotes[math.floor(love.math.random(1, #quotes))] .. "\n")
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	local img = love.graphics.newImage("assets/crash/sword.png", {linear = true})
	local quads = {
		love.graphics.newQuad(0, 0, img:getWidth() / 2, img:getHeight(), img:getWidth(), img:getHeight()),
		love.graphics.newQuad(img:getWidth() / 2, 0, img:getWidth() / 2, img:getHeight(), img:getWidth(), img:getHeight())
	}

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(0, 0, 0)

		love.graphics.draw(img, quads[(math.floor(love.timer.getTime() * 1) % #quads) + 1], 650, 100)

		local outlineSize = 2
		love.graphics.setColor(0, 0, 0, 1)
		
		-- top outline
		love.graphics.printf(p, pos - outlineSize, pos - outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos, pos - outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos + outlineSize, pos - outlineSize, love.graphics.getWidth() - pos)

		-- bottom outline
		love.graphics.printf(p, pos - outlineSize, pos + outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos, pos + outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos + outlineSize, pos + outlineSize, love.graphics.getWidth() - pos)

		-- left outline
		love.graphics.printf(p, pos - outlineSize, pos - outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos - outlineSize, pos, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos - outlineSize, pos + outlineSize, love.graphics.getWidth() - pos)

		-- right outline
		love.graphics.printf(p, pos + outlineSize, pos - outlineSize, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos + outlineSize, pos, love.graphics.getWidth() - pos)
		love.graphics.printf(p, pos + outlineSize, pos + outlineSize, love.graphics.getWidth() - pos)

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error\nPress CTRL+R to restart the game"
	end
	love.audio.newSource("assets/crash/hehe funny mac death sound.ogg", "static"):play()

	collectgarbage()
	collectgarbage()

	return function()
		love.event.pump(0.1)

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "keypressed" and a == "r" and love.keyboard.isDown("lctrl", "rctrl") then
				return "restart"
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel", "Restart"}
				if love.system then
					buttons[4] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					return "restart"
				elseif pressed == 4 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.001)
		end
	end

end

function CrashHandler.init()
    love.errorhandler = errorhandler
end

return CrashHandler