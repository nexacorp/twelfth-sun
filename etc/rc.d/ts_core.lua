local thread = require("thread")
local component = require("component")
local event = require("event")
local reactor = component.draconic_reactor
local th = nil

function start()
	if th ~= nil then
		io.stderr:write("\"Twelfth Sun: Core\" is already running!\n")
		return
	end
	th = thread.create(function()
		local status = "unknown"
		local criticalSaturation = false
		while true do
			local info = reactor.getReactorInfo()
			if info.status ~= status then
				status = info.status
				event.push("reactor_new_status", info.status)
			end
			if info.energySaturation >= 200000000 and not criticalSaturation then
				event.push("saturation_alert", "critical")
				criticalSaturation = true
			end
			if info.energySaturation < 200000000 and criticalSaturation then
				event.push("saturation_alert", "normal")
				criticalSaturation = false
			end
			
			os.sleep(0.1)
		end
	end):detach()
end

function stop()
	th:kill()
	th = nil
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
