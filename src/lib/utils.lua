local api = {}

function api.concat(consumer, supplier)
	for k, v in pairs(supplier) do
		consumer[k] = v
	end
	return consumer
end

return api
