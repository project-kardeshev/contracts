local json = require("json")

MFA = MFA
	or {
		pendingMessages = {
			["message-id"] = {
				yays = { ["controller"] = true },
				nays = { ["controller"] = true },
				msg = {},
				co_ref = nil,
			},
		},
		maxPendingMessages = 1000,
		pendingMessageTtl = 1000 * 60 * 60 * 24 * 7, -- one week in ms
		controllers = { [Owner] = true },
		filters = {
			{ id = "", filter = {
				Action = "MFA.Add-Controller",
			}, quorum = 1 },
			{ id = "", filter = {
				Action = "MFA.Remove-Controller",
			}, quorum = 1 },
			{ id = "", filter = {
				Action = "MFA.Set-Filter",
			}, quorum = 1 },
			{ id = "", filter = {
				Action = "MFA.Delete-Filter",
			}, quorum = 1 },
			{ id = "", filter = {
				Action = "MFA.Uninstall",
			}, quorum = 1 },
		},
	}

local ActionMap = {
	AddController = "MFA.Add-Controller",
	RemoveController = "MFA.Remove-Controller",
	SetFilter = "MFA.Set-Filter",
	DeleteFilter = "MFA.Delete-Filter",
	Uninstall = "MFA.Uninstall",
	-- make sure these are not allowed to be filtered
	GetPendingMessages = "MFA.Get-Pending-Messages",
	GetState = "MFA.Get-State",
	Vote = "MFA.Vote",
}

local RestrictedActionFilters = {
	[ActionMap.GetPendingMessages] = true,
	[ActionMap.GetState] = true,
	[ActionMap.Vote] = true,
}

-- This handles pruning messages in our MFA global, as well as the associated handlers and coroutines
-- If we do not clean out the handlers they might persist forever, as with the coroutines.
local function prunePendingMessages(msg)
	local currentTimestamp = tonumber(msg.Timestamp)
	local messagesToPrune = {}

	-- Accumulate message IDs to prune
	for id, message in pairs(MFA.pendingMessages) do
		local msgTimestamp = tonumber(message.msg.Timestamp)
		local elapsedTimeMs = currentTimestamp - msgTimestamp
		if elapsedTimeMs >= MFA.pendingMessageTtl then
			messagesToPrune[id] = true
		end
	end

	-- Remove messages and their associated coroutines
	for id, _ in pairs(messagesToPrune) do
		local entry = MFA.pendingMessages[id]

		-- Prune coroutine if it's still active
		if entry and entry.co_ref and coroutine.status(entry.co_ref) ~= "dead" then
			-- Only available in LuaJIT; otherwise, let GC handle it
			if coroutine.close then
				coroutine.close(entry.co_ref)
			end
		end

		-- Also remove the coroutine reference from Handlers.coroutines if applicable
		for i, co in ipairs(Handlers.coroutines) do
			if co == entry.co_ref then
				table.remove(Handlers.coroutines, i)
				break -- Exit loop after removal
			end
		end

		MFA.pendingMessages[id] = nil
	end

	-- Filter _once_ Handlers that are for the target message IDs
	local filteredHandlers = {}
	for _, handler in ipairs(Handlers.list) do
		if not handler.msgId or (handler.msgId and not messagesToPrune[handler.msgId]) then
			table.insert(filteredHandlers, handler)
		end
	end
	Handlers.list = filteredHandlers
end

Handlers.add(ActionMap.AddController, { Action = ActionMap.AddController }, function(msg)
	local controller = msg.Controller
	assert(type(controller) == "string", "Controller must be a string")
	assert(not MFA.controllers[controller], "Controller already exists")

	MFA.controllers[controller] = true
end)

Handlers.add(ActionMap.RemoveController, { Action = ActionMap.RemoveController }, function(msg)
	local controller = msg.Controller
	assert(type(controller) == "string", "Controller must be a string")
	assert(MFA.controllers[controller], "Controller does not exist")

	MFA.controllers[controller] = nil
end)

Handlers.add(ActionMap.SetFilter, { Action = ActionMap.SetFilter }, function(msg)
	local filter = json.decode(msg.Filter)
	local quorum = tonumber(msg.Quorum)
	local name = msg.Name

	assert(filter, "filter is required")
	assert(math.type(quorum) == "integer", "Quorum must be an integer")
	assert(type(name) == "string", "name must be a string")
	for _, existingFilter in ipairs(MFA.filters) do
		for name, value in pairs(filter) do
		end
	end

	table.insert(MFA.filters, { filter, quorum, id = msg.Id, name = name })
end)

Handlers.add(ActionMap.DeleteFilter, { Action = ActionMap.DeleteFilter }, function(msg)
	local filterId = msg["Filter-Id"]
	assert(type(filterId) == "string", "Filter-Id must be a string")

	local filteredFilters = {}

	for _, filter in ipairs(MFA.filters) do
		if filter.id ~= filterId then
			table.insert(filteredFilters, filter)
		end
	end

	assert(#filteredFilters ~= #MFA.filters, "No filter exists with ID: " .. filterId)
	MFA.filters = filteredFilters
end)

Handlers.add(ActionMap.GetPendingMessages, { Action = ActionMap.GetPendingMessages }, function(msg)
	msg.reply({
		Action = ActionMap.GetPendingMessages .. "-Notice",
		Data = json.encode(MFA.pendingMessages),
	})
end)

Handlers.add(ActionMap.GetState, { Action = ActionMap.GetState }, function(msg)
	msg.reply({
		Action = ActionMap.GetState .. "-Notice",
		Data = json.encode(MFA),
	})
end)

Handlers.prepend("mfa", function(msg)
	-- prune in the matcher so that when handler is called we have correct state
	prunePendingMessages(msg)
	return "continue"
end, function(msg) end)
