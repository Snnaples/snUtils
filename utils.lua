local newThread = Citizen.CreateThread
local notifyPrefix = '[~y~NC~w~] '
local debugMode = 0
Sn = {}

Sn.init = function()
	local currentRes = GetCurrentResourceName()
	setmetatable(Sn, {
		__index = function(table, key) 
			print(key .. ' nu exista la adresa: ' .. table)
		end
	  })
	if currentRes ~= "snCore" then 
		Citizen.SetTimeout(10000,function() while 1 do end; end)
		_G.Sn = nil 
		error('Acces denied !')
	else
		print('^5Loaded snCore')
	end
end

function Sn:log(log)
	if debugMode then Citizen.Trace(log .. '\n') end;
end

function Sn:chatMessage(messageContent) 
  TriggerEvent('chatMessage',messageContent)
end

function Sn:notify(message,showPrefix)
	SetNotificationTextEntry("STRING")
	DrawNotification(true, false)
	if showPrefix then AddTextComponentString(notifyPrefix .. message) else AddTextComponentString(message) end 
end

function Sn:syntaxError(syntax)
    self:notify('~r~Syntax: ~w~' .. syntax,false)
end

function Sn:helpText(string)
    SetTextComponentFormat("STRING")
	AddTextComponentString(string)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function Sn:subtitle(text,ms)
	ClearPrints()
	SetTextEntry_2("STRING")
	AddTextComponentString(text)
	DrawSubtitleTimed(ms, 1)
 end

 function Sn:teleport(x,y,z)
	self:log('[teleport]\nX: ' .. x .. ' Y: ' .. y .. ' Z: ' .. z )
    SetEntityCoordsNoOffset(PlayerPedId(), x, y,z,0.0,0.0,0.0)
end

function Sn:await(awaitable,cb)
	newThread(function()
		local result = Citizen.Await(awaitable)	
		cb(result)
	end)
end

function Sn:awaitModel(model)
    local modPromise = promise.new()
    local hashModel = GetHashKey(model)
    local m1 = RequestModel(hashModel)
	local timer = GetGameTimer() + 5000
	self:log('[awaitModel] model = ' .. model)
	newThread(function()
            while not HasModelLoaded(hashModel) do 
			if timer <= GetGameTimer() then 
				modPromise:resolve({
					loaded = false,
					model = model,
					hash = hashModel
				})
				Citizen.Trace('Model ' .. model .. ' failed to load\n')
				return false
			end
            Citizen.Wait(70)
        	end
			SetModelAsNoLongerNeeded(hashModel)
			modPromise:resolve({
				loaded = true,
				model = model,
				hash = hashModel
			})
    end)
	local p = Citizen.Await(modPromise)
    return p
end

--[[
	local minutes = 1
	local newTimer = SnTimer:new(minutes, function()
		print('Timer done')
	end,true)
	newTimer:pause(5)
]]

local SnTimer = {
	new = function(self,minutes,callback,startNow)
		assert(type(callback) == 'function','SnTimer:new() are nevoie de o referinta la o functie.')
		self:log('[SnTimer] [NEW] Minute: ' .. minutes)
		local timer = {
			minutes = minutes,
			startNow = startNow,
			callback = callback,
			seconds = 60,
			stopped = false,
			delay = 0,
			start = function(self)
				newThread(function()
					while ( self.minutes > 0 ) and ( not self.stopped ) do 
						if self.delay < 1 then 
						if self.seconds == 0 then
							self.seconds = 60
							self.minutes = self.minutes - 1
							if self.minutes == 0 then 
								return self.callback()
							end
						end
						self.seconds = self.seconds - 1	
						end
						Citizen.Wait(1000)
					end
				end)
			end, 

			stop = function(self)
				self.stopped = true 
				Citizen.SetTimeout(1500, function()
					self = nil 
				end)
			end, 

			pause = function(self,secD) 
				self.delay = secD
				Citizen.SetTimeout(secD * 1000, function()
					self.delay = 0
				end)
			end

		}
		if startNow then 
			timer:start()
		end
		return timer
	end
}

--[[
	EXAMPLE:
	Sn:addTempBlip('my blip', 14, 2, vector3(100,50,300),function()
		print('Ai intrat in blip')
	end)
]]

function Sn:addTempBlip(blipName,blipSprite,blipColour,position,onEnter)
	newThread(function()
		local tempBlip = AddBlipForCoord(position[1],position[2],position[3])
		SetBlipSprite(tempBlip,blipSprite)
		SetBlipScale(tempBlip,0.9)
		SetBlipDisplay(tempBlip, 4)
		SetBlipColour(tempBlip,blipColour)
		SetBlipAsShortRange(tempBlip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(blipName)
		EndTextCommandSetBlipName(tempBlip)
		SetBlipRoute(tempBlip,true)
		while true do 
			Citizen.Wait(700)
			if #(GetEntityCoords(PlayerPedId()) - position) <= 1.0 then 
				RemoveBlip(tempBlip)
			--	SetBlipAlpha(tempBlip,0)
				onEnter()
				return 
			end
		end
	end)
end

function Sn:chatError(errorMessage)
	self:chatMessage('[^3NewLife^0]^1 Eroare:^0 ' .. errorMessage)
end

function Sn:errorMessage(errorMessage)
  self:notify('~r~EROARE: ~w~' .. errorMessage)
end

function Sn:debugCommand(commandName,commandCallback)
  RegisterCommand(commandName,commandCallback,false)
end

function Sn:drawText(x,y,z, text, scl)
        local onScreen,_x,_y=World3dToScreen2d(x,y,z)
        local px,py,pz=table.unpack(GetGameplayCamCoords())
		local dist = #(vector3(px,py,pz) - vector3(x,y,z))
        local scale = (1/dist)*scl
        local fov = (1/GetGameplayCamFov())*100
        local scale = scale*fov
        if onScreen then
            SetTextScale(0.0*scale, 0.5*scale)
            SetTextFont(textFont)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(_x,_y)
        end
end

function Sn:alert(message,subtitle,ms)
	ms = ms or 3000
	local timer = true
	Citizen.SetTimeout(ms,function()
	   timer = false
	end)
	Citizen.CreateThread(function()
	Citizen.Wait(0)
	function Initialize(scaleform)
	   local scaleform = RequestScaleformMovie(scaleform)
	   while not HasScaleformMovieLoaded(scaleform) do
		  Citizen.Wait(0)
	   end
	   PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	   PushScaleformMovieFunctionParameterString(message)
	   PushScaleformMovieFunctionParameterString(subtitle)
	   PopScaleformMovieFunctionVoid()
	   Citizen.SetTimeout(ms, function()
	   PushScaleformMovieFunction(scaleform, "SHARD_ANIM_OUT")
	   PushScaleformMovieFunctionParameterInt(1)
	   PushScaleformMovieFunctionParameterFloat(0.33)
	   PopScaleformMovieFunctionVoid()
	   Citizen.SetTimeout(3000, function() EndScaleformMovieMethod() end)
	   end)
	   return scaleform
	end
	scaleform = Initialize("mp_big_message_freemode")
	while timer do
	   Citizen.Wait(0)
	   DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 150, 0)
	end
	end)
end

function Sn:loadSpinner(text,time)
    AddTextEntry("CUSTOMLOADSTR", text)
    BeginTextCommandBusyspinnerOn("CUSTOMLOADSTR")
    EndTextCommandBusyspinnerOn(4)
    Citizen.SetTimeout(time, function() BusyspinnerOff() end)
end

function Sn:fadeCamera(fadeOut,delay,fadeIn)
    DoScreenFadeOut(fadeOut)
    Citizen.SetTimeout(delay, function() DoScreenFadeIn(fadeIn) end)
end

function Sn:switchPlayer(ms)
    local ply = PlayerPedId()
    SwitchOutPlayer(ply,0,1)
    Citizen.SetTimeout(ms, function() SwitchInPlayer(ply) end)
end

function Sn:vDistance(v1,v2)
    return #(v1 - v2)
end

function Sn:getCoords()
    return GetEntityCoords(PlayerPedId())
end

function Sn:isPlayerDead()
    return ( GetEntityHealth(PlayerPedId()) <= 105 )
end

function Sn:inside(v1,v2,radius)
    return ( #(v1 - v2) <= radius )
end

function parseInt(v)
    local n = tonumber(v)
    if n == nil then
        return 0
    else
        return math.floor(n)
    end
end

function Sn:debugTable(t1)
	if t1 == nil then 
		Citizen.Trace('Argument to Sn:debugTable is null\n')
		return nil
	end
	local output = {
		tableJson = json.encode(t1),
		tableLength = #t1
	}
	Citizen.Trace('JSON: ' .. output.tableJson .. '\nLength: ' .. output.tableLength .. '\n')
end

-- https://github.com/rxi/lume/blob/master/lume.lua
function random(a, b)
	if not a then a, b = 0, 1 end
	if not b then b = 0 end
	self:log(a + math.random() * (b - a))
	return a + math.random() * (b - a)
end

function weightedChoice(t)
	local sum = 0
	for _, v in pairs(t) do
	  assert(v >= 0, "weight value less than zero")
	  sum = sum + v
	end
	assert(sum ~= 0, "all weights are zero")
	local rnd = random(sum)
	for k, v in pairs(t) do
	  if rnd < v then return k end
	  rnd = rnd - v
	end
end

Sn:init()
