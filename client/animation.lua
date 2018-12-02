local Animation = Object:extend()

function Animation:new(img, cellw, cellh)
	self.img = love.graphics.newImage(img)
	self.cellw, self.cellh = cellw, cellh

	self.anim_quads = {}

	self.paused = false
	self.time = 0
	self.timestep = 0.2
end

function Animation:add(name, ...)
	local anim_indices = {...}
	assert(#anim_indices%2 == 0, "Animation indices must be multiples of two")

	self.anim_quads[name] = {}
	for i=1,#anim_indices,2 do
		local ix, iy = anim_indices[i]*self.cellw, anim_indices[i+1]*self.cellh
		local quad = love.graphics.newQuad(ix,iy,self.cellw,self.cellh,self.img:getWidth(),self.img:getHeight())
		table.insert(self.anim_quads[name], quad)
	end
end

function Animation:set(name, play_once)
	self.play_once = play_once or false
	assert(self.anim_quads[name], "Animation "..name.." does not exist!")
	if self.current ~= name then
		self.current = name
		self.time = 0
	end
end

function Animation:pause()
	self.paused = true
end

function Animation:continue()
	self.paused = false
end

function Animation:update(dt)
	if not self.paused then
		self.time = self.time + dt
	end
end

function Animation:draw()
	if self.current then
		local index
		if self.play_once then
			index = math.min(math.floor(self.time/self.timestep)+1,#self.anim_quads[self.current])
		else
			index = math.floor(self.time/self.timestep)%(#self.anim_quads[self.current])+1
		end
		love.graphics.draw(self.img, self.anim_quads[self.current][index])
	end
end

return Animation
