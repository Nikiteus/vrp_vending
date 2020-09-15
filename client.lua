local Config = module("vrp_vending", "config")

local Vending = class("Vending", vRP.Extension)
Vending.tunnel = {}

local player = PlayerPedId()
local NearVendingMachine = false
local UsingMachine = false
local InVehicle = false
local ClosestMachine = nil

function Vending.tunnel:playAnim()
	UsingMachine = true
	local machine = ClosestMachine
	local machineInfo = Config.Machines[machine.Model]
	local position = GetOffsetFromEntityInWorldCoords(machine.Object, 0.0, -0.97, 0.05)
	
	TaskTurnPedToFaceEntity(player, machine.Object, -1)
	ReqAnimDict(Config.DispenseDict[1])
	RequestAmbientAudioBank("VENDING_MACHINE")
	HintAmbientAudioBank("VENDING_MACHINE", 0, -1)
	SetPedCurrentWeaponVisible(player, false, true, 1, 0)
	--ReqTheModel(machineInfo.prop[i])
	SetPedResetFlag(player, 322, true)
	if not IsEntityAtCoord(player, position, 0.1, 0.1, 0.1, false, true, 0) then
		TaskGoStraightToCoord(player, position, 1.0, 20000, GetEntityHeading(machine.Object), 0.1)
		while not IsEntityAtCoord(player, position, 0.1, 0.1, 0.1, false, true, 0) do
			Citizen.Wait(2000)
		end
	end
	TaskTurnPedToFaceEntity(player, machine.Object, -1)
	Citizen.Wait(1000)
	TaskPlayAnim(player, Config.DispenseDict[1], Config.DispenseDict[2], 8.0, 5.0, -1, true, 1, 0, 0, 0)
	Citizen.Wait(2500)
	local canModel = CreateObjectNoOffset(machineInfo.prop[i], position, true, false, false)
	SetEntityAsMissionEntity(canModel, true, true)
	SetEntityProofs(canModel, false, true, false, false, false, false, 0, false)
	AttachEntityToEntity(canModel, player, GetPedBoneIndex(player, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
	Citizen.Wait(1700)
	ReqAnimDict(Config.PocketAnims[1])
	TaskPlayAnim(player, Config.PocketAnims[1], Config.PocketAnims[2], 8.0, 5.0, -1, true, 1, 0, 0, 0)
	Citizen.Wait(1000)
	ClearPedTasks(player)
	ReleaseAmbientAudioBank()
	RemoveAnimDict(Config.DispenseDict[1])
	RemoveAnimDict(Config.PocketAnims[1])
	if DoesEntityExist(canModel) then
		DetachEntity(canModel, true, true)
		DeleteEntity(canModel)
	end
	SetModelAsNoLongerNeeded(machineInfo.prop[i])
end

vRP:registerExtension(Vending)

-- Main thread
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
        if NearVendingMachine and not UsingMachine and not InVehicle then
			local machine = ClosestMachine
			local machineInfo = Config.Machines[machine.Model]
			local machineNames = machineInfo.name
			
			DrawRect3Ds(machine.Coords.x, machine.Coords.y, machine.Coords.z, machine.Message.MaxLineLength, #machineNames)
			for i = 1, #machineNames do
				DrawText3Ds(machine.Coords.x, machine.Coords.y, machine.Coords.z, machine.Message.Content[i], i - 1)
				if IsControlJustReleased(1, Config.PurchaseButtons[i]) then
					vRP.EXT.Vending.remote.checkMoneyandInvent(machine.Model, i)
					UsingMachine = false
				end
			end
			
			BlockWeaponWheelThisFrame()
		end
	end
end)

-- Slow thread that updates in vehicle status
Citizen.CreateThread(function()
    while true do
		InVehicle = IsPedInAnyVehicle(player, 1)
        Citizen.Wait(1000)
    end
end)

-- Slow thread that updates closest machine
Citizen.CreateThread(function()
	Citizen.Wait(1500)
	while true do
		local playerLoc = GetEntityCoords(player)
		for machine, _  in pairs(Config.Machines) do
			local closest = GetClosestObjectOfType(playerLoc.x, playerLoc.y, playerLoc.z, 0.6, machine, false)
			if DoesEntityExist(closest) then
				ClosestMachine = {
					Object = closest,
					Coords = GetEntityCoords(closest),
					Model = machine,
					Message = GenerateMessage(machine)
				}
				NearVendingMachine = true
				break
			elseif NearVendingMachine and machine == ClosestMachine.Model then
				NearVendingMachine = false
				ClosestMachine = nil
			end
		end
		Citizen.Wait(700)
	end
end)

function GenerateMessage(machineModel)
	local message = {}
	message.Content = {}
	local machineInfo = Config.Machines[machineModel]
	local names = machineInfo.name
	local prices = machineInfo.price
	
	for i = 1, #names do
		message.Content[i] = "Нажмите ~g~"..i.."~w~ чтобы купить "..names[i].." ("..prices[i].."$)"
	end
	message.MaxLineLength = GetMaxLineLength(message.Content)
	
	return message
end

function GetMaxLineLength(text)
	local result = 0
	for i = 1, #text do
		result = math.max(result, string.len(text[i]))
	end
	return result
end

function DrawText3Ds(x, y, z, text, line)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x, _y + 0.025 * line)
	end
end

function DrawRect3Ds(x, y, z, length, linesCount)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	
	if onScreen then
		local factor = length / 380
		DrawRect(_x, _y + (0.0125 * linesCount), 0.015 + factor, 0.005 + (0.025 * linesCount), 41, 11, 41, 68)
	end
end

function ReqTheModel(model)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Citizen.Wait(0)
	end
end

function ReqAnimDict(animDict)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(0)
	end
end
