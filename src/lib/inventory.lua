local api = {}

function api.countID(itemID, firstSlot, lastSlot)
	if (not firstSlot) or (firstSlot < 1) then
		firstSlot = 1
	end
	if (not lastSlot) or (lastSlot > 16) then
		lastSlot = 16
	end
	local count = 0
	for i = firstSlot, lastSlot do
		local detail = turtle.getItemDetail(i)
		if detail and (detail.name == itemID) then
			count = count + detail.count
		end
	end
	return count
end

function api.selectID(itemID, firstSlot, lastSlot)
	if (not firstSlot) or (firstSlot < 1) then
		firstSlot = 1
	end
	if (not lastSlot) or (lastSlot > 16) then
		lastSlot = 16
	end
	local currentSlot = turtle.getSelectedSlot()
	if (currentSlot >= firstSlot) and (currentSlot <= lastSlot) then
		local currentDetail = turtle.getItemDetail()
		if currentDetail and (currentDetail.name == itemID) then
			return true
		end
	end
	for i = firstSlot, lastSlot do
		local detail = turtle.getItemDetail(i)
		if detail and (detail.name == itemID) then
			turtle.select(i)
			return true
		end
	end
	return false
end

function api.selectIDs(itemIDs, firstSlot, lastSlot)
	if (not firstSlot) or (firstSlot < 1) then
		firstSlot = 1
	end
	if (not lastSlot) or (lastSlot > 16) then
		lastSlot = 16
	end
	local currentSlot = turtle.getSelectedSlot()
	if (currentSlot >= firstSlot) and (currentSlot <= lastSlot) then
		local currentDetail = turtle.getItemDetail()
		if currentDetail and itemIDs[currentDetail.name] then
			return true
		end
	end
	for i = firstSlot, lastSlot do
		local detail = turtle.getItemDetail(i)
		if detail and itemIDs[detail.name] then
			turtle.select(i)
			return true
		end
	end
	return false
end

function api.compact(firstSlot, lastSlot)
	if (not firstSlot) or (firstSlot < 2) then
		firstSlot = 2
	end
	if (not lastSlot) or (lastSlot > 16) then
		lastSlot = 16
	end
	local oldSlot = turtle.getSelectedSlot()
	for source = firstSlot, lastSlot do
		local sourceDetail = turtle.getItemDetail(source)
		if sourceDetail then
			for target = 1, source - 1 do
				local targetDetail = turtle.getItemDetail(target)
				if targetDetail and (sourceDetail.name == targetDetail.name) and (targetDetail.count < 64) then
					turtle.select(source)
					turtle.transferTo(target)
				end
			end
		end
	end
	if turtle.getSelectedSlot() ~= oldSlot then
		turtle.select(oldSlot)
	end
end

return api
