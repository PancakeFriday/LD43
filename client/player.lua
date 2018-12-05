local utf8 = require("utf8")
local Animation = require "animation"
local HC = require "lib.HC"

local Player = Object:extend()

function Player:new(in_control,x,y,camera)
	Client:on("death_received", function()
		love.event.quit()
	end)

	self.sword_hit = love.audio.newSource("sound/hit_sword.wav","static")
	self.sword_hit:setLooping(false)
	self.sword_hit:setVolume(0.6)

	self.hit_sound = love.audio.newSource("sound/hit.wav","static")
	self.hit_sound:setLooping(false)
	self.hit_sound:setVolume(0.6)

	self.x = x*32
	self.y = y*32
	self.camera = camera

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

	self.heart_img = love.graphics.newImage("img/heart.png")
	self.heart_quads = {
		love.graphics.newQuad(0,0,13,12,26,12),
		love.graphics.newQuad(13,0,13,12,26,12),
	}

	self.death_scroll_img = love.graphics.newImage("img/death_scroll.png")
	self.death_text = ""
	love.keyboard.setKeyRepeat(true)

	self.font_headline = love.graphics.newFont("fonts/Monda-Regular.ttf", 20)
	self.font_text = love.graphics.newFont("fonts/Monda-Regular.ttf", 10)

	self.sword_movement = {s=0,x=0,y=0,t=0}
	self.dir = {x=0,y=1}

	self.sword_tween = nil

	self.health = 3

	self.inv_timer = 0

	self.read_tutorial = false
end

function Player:update(dt)
	if not self.dead and self.read_tutorial then
		self.inv_timer = self.inv_timer + dt
		local speed = 100
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
	else
		self.inv_timer = 0
	end
end

function Player:hurt(dx,dy)
	if self.inv_timer > 0 then
		self.hit_sound:stop()
		self.hit_sound:play()
		self.inv_timer = -1
		self.health = self.health - 1

		if self.health <= 0 then
			self:kill()
			return
		end

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

function Player:kill()
	self.dead = true
end

function Player:move(mx, my)
	-- Since we can only move in one dir at a time, I won't separate x and y
	self.bbox:move(mx,my)
	local has_col = false
	for shape, delta in pairs(HC.collisions(self.bbox)) do
		if shape.type == "wall" or shape.type == "door" or shape.type == "door_special" then
			has_col = true
			break
		elseif shape.type == "enemy" then
			self:hurt()
		elseif shape.type == "door_trigger" then
			shape.obj:activate()
		elseif shape.type == "money" then
			shape.level.finished = true
			if not self.game_done then
				self.game_done = true
				Client:send("game_done")
			end
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

function Player:draw(l,t,w,h)
	local v = math.cos(self.inv_timer*math.pi*1.5)^2
	if self.inv_timer < 0 then
		love.graphics.setColor(0.5,1,0.5,v)
	else
		love.graphics.setColor(1,1,1)
	end
	love.graphics.push()
		love.graphics.translate(self.x-8, self.y-8)
		self.anim:draw()
	love.graphics.pop()
	love.graphics.setColor(1,1,1)
	love.graphics.setCanvas()

	for v,i in pairs(HC.collisions(self.bbox)) do
		if v.type == "dead_player" then
			self:show_scroll(l,t,w,h,v.obj.text,"",function() end)
		elseif v.type == "door_special_trigger" then
			self:show_scroll(l,t,w,h,"Your sacrifice is required in order to unlock this door. The next hero will be able to continue in order to find the hidden treasure", "Continue", function()
				local t = {}
				flux.to(t,0.2,{}):oncomplete(function()
					if not self.sent_unlock then
						self.sent_unlock = true
						local hash = love.data.hash("sha256", "x:"..v.x.."y:"..v.y)
						Client:send("unlock_door",{hash=hash,index=v.id})
						self:kill()
					end
				end)
			end)
		end
	end

	if self.dead then
		local text = "You have died. With your last breath, you write down the following words to the next hero (start typing):\n"..self.death_text
		self:show_scroll(l,t,w,h,text,"Send",function(tx,ty)
			local mx, my = love.mouse.getPosition()
			tx, ty = self.camera:toScreen(tx,ty)
			if mx > tx and mx < tx + 60 then
				if my > ty-10 and my < ty + 50 then
					if not self.sent_letter then
						self.sent_letter = true
						Client:send("player_death", {x=self.x,y=self.y,text=self.death_text})
						Client:update()
					end
				end
			end
		end)
	end

	if not self.read_tutorial then
		self:show_scroll(l,t,w,h,"Hello, fellow hero. You have entered this dungeon, as you loathe for the sacred treasure. However, this dungeon will require many sacrifices and therefore, it might not be you who will reach the treasure. You have been warned.\nOther heroes might have explored parts of the dungeon already, so you've got that going for you.\n\nMovement: Directional keys\nAttack: Spacebar\nMap: [m]","Continue",function() self.read_tutorial =true end)
	end

	for i=1,3 do
		local q = 1
		if self.health < 4-i then
			q = 2
		end
		love.graphics.draw(self.heart_img, self.heart_quads[q], l+w-(20+i*15), t+15)
	end
end

function Player:show_scroll(l,t,w,h,text,send_text,send_fun)
	love.graphics.draw(self.death_scroll_img, l+w/2-self.death_scroll_img:getWidth()/2, t+30)
	love.graphics.setFont(self.font_headline)
	love.graphics.setColor(1,1,1)
	local width, wrappedText = self.font_headline:getWrap(text, 130*self.camera:getScale())
	for i,text in pairs(wrappedText) do
		love.graphics.setColor(0,0,0)
		love.graphics.printUnscaled(self.camera, text, l+w/2-self.death_scroll_img:getWidth()/2+13, t+35.5+i*10)
		love.graphics.setColor(1,1,1)
		love.graphics.printUnscaled(self.camera, text, l+w/2-self.death_scroll_img:getWidth()/2+13, t+35+i*10)
	end

	local tx = l+w/2+self.death_scroll_img:getWidth()/2-60
	local ty = t+self.death_scroll_img:getHeight()
	love.graphics.setColor(0,0,0)
	love.graphics.printUnscaled(self.camera, send_text, tx, ty+1)
	love.graphics.setColor(1,1,1)
	love.graphics.printUnscaled(self.camera, send_text, tx,ty)

	if love.mouse.isDown(1) then
		send_fun(tx,ty)
	end
end

function Player:keypressed(key)
	if key == "left" or key == "right" or key == "up" or key == "down" then
		table.insert(self.key_stack, key)
		self.key_stack = lume.unique(self.key_stack)
	end
	if key == "space" then
		if not self.dead then
			self.sword_hit:stop()
			self.sword_hit:play()
		end
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
			self.sword_bbox:scale(2.0,2.0)
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

	if self.dead then
		if key == "backspace" then
			-- get the byte offset to the last UTF-8 character in the string.
			local byteoffset = utf8.offset(self.death_text, -1)

			if byteoffset then
				-- remove the last UTF-8 character.
				-- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
				self.death_text = string.sub(self.death_text, 1, byteoffset - 1)
			end
		elseif key == "return" then
			self.death_text = self.death_text .. "\n"
		end
	end
end

function Player:keyreleased(key)
	if key == "left" or key == "right" or key == "up" or key == "down" then
		lume.remove(self.key_stack, key)
	end
end

function Player:textinput(text)
	if self.dead then
		self.death_text = self.death_text .. text
	end
end

return Player
