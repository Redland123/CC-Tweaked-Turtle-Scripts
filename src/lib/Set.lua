local instanceMetatable = {}

local Set = {}

function Set.is(s)
	return getmetatable(s) == instanceMetatable
end

function instanceMetatable.__concat(leftSet, rightSet)
	for k, _ in pairs(rightSet) do
		leftSet[k] = true
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
		for k, _ in pairs(listOrSet) do
			set[k] = true
		end
	else
		for _, v in ipairs(listOrSet) do
			set[v] = true
		end
	end
	setmetatable(set, instanceMetatable)
	return set
end

setmetatable(Set, staticMetatable)

return Set
