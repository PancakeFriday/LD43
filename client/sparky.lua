local HC = require "HC"

local Sparky = Object:extend()

function Sparky:new(x,y)
	self.x = x*32
	self.y = y*32
	self.img = love.graphics.newImage("img/sparky.png")
	self.quad = love.graphics.newQuad(0,0,32,32,self.img:getWidth(),self.img:getHeight())
	self.bbox = HC.circle(self.x-8, self.y-8, 6)
	self.bbox.type = "enemy"

	self.grav_vector={x=0,y=-50}
	self.vel = {x=50,y=0}

	self.time = 0
	self.inv_timer = 0
	self.health = 2
end

function Sparky:update(dt)
	if self.health <= 0 then
		self.dead = true
	end

	if not self.dead then
		self.time = self.time + dt
		self.inv_timer = math.min(self.inv_timer+dt*2,0)
		if self.inv_timer >= 0 then
			self.bbox.type = "enemy"
		end

		local mx, my = 0, 0
		self.vel.x = self.grav_vector.x*dt+self.vel.x
		self.vel.y = self.grav_vector.y*dt+self.vel.y

		mx = self.vel.x*dt
		my = self.vel.y*dt

		self:move(mx,my)
	end
end

function Sparky:move(mx,my)
	self.bbox:move(mx,my)
	for shape, delta in pairs(HC.collisions(self.bbox)) do
		if shape.type == "wall" or shape.type == "door" then
			self.bbox:move(-mx,-my)
			if math.abs(delta.y) > math.abs(delta.x) then
				self.vel.y = 100*lume.sign(delta.y)
				self.vel.x = 50*lume.sign(delta.x)
				self.grav_vector = {x=0,y=-50*lume.sign(delta.x)}
			else
				self.vel.x = 100*lume.sign(delta.x)
				self.vel.y = -50*lume.sign(delta.y)
				self.grav_vector = {x=-50*lume.sign(delta.x),y=0}
			end
			return
		elseif shape.type == "sword" and self.inv_timer >= 0 then
			self.health = self.health - 1
			self.inv_timer = -math.pi
			self.bbox.type = ""
			break
		end
	end

	self.x = self.x + mx
	self.y = self.y + my
end

function Sparky:draw()
	if not self.dead then
		local v = math.cos(self.inv_timer*math.pi*1.5)^2
		if self.inv_timer < 0 then
			love.graphics.setColor(1,0.5,0.5,v)
		else
			love.graphics.setColor(1,1,1)
		end
		love.graphics.draw(self.img, self.quad, self.x-8, self.y-8,self.time,1,1,16,16)
	end
end

return Sparky
