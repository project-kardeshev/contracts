local git = require("deps.lua-git")
local vfs = require("src.vfs.init")
local utils = require("src.utils")
local routes = require("src.routes.init")

GIT_DB = GIT_DB or git.mount(vfs.simple_vfs)

local wrapHandler = function(handler)
	return function(msg)
		local memBefore = collectgarbage("count")
		local startTime = os.clock()

		local status, result = xpcall(function()
			return handler(msg)
		end, debug.traceback)
		local endTime = os.clock()
		collectgarbage()

		local memAfter = collectgarbage("count")
		local runtime = endTime - startTime
		local user = msg.From

		-- emit event to metrics tracker
		
		-- emit event to pubsub tracker 
	end
end

for _, handlerConfig in ipairs(routes) do
	handlerConfig.mount(handlerConfig.name, handlerConfig.matcher, wrapHandler(handlerConfig.handler))
end
