--sv_bans -- by Stickly Man! -- and edited by nil
--Server-side code related to the bans menu.

local shitbans={}
function shitbans.init()
	ULib.ucl.registerAccess( "xgui_manageshitbans", "admin", "Allows addition, removal, and viewing of shitbans in XGUI.", "XGUI" )

	xgui.addDataType( "shitbans", function() return { count=table.Count( ulx.shitbanned ) } end, "xgui_manageshitbans", 30, 20 )

	--Chat commands
	local function xgui_banWindowChat( ply, func, args, doFreeze )
		if doFreeze ~= true then doFreeze = false end
		if args[1] and args[1] ~= "" then
			local target = ULib.getUser( args[1] )
			if target then
				ULib.clientRPC( ply, "xgui.ShowBanWindow", target, target:SteamID(), doFreeze )
			end
		else
			ULib.clientRPC( ply, "xgui.ShowBanWindow" )
		end
	end
	ULib.addSayCommand( "!xsban", xgui_banWindowChat, "ulx shitban" )

	local function xgui_banWindowChatFreeze( ply, func, args )
		xgui_banWindowChat( ply, func, args, true )
	end
	ULib.addSayCommand( "!fsban", xgui_banWindowChatFreeze, "ulx shitban" )

	--XGUI commands
	function shitbans.updateShitBan( ply, args )
		local access, accessTag = ULib.ucl.query( ply, "ulx shitban" )
		if not access then
			ULib.tsayError( ply, "Error editing ban: You must have access to ulx shitban, " .. ply:Nick() .. "!", true )
			return
		end

		local steamID = args[1] or ""
		local bantime = tonumber( args[2] )
		local reason = args[3]
		local name = args[4]

		-- Check steamid
		if not ULib.isValidSteamID(steamID) then
			ULib.tsayError( ply, "Invalid steamid", true )
			return
		end

		-- Check restrictions
		local cmd = ULib.cmds.translatedCmds[ "ulx shitban" ]
		local accessPieces = {}
		if accessTag then
			accessPieces = ULib.splitArgs( accessTag, "<", ">" )
		end

		-- Ban length
		local argInfo = cmd.args[3]
		local success, err = argInfo.type:parseAndValidate( ply, bantime, argInfo, accessPieces[2] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: " .. err, true )
			return
		end

		-- Reason
		local argInfo = cmd.args[4]
		local success, err = argInfo.type:parseAndValidate( ply, reason, argInfo, accessPieces[3] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: You did not specify a valid reason, " .. ply:Nick() .. "!", true )
			return
		end


		if not ulx.shitbanned[steamID] then
			ULib.addBan( steamID, bantime, reason, name, ply )
			return
		end

		if name == "" then
			name = nil
			ulx.shitbanned[steamID].name = nil
		end

		if bantime ~= 0 then
			if (ulx.shitbanned[steamID].time + bantime*60) <= os.time() then --New ban time makes the ban expired
				ULib.unban( steamID, ply )
				return
			end
			bantime = bantime - (os.time() - ulx.shitbanned[steamID].time)/60
		end
		ULib.addBan( steamID, bantime, reason, name, ply )
	end
	xgui.addCmd( "updateShitBan", shitbans.updateShitBan )

	--Misc functions
	function shitbans.processBans()
		shitbans.clearSortCache()
		xgui.sendDataTable( {}, "shitbans" )	--Only sends the ban count, and triggers the client to clear their cache.
	end

	function shitbans.clearSortCache()
		xgui.shitbansbyid = {}
		xgui.shitbansbyname = {}
		xgui.shitbansbyadmin = {}
		xgui.shitbansbyreason = {}
		xgui.shitbansbydate = {}
		xgui.shitbansbyunban = {}
		xgui.shitbansbybanlength = {}
	end

	local sortTypeTable = {
		[1] = function()
			-- Bans by Name
			if next( xgui.shitbansbyname ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbyname, { k, v.name and string.upper( v.name ) or nil } )
				end
				table.sort( xgui.shitbansbyname, function( a, b ) return (a[2] or "\255" .. a[1]) < (b[2] or "\255" .. b[1]) end )
			end
			return xgui.shitbansbyname

		end,
		[2] = function()
			-- Bans by SteamID
			if next( xgui.shitbansbyid ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbyid, { k } )
				end
				table.sort( xgui.shitbansbyid, function( a, b ) return a[1] < b[1] end )
			end
			return xgui.shitbansbyid

		end,
		[3] = function()
			-- Bans by Admin
			if next( xgui.shitbansbyadmin ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbyadmin, { k, v.admin or "" } )
				end
				table.sort( xgui.shitbansbyadmin, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.shitbansbyadmin

		end,
		[4] = function()
			-- Bans by Reason
			if next( xgui.shitbansbyreason ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbyreason, { k, v.reason or "" } )
				end
				table.sort( xgui.shitbansbyreason, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.shitbansbyreason

		end,
		[5] = function()
			-- Bans by Unban Date
			if next( xgui.shitbansbyunban ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbyunban, { k, tonumber(v.unban) or 0 } )
				end
				table.sort( xgui.shitbansbyunban, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.shitbansbyunban

		end,
		[6] = function()
			-- Bans by Ban Length
			if next( xgui.shitbansbybanlength ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbybanlength, { k, (tonumber(v.unban) ~= 0) and (v.unban - v.time) or nil } )
				end
				table.sort( xgui.shitbansbybanlength, function( a, b ) return (a[2] or math.huge) < (b[2] or math.huge) end )
			end
			return xgui.shitbansbybanlength

		end,
		[7] = function()
			-- Bans by Ban Date
			if next( xgui.shitbansbydate ) == nil then
				for k, v in pairs( ulx.shitbanned ) do
					table.insert( xgui.shitbansbydate, { k, v.time or 0 } )
				end
				table.sort( xgui.shitbansbydate, function( a, b ) return tonumber( a[2] ) > tonumber( b[2] ) end )
			end
			return xgui.shitbansbydate
		end,
	}
	function shitbans.getSortTable( sortType )
		-- Retrieve the sorted table of shitbans. If type hasn't been sorted, then sort and cache.
		local value = sortTypeTable[sortType] and sortTypeTable[sortType]() or sortTypeTable[7]()
		return value
	end

	function shitbans.sendBansToUser( ply, args )
		if not ply then return end

		if not ULib.ucl.query( ply, "xgui_manageshitbans" ) then return end

		--local perfTimer = os.clock() --Debug

		-- Default params
		sortType = tonumber( args[1] ) or 0
		filterString = (args[2] ~= "" and args[2] ~= nil) and string.lower( args[2] ) or nil
		filterPermaBan = args[3] and tonumber( args[3] ) or 0
		filterIncomplete = args[4] and tonumber( args[4] ) or 0
		page = tonumber( args[5] ) or 1
		ascending = tonumber( args[6] ) == 1 or false

		-- Get cached sort table to use to reference the real data.
		sortTable = shitbans.getSortTable( sortType )

		local shitbansToSend = {}

		-- Handle ascending or descending
		local startValue = ascending and #sortTable or 1
		local endValue = ascending and 1 or #sortTable
		local firstEntry = (page - 1) * 17
		local currentEntry = 0

		local noFilter = ( filterPermaBan == 0 and filterIncomplete == 0 and filterString == nil )

		for i = startValue, endValue, ascending and -1 or 1 do
			local steamID = sortTable[i][1]
			local bandata = ulx.shitbanned[steamID]

			-- Handle filters. This is confusing, but essentially 0 means skip check, 1 means restrict if condition IS true, 2+ means restrict if condition IS NOT true.
			if not ( filterPermaBan > 0 and ( ( tonumber( bandata.unban ) == 0 ) == ( filterPermaBan == 1 ) ) ) then
				if not ( filterIncomplete > 0 and ( ( bandata.time == nil ) == ( filterIncomplete == 1 ) ) ) then

					-- Handle string filter
					if not ( filterString and
						not ( steamID and string.find( string.lower( steamID ), filterString ) or
							bandata.name and string.find( string.lower( bandata.name ), filterString ) or
							bandata.reason and string.find( string.lower( bandata.reason ), filterString ) or
							bandata.admin and string.find( string.lower( bandata.admin ), filterString ) or
							bandata.modified_admin and string.find( string.lower( bandata.modified_admin ), filterString ) )) then

						--We found a valid one! .. Now for the pagination.
						if #shitbansToSend < 17 and currentEntry >= firstEntry then
							table.insert( shitbansToSend, bandata )
							shitbansToSend[#shitbansToSend].steamID = steamID
							if noFilter and #shitbansToSend >= 17 then break end	-- If there is a filter, then don't stop the loop so we can get a "result" count.
						end
						currentEntry = currentEntry + 1
					end
				end
			end
		end
		if not noFilter then shitbansToSend.count = currentEntry end

		--print( "XGUI: Ban request took " .. os.clock() - perfTimer ) --Debug

		-- Send shitbans to client via custom handling.
		xgui.sendDataEvent( ply, 7, "shitbans", shitbansToSend )
	end
	xgui.addCmd( "getshitbans", shitbans.sendBansToUser )

	ulx.addToHelpManually( "Menus", "xgui fsban", "<player> - Opens the add ban window, freezes the specified player, and fills out the Name/SteamID automatically. (say: !fban)" )
	ulx.addToHelpManually( "Menus", "xgui xsban", "<player> - Opens the add ban window and fills out Name/SteamID automatically if a player was specified. (say: !xban)" )
end

function shitbans.postinit()
    shitbans.processBans()
end

xgui.addSVModule( "shitbans", shitbans.init, shitbans.postinit )

xgui.shitbans_processBans = shitbans.processBans
