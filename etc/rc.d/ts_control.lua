local rc = require("rc")
local thread = require("thread")
local component = require("component")
local event = require("event")
local reactor = component.draconic_reactor

local outputRedstone = nil -- redstone block for energy output (connected to flux gate)
local inputRedstone = nil -- redstone block energy input (connected to energy injector flux gate)

local th = nil

local function outputRed(signal)
	for i=0,5 do
		outputRedstone.setOutput(i, signal)
	end
end

local function inputRed(signal)
	for i=0,5 do
		inputRedstone.setOutput(i, signal)
	end
end

function start()
	if not rc.loaded.ts_core or not rc.loaded.ts_core.isRunning() then
		io.stderr:write("\"Twelfth Sun: Control\" requires \"Twelfth Sun: Core\" running!\n")
		return
	end
	if th ~= nil then
		io.stderr:write("\"Twelfth Sun: Control\" is already running!\n")
		return
	end
	th = thread.create(function()
		while true do
			local name, a, b, c = event.pull()
			if name == "saturation_alert" then
				if a == "critical" then
					
				end
			end
		end
	end):detach()
end

function stop()
	th:kill()
end

function isRunning()
	return th ~= nil
end

function suspend()
	th:suspend()
end

function resume()
	th:resume()
end
