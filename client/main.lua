local HOSTNAME = "sofapizza.de"
local PORT = 22122

-- Add libraries to path
--package.path = package.path .. ";lib/?.lua"
--package.path = package.path .. ";lib/?/init.lua"
--package.path = package.path .. ";lib/?/main.lua"

Sock = require "lib.sock"
Object = require "lib.classic"
Gamestate = require "gamestate"
lume = require "lib.lume"
flux = require "lib.flux"

-- Gamestates
local Lobby = require "lobby"

-- no blurry images
love.graphics.setDefaultFilter( "nearest", "nearest", 1 )

local function registerCallbacks()
	Client:on("connect", function(data)
	end)

	Client:on("disconnect", function(data)
	end)

	Client:on("handshake", function(msg)
		print("Handshake complete: " .. msg)

		Gamestate:set("Lobby")
	end)
end

function love.load()
	min_dt = 1/60
	next_time = love.timer.getTime()
	Client = Sock.newClient(HOSTNAME, PORT)

	registerCallbacks()

	Client:connect()

	Gamestate:register(Lobby, "Lobby")
end

function love.update(dt)
	next_time = next_time + min_dt
	flux.update(dt)
	Client:update()

	Gamestate:update(dt)
end

function love.draw()
	Gamestate:draw()

	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
		next_time = cur_time
		return
	end
	love.timer.sleep(next_time - cur_time)

end

function love.keypressed(key)
	Gamestate:keypressed(key)
end

function love.keyreleased(key)
	Gamestate:keyreleased(key)
end

function love.textinput(text)
	Gamestate:textinput(text)
end

function love.quit()
	if Client then
		Client:disconnect()
		Client:update()
	end
end
