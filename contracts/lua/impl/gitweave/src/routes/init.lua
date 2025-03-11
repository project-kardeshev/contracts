-- ROUTES are handler definitions
---@alias Route {
--- name: string,
--- matcher: function | table,
--- handler: function,
--- mount: function,
--- manual: table<string, string>,
---}
-- When exported from here, we can iterate over them to mount them in our process.

---@type Route
local route = {
	--- route logic
	name = "my printing handler",
	matcher = { Action = "Print" },
	handler = function(msg)
		local printInfo = msg.PrintInfo
		print(msg.Id)
	end,
	mount = function(name, matcher, handler)
		Handlers.before("_boot").add(name, matcher, handler, 2)
	end,
	--- extra route info
	manual = { APIS = [[
    Action: 'Print'

    ## Description

    Prints out the message id
]] },
	--- informs eventing and metrics system
	generateEvent = function(msg)
		return { type = "event", keys = { "Id" } }
	end,
}

return {}
