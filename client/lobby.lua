local Player = require "player"
local Gamera = require "gamera"

local ll,lr,lt,lb = 0.13,0.76,0.06,0.76

love.math.setRandomSeed(love.timer.getTime())

local Lobby = Object:extend()

local ROT = require 'rotLove/rot'
local HC = require 'HC'

local Sparky = require "sparky"
local Door = require "door"

function love.graphics.printUnscaled(camera, ...)
	local args = {...}
	love.graphics.push()
	local s = camera:getScale()
	local px, py = camera:getPosition()
	love.graphics.translate(-args[2]-px, -args[3]-py)
	love.graphics.scale(1/s, 1/s)
	love.graphics.translate((args[2]*s+px*s), (args[3]*s+py*s))
	args[2] = args[2]*s
	args[3] = args[3]*s
	love.graphics.print(unpack(args))
	love.graphics.pop()
end

function Lobby:new()
	Client:send("request_map")
	Client:on("ready", function(data)
		self.ready = true
		self.dead_players = data

		for i,v in pairs(self.dead_players) do
			v.bbox = HC.rectangle(v.x-4.5,v.y-9,9,19)
			v.bbox.type="dead_player"
			v.bbox.obj = v
		end

		for i,v in lume.ripairs(self.doors) do
			if v.r == self.startRoom or v.r == self.endRoom then
				v:deactivate()
				table.remove(self.doors,i)
			end
		end
	end)
	Client:on("request_map", function(data)
		self.draw_map = data.draw_map
		self.rooms = data.rooms
		self.doors = data.doors
		--self.corridors = data.corridors
		self.mapw = data.mapw
		self.maph = data.maph
		self.startRoom = data.startRoom
		self.endRoom = data.endRoom
		self:init()
	end)
	Client:on("update_light", function(data)
		for x,v in pairs(self.draw_map) do
			for y,k in pairs(v) do
				self.draw_map[x][y].l = math.max(k.l, data[x][y].l)
			end
		end
	end)
end

function Lobby:init()
	self.bgm = love.audio.newSource("sound/bgm.wav","static")
	self.bgm:play()
	self.num_frames = 0
	self.enemies = {}
	self.dead_players = {}
	self.body_img = love.graphics.newImage("img/body.png")

	self.camera = Gamera.new(0,0,self.mapw*32,self.maph*32)
	local winw = love.graphics.getWidth()
	self.camera:setScale(winw/((10+1)*32))

	local r = self.rooms[self.startRoom]
	local startx = (r.l+r.r)/2
	local starty = (r.t+r.b)/2
	self.player = Player(true, startx, starty, self.camera)

	self:createBounds()
	self:createDoors()

	self.minicamera = Gamera.new(0,0,self.mapw,self.maph)
	self.minicamera:setScale(3)
	self.minicamera:setWindow(10,10,200,100)

	self.room_img = love.graphics.newImage("img/room_tiles_16.png")
	self.room_quads = {}
	for j=0,4 do
		for i=0,2 do
			local quad = love.graphics.newQuad(i*16,j*16,16,16,self.room_img:getWidth(),self.room_img:getHeight())
			table.insert(self.room_quads, quad)
		end
	end

	self.money_img = love.graphics.newImage("img/money.png")

	self.shadow_canvas = love.graphics.newCanvas()

	for i,v in pairs(self.doors) do
		if v.r == self.startRoom then
			v:activate(true)
		end
		if v.s and v.r ~= self.startRoom then
			v:setSpecial()
		end
	end

	-- Draw endroom
	local endroom = self.rooms[self.endRoom]
	local l,r,t,b = endroom.l, endroom.r, endroom.t, endroom.b
	local x = (l+r)/2*32-self.money_img:getWidth()/2+16
	local y = (t+b)/2*32-self.money_img:getHeight()/2+16
	self.money_box = HC.rectangle(x,y,self.money_img:getWidth(),self.money_img:getHeight())
	self.money_box.x = x
	self.money_box.y = y
	self.money_box.level = self
	self.money_box.type = "money"

	self.camera:setPosition(500,500)

	self.font = love.graphics.newFont("fonts/Monda-Regular.ttf", 30)
	love.graphics.setFont(self.font)

	self.waiting = true
	Client:send("player_ready")

	self.initialized = true
end

function Lobby:createBounds()
	for x,col in pairs(self.draw_map) do
		for y,v in pairs(col) do
			if v.q ~= 5 then
				v.col = HC.rectangle(x*32+2,y*32+2,12,12)
				v.col.type = "wall"
			end
		end
	end
end

function Lobby:createDoors()
	for i,v in pairs(self.doors) do
		self.doors[i] = Door(v, self.rooms, self.doors, self.enemies, self.player,i)
	end
end

function Lobby:getCamPosition()
	local player_in_room = false
	local player_room = nil

	for i,room in pairs(self.rooms) do
		local l,r,t,b = room.l+ll, room.r+lr, room.t+lt, room.b+lb
		local px, py = self.player.x/32, self.player.y/32
		if px > l and px < r then
			if py > t and py < b then
				player_in_room = true
				player_room = room
				break
			end
		end
	end

	if player_in_room then
		local l,r,t,b = player_room.l, player_room.r, player_room.t, player_room.b
		self.camera:setPosition((l+r)/2*32+16,(t+b)/2*32+16)
	else
		self.camera:setPosition(self.player.x,self.player.y)
	end
end

function Lobby:update(dt)
	if self.initialized then
		self.num_frames = self.num_frames + 1

		if self.num_frames % 10 == 0 then
			local light_values = {}
			for x,v in pairs(self.draw_map) do
				light_values[x] = {}
				for y,k in pairs(v) do
					light_values[x][y] = k.l
				end
			end
			Client:send("update_light", light_values)
		end

		self.player:update(dt)
		for i,v in pairs(self.enemies) do
			if #v == 0 then
				for j,k in lume.ripairs(self.doors) do
					if k.r == i then
						if not k.special then
							k:deactivate()
							table.remove(self.doors,j)
						end
						Client:send("room_done",k.r)
					end
				end
			end
			for j,k in lume.ripairs(v) do
				if k.dead then
					table.remove(v,j)
				end
				k:update(dt)
			end
		end
		local camx, camy = self:getCamPosition()
		--self.camera:setPosition(camx, camy)

		self.minicamera:setPosition(self.player.x/32,self.player.y/32)
	end
end

function Lobby:draw()
	if self.initialized then
		local light_values = {}
		self.camera:draw(function(l,t,w,h)
			love.graphics.setColor(1,1,1)
			local p = 4
			local a = 5
			local centerx = lume.round(self.player.x,0.5)+0.25
			love.graphics.setColor(1,1,1)
			for x=lume.round(l/32,0.5)-0.25,(l+w)/32,0.5 do
				local col = self.draw_map[x]
				if col then
					for y=lume.round(t/32,0.5)-0.25,(t+h)/32,0.5 do
						local v = col[y]
						if v then
							v.l = math.max(v.l, a/math.sqrt((self.player.x/32-x)^2+(self.player.y/32-y)^2)^p)
							love.graphics.draw(self.room_img, self.room_quads[v.q],x*32,y*32)
						end
					end
				end
			end

			love.math.setRandomSeed(777)
			love.graphics.setCanvas(self.shadow_canvas)
			for x=lume.round(l/32,0.5)-0.25,(l+w)/32,0.5 do
				local col = self.draw_map[x]
				if col then
					for y=lume.round(t/32,0.5)-0.25,(t+h)/32,0.5 do
						local v = col[y]
						if v then
							love.graphics.push()
							love.graphics.translate(x*32,y*32)
							local c = 1*v.l
							love.graphics.setColor(c,c,c)
							love.graphics.rectangle("fill",0,0,16,16)
							local prev_col = (self.draw_map[x-0.5] and self.draw_map[x-0.5][y])
							if prev_col then
								c = 1*prev_col.l
								local xoff = 16*(x%.25)
								local yoff = 16*(y%.25)
								love.graphics.setColor(c,c,c)
								love.graphics.polygon("fill",-16+xoff,8,-16+xoff,16,-24+xoff,16)
								love.graphics.polygon("fill",-16+xoff,8,-16+xoff,0,-24+xoff,0)
							else

							end
							love.graphics.pop()
						end
					end
				end
			end
			love.graphics.setCanvas()
			love.math.setRandomSeed(love.timer.getTime())

			love.graphics.setColor(1,1,1)
			for i,v in pairs(self.enemies) do
				for j,k in pairs(v) do
					k:draw()
				end
			end
			love.graphics.setColor(1,1,1)
			for i,v in pairs(self.doors) do
				v:draw()
			end
			love.graphics.setColor(1,1,1)

			love.graphics.draw(self.money_img, self.money_box.x, self.money_box.y)
			for i,v in pairs(self.dead_players) do
				love.graphics.draw(self.body_img,v.x-4.5,v.y-9)
			end
		end)
		love.graphics.setBlendMode("multiply","premultiplied")
		love.graphics.draw(self.shadow_canvas)
		love.graphics.setBlendMode("alpha","alphamultiply")

		self.camera:draw(function(l,t,w,h)
			self.player:draw(l,t,w,h)
		end)

		self.minicamera:draw(function(l,t,w,h)
			love.graphics.rectangle("line", l,t,w,h)
			love.graphics.setColor(0,0,0,0.4)
			love.graphics.rectangle("fill", l,t,w,h)
			love.graphics.setColor(1,1,1)
			for x,col in pairs(self.draw_map) do
				for y,v in pairs(col) do
					if v.l > 0.4 then
						love.graphics.setColor(1,1,1,1)
						love.graphics.rectangle("fill",x,y,1,1)
					end
				end
			end
			love.graphics.setColor(1,0,0)
			love.graphics.rectangle("fill",self.player.x/32,self.player.y/32,1,1)
		end)

		love.graphics.setColor(1,1,1)
		love.graphics.setFont(self.font)
		if not self.ready then
			local t = "        Your soul is not yet ready.\nI will accept your offering shortly..."
			local w = self.font:getWidth(t)
			love.graphics.setColor(0,0,0)
			love.graphics.print(t,love.graphics.getWidth()/2-w/2,love.graphics.getHeight()-200)
			love.graphics.setColor(1,1,1)
			love.graphics.print(t,love.graphics.getWidth()/2-w/2,love.graphics.getHeight()-202)
		end
		if self.finished then
			local t = "The offerings of your predecors were well received\n     and I reward you with the monies. Congrats."
			local w = self.font:getWidth(t)
			love.graphics.setColor(0,0,0)
			love.graphics.print(t,love.graphics.getWidth()/2-w/2,love.graphics.getHeight()-200)
			love.graphics.setColor(1,1,1)
			love.graphics.print(t,love.graphics.getWidth()/2-w/2,love.graphics.getHeight()-202)
		end
	end
end

function Lobby:keypressed(key)
	if self.initialized then
		if key == "m" and not self.player.dead then
			local l,t,w,h = self.minicamera:getWindow()
			if w == 200 then
				self.minicamera:setWindow(10,10,love.graphics.getWidth()-20,love.graphics.getHeight()-20)
				self.minicamera:setScale(6)
			else
				self.minicamera:setWindow(10,10,200,100)
				self.minicamera:setScale(3)
			end
		end
		--if key == "+" then
			--local s = self.camera:getScale()
			--self.camera:setScale(s+1)
		--end
		--if key == "-" then
			--local s = self.camera:getScale()
			--self.camera:setScale(math.max(1,s-1))
		--end
		self.player:keypressed(key)
	end
end

function Lobby:keyreleased(key)
	if self.initialized then
		self.player:keyreleased(key)
	end
end

function Lobby:textinput(text)
	self.player:textinput(text)
end

return Lobby
