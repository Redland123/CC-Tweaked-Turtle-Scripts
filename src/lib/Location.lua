function Location()
	return {
		x = 0,
		y = 0,
		z = 0,
		d = 0, -- 0, forward. 1, left. 2, backward. 3, right. (counter-clockwise)
		turnLeft = function (self)
			self.d = (self.d + 1) % 4
		end,
		turnRight = function (self)
			self.d = (self.d - 1) % 4
		end,
		move = function (self, v)
			if self.d == 0 then
				self.z = self.z + v
			elseif self.d == 1 then
				self.x = self.x + v
			elseif self.d == 2 then
				self.z = self.z - v
			else
				self.x = self.x - v
			end
		end,
		mag = function (self)
			return math.sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
		end
	}
end

return Location
