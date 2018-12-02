local PORT = 22122

-- Add libraries to path
package.path = package.path .. ";lib/?.lua"
package.path = package.path .. ";lib/?/init.lua"

Sock = require "sock"
Object = require "classic"
lume = require "lume"

local Lobby = require "lobby"

local function registerCallbacks()
    Server:on("connect", function(data, client)
		print("[INFO]: Received new client: " .. client:getConnectId())
        -- Send a message back to the connected client
        client:send("handshake", "ok")
    end)
	Server:on("disconnect",function(data, client)
		print("[INFO]: Disconnected client: "..client:getConnectId())
		main_game:removePlayer(client)
	end)
end

function love.load()
	print("-Starting server-")
	Server = Sock.newServer("*", PORT)

	registerCallbacks()

	main_game = Lobby()
	main_game:registerCallbacks()
end

function love.update(dt)
	Server:update()
end
