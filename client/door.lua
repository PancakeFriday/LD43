local HC = require "lib.HC"

local Door = Object:extend()
Door.img = love.graphics.newImage("img/doors.png")
Door.img:setFilter("nearest","nearest")

local Sparky = require "sparky"

function Door:new(obj, rooms, doors, enemies, player, id)
	self.rooms = rooms
	self.doors = doors
	self.enemies = enemies
	self.player = player
	self.id = id

	for i,k in pairs(obj) do
		self[i] = k
	end

	self.quads={
		love.graphics.newQuad(0,0,32,16,Door.img:getWidth(),Door.img:getHeight()),
		love.graphics.newQuad(32,0,32,16,Door.img:getWidth(),Door.img:getHeight()),
		love.graphics.newQuad(16,16,16,32,Door.img:getWidth(),Door.img:getHeight()),
		love.graphics.newQuad(0,16,16,32,Door.img:getWidth(),Door.img:getHeight())
	}
	if self.tx - self.x == 0 then
		if self.ty - self.y == 1 then
			self.quad = 1
			self.xoff = 0
			self.yoff = 24
		else
			self.quad = 2
			self.xoff = 0
			self.yoff = -8
		end
	else
		if self.tx - self.x == 1 then
			self.quad = 3
			self.xoff = 24
			self.yoff = 0
		else
			self.quad = 4
			self.xoff = -8
			self.yoff = 0
		end
	end

	self.trigger_box = HC.rectangle(self.tx*32,self.ty*32,32,32)
	self.trigger_box:scale(0.2,0.2)
	self.trigger_box.type = "door_trigger"
	self.trigger_box.obj = self

	self.door_box = nil
end

function Door:activate(dont_check_room)
	HC.remove(self.trigger_box)

	self.door_box = HC.rectangle(self.x*32,self.y*32,32,32)
	self.door_box.type = "door"

	if not dont_check_room then
		for j,door in pairs(self.doors) do
			if door ~= self and door.r == self.r then
				door:activate(true)
			end
		end

		local t = {}
		math.randomseed(love.timer.getTime())
		love.math.setRandomSeed(love.timer.getTime())
		flux.to(t, 3, {}):oncomplete(function()
			self.player.inv_timer = -2
			local enemies = {Sparky}
			for i,room in pairs(self.rooms) do
				if i == self.r then
					local num_enemies = math.floor(lume.random(2,8))
					for j=1,num_enemies do
						self.enemies[self.r] = self.enemies[self.r] or {}

						local x = lume.random(room.l+1,room.r-1)
						local y = lume.random(room.t+1,room.b-1)
						table.insert(self.enemies[self.r], lume.randomchoice(enemies)(x,y))
					end
					break
				end
			end
		end)
	end
end

function Door:deactivate()
	if self.door_box then
		HC.remove(self.door_box)
	end
	HC.remove(self.trigger_box)
end

function Door:setSpecial()
	local w,h
	if self.quad == 1 then
		w,h = 32,16
	elseif self.quad == 2 then
		w,h = 32,16
	elseif self.quad == 3 then
		w,h = 16,32
	else
		w,h = 16,32
	end
	self.door_box = HC.rectangle(self.x*32+self.xoff,self.y*32+self.yoff,w,h)
	self.door_box.type = "door_special"
	self.door_box_trigger = HC.rectangle(self.x*32+self.xoff,self.y*32+self.yoff,w,h)
	self.door_box_trigger:scale(2.0,2.0)
	self.door_box_trigger.type = "door_special_trigger"
	self.door_box_trigger.id = self.id
	self.door_box_trigger.x = self.x
	self.door_box_trigger.y = self.y

	self.special = true
end

function Door:draw()
	if self.door_box then
		if self.special then
			love.graphics.setColor(1,0,1)
			--love.graphics.rectangle("fill",self.x*32,self.y*32,100,100)
		else
			love.graphics.setColor(1,1,1)
		end
		love.graphics.draw(Door.img, self.quads[self.quad], self.x*32+self.xoff,self.y*32+self.yoff)
	end
end

return Door
