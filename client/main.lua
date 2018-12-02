local HOSTNAME = "localhost"
local PORT = 22122

-- Add libraries to path
package.path = package.path .. ";lib/?.lua"
package.path = package.path .. ";lib/?/init.lua"
package.path = package.path .. ";lib/?/main.lua"

Sock = require "sock"
Object = require "classic"
Gamestate = require "gamestate"
lume = require "lume"
flux = require "flux"

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
	Client = Sock.newClient(HOSTNAME, PORT)

	registerCallbacks()

	Client:connect()

	Gamestate:register(Lobby, "Lobby")
end

function love.update(dt)
	flux.update(dt)
	Client:update()

	Gamestate:update(dt)
end

function love.draw()
	Gamestate:draw()
end

function love.keypressed(key)
	Gamestate:keypressed(key)
end

function love.keyreleased(key)
	Gamestate:keyreleased(key)
end
