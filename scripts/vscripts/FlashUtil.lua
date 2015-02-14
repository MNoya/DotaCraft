--[[
Utility for requesting data from flash, uses an event to request data and fires a callback. 

Data available for request:
	-Player Name (String)
		dataName: 'player_name'

	-Cursor position (Vector (X,Y,0))
		dataName: 'cursor_position'

	-Cursor position (world coordinates) (Vector (X,Y,Z))
		dataName: 'cursor_position_world'

Author: Perry
]]

--Define the FlashUtil class
if FlashUtil == nil then
	FlashUtil = {}
	FlashUtil.__index = FlashUtil
end

--Initialise
function FlashUtil:Init()
	FlashUtil = self

	self.callbacks = {}

	--Register the return command
	Convars:RegisterCommand( "FlashUtil_return", function(name, p)
		--get the player that sent the command
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer then 
			self:HandleReturn( p )
			return 0
		end
	end, "FlashUtil return message", 0 )

	print('[FlashUtil] Done loading.')
end

--Send a request to the flash UI of a player
--Params:	dataName - the name of the data you want to request (see top of file)
--			playerID - the ID of the player you want to send the request to, -1 to send to all (callback will only fire for the first reply)
--			callback - a callback function to be executed once the request returns.
--					Callback parameters: playerID - the player that has responded; data - the requested data
function FlashUtil:RequestData( dataName, playerID, callback )
	local requestID = DoUniqueString(dataName)
	self.callbacks[requestID] = callback

	FireGameEvent('FlashUtil_request', { request_id = requestID, data_name = dataName, target_player = playerID })
end

--Handle return data from a flash UI
--Params:	return_data - return data from the client formatted like so:
--				[requestID]:[playerID (owner of replying UI)]:[data type]:[data]
function FlashUtil:HandleReturn( return_data )
	--Parse data
	local split = string.gmatch(return_data, "[^;]+")
	local data = {}
	for i in split do
		data[#data + 1] = i
	end

	local requestID = data[1]
	local playerID = data[2]
	local dataType = data[3]
	local result = data[4]

	if dataType == 'Vector2' then
		result = self:ParseVector(result)
	elseif dataType == 'Vector3' then
		result = self:ParseVector(result)
	end


	--Call the corresponding callback
	if not self.callbacks[requestID] then
		--print('[FlashUtil] Error: callback not found. Data: '.. return_data)
	else
		self.callbacks[requestID](playerID, result)
	end
end

--Parse a vector from a string if possible
--Params:	str - a vector formatted as string, its components separated by ;
function FlashUtil:ParseVector( str )
	local split = string.gmatch(str, "[^,]+")
	local data = {}
	for i in split do
		data[#data + 1] = i
	end

	--Check number of components
	if #data == 2 then
		return Vector(data[1], data[2], 0)
	elseif #data == 3 then
		return Vector(data[1], data[2], data[3])
	else
		print('[FlashUtil] Error: could not parse vector from string: '..str)
		return str
	end
end

--[[function FlashUtil:( ... )
	-- body
end]]

--Request a player's cursor position in world coordinates
--Params:	pID - the player ID we want the cursor position for
function FlashUtil:GetCursorWorldPos( pID, callback )
	self:RequestData('cursor_position_world', pID, callback)
end

--Request a player's cursor position
--Params:	pID - the player ID we want the cursor position for
function FlashUtil:GetCursorPos( pID, callback )
	self:RequestData('cursor_position', pID, callback)
end

--Request a player's name
--Params:	pID - the player ID we want the name for
function FlashUtil:GetPlayerName( pID, callback )
	self:RequestData('player_name', pID, callback)
end

--Request a data stream
--Params:	dataName - the name of the data you want to request (see top of file)
--			rps - requests per second, lower values yield better performance, higher values give smoother data
--			playerID - the ID of the player you want to send the request to, -1 to send to all (callback will only fire for the first reply)
--			callback - a callback function to be executed once the request returns.
--					Callback parameters: playerID - the player that has responded; data - the requested data
--Returns:	an ID that uniquely identifies this stream (needed for stopping)
function FlashUtil:RequestDataStream( dataName, rps, pID, callback )
	local requestID = DoUniqueString(dataName)
	self.callbacks[requestID] = callback
	FireGameEvent('FlashUtil_request_stream', { request_id = requestID, data_name = dataName, requests_per_second = rps, target_player = playerID })

	return requestID
end

--Stop a data stream
--Params:	streamID - an ID that identifies a unique stream, returned by the RequestDataStream function
function FlashUtil:StopDataStream( streamID )
	--remove callback
	self.callbacks[streamID] = nil

	--tell UIs to stop transmitting data
	FireGameEvent('FlashUtil_stop_stream', { stream_id = streamID })
end

FlashUtil:Init()