local instanceMetatable = {}

local Set = {}

function Set.is(s)
	return getmetatable(s) == instanceMetatable
end

function instanceMetatable.__concat(leftSet, rightSet)
	if type(leftSet) ~= "table" or type(rightSet) ~= "table" then
		print("Error: set concat given string instead of table")
		return nil
	end

	local largest = 0
	-- Iterate over leftSet to find largest index
	for _, i in pairs(leftSet) do
		if i > largest then
			largest = i
		end
	end
	-- Copy keys from rightSet and offset by the largest in the leftSet
	-- TODO: Check if bug is fixed: "Bad argument (table expected, got string)" line 18: "for k, i in pairs(rightSet) do"
	for k, i in pairs(rightSet) do
		leftSet[k] = i + largest
	end
	return leftSet
end

function instanceMetatable.__add(leftSet, rightSet)
	return Set(leftSet) .. rightSet
end

function instanceMetatable.__tostring(set)
	local next = "{ "
	local last = next
	local has = false
	for k, _ in pairs(set) do
		local n = next .. k
		next = n .. ", "
		last = n
		has = true
	end
	return has and (last .. " }") or "{}"
end

local staticMetatable = {}

function staticMetatable.__call(_, listOrSet)
	local set = {}
	if Set.is(listOrSet) then
		for k, i in pairs(listOrSet) do
			set[k] = i
		end
	else
		for i, v in ipairs(listOrSet) do
			set[v] = i
		end
	end
	setmetatable(set, instanceMetatable)
	return set
end

setmetatable(Set, staticMetatable)

return Set
