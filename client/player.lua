local Animation = require "animation"
local HC = require "HC"

local Player = Object:extend()

function Player:new(in_control,x,y)
	self.x = x*32
	self.y = y*32

	self.anim = Animation("img/player.png",32,32)
	self.anim:add("idle", 0,0)
	self.anim:add("move_up", 0,1,1,1,2,1,3,1)
	self.anim:add("move_down", 0,0,1,0,2,0,3,0)
	self.anim:add("move_left", 0,3,1,3,2,3)
	self.anim:add("move_right", 0,2,1,2,2,2)

	self.anim:add("sword_down", 0,4,1,4)
	self.anim:add("sword_up", 0,5,1,5)
	self.anim:add("sword_right", 0,6,1,6)
	self.anim:add("sword_left", 0,7,1,7)
	self.anim:set("idle")

	self.sword_w, self.sword_h = 14, 6

	self.key_stack = {}
	self.bbox = HC.rectangle(self.x+2,self.y+4,12,12)
	self.sword_bbox = HC.rectangle(-10000,-10000,self.sword_w,self.sword_h)
	self.sword_bbox.type = "sword"

	self.sword_movement = {s=0,x=0,y=0,t=0}
	self.dir = {x=0,y=1}

	self.sword_tween = nil

	self.health = 3

	self.inv_timer = 0
end

function Player:update(dt)
	self.inv_timer = self.inv_timer + dt
	local speed = 100
	if love.keyboard.isDown("lshift") then
		speed = 300
	end
	local mx, my = 0, 0

	if self.sword_movement.t == 0 and self.sword_movement.s == 0 then
		if self.key_stack[#self.key_stack] == "left" then
			self.anim:set("move_left")
			self.anim.timestep=0.2
			mx = mx - speed*dt
			self.dir.x = -1
			self.dir.y = 0
		elseif self.key_stack[#self.key_stack] == "right" then
			self.anim:set("move_right")
			self.anim.timestep=0.2
			mx = mx + speed*dt
			self.dir.x = 1
			self.dir.y = 0
		elseif self.key_stack[#self.key_stack] == "up" then
			self.anim:set("move_up")
			self.anim.timestep=0.2
			my = my - speed*dt
			self.dir.x = 0
			self.dir.y = -1
		elseif self.key_stack[#self.key_stack] == "down" then
			self.anim:set("move_down")
			self.anim.timestep=0.2
			my = my + speed*dt
			self.dir.x = 0
			self.dir.y = 1
		end

		if mx == 0 and my == 0 then
			self.anim.time = 0
			self.anim:pause()
		else
			self.anim:continue()
		end
	else
		mx = self.sword_movement.x*dt
		my = self.sword_movement.y*dt
	end
	self:move(mx,my)
	self.anim:update(dt)
end

function Player:hurt(dx,dy)
	if self.inv_timer > 0 then
		self.inv_timer = -1
		self.health = self.health - 1

		local m = 500
		flux.to(self.sword_movement,0.1,{x=-m*self.dir.x,y=-m*self.dir.y,t=1})
			:ease("quadinout")
			:onstart(function()
				self.sword_movement.s = -1
			end)
			:oncomplete(function()
				self.sword_movement={x=0,y=0,t=0,s=0}
			end)
	end
end

function Player:move(mx, my)
	-- Since we can only move in one dir at a time, I won't separate x and y
	self.bbox:move(mx,my)
	local has_col = false
	for shape, delta in pairs(HC.collisions(self.bbox)) do
		if shape.type == "wall" then
			has_col = true
			break
		elseif shape.type == "enemy" then
			self:hurt()
		end
	end
	if has_col then
		self.bbox:move(-mx,-my)
	else
		self.x = self.x + mx
		self.y = self.y + my
		self.sword_bbox:move(mx,my)
	end
end

function Player:draw()
	love.graphics.setColor(1,1,1)
	love.graphics.push()
		love.graphics.translate(self.x-8, self.y-8)
		self.anim:draw()
	love.graphics.pop()
	--self.bbox:draw()
	--self.sword_bbox:draw()
end

function Player:keypressed(key)
	if key == "left" or key == "right" or key == "up" or key == "down" then
		table.insert(self.key_stack, key)
	end
	if key == "space" then
		if self.sword_movement.t ~= 0 and self.sword_movement.s == 1 then
			self.anim.time = 0
			self.anim:continue()
			local m = 800
			self.sword_tween:stop()
			self.sword_tween = flux.to(self.sword_movement, 0.1, {x=m*self.dir.x,y=m*self.dir.y,t=1})
				:ease("quadinout")
				:onstart(function()
					self.sword_movement.s = 2
				end)
				:oncomplete(function()
					self.sword_tween:stop()
					self.sword_movement={x=0,y=0,t=0,s=3}
					self.sword_tween = flux.to(self.sword_movement, 0.6, {t=1})
						:oncomplete(function()
							self.sword_bbox:moveTo(-10000,-10000)
							self.sword_movement={x=0,y=0,t=0,s=0}
						end)
				end)
		elseif self.sword_movement.s == 0 then
			self.anim.timestep=0.1
			local move_dir
			if self.dir.x == 1 then
				move_dir = "right"
				self.sword_bbox = HC.rectangle(self.x+10, self.y+8, self.sword_w, self.sword_h)
				self.sword_bbox.type = "sword"
			elseif self.dir.x == -1 then
				move_dir = "left"
				self.sword_bbox = HC.rectangle(self.x-8, self.y+8, self.sword_w, self.sword_h)
				self.sword_bbox.type = "sword"
			elseif self.dir.y == 1 then
				move_dir = "down"
				self.sword_bbox = HC.rectangle(self.x+8, self.y+10, self.sword_h, self.sword_w)
				self.sword_bbox.type = "sword"
			elseif self.dir.y == -1 then
				move_dir = "up"
				self.sword_bbox = HC.rectangle(self.x+3, self.y-9, self.sword_h, self.sword_w)
				self.sword_bbox.type = "sword"
			end
			self.anim:set("sword_"..move_dir, true)
			self.anim:continue()

			local m = 500
			self.sword_tween = flux.to(self.sword_movement, 0.2, {x=m*self.dir.x,y=m*self.dir.y,t=1})
				:ease("quadinout")
				:onstart(function()
					self.sword_movement.s = -1
				end)
				:oncomplete(function()
					self.sword_tween:stop()
					self.sword_movement={x=0,y=0,t=0,s=1}
					self.sword_tween = flux.to(self.sword_movement, 0.2, {t=1})
						:oncomplete(function()
							self.anim:set("move_"..move_dir)
							self.sword_movement={x=0,y=0,t=0,s=0}
							self.sword_bbox:moveTo(-10000,-10000)
						end)
				end)
		end
	end
end

function Player:keyreleased(key)
	if key == "left" or key == "right" or key == "up" or key == "down" then
		lume.remove(self.key_stack, key)
	end
end

return Player
