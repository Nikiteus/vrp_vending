local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

local Config = module("xnVending", "config")

TryGiveInventoryItem = function(source, cb, machine, entry, confirm)
	local user_id = vRP.getUserId({source})
	local item = Config.Machines[machine]
	local itemid = item.item[entry]
	local price = item.price[entry]
	-- Make sure we can afford the item
	if vRP.getMoney({user_id}) >= price then
		local weight = vRP.getItemWeight({itemid})
		local remaining = vRP.getInventoryMaxWeight({user_id}) - vRP.getInventoryWeight({user_id})
		-- Make sure we can carry the item
		if weight <= remaining then
			-- Give and pay
			if confirm then
				vRP.giveInventoryItem({user_id, itemid, 1, true})
				vRP.tryPayment({user_id, price})
			end
			cb(true)
		else
			cb("inventory")
		end
	else
		cb("cash")
	end
end

RegisterServerEvent('xnVending:triggerServerCallback')
AddEventHandler('xnVending:triggerServerCallback', function(name, requestId, ...)
	local playerId = source
	if name == "esx_vending:checkMoneyandInvent" then
		TryGiveInventoryItem(playerId, function(...)
			TriggerClientEvent('xnVending:serverCallback', playerId, requestId, ...)
		end, ...)
	end
end)
