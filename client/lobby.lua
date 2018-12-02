local Player = require "player"
local Gamera = require "gamera"

local ll,lr,lt,lb = 0.13,0.76,0.06,0.76

love.math.setRandomSeed(love.timer.getTime())

local ____ = 0.6
local Lobby = Object:extend()

local ROT = require 'rotLove/rot'
local HC = require 'HC'

local Sparky = require "sparky"

function Lobby:new()
	self.mapw, self.maph = 100,100
	local roomw, roomh = 10,9
	self.camera = Gamera.new(0,0,self.mapw*32,self.maph*32)
	local winw = love.graphics.getWidth()
	self.camera:setScale(winw/((roomw+1)*32))

	self.minicamera = Gamera.new(0,0,self.mapw,self.maph)
	self.minicamera:setScale(3)
	self.minicamera:setWindow(10,10,200,100)

	local time0 = love.timer.getTime()
	local startx, starty = self:createMap(mapw,maph,roomw,roomh)
	print("creating map took: " ..love.timer.getTime()-time0.."s")
	self.player = Player(true, startx, starty)

	self.light_img = love.graphics.newImage("img/light.png")

	self.room_img = love.graphics.newImage("img/room_tiles_16.png")
	self.door_img = love.graphics.newImage("img/doors.png")
	self.room_quads = {}
	for j=0,4 do
		for i=0,2 do
			local quad = love.graphics.newQuad(i*16,j*16,16,16,self.room_img:getWidth(),self.room_img:getHeight())
			table.insert(self.room_quads, quad)
		end
	end

	self.shadow_canvas = love.graphics.newCanvas()

	self.enemies = {}
	table.insert(self.enemies, Sparky(startx, starty))
end

function Lobby:createMap()
	self.map = ROT.Map.Digger(self.mapw,self.maph,{
		roomWidth={8,10},
		roomHeight={6,7},
		corridorLength={2,2},
	})
	self.draw_map = {}
	self.map:create(function(x,y,value)
		if value == 0 then
			for i=-0.25,0.75,0.5 do
				if not self.draw_map[x+i] then self.draw_map[x+i] = {} end
				for j=-0.25,0.75,0.5 do
					self.draw_map[x+i][y+j] = {}
					self.draw_map[x+i][y+j].q = 5
					self.draw_map[x+i][y+j].l = 0
				end
			end
		end
	end)

	for x,col in pairs(self.draw_map) do
		for y,v in pairs(col) do
			if self:checkSurrounding(self.draw_map,x,y,{{0,0,0},{0,1,1},{0,1,1}}) then
				self.draw_map[x][y].q = 1
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,0,0},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 2
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,0,1},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 2
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,0,0},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 2
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,0,1},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 2
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,0,0},{1,1,0},{1,1,0}}) then
				self.draw_map[x][y].q = 3
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,1,1},{0,1,1},{0,1,1}}) then
				self.draw_map[x][y].q = 4
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{0,1,1},{0,1,1}}) then
				self.draw_map[x][y].q = 4
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,1,1},{0,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 4
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{0,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 4
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,0},{1,1,0},{1,1,0}}) then
				self.draw_map[x][y].q = 6
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,0},{1,1,0},{1,1,1}}) then
				self.draw_map[x][y].q = 6
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,0},{1,1,0}}) then
				self.draw_map[x][y].q = 6
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,0},{1,1,1}}) then
				self.draw_map[x][y].q = 6
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,1,1},{0,1,1},{0,0,0}}) then
				self.draw_map[x][y].q = 7
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{0,0,0}}) then
				self.draw_map[x][y].q = 8
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{1,0,0}}) then
				self.draw_map[x][y].q = 8
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{0,0,1}}) then
				self.draw_map[x][y].q = 8
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{1,0,1}}) then
				self.draw_map[x][y].q = 8
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,0},{1,1,0},{0,0,0}}) then
				self.draw_map[x][y].q = 9
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{1,1,0}}) then
				self.draw_map[x][y].q = 10
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,1},{1,1,1},{0,1,1}}) then
				self.draw_map[x][y].q = 11
			elseif self:checkSurrounding(self.draw_map,x,y,{{1,1,0},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 13
			elseif self:checkSurrounding(self.draw_map,x,y,{{0,1,1},{1,1,1},{1,1,1}}) then
				self.draw_map[x][y].q = 14
			end
		end
	end

	for x,col in pairs(self.draw_map) do
		for y,v in pairs(col) do
			if v.q ~= 5 then
				v.col = HC.rectangle(x*32+2,y*32+2,12,12)
				v.col.type = "wall"
			end
		end
	end

	--for i,room in pairs(self.map:getRooms()) do
		--local l,r,t,b = room:getLeft(), room:getRight(), room:getTop(), room:getBottom()
		--for _,x,y in room._doors:each() do
			--if (x+1==l and y==t) or (x==l and y+1==t) --top left
			--or (x-1==r and y==t) or (x==r and y+1==t) --top right
			--or (x+1==l and y==b) or (x==l and y-1==b) --bottom left
			--or (x-1==r and y==b) or (x==r and y-1==b) --bottom right
			--then
				--goto start_map
			--end
		--end
	--end

	-- Get start position
	local rooms = self.map:getRooms()
	rooms = lume.sort(rooms, function(r1,r2)
		local cx1, cy1 = r1:getCenter()[1], r1:getCenter()[2]
		local cx2, cy2 = r2:getCenter()[1], r2:getCenter()[2]
		-- It's not exactly what I want but good enough
		return cy1 < cy2 and cx1 < cx2
	end)
	return rooms[1]:getCenter()[1]-1, rooms[1]:getCenter()[2]-1
end

function Lobby:checkSurrounding(t,x,y,comp)
	local t1 = {}
	for j,col in pairs(comp) do
		for i,v in pairs(col) do
			local comp_value = ((t[x+(i-2)/2] and t[x+(i-2)/2][y+(j-2)/2]) and t[x+(i-2)/2][y+(j-2)/2].q) or 0
			if math.min(1,comp_value) ~= v then
				return false
			end
		end
	end
	return true
end

function Lobby:getCamPosition()
	local player_in_room = false
	local player_room = nil

	for i,room in pairs(self.map:getRooms()) do
		local l,r,t,b = room:getLeft()+ll, room:getRight()+lr, room:getTop()+lt, room:getBottom()+lb
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
		local l,r,t,b = player_room:getLeft(), player_room:getRight(), player_room:getTop(), player_room:getBottom()
		local center = player_room:getCenter()
		local camx = center[1]*32+8
		local camy = center[2]*32-8
		self.camera:setPosition((l+r)/2*32+16,(t+b)/2*32+16)
	else
		self.camera:setPosition(self.player.x,self.player.y)
	end
end

function Lobby:update(dt)
	self.player:update(dt)
	for i,v in pairs(self.enemies) do
		v:update(dt)
	end
	local camx, camy = self:getCamPosition()
	--self.camera:setPosition(camx, camy)

	self.minicamera:setPosition(self.player.x/32,self.player.y/32)
end

function Lobby:draw()
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
			v:draw()
		end
		self.player:draw()
	end)
	love.graphics.setBlendMode("multiply","premultiplied")
	love.graphics.draw(self.shadow_canvas)
	love.graphics.setBlendMode("alpha")
	--love.graphics.setBlendMode("subtract")
	--love.graphics.draw(self.shadow_canvas)
	--love.graphics.setBlendMode("alpha")

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
end

function Lobby:keypressed(key)
	if key == "m" then
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

function Lobby:keyreleased(key)
	self.player:keyreleased(key)
end

return Lobby
