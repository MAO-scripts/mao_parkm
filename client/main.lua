local locations = {}
local parks = {}
local p_cars = {}
local my_parks = {}
local ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
        if config.ESX_version == "new" then
            exports["es_extended"]:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
		Citizen.Wait(0)
	end
    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end
    ESX.PlayerData = ESX.GetPlayerData()
    TriggerServerEvent("mao_parkm:getLoc")
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent("mao_parkm:getLocations", function(loca, loca2, loca3)
    for i=1, #loca do
        locations[i] = {coords = loca[i]}
        if config.blip_options.enable then
            locations[i].blip = addBlip(loca[i])
        end
    end
    for k, v in pairs(loca3) do
        my_parks[k] = v
    end
    updateCar(loca2)
end)

RegisterNetEvent("mao_parkm:updatePark", function(data, name)
    my_parks[name] = data
end)

RegisterNetEvent("mao_parkm:addCoords", function(coords, number)
    locations[number] = {coords = coords}
    if config.blip_options.enable then
        locations[number].blip = addBlip(coords)
    end
end)

RegisterNetEvent("mao_parkm:changeState", function(number, data)
    if type(number) == "table" then
        for k,v in pairs(number) do
            if v and locations[k] then
                changeState(k, v)
            end
        end
    else
        if locations[number] then
            changeState(number, data)
        end
    end
end)

if config.parkingmeter2 then
    local ped = PlayerPedId()
    local s_d = {}
    function checking(name, obj, hash)
        if s_d[name] then return end
        s_d[name] = obj
        CreateThread(function()
            while s_d[name] and DoesEntityExist(s_d[name]) do
                Wait(1)
                local coords = GetEntityCoords(ped)
                local veh = GetVehiclePedIsIn(ped)
                local obj_coords = GetEntityCoords(s_d[name])
                local vehExist = veh ~= 0 and DoesEntityExist(veh)
                if #(coords - obj_coords) > 4.0 or find_coords(obj_coords, hash) then
                    break
                end
                if IsVehicleStopped(veh) then
                    floatText(config.txt['park2'] .. "("..config.parkingmeterprice..'$)', obj_coords+vec(0.0,0.0,1.2))
                    if IsControlJustPressed(0, 38) then
                        local damages = GetVehDamages(veh)
                        local vehicleProps  = ESX.Game.GetVehicleProperties(veh)
                        local netId = VehToNet(veh)
                        local x,y,z = table.unpack(GetEntityCoords(veh))
                        local s_heading = GetEntityHeading(veh)
                        
                        TriggerServerEvent("mao_parkm:parkCar2", netId, vehicleProps, damages, obj_coords, hash, vec(x,y,z,s_heading))
                    end
                end
            end
            s_d[name] = nil
        end)
    end
    Citizen.CreateThread(function()
        while true do
            Wait(3000)
            ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local veh = GetVehiclePedIsIn(ped)
            local vehExist = veh ~= 0 and DoesEntityExist(veh)
            if vehExist and GetPedInVehicleSeat(veh, -1) == ped then
                for k,v in pairs(config.objects) do
                    if not HasClosestObjectOfTypeBeenCompletelyDestroyed(coords, 3.0, v) then
                        local closestObject = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 3.0, v)
                        if closestObject and DoesEntityExist(closestObject) then
                            local obj_coords = GetEntityCoords(closestObject)
                            checking(tostring(obj_coords), closestObject, v)
                        end
                    end
                end
            end
        end
    end)
    if config.show_text then
        CreateThread(function()
            local ped = PlayerPedId()
            while ESX == nil or ESX.PlayerData == nil or ESX.PlayerData.job == nil do
                Wait(10)
            end
            while true do
                local wait = 2000
                local coords = GetEntityCoords(ped)
                if not config.use_job or config.job_name == ESX.PlayerData.job.name then 
                    for k,v in pairs(p_cars) do
                        if v and not my_parks[k] then
                            local dis = #(v.coords - coords)
                            if dis <= 20.0 then
                                wait = 300
                                if dis <= 2.0 then
                                    floatText(config.txt["paid"], v.coords+vec(0.0,0.0,1.2))
                                    wait = 0
                                    break
                                end
                            end
                        end
                    end
                end
                Wait(wait)
            end
        end)
    end
    if config.d_car then
        CreateThread(function()
            while true do
                local wait = 3000
                local coords = GetEntityCoords(PlayerPedId())
                for k,v in pairs(my_parks) do
                    if v then
                        local dis = #(coords - v.coords)
                        if dis <= 20.0 then
                            sleep = wait == 3000 and 200 or wait
                            if dis <= 2.0 then
                                wait = 0
                                floatText(config.txt['get'], v.coords+vec(0.0,0.0,1.2))
                                if IsControlJustPressed(0, 38) then
                                    if ESX.Game.IsSpawnPointClear(v.b_coords, 3.0) then
                                        fadeOut(200, true)
                                        ESX.Game.SpawnVehicle(v.props.model, {
                                            x = v.b_coords.x,
                                            y = v.b_coords.y,
                                            z = v.b_coords.z
                                        }, v.b_coords.w, function(callback_vehicle)
                                            if callback_vehicle and callback_vehicle ~= 0 then
                                                SetVehRadioStation(callback_vehicle, "OFF")
                                                Wait(150)
                                                ESX.Game.SetVehicleProperties(callback_vehicle, v.props)
                                                setDamages(callback_vehicle, v.damages)
                                                TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
                                                fadeIn(100)
                                            end
                                        end)
                                        my_parks[k] = nil
                                        TriggerServerEvent("mao_parkm:removePark", k)
                                    else
                                        showNotification(config.txt["block"])
                                    end
                                end
                            end
                        end
                    end
                end
                Wait(wait)
            end
        end)
    else
        Citizen.CreateThread(function()
            while true do
                Wait(2000)
                local coords = GetEntityCoords(ped)
                local veh = GetVehiclePedIsIn(ped)
                local vehExist = veh ~= 0 and DoesEntityExist(veh)
                for k,v in pairs(p_cars) do
                    if v and #(v.coords - coords) <= 200 then
                        if v.create_data then
                            ESX.Game.SpawnVehicle(v.props.model, {
                                x = v.create_data.coords.x,
                                y = v.create_data.coords.y,
                                z = v.create_data.coords.z
                            }, v.create_data.heading, function(callback_vehicle)
                                if callback_vehicle and callback_vehicle ~= 0 then
                                    SetVehRadioStation(callback_vehicle, "OFF")
                                    ESX.Game.SetVehicleProperties(callback_vehicle, v.props)
                                    setDamages(callback_vehicle, v.damages)
                                    TriggerServerEvent("mao_parkm:spawnVehicle", v.props.plate, VehToNet(callback_vehicle))
                                end
                            end)
                        else
                            local veh = NetToVeh(v.net)
                            if veh and DoesEntityExist(veh) then
                                local veh_coords = GetEntityCoords(veh)
                                if #(veh_coords - v.coords) > 4.0 then
                                    TriggerServerEvent("mao_parkm:removePark", k)
                                end
                            end
                        end
                    end
                end 
            end
        end)
    end
end

Citizen.CreateThread(function()
    local ped = PlayerPedId()
    while true do
        Wait(0)
        local sleep = true
        local coords = GetEntityCoords(ped)
        local veh = GetVehiclePedIsIn(ped)
        local vehExist = veh ~= 0 and DoesEntityExist(veh)
        for k,v in pairs(locations) do
            if v then
                if #(v.coords.xyz - coords) < 30.0 then
                    sleep = false
                    local color = config.marker_options.color1
                    if v.data then
                        color = config.marker_options.color2
                    end
                    DrawMarker(config.marker_options.type, v.coords.x, v.coords.y, v.coords.z-0.3, 0.0,0.0,0.0,0.0,0.0,0.0,config.marker_options.size.x,config.marker_options.size.y,config.marker_options.size.z, color.r, color.g, color.b, 155, false, true)
                    if #(v.coords.xyz - coords) < 2.0 then
                        if v.data then
                            showHelp(config.txt["get"])
                            if IsControlJustPressed(0, 38) then
                                if ESX.Game.IsSpawnPointClear(v.coords, 1.5) then
                                    TriggerServerEvent("mao_parkm:getCar", k)
                                else
                                    showNotification(config.txt["block"])
                                end
                            end
                        else
                            local veh = GetVehiclePedIsIn(ped)
                            if vehExist and GetPedInVehicleSeat(veh, -1) == ped then
                                showHelp(config.txt["park"])
                                if IsControlJustPressed(0, 38) then
                                    local damages = GetVehDamages(veh)
                                    local vehicleProps  = ESX.Game.GetVehicleProperties(veh)
                                    local netId = VehToNet(veh)
                                    TriggerServerEvent("mao_parkm:parkCar", netId, vehicleProps, damages, vehicleProps.plate, k)
                                end
                            end
                        end
                    end
                end
            end
        end
        if sleep then
            Wait(2000)
        end
    end
end)

RegisterNetEvent("mao_parkm:spawnVeh", function(data, number)
    if locations[number] then
        local coords = locations[number].coords
        fadeOut(200, true)
        ESX.Game.SpawnVehicle(data.props.model, {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }, coords.w, function(callback_vehicle)
            if callback_vehicle and callback_vehicle ~= 0 then
                SetVehRadioStation(callback_vehicle, "OFF")
                Wait(150)
                ESX.Game.SetVehicleProperties(callback_vehicle, data.props)
                setDamages(callback_vehicle, data.damages)
                TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
                fadeIn(100)
            end
        end)
    end
end)

function updateCar(plate, data)
    if type(plate) == "table" then
        for k,v in pairs(plate) do
            updateCar(k, v)
        end
    else
        p_cars[plate] = data
    end
end

RegisterNetEvent("mao_parkm:updateCar", updateCar)

function showHelp(msg)
    if not IsHelpMessageOnScreen() then
		BeginTextCommandDisplayHelp('STRING')
		AddTextComponentSubstringWebsite(msg)
		EndTextCommandDisplayHelp(0, false, true, -1)
	end
end

function showNotification(msg)
    SetNotificationTextEntry('STRING')
	AddTextComponentSubstringWebsite(msg)
	DrawNotification(false, true)
end

RegisterNetEvent("mao_parkm:sendNotif", showNotification)

function GetVehDamages(vehicle)
	local damages 	   = {['damaged_windows'] = {}, ['burst_tires'] = {}, ['broken_doors'] = {}, ['body_health'] = GetVehicleBodyHealth(vehicle), ['engine_health'] = GetVehicleEngineHealth(vehicle)}
	for i = 0, 5 do
		if IsVehicleTyreBurst(vehicle, i, false) then table.insert(damages['burst_tires'], i) end 
	end
	for i = 0, 7 do
		if not IsVehicleWindowIntact(vehicle, i) then table.insert(damages['damaged_windows'], i) end
	end
	for i = 0, 5 do 
		if IsVehicleDoorDamaged(vehicle, i) then table.insert(damages['broken_doors'], i) end 
	end

	return damages
end

function floatText(msg, coords)
    AddTextEntry('FloatingHelpNotification', msg)
	SetFloatingHelpTextWorldPosition(1, coords)
	SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
	BeginTextCommandDisplayHelp('FloatingHelpNotification')
	EndTextCommandDisplayHelp(2, false, false, -1)
end

function setDamages(car, damages)
	for i = 0, 5 do
		if damages['burst_tires'] then
			if damages['burst_tires'][i] then
				SetVehicleTyreBurst(car, damages['burst_tires'][i], true, 1000.0)
			end
		end
	end
	
	for i = 0, 7 do
		if damages['damaged_windows'] then
			if damages['damaged_windows'][i] then
				SmashVehicleWindow(car, damages['damaged_windows'][i])
			end
		end
	end
	
	for i = 0, 5 do 
		if damages['broken_doors'] then
			if damages['broken_doors'][i] then
				SetVehicleDoorBroken(car, damages['broken_doors'][i], true)
			end
		end
	end
  
	if damages['body_health'] then
		SetVehicleBodyHealth(car, damages['body_health'])
	end
  
	if damages['engine_health'] then
		SetVehicleEngineHealth(car, damages['engine_health'])
	end
end

function find_coords(coords, hash)
    for k,v in pairs(p_cars) do
        if v and v.hash == hash and #(coords - v.coords) < 0.1 then
            return true
        end
    end
    return false
end

fadeOut = function(sec)
	sec = sec or 200
	DoScreenFadeOut(sec)
	while not IsScreenFadedOut() do
        Wait(5)
    end
end

fadeIn = function(sec)
	sec = sec or 200
	DoScreenFadeIn(sec)
	while not IsScreenFadedIn() do
        Wait(5)
    end
end

function addBlip(coords)
    local blip = AddBlipForCoord(coords.xyz)
	
    SetBlipSprite(blip, config.blip_options.sprite)
    SetBlipScale(blip, config.blip_options.scale)
    SetBlipColour(blip, config.blip_options.colour1)
    SetBlipAsShortRange(blip, config.blip_options.shortrange)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(config.blip_options.name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function changeState(number, data)
    if config.blip_options.enable then
        if data then
            SetBlipColour(locations[number].blip, config.blip_options.colour2)
        else
            SetBlipColour(locations[number].blip, config.blip_options.colour1)
        end
    end
    locations[number].data = data
end
