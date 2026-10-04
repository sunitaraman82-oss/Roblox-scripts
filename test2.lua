repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character
local hrp

local running = false
local riotRunning = false
local returnHomeEnabled = false

local orientationOffsetEnabled = false
local orientationOffsetPitch = 0
local orientationOffsetYaw = 0
local orientationOffsetRoll = 0
local orientationOffsetConnection = nil

local velocityPulseEnabled = false
local velocityPulseConnection = nil
local offsetDesyncEnabled = false
local burstDesyncEnabled = false
local anchorStutterEnabled = false
local desyncConnection = nil
local desyncOffsetAmount = 40
local desyncBurstPower = 1500
local desyncPulseDelay = 0.03
local desyncStutterDelay = 0.08
local desyncPulseClock = 0
local desyncBurstClock = 0
local desyncStutterClock = 0
local desyncStutterAnchored = false
local desyncOriginalAnchored = nil
local desyncPreset = "Strong"
local customJumpEnabled = false
local jumpPowerValue = 50
local originalJumpPower = nil
local originalJumpHeight = nil
local freezeCharacterEnabled = false
local previousRootAnchored = nil
local customGravityEnabled = false
local originalGravity = workspace.Gravity
local gravityValue = workspace.Gravity

local currentDistance = 500
local teleportMode = "VOID_SPAM"
local voidSpamMode = "Random Far"
local voidProfile = "Manual"
local teleportInterval = 0.035
local jitterStrength = 14

local distPlusX = 200000
local distMinusX = 200000
local distPlusY = 200000
local distMinusY = 200000
local distPlusZ = 200000
local distMinusZ = 200000

local spinSpeed = 720
local riotXJitter = 30
local riotYJitter = 8
local riotDistance = 300

local homePosition = nil
local homeCFrame = nil
local homeReturnDelay = 3
local homeReturnDistance = 10

local teleportConnection
local riotConnection
local homeConnection

local originalCFrame
local riotOriginalCFrame
local voidHideLastCFrame = nil
local lastTeleport = 0
local lastVelocityClear = 0

local voidX = math.random(-1e8, 1e8)
local voidZ = math.random(-1e8, 1e8)
local voidYOffset = 0
local voidYDir = 1
local voidDirX = math.random() * 2 - 1
local voidDirZ = math.random() * 2 - 1
local voidElapsed = 0
local voidYBase = 1e10 + math.random(-5e9, 5e9)
local voidDriftSpeed = 9e6
local voidYDriftSpeed = 4e6
local voidYDriftRange = 2e9
local voidChaos = 0.98

local function resetVoidPattern()
	voidX = math.random(-1e8, 1e8)
	voidZ = math.random(-1e8, 1e8)
	voidYOffset = 0
	voidYDir = 1
	voidDirX = math.random() * 2 - 1
	voidDirZ = math.random() * 2 - 1
	voidElapsed = 0
	voidYBase = 1e10 + math.random(-5e9, 5e9)
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Project Rose",
			Text = tostring(text),
			Duration = 5,
		})
	end)
end

local function disconnect(conn)
	if conn then
		conn:Disconnect()
	end

	return nil
end

local function updateChar(newCharacter)
	character = newCharacter
	hrp = nil
	originalJumpPower = nil
	originalJumpHeight = nil
	previousRootAnchored = nil
	desyncOriginalAnchored = nil
	desyncStutterAnchored = false

	if character then
		hrp = character:WaitForChild("HumanoidRootPart", 5)
	end
end

if player.Character then
	updateChar(player.Character)
end

player.CharacterAdded:Connect(updateChar)
player.CharacterRemoving:Connect(function()
	updateChar(nil)
end)

local SAFE_FLOOR = 2
local SAFE_MAX_RISE = 800

local function safeTeleport(pos)
	if not hrp then
		return
	end

	local x = pos.X
	local y = math.clamp(pos.Y, SAFE_FLOOR, hrp.Position.Y + SAFE_MAX_RISE)
	local z = pos.Z

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and { character } or {}

	local hit = workspace:Raycast(Vector3.new(x, y + 500, z), Vector3.new(0, -1000, 0), params)
	if hit then
		y = math.max(hit.Position.Y + 3, SAFE_FLOOR)
	end

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(x, y, z)
end

local function rawVoidTeleport(pos)
	if not hrp then
		return
	end

	if tick() - lastVelocityClear > 0.2 then
		lastVelocityClear = tick()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	hrp.CFrame = CFrame.new(pos)
end

local function getVoidHidePosition()
	if not hrp then
		return nil
	end

	return Vector3.new(
		hrp.Position.X + 2e15,
		999999,
		hrp.Position.Z + 2e15
	)
end

local function getDirectionalLimitOffset()
	local raw = Vector3.new(
		math.random(-distMinusX, distPlusX),
		math.random(-distMinusY, distPlusY),
		math.random(-distMinusZ, distPlusZ)
	)

	if raw.Magnitude <= 0 then
		return Vector3.zero
	end

	return raw.Unit * math.min(raw.Magnitude, currentDistance)
end

local function computeVoidDriftDir(t)
	local nx = 0
	local nz = 0
	local amplitude = 1
	local frequency = 0.0001

	for _ = 1, 4 do
		nx += math.noise(t * frequency, 0) * amplitude
		nz += math.noise(0, t * frequency) * amplitude
		frequency *= 2.37
		amplitude *= 0.5
	end

	nx += math.sin(t * 0.00213) * math.cos(t * 0.00344) * 0.2
	nz += math.cos(t * 0.00131) * math.sin(t * 0.00579) * 0.2

	local len = math.sqrt(nx * nx + nz * nz)
	if len < 0.001 then
		return math.cos(t * 0.1), math.sin(t * 0.1)
	end

	return nx / len, nz / len
end

local function getFarVoidPosition(dt)
	voidElapsed += dt

	if voidSpamMode == "Still Point" then
		return Vector3.new(voidX, voidYBase + voidYOffset, voidZ)
	end

	if voidSpamMode == "Slow Drift" then
		local dx, dz = computeVoidDriftDir(voidElapsed)

		voidDirX += (dx - voidDirX) * voidChaos * dt * 10
		voidDirZ += (dz - voidDirZ) * voidChaos * dt * 10

		voidX += voidDirX * voidDriftSpeed * dt
		voidZ += voidDirZ * voidDriftSpeed * dt

		voidYOffset += voidYDir * voidYDriftSpeed * dt
		if math.abs(voidYOffset) >= voidYDriftRange then
			voidYDir = -voidYDir
		end

		return Vector3.new(voidX, voidYBase + voidYOffset, voidZ)
	end

	if voidSpamMode == "Circle" then
		local r = math.max(currentDistance * 1000, 1e9) * (1 + math.sin(voidElapsed))
		return Vector3.new(
			voidX + math.cos(voidElapsed * 3) * r,
			voidYBase + voidYOffset,
			voidZ + math.sin(voidElapsed * 3) * r
		)
	end

	if voidSpamMode == "Figure Eight" then
		local r = math.max(currentDistance * 2000, 2e9)
		return Vector3.new(
			voidX + math.sin(voidElapsed * 2) * r,
			voidYBase + math.sin(voidElapsed * 4) * r * 0.1,
			voidZ + math.sin(voidElapsed * 3) * r
		)
	end

	if voidSpamMode == "Wide Sweep" then
		local t = voidElapsed * 15
		local r = math.max(currentDistance * 10000, 1e10)
		return Vector3.new(
			voidX + math.sin(t) * r,
			voidYBase + math.cos(t * 1.5) * r * 0.1,
			voidZ + math.cos(t) * r
		)
	end

	if voidSpamMode == "Fast Bounce" then
		local t = voidElapsed * 50
		local r = math.max(currentDistance * 10000, 1e10) * math.sin(t)
		return Vector3.new(
			voidX + r,
			voidYBase + math.cos(t) * 1e10,
			voidZ + r
		)
	end

	if voidSpamMode == "Blink" then
		if tick() % 0.1 < 0.05 then
			return Vector3.new(voidX * 2, voidYBase + 1e11, voidZ * 2)
		end

		return Vector3.new(voidX, voidYBase, voidZ)
	end

	if voidSpamMode == "Grid Hop" then
		local cell = math.max(currentDistance * 5000, 5e8)
		local step = math.floor(voidElapsed * 8)
		local gx = (step % 5) - 2
		local gz = (math.floor(step / 5) % 5) - 2
		local gy = (step % 2 == 0) and 0 or cell * 0.18

		return Vector3.new(voidX + gx * cell, voidYBase + gy, voidZ + gz * cell)
	end

	if voidSpamMode == "Height Wave" then
		local t = voidElapsed * 6
		local r = math.max(currentDistance * 3000, 2e9)

		return Vector3.new(
			voidX + math.cos(t * 0.4) * r,
			voidYBase + math.sin(t) * r * 0.35,
			voidZ + math.sin(t * 0.4) * r
		)
	end

	if voidSpamMode == "Square Loop" then
		local r = math.max(currentDistance * 4000, 3e9)
		local t = (voidElapsed * 1.8) % 4
		local side = math.floor(t)
		local a = t - side
		local x
		local z

		if side == 0 then
			x = -r + a * 2 * r
			z = -r
		elseif side == 1 then
			x = r
			z = -r + a * 2 * r
		elseif side == 2 then
			x = r - a * 2 * r
			z = r
		else
			x = -r
			z = r - a * 2 * r
		end

		return Vector3.new(voidX + x, voidYBase + math.sin(voidElapsed * 8) * r * 0.05, voidZ + z)
	end

	if voidSpamMode == "Cross Sweep" then
		local r = math.max(currentDistance * 6000, 4e9)
		local t = voidElapsed * 4
		local axis = math.floor(t) % 4
		local a = math.sin(t * math.pi) * r

		if axis == 0 then
			return Vector3.new(voidX + a, voidYBase, voidZ)
		elseif axis == 1 then
			return Vector3.new(voidX, voidYBase + math.sin(t) * r * 0.08, voidZ + a)
		elseif axis == 2 then
			return Vector3.new(voidX - a, voidYBase, voidZ)
		end

		return Vector3.new(voidX, voidYBase - math.sin(t) * r * 0.08, voidZ - a)
	end

	if voidSpamMode == "Stacked Steps" then
		local cell = math.max(currentDistance * 3500, 2e9)
		local step = math.floor(voidElapsed * 7)
		local x = ((step % 7) - 3) * cell
		local z = ((math.floor(step / 7) % 7) - 3) * cell
		local y = (step % 5) * cell * 0.12

		return Vector3.new(voidX + x, voidYBase + y, voidZ + z)
	end

	if voidSpamMode == "Noise Cloud" then
		local r = math.max(currentDistance * 5000, 4e9)
		local t = voidElapsed * 1.5

		return Vector3.new(
			voidX + math.noise(t, 0, 0) * r,
			voidYBase + math.noise(0, t, 0) * r * 0.25,
			voidZ + math.noise(0, 0, t) * r
		)
	end

	local r = math.max(currentDistance * 10000, 1e11)
	local sign = math.random() > 0.5 and 1 or -1
	local jitter = Vector3.new(
		math.random(-1e9, 1e9),
		math.random(-1e8, 1e8),
		math.random(-1e9, 1e9)
	)

	return Vector3.new(voidX + r * sign, voidYBase + jitter.Y, voidZ + r * sign) + jitter
end

local function performVoidStep(dt, phase)
	if not hrp then
		return false
	end

	dt = dt or teleportInterval
	phase = phase or (voidElapsed + dt * 28)

	if teleportMode == "VOID_HIDE" then
		if not voidHideLastCFrame then
			voidHideLastCFrame = hrp.CFrame
		end

		local hidePos = getVoidHidePosition()
		if hidePos then
			rawVoidTeleport(hidePos)
		end

		return true
	end

	if teleportMode == "VOID_SPAM" then
		rawVoidTeleport(getFarVoidPosition(dt))
		return true
	end

	local offset

	if teleportMode == "FORWARD" then
		offset = hrp.CFrame.LookVector * currentDistance
	elseif teleportMode == "CAMERA" and workspace.CurrentCamera then
		offset = workspace.CurrentCamera.CFrame.LookVector * currentDistance
	elseif teleportMode == "DIRECTIONAL" then
		offset = getDirectionalLimitOffset()
	else
		local r1 = currentDistance * (0.60 + 0.40 * math.sin(phase * 2.3))
		local r2 = currentDistance * (0.25 + 0.15 * math.sin(phase * 5.7))
		local r3 = currentDistance * (0.10 + 0.10 * math.sin(phase * 11.3))

		local oX = math.cos(phase * 7.1) * r1 + math.cos(phase * 13.4) * r2 + math.cos(phase * 21.9) * r3
		local oZ = math.sin(phase * 7.1) * r1 + math.sin(phase * 13.4) * r2 + math.sin(phase * 21.9) * r3
		local oY = math.sin(phase * 9) * r1 * 0.4 + math.sin(phase * 17) * r2 * 0.3

		local jX = math.noise(phase * 6, 0, 0) * jitterStrength * 3 + (math.random() - 0.5) * jitterStrength * 2.5
		local jY = math.noise(0, phase * 6, 0) * jitterStrength * 1.5 + (math.random() - 0.5) * jitterStrength * 1.2
		local jZ = math.noise(0, 0, phase * 6) * jitterStrength * 3 + (math.random() - 0.5) * jitterStrength * 2.5

		offset = Vector3.new(oX + jX, oY + jY, oZ + jZ)
	end

	safeTeleport(hrp.Position + offset)
	return true
end

local function startTeleport()
	teleportConnection = disconnect(teleportConnection)

	if hrp then
		originalCFrame = hrp.CFrame
	end

	local phase = 0

	teleportConnection = RunService.Heartbeat:Connect(function(dt)
		if not running or not hrp then
			return
		end

		if tick() - lastTeleport < teleportInterval then
			return
		end

		lastTeleport = tick()
		phase += dt * 28

		performVoidStep(dt, phase)
	end)
end

local function stopTeleport()
	teleportConnection = disconnect(teleportConnection)

	if teleportMode == "VOID_HIDE" and hrp and voidHideLastCFrame then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = voidHideLastCFrame
		voidHideLastCFrame = nil
	elseif hrp and originalCFrame then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = originalCFrame
	end

	originalCFrame = nil
end

local function startRiot()
	riotConnection = disconnect(riotConnection)

	if hrp then
		riotOriginalCFrame = hrp.CFrame
	end

	local t0 = tick()
	local seed = math.random(1000, 9999)

	riotConnection = RunService.Heartbeat:Connect(function(dt)
		if not riotRunning or not hrp then
			return
		end

		local t = tick() - t0
		local spread = riotDistance / 300

		local yaw = math.rad(spinSpeed * dt)
		local pitch = math.rad(spinSpeed * 0.37 * dt * math.sin(t * 3.1))
		local roll = math.rad(spinSpeed * 0.19 * dt * math.cos(t * 5.7 + seed))

		local spinCF = hrp.CFrame * CFrame.Angles(pitch, yaw, roll)

		local jX = (math.random() - 0.5) * riotXJitter * spread * 2 + math.noise(t * 9, seed, 0) * riotXJitter * spread
		local jY = (math.random() - 0.5) * riotYJitter * spread + math.noise(0, t * 9, seed) * riotYJitter * spread * 0.3
		local jZ = (math.random() - 0.5) * riotXJitter * spread * 2 + math.noise(0, 0, t * 9 + seed) * riotXJitter * spread

		local newY = math.max(spinCF.Position.Y + jY, SAFE_FLOOR)
		hrp.CFrame = spinCF + Vector3.new(jX, newY - spinCF.Position.Y, jZ)
	end)
end

local function stopRiot()
	riotConnection = disconnect(riotConnection)

	if hrp and riotOriginalCFrame then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = riotOriginalCFrame
	end

	riotOriginalCFrame = nil
end

local function startVelocityPulse()
	velocityPulseConnection = disconnect(velocityPulseConnection)

	local pulseClock = 0

	velocityPulseConnection = RunService.Heartbeat:Connect(function(dt)
		if not velocityPulseEnabled or not hrp then
			return
		end

		pulseClock += dt * math.max(spinSpeed / 180, 0.1)

		local horizontal = math.clamp(riotDistance * 0.35, 0, 220)
		local lift = math.clamp(riotYJitter * 4, 0, 120)
		local vx = math.cos(pulseClock) * horizontal
		local vz = math.sin(pulseClock) * horizontal

		hrp.AssemblyLinearVelocity = Vector3.new(vx, lift, vz)
		hrp.AssemblyAngularVelocity = Vector3.new(0, math.rad(math.clamp(spinSpeed, 0, 1440)), 0)
	end)
end

local function stopVelocityPulse()
	velocityPulseConnection = disconnect(velocityPulseConnection)

	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

local function anyDesyncEnabled()
	return offsetDesyncEnabled or burstDesyncEnabled or anchorStutterEnabled
end

local function restoreDesyncStutter()
	if hrp and desyncOriginalAnchored ~= nil then
		hrp.Anchored = desyncOriginalAnchored
	end

	desyncOriginalAnchored = nil
	desyncStutterAnchored = false
	desyncStutterClock = 0
end

local function clearDesyncVelocity()
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

local function stopDesyncSystems()
	desyncConnection = disconnect(desyncConnection)
	desyncPulseClock = 0
	desyncBurstClock = 0
	clearDesyncVelocity()
	restoreDesyncStutter()
end

local function startDesyncSystems()
	if desyncConnection then
		return
	end

	desyncConnection = RunService.Heartbeat:Connect(function(dt)
		if not anyDesyncEnabled() then
			stopDesyncSystems()
			return
		end

		if not hrp then
			return
		end

		if offsetDesyncEnabled then
			desyncPulseClock += dt

			if desyncPulseClock >= desyncPulseDelay then
				desyncPulseClock = 0

				local angle = tick() * 3
				local offset = Vector3.new(
					math.sin(angle) * desyncOffsetAmount,
					math.sin(angle * 1.7) * desyncOffsetAmount * 0.35,
					math.cos(angle) * desyncOffsetAmount
				)
				local pulse = offset * 40
				local velocity = hrp.AssemblyLinearVelocity

				hrp.AssemblyLinearVelocity = Vector3.new(pulse.X, velocity.Y + pulse.Y, pulse.Z)
				task.delay(0.05, function()
					if hrp and hrp.Parent and offsetDesyncEnabled then
						clearDesyncVelocity()
					end
				end)
			end
		end

		if burstDesyncEnabled then
			desyncBurstClock += dt

			if desyncBurstClock >= 0.025 then
				desyncBurstClock = 0

				local direction = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
				if direction.Magnitude < 0.01 then
					direction = Vector3.new(1, 0, 0)
				else
					direction = direction.Unit
				end

				local velocity = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(
					direction.X * desyncBurstPower,
					velocity.Y + (math.random() - 0.5) * desyncBurstPower * 0.2,
					direction.Z * desyncBurstPower
				)

				task.delay(0.05, function()
					if hrp and hrp.Parent and burstDesyncEnabled then
						clearDesyncVelocity()
					end
				end)
			end
		end

		if anchorStutterEnabled and not freezeCharacterEnabled then
			if desyncOriginalAnchored == nil then
				desyncOriginalAnchored = hrp.Anchored
			end

			desyncStutterClock += dt
			if desyncStutterClock >= desyncStutterDelay then
				desyncStutterClock = 0
				desyncStutterAnchored = not desyncStutterAnchored
				hrp.Anchored = desyncStutterAnchored
			end
		elseif desyncOriginalAnchored ~= nil then
			restoreDesyncStutter()
		end
	end)
end

local function refreshDesyncSystems()
	if not anchorStutterEnabled and desyncOriginalAnchored ~= nil then
		restoreDesyncStutter()
	end

	if anyDesyncEnabled() then
		startDesyncSystems()
	else
		stopDesyncSystems()
	end
end

local function getHumanoid()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function captureCharacterDefaults(humanoid)
	if not humanoid then
		return
	end

	if originalJumpPower == nil then
		originalJumpPower = humanoid.JumpPower
	end

	if originalJumpHeight == nil then
		originalJumpHeight = humanoid.JumpHeight
	end
end

local function applyPlayerSettings()
	local humanoid = getHumanoid()

	if humanoid then
		captureCharacterDefaults(humanoid)

		if customJumpEnabled then
			pcall(function()
				humanoid.UseJumpPower = true
			end)

			humanoid.JumpPower = jumpPowerValue
		end
	end
end

local function restorePlayerSettings()
	local humanoid = getHumanoid()

	if humanoid then
		if originalJumpPower then
			humanoid.JumpPower = originalJumpPower
		end

		if originalJumpHeight then
			humanoid.JumpHeight = originalJumpHeight
		end
	end
end

local function setCharacterFrozen(value)
	freezeCharacterEnabled = value

	if not hrp then
		if not value then
			previousRootAnchored = nil
		end

		return
	end

	if value then
		if previousRootAnchored == nil then
			previousRootAnchored = hrp.Anchored
		end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Anchored = true
	else
		hrp.Anchored = previousRootAnchored == true
		previousRootAnchored = nil
	end
end

local function setCustomGravity(value)
	customGravityEnabled = value

	if value then
		workspace.Gravity = gravityValue
	else
		workspace.Gravity = originalGravity
	end
end

local function saveHome()
	if hrp then
		homeCFrame = hrp.CFrame
		homePosition = hrp.Position
	end
end

local function teleportHome()
	if hrp and homeCFrame then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = homeCFrame
	end
end

local function startReturnHome()
	homeConnection = disconnect(homeConnection)

	if not homeCFrame and hrp then
		saveHome()
	end

	local lastReturn = 0
	local lastHomeCheck = 0

	homeConnection = RunService.Heartbeat:Connect(function()
		if tick() - lastHomeCheck < 0.1 then
			return
		end

		lastHomeCheck = tick()

		if not returnHomeEnabled or not hrp or not homePosition or not homeCFrame then
			return
		end

		if (hrp.Position - homePosition).Magnitude > homeReturnDistance
			and tick() - lastReturn >= homeReturnDelay then
			lastReturn = tick()
			teleportHome()
		end
	end)
end

local function 