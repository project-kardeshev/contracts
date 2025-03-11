local mod = {}

---@param name string
---@param matcher table | function
---@param handler function
---@param inserter function
function mod.addEventingHandler(name, matcher, handler, inserter)
	inserter(name, matcher, function(msg)
		handler(msg)
	end)
end

return mod
