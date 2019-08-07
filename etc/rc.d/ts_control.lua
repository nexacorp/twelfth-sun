local rc = require("rc")
local thread = require("thread")
local component = require("component")
local event = require("event")
local ser = require("serialization")

local reactor = component.draconic_reactor

local outFlux = nil
local inFlux = nil

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

local function configAutodetect()
	print("Twelfth-Sun: Flux Gate Detection")
	print("\tYour flux gate aren't configured, let's configure them!")
	print("\tDon't worry your flux gate will be controlled before reactor is on")
	print("\tPlease do following steps:")
	print("\t1. Shutdown my reactor if running")
	print("\t2. Set input flux gate (low) flux to 100")
	print("\t3. Set output flux gate (low) flux to 200")
	print("\t4. Press any key WHEN ALL STEPS COMPLETE")
	event.pull("key_down")
	local cfg = {}
	local inputGate = nil
	local outputGate = nil
	for addr in component.list("flux_gate") do
		local proxy = component.proxy(addr)
		if proxy.getSignalLowFlow() == 100 then
			inputGate = addr
		end
		if proxy.getSignalLowFlow() == 200 then
			outputGate = addr
		end
	end
	if not inputGate or not outputGate then
		print("Input/Output gate(s) not configured!")
		cfg = configAutodetect()
	else
		print("Sucesfully configured Twelfth Sun!")
	end
	cfg.input = inputGate
	cfg.output = outputGate
	component.proxy(inputGate).setSignalLowFlow(0)
	component.proxy(outputGate).setSignalLowFlow(0)
	return cfg
end

function start(cfg)
	if not rc.loaded.ts_core or not rc.loaded.ts_core.isRunning() then
		io.stderr:write("\"Twelfth Sun: Control\" requires \"Twelfth Sun: Core\" running!\n")
		return
	end
	if th ~= nil then
		io.stderr:write("\"Twelfth Sun: Control\" is already running!\n")
		return
	end
	if cfg then
		if component.get(cfg.input) == nil or component.get(cfg.output) == nil then
			cfg = nil
		end
	end
	if not cfg then
		cfg = configAutodetect()
		local stream = io.open("/etc/rc.cfg", "a")
		stream:write("\nts_control = " .. ser.serialize(cfg))
		stream:close()
	end
	outFlux = component.proxy(cfg.output)
	inFlux = component.proxy(cfg.input)
	th = thread.create(function()
		local status = reactor.getReactorInfo().status
		while true do
			local name, a, b, c = event.pull()
			if name == "reactor_new_status" then
				status = a
			end
			if status == "cold" then
				
			end
			if status == "running" then
				if name == "saturation_alert" then
					if a == "critical" then
						
					end
				end
			end
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
