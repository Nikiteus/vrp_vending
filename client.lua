local Config = module("vrp_vending", "config")

local Vending = class("Vending", vRP.Extension)
Vending.tunnel = {}

local animPlaying = false
local usingMachine = false
local VendingObject = nil
local machineModel = nil

function Vending.tunnel:playAnim()
	usingMachine = true
	local machine = machineModel
	local machineInfo = Config.Machines[machineModel]
	local ped = PlayerPedId()
	local position = GetOffsetFromEntityInWorldCoords(VendingObject, 0.0, -0.97, 0.05)
	TaskTurnPedToFaceEntity(ped, VendingObject, -1)
	ReqAnimDict(Config.DispenseDict[1])
	RequestAmbientAudioBank("VENDING_MACHINE")
	HintAmbientAudioBank("VENDING_MACHINE", 0, -1)
	SetPedCurrentWeaponVisible(ped, false, true, 1, 0)
	--ReqTheModel(machineInfo.prop[i])
	SetPedResetFlag(ped, 322, true)
	if not IsEntityAtCoord(ped, position, 0.1, 0.1, 0.1, false, true, 0) then
		TaskGoStraightToCoord(ped, position, 1.0, 20000, GetEntityHeading(VendingObject), 0.1)
		while not IsEntityAtCoord(ped, position, 0.1, 0.1, 0.1, false, true, 0) do
			Citizen.Wait(2000)
		end
	end
	TaskTurnPedToFaceEntity(ped, VendingObject, -1)
	Citizen.Wait(1000)
	TaskPlayAnim(ped, Config.DispenseDict[1], Config.DispenseDict[2], 8.0, 5.0, -1, true, 1, 0, 0, 0)
	Citizen.Wait(2500)
	local canModel = CreateObjectNoOffset(machineInfo.prop[i], position, true, false, false)
	SetEntityAsMissionEntity(canModel, true, true)
	SetEntityProofs(canModel, false, true, false, false, false, false, 0, false)
	AttachEntityToEntity(canModel, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
	Citizen.Wait(1700)
	ReqAnimDict(Config.PocketAnims[1])
	TaskPlayAnim(ped, Config.PocketAnims[1], Config.PocketAnims[2], 8.0, 5.0, -1, true, 1, 0, 0, 0)
	Citizen.Wait(1000)
	ClearPedTasks(ped)
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

Citizen.CreateThread(function()
    local waitTime = 500
	while true do
		Citizen.Wait(waitTime)
        if nearVendingMachine() and not usingMachine and not IsPedInAnyVehicle(PlayerPedId(), 1) then
			waitTime = 1
			local message = {}
			local machine = machineModel
			local machineInfo = Config.Machines[machineModel]
			local machineNames = machineInfo.name
			local machineCoords = GetEntityCoords(VendingObject)
			
			for i = 1, #machineNames do
				message[i] = "Нажмите ~g~"..i.."~w~ чтобы купить "..machineNames[i].." ("..machineInfo.price[i].."$)"
				DrawText3Ds(machineCoords.x, machineCoords.y, machineCoords.z, message[i], i - 1)
				
				if IsControlJustReleased(1, Config.PurchaseButtons[i]) then
					vRP.EXT.Vending.remote.checkMoneyandInvent(machine, i)
					usingMachine = false
				end
			end
			
			DrawRect3Ds(machineCoords.x, machineCoords.y, machineCoords.z, GetMaxLineLength(message), #machineNames)
			BlockWeaponWheelThisFrame()
        else
            waitTime = 500
		end
	end
end)

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

function nearVendingMachine()
	local player = PlayerPedId()
	local playerLoc = GetEntityCoords(player, 0)

	for machine, _  in pairs(Config.Machines) do
		VendingObject = GetClosestObjectOfType(playerLoc.x, playerLoc.y, playerLoc.z, 0.6, machine, false)
		if DoesEntityExist(VendingObject) then
			machineModel = machine
            return true
		end
	end
	return false
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

function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    PushScaleformMovieMethodParameterButtonName(ControlButton)
end

function setupScaleform(scaleform, buttonsMessages)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

	local buttonCount = 0
	for machine, buttons in pairs(buttonsMessages) do
		PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(buttonCount)
		Button(GetControlInstructionalButton(2, buttons, true))
		ButtonMessage(machine)
		PopScaleformMovieFunctionVoid()
		buttonCount = buttonCount + 1
	end

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(70)
    PopScaleformMovieFunctionVoid()

    return scaleform
end
