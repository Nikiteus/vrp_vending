local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")

async(function()
    vRP.loadScript("xnVending", "server")
end)
