--!strict

--[[
	Runs a callback with arguments when the referenced instance is destroyed.
	Returns a function to disconnect from this event later.

	This is more comprehensive than `instance.Destroyed` as it covers instances
	not explicitly destroyed with `:Destroy()`.

	NOTE: use of this function should be a last resort - if you have another way
	of more concretely tracking the lifetime of the instance, please use that
	instead. This function is intended for use with user-provided instances for
	which the lifetime is not known.
]]

local Package = script.Parent.Parent
local PubTypes = require(Package.PubTypes)
local logWarn = require(Package.Logging.logWarn)
local isAccessible = require(Package.Instances.isAccessible)

-- FIXME: whenever they fix generic type packs in Roblox LSP:
--- onDestroy<A...>(instanceRef: Types.SemiWeakRef, callback: (A...) -> (), ...: A...)

local function onDestroy(instanceRef: PubTypes.SemiWeakRef, callback: (...any) -> (), ...: any): () -> ()
	if instanceRef.instance == nil then
		-- if we get a nil reference initially, then there's probably an issue
		-- somewhere else - usually the instance isn't destroyed until later!
		logWarn("onDestroyNilRef")
		callback(...)
		return function() end
	end

	local disconnectConn: RBXScriptConnection
	local disconnected = false

	local function disconnect()
		if not disconnected then
			disconnected = true
			disconnectConn:Disconnect()
		end
	end

	local args = table.pack(...)
	disconnectConn = (instanceRef.instance :: Instance).Destroying:Connect(function()
		callback(table.unpack(args, 1, args.n))
		disconnect()
		return
	end)

	return disconnect
end

return onDestroy
