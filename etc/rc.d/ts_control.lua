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
		cfg.input = inputGate
		cfg.output = outputGate
	end
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
		local normalOutput = true
		while true do
			local info = reactor.getReactorInfo()
			local name, a, b, c = event.pull(0.1)
			if name == "reactor_new_status" then
				status = a
			end
			if status == "cold" then
				reactor.chargeReactor()
			end
			if status == "warming_up" then
				if info.temperature < 2000 then
					inFlux.setSignalLowFlow(100000) -- input RF to power, but not too much
					outFlux.setSignalLowFlow(0)
				else -- reactor can be activated
					reactor.activateReactor()
				end
			end
			if status == "running" then
				inFlux.setSignalLowFlow(20000)
				if normalOutput then
					outFlux.setSignalLowFlow(info.generationRate)
				end
				if name == "saturation_alert" then
					if a == "high" then
						outFlux.setSignalLowFlow(200000)
						normalOutput = false
					elseif a == "normal" then
						outFlux.setSignalLowFlow(50000)
						normalOutput = true
					elseif a == "low" then
						outFlux.setSignalLowFlow(0)
						normalOutput = false
					end
				end
				if name == "field_alert" then
					if a == "critical" then
						inFlux.setSignalLowFlow(info.fieldDrainRate*5)
					else
						inFlux.setSignalLowFlow(info.fieldDrainRate)
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
