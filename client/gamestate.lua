local Gamestate = {
	registered = {},
	names = {},
	instances = {}
}

function Gamestate:register(s, n)
	if not lume.find(self.registered, s) then
		self.registered[n] = s
	else
		print("[WARNING] Class ".." already registered as a gamestate!")
	end
end

function Gamestate:set(n, ...)
	if not self.registered[n] then
		error("Class is not registered as a gamestate. Call register(...) before setting it")
	end

	if not self.instances[n] then
		self.instances[n] = self.registered[n](...)
	end
	self.state = self.instances[n]
end

function Gamestate:reset(n)
	self.instances[n] = nil
end

function Gamestate:call(f, ...)
	if self.state then
		if self.state[f] then
			self.state[f](self.state, ...)
		end
	end
end

function Gamestate:load(...)
	self:call("load", ...)
end

function Gamestate:draw()
	self:call("draw")
end

function Gamestate:update(...)
	self:call("update", ...)
end

function Gamestate:textedited(...)
	self:call("textedited", ...)
end

function Gamestate:textinput(...)
	self:call("textinput", ...)
end

function Gamestate:keypressed(...)
	self:call("keypressed", ...)
end

function Gamestate:keyreleased(...)
	self:call("keyreleased", ...)
end

function Gamestate:mousepressed(...)
	self:call("mousepressed", ...)
end

function Gamestate:mousereleased(...)
	self:call("mousereleased", ...)
end

function Gamestate:wheelmoved(...)
	self:call("wheelmoved", ...)
end

function Gamestate:resize(...)
	self:call("resize", ...)
end

return Gamestate
