local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

local Config = module("xnVending", "config")

TryGiveInventoryItem = function(source, cb, machine, entry, confirm)
	local user = vRP.users_by_source[source]
	local item = Config.Machines[machine]
	local itemid = item.item[entry]
	local price = item.price[entry]

	if user:tryPayment(price, true) then
		if user:tryGiveItem(itemid, 1, true, false) then
			if confirm then
				user:tryGiveItem(itemid, 1, false, false)
				user:tryPayment(price, false)
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
	if name == "xnVending:checkMoneyandInvent" then
		TryGiveInventoryItem(playerId, function(...)
			TriggerClientEvent('xnVending:serverCallback', playerId, requestId, ...)
		end, ...)
	end
end)
