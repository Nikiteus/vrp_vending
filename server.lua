local Config = module("vrp_vending", "config")

local Vending = class("Vending", vRP.Extension)
Vending.tunnel = {}

function Vending.tunnel:checkMoneyandInvent(machine, entry)
	local user = vRP.users_by_source[source]
	local item = Config.Machines[machine]
	local itemid = item.item[entry]
	local price = item.price[entry]

	if user:tryPayment(price, true) then
		if user:tryGiveItem(itemid, 1, true, true) then
			vRP.EXT.Vending.remote.playAnim(source)
			user:tryGiveItem(itemid, 1, false, false)
			user:tryPayment(price, false)
		else
			vRP.EXT.Base.remote._notify(user.source, "~r~У вас недостаточно места в инвентаре")
		end
	else
		vRP.EXT.Base.remote._notify(user.source, "~r~У вас недостаточно денег")
	end
end

vRP:registerExtension(Vending)
