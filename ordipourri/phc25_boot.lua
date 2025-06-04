-- Script for MAME that launches the Sanyo PHC-25 emulator, waits for boot, loads
-- a tape in fast mode.
--
-- Copyright 2025 Sylvain Glaize
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
-- documentation files (the "Software"), to deal in the Software without restriction, including without
-- limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
-- Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
-- TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
-- CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- Launch with:
-- mame phc25 -autoboot_delay 0 -autoboot_script phc25_boot.lua -debug -debugger none -cass phc25.wav

local machine = manager.machine
local machine_debugger = machine.debugger
local memory_manager = machine.memory
local log = machine_debugger.consolelog
local log_count = 1
local video = machine.video

-- First verity if the debugger was launched with the emulator
if not machine_debugger then
	print("No debugger found.")
	return
end

-- Pause the emulator while setup'ing the system
emu.pause()

-- Get control objects from the emulator
local cpu = manager.machine.devices[":maincpu"]
local debug = cpu.debug

-- Sends key strokes to the emulated machine
function send_keys(str)
	local keyboard = machine.natkeyboard
	keyboard:post(str)
end

-- Prepare the cassette to be read
function play_cassette()
	local k7
	k7 = manager.machine.cassettes[':cassette']
	k7:forward()
	k7:seek(0, "set")
	k7:play()
end

-- The steps
local boot = {
	name = "BOOT",
	next_break = 0x0C44,
	action = function()
        video.throttled = false
	end
}

local screen_input = {
    name = "SCREEN INPUT",
	condition = "Stopped at temporary breakpoint C44 on CPU ':maincpu'",
	next_break = 0x065A,
    action = function()
		send_keys('1')
    end
}

local basic_ready = {
	name = "CLOAD",
	condition = "Stopped at temporary breakpoint 65A on CPU ':maincpu'",
	next_break = 0x459b,
	action = function()
		send_keys('CLOAD\n')
		play_cassette()
	end
}

local end_load = {
    name = "END LOAD",
	condition = "Stopped at temporary breakpoint 459B on CPU ':maincpu'",
	next_break = 0x065A,
    action = function()
    end
}
local final_step = {
	name = "RUN",
	condition = "Stopped at temporary breakpoint 65A on CPU ':maincpu'",
	action = function()
		send_keys('RUN\n')
		video.throttled = true
	end
}

local steps = {
	boot,
	screen_input,
	basic_ready,
	end_load,
	final_step
}

-- The Step Machine
local current_step = 0
local next_step

function do_action()
	local next_break = next_step.next_break
	if next_break then
		debug:go(next_break)
	end

	next_step.action()
end

function go_to_next_step()
	current_step = current_step + 1

	if current_step <= #steps then
		next_step = steps[current_step]
		print("Running step: " .. next_step.name)
	else
		next_step = nil
		print("No more step")
	end

end

-- Bootstraping
go_to_next_step()

-- Running the Step Machine
emu.register_periodic(function()
	local condition_found = false

	if log_count <= #log then
		for i = log_count, #log do
			local msg = log[i]

			print("DEBUG: " .. msg)
			if next_step and next_step.condition and msg:sub(1, #next_step.condition) == next_step.condition then
				condition_found = true
			end
		end

		log_count = #log + 1
	end

	if condition_found or (next_step and not next_step.condition) then
		emu.pause()
		do_action()
		emu.unpause()
		go_to_next_step()
	end
end)
