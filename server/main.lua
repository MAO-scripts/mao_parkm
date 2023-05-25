local in_park = {}
local veh_in_park = {}
local in_park2 = {}
local ESX = nil
if config.ESX_version == "new" then
    exports["es_extended"]:getSharedObject()
else
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end
RegisterCommand(command, function(src, args)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()
    if Admins[identifier] then
        if args[1] then
            local ped = GetPlayerPed(src)
            if not ped or not DoesEntityExist(ped) then return end
            local coords = GetEntityCoords(ped)
            local s_d = '\n\n--'..args[1]..'\ntable.insert(locations, '..tostring(vec(coords.x, coords.y, coords.z, GetEntityHeading(ped)))..')'
            local path = GetResourcePath(GetCurrentResourceName())
            path = path:gsub('//', '/')..'/server/config_sv.lua'
            local file = io.open(path, 'a+')
            file:write(s_d)
            file:close()
            table.insert(locations, coords)
            TriggerClientEvent("mao_parkm:addCoords", -1, vec(coords.x, coords.y, coords.z, GetEntityHeading(ped)), #locations)
        else
            TriggerClientEvent("mao_parkm:sendNotif", src, "please enter parkmeter name.")
        end
    end
end)

function park_car(netId, props, damages, plate, number)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = xPlayer.getIdentifier()
    if not in_park[identifier] then
        in_park[identifier] = {}
    end
    if not locations[number] then
        return
    end
    if in_park[identifier][number] then
        TriggerClientEvent("mao_parkm:sendNotif", _source, config.txt["full"])
    end
    in_park[identifier][number] = {plate = plate, props = props, damages = damages, time = GetGameTimer()}
    veh_in_park[plate] = {identifier = identifier, num = number}
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh ~= 0 then
        DeleteEntity(veh)
    end
    exports["mao_keys"]:removeKey(netId)
    TriggerClientEvent("mao_parkm:changeState", _source, number, in_park[identifier][number])
end

RegisterServerEvent("mao_parkm:parkCar", park_car)

function park_car2(netId, props, damages, d_coords, hash, b_coords)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local account = xPlayer.getAccount('money')
    if account.money >= config.parkingmeterprice then
        if not in_park2[props.plate] then
            xPlayer.removeAccountMoney('money', config.parkingmeterprice)
            in_park2[props.plate] = {net = netId, props = props, damages = damages, coords = d_coords, hash = hash, b_coords = b_coords, identifier = xPlayer.getIdentifier()}
            local veh = NetworkGetEntityFromNetworkId(netId)
            local v_ped = nil
            if veh ~= 0 then
                for i=-1, 6 do
                    local ped = GetPedInVehicleSeat(veh, i)
                    if DoesEntityExist(ped) then
                        TaskLeaveVehicle(ped, veh, 0)
                        v_ped = ped
                    end
                end
            end
            TriggerClientEvent("mao_parkm:updateCar", -1, props.plate, in_park2[props.plate])
            if config.d_car then
                TriggerClientEvent("mao_parkm:updatePark", _source, in_park2[props.plate], props.plate)
                if v_ped then
                    while true do
                        Wait(100)
                        local veh = GetVehiclePedIsIn(v_ped)
                        if veh == 0 or not DoesEntityExist(veh) then
                            break
                        end
                    end
                    Wait(1000)
                end
                DeleteEntity(veh)
            end
        else
            TriggerClientEvent("mao_parkm:sendNotif", _source, config.txt["aleardy_parked"])
        end
    else
        TriggerClientEvent("mao_parkm:sendNotif", _source, config.txt["not_enough_money"]:gsub("_money_", config.parkingmeterprice))
    end
end

RegisterServerEvent("mao_parkm:parkCar2", park_car2)

RegisterServerEvent("mao_parkm:removePark")
AddEventHandler("mao_parkm:removePark", function(plate)
    if in_park2[plate] then
        local veh = NetworkGetEntityFromNetworkId(in_park2[plate].net)
        if veh ~= 0 then
            for i=-1, 6 do
                local ped = GetPedInVehicleSeat(veh, i)
                if DoesEntityExist(ped) and IsPedAPlayer(ped) then
                    local src = NetworkGetEntityOwner(ped)
                    TriggerClientEvent("mao_parkm:sendNotif", src, config.txt["takeout"])
                    break
                end
            end
        end
        in_park2[plate] = nil
        TriggerClientEvent("mao_parkm:updateCar", -1, plate, nil)
    end
end)

function get_car( number)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = xPlayer.getIdentifier()
    if not in_park[identifier] or not in_park[identifier][number] then
        return
    end
    if not locations[number] then
        return
    end
    TriggerClientEvent("mao_parkm:spawnVeh", _source, in_park[identifier][number], number)
    TriggerClientEvent("mao_parkm:changeState", _source, number, false)
    veh_in_park[in_park[identifier][number].plate] = nil
    in_park[identifier][number] = nil
end

RegisterServerEvent("mao_parkm:getCar", get_car)

function impound_r(plate)
    if veh_in_park[plate] then
        local identifier = veh_in_park[plate].identifier
        if in_park[identifier] and in_park[identifier][veh_in_park[plate].num] then
            if in_park[identifier][veh_in_park[plate].num].plate == plate then
                in_park[identifier][veh_in_park[plate].num] = nil
                local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
                if xPlayer then
                    TriggerClientEvent("mao_parkm:changeState", xPlayer.source, veh_in_park[plate].num, false)
                end
                veh_in_park[plate] = nil
            end
        end
    end
    if in_park2[plate] then
        local identifier = in_park2[plate].identifier
        in_park2[plate] = nil
        TriggerClientEvent("mao_parkm:updateCar", -1, plate, nil)
        if config.d_car then
            local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
            if xPlayer then
                TriggerClientEvent("mao_parkm:updatePark", xPlayer.source, nil, plate)
            end
        end
    end
end

exports("impound_r", impound_r)

RegisterServerEvent("mao_parkm:getLoc", function()
    local _source = source
    local _park = {}
    for k,v in pairs(in_park2) do
        if v and v.identifier == identifier then
            _park[k] = v
        end
    end
    TriggerClientEvent("mao_parkm:getLocations", _source, locations, in_park2, _park)
end)

RegisterServerEvent("mao_parkm:spawnVehicle", function(plate, net)
    if in_park2[plate] and in_park2[plate].create_data then
        in_park2[plate].create_data = nil
        in_park2[plate].net = net
        TriggerClientEvent("mao_parkm:updateCar", -1, plate, in_park2[plate])
        return
    end
    local veh = NetworkGetEntityFromNetworkId(net)
    if veh ~= 0 then
        DeleteEntity(veh)
    end
end)

AddEventHandler("esx:playerLoaded", function(source, xPlayer)
    local identifier = xPlayer.getIdentifier()
    local _park = {}
    if config.d_car then
        for k,v in pairs(in_park2) do
            if v and v.identifier == identifier then
                _park[k] = v
            end
        end
    end
    TriggerClientEvent("mao_parkm:getLocations", source, locations, in_park2, _park)
    Wait(1000)
    if in_park[identifier] and next(in_park[identifier]) then
        TriggerClientEvent("mao_parkm:changeState", source, in_park[identifier])
    end
end)

if config.anti_delete and not config.d_car then
    AddEventHandler("entityRemoved", function(entity)
        local model = GetEntityModel(entity)
        local _type = GetEntityType(entity)
        if model == 0 then
            return
        end
        local net = NetworkGetNetworkIdFromEntity(entity)
        if _type == 2 then
            for k,v in pairs(in_park2) do
                if v.net == net then
                    local coords = GetEntityCoords(entity)
                    local heading = GetEntityHeading(entity)
                    Wait(500)
                    in_park2[k].create_data = {coords = coords, heading = heading}
                    TriggerClientEvent("mao_parkm:updateCar", -1, k, in_park2[k])
                end
            end
        end
    end)
end
