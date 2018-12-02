local ROT = require 'rotLove/rot'

local Lobby = Object:extend()

function Lobby:new()
	self.mapw, self.maph = 100,100

	self.players = {}

	self.startRoom, self.endRoom = self:createMap()

	self.dead_players = {}
	self.unlocked_doors = {}
	self.unlocked_rooms = {}

	self.enemies = {}
end

function Lobby:addPlayer(client)
	table.insert(self.players, {c=client,name="hannibal"})
end

function Lobby:removePlayer(client)
	for i,v in pairs(self.players) do
		if v.c == client then
			table.remove(self.players,i)
			if #self.players >= 1 then
				local map_data = self:get_map_data()
				self.players[1].c:send("ready", map_data)
			end
			break
		end
	end
end

function Lobby:get_map_data()
	local rooms = {}
	local doors = {}
	local door_triggers = {}
	math.randomseed(777)
	for i,room in pairs(self.map:getRooms()) do
		local l,r,t,b = room:getLeft(),room:getRight(),room:getTop(),room:getBottom()
		table.insert(rooms, {l=l,r=r,t=t,b=b})

		for ix=l,r do
			local s=(math.random()<0.3)
			if lume.find(self.unlocked_doors, #doors+1) then
				s=false
			end
			if not lume.find(self.unlocked_rooms, i) then
				local iy = t-1
				if self.map_values[ix][iy] and self.map_values[ix][iy] == 0 then
					table.insert(doors, {x=ix,y=iy,tx=ix,ty=iy+1,r=i,s=s})
				end
				local iy = b+1
				if self.map_values[ix][iy] and self.map_values[ix][iy] == 0 then
					table.insert(doors, {x=ix,y=iy,tx=ix,ty=iy-1,r=i,s=s})
				end
			end
		end
		for iy=t,b do
			local s=(math.random()<0.3)
			if lume.find(self.unlocked_doors, #doors+1) then
				s=false
			end
			if not lume.find(self.unlocked_rooms, i) then
				local ix = l-1
				if self.map_values[ix][iy] and self.map_values[ix][iy] == 0 then
					table.insert(doors, {x=ix,y=iy,tx=ix+1,ty=iy,r=i,s=s})
				end
				local ix = r+1
				if self.map_values[ix][iy] and self.map_values[ix][iy] == 0 then
					table.insert(doors, {x=ix,y=iy,tx=ix-1,ty=iy,r=i,s=s})
				end
			end
		end
	end
	math.randomseed(love.timer.getTime())

	local players = {}
	for i,v in pairs(self.players) do
		table.insert(players, {name=v.name,x=0,y=0})
	end

	return {
		draw_map=self.draw_map,
		rooms=rooms,
		doors=doors,
		mapw=self.mapw,
		maph=self.maph,
		startRoom=self.startRoom,
		endRoom=self.endRoom,
		players=players,
	}
end

function Lobby:registerCallbacks()
	Server:on("request_map", function(data,client)
		self:addPlayer(client)
		local map_data = self:get_map_data()
		client:send("request_map", map_data)
	end)

	Server:on("game_finished", function(data,client)
		print("game finished!")
		love.event.quit()
	end)

	Server:on("update_light", function(data,client)
		for x,v in pairs(self.draw_map) do
			for y,k in pairs(v) do
				self.draw_map[x][y].l = math.max(k.l, data[x][y])
			end
		end
		client:send("update_light",self.draw_map)
	end)

	Server:on("update_player", function(data,client)
	end)

	Server:on("player_ready", function(data,client)
		print(self.players[1].c)
		if self.players[1].c:getConnectId() == client:getConnectId() then
			print(self.dead_players)
			client:send("ready", self.dead_players)
		end
	end)

	Server:on("player_death", function(data,client)
		table.insert(self.dead_players,data)
		client:send("death_received")
	end)

	Server:on("unlock_door",function(data,client)
		table.insert(self.unlocked_doors,data)
	end)

	Server:on("room_done",function(data,client)
		table.insert(self.unlocked_rooms,data)
	end)
end

function Lobby:createMap()
	self.map = ROT.Map.Digger(self.mapw,self.maph,{
		roomWidth={8,10},
		roomHeight={6,7},
		corridorLength={3,3},
	})
	self.draw_map = {}
	self.map_values = {}
	self.map:create(function(x,y,value)
		if not self.map_values[x] then self.map_values[x] = {} end
		self.map_values[x][y] = value
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

	-- Get start position
	local rooms = self.map:getRooms()
	local trooms = lume.sort(rooms, function(r1,r2)
		local cx1, cy1 = r1:getCenter()[1], r1:getCenter()[2]
		local cx2, cy2 = r2:getCenter()[1], r2:getCenter()[2]
		-- It's not exactly what I want but good enough
		return cy1 < cy2 and cx1 < cx2
	end)
	local startRoom, endRoom
	for i,v in pairs(rooms) do
		if v==trooms[1] then
			startRoom = i
		elseif v==trooms[#trooms] then
			endRoom = i
		end
	end
	return startRoom, endRoom
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

return Lobby
