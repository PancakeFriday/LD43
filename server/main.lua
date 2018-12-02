local PORT = 22122

-- Add libraries to path
package.path = package.path .. ";lib/?.lua"
package.path = package.path .. ";lib/?/init.lua"

Sock = require "sock"

local function registerCallbacks()
    Server:on("connect", function(data, client)
		print("[INFO]: Received new client: " .. client:getConnectId())
        -- Send a message back to the connected client
        client:send("handshake", "ok")
    end)
	Server:on("disconnect",function(data, client)
		print("[INFO]: Disconnected client: "..client:getConnectId())
	end)
end

function love.load()
	print("-Starting server-")
	Server = Sock.newServer("*", PORT)

	registerCallbacks()
end

function love.update(dt)
	Server:update()
end
