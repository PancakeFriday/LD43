local Lobby = Object:extend()

function Lobby:new()
	self.mapw, self.maph = 100,100

	local startx, starty = self:createMap()

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

return Lobby
