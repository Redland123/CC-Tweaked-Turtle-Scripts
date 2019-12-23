local movement = require("lib.movement")

local api = {}

function api.forward(attack)
	if turtle.forward() then
		return true
	end
	while turtle.dig() do
		if turtle.forward() then
			return true
		end
	end
	if attack then
		turtle.attack()
		return api.forward(attack)
	end
	return false
end

function api.back(attack)
	if turtle.back() then
		return true
	end
	movement.turnAround()
	local success = api.forward(attack)
	movement.turnAround()
	return success
end

function api.up(attack)
	if turtle.up() then
		return true
	end
	while turtle.digUp() do
		if turtle.up() then
			return true
		end
	end
	if attack then
		turtle.attackUp()
		return api.up(attack)
	end
	return false
end

function api.down(attack)
	if turtle.down() then
		return true
	end
	while turtle.digDown() do
		if turtle.down() then
			return true
		end
	end
	if attack then
		turtle.attackDown()
		return api.down(attack)
	end
	return false
end

return api
