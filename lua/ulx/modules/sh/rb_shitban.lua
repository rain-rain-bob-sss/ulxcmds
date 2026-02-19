local PLY = FindMetaTable"Player"
local ENT = FindMetaTable"Entity"
local VEH = FindMetaTable"Vehicle"
local DMG = FindMetaTable"CTakeDamageInfo"

local sethp = ENT.SetHealth
local setmhp = ENT.SetMaxHealth
local getclass = ENT.GetClass
local rm = ENT.Remove
local valid = ENT.IsValid
local isvalid = function(e) return e and valid(e) end
local isply = function(e) return getclass(e) == "player" end

local setnwbool = ENT.SetNWBool
local getnwbool = ENT.GetNWBool
local setnwint = ENT.SetNWInt
local getnwint = ENT.GetNWInt
local spawn = ENT.Spawn

local seta = PLY.SetArmor
local getweps = PLY.GetWeapons
local godd = PLY.GodDisable
local steamid = PLY.SteamID
local alive = PLY.Alive
local give = PLY.Give
local haswep = PLY.HasWeapon
local drop = PLY.DropWeapon
local strip = PLY.StripWeapons

local getdriver = VEH.GetDriver

local getatt = DMG.GetAttacker
local scaledmg = DMG.ScaleDamage

local gm = engine.ActiveGamemode

local next = next

ulx.shitbanned = ulx.shitbanned or {}

local function shiton(ply)
    if not alive(ply) then spawn(ply) if gm() == "sandbox" then sethp(ply,69) strip(ply) give(ply,"weapon_physgun") give(ply,"gmod_tool") end end
    setmhp(ply,1)
    seta(ply,0)
    godd(ply)
    setnwbool(ply,"build_pvp",false)
    setnwbool(ply,"shitbanned",true)
    local t = ulx.shitbanned[steamid(ply)]
    if t and t.unban then setnwint(ply,"shitbanned_time",(t.unban == 0) and -1 or math.max(t.unban - os.time(),0)) end
    if not haswep(ply,"weapon_crowbar") and gm() == "sandbox" then give(ply,"weapon_crowbar") end

    for _,wep in next,getweps(ply) do
        local class = getclass(wep)
        if gm() == "sandbox" and (class ~= "weapon_physgun" and class ~= "gmod_tool" and class ~= "weapon_crowbar") then drop(ply,wep,nil,VectorRand(-150,150)) end
    end
end

if CLIENT then
    local lp
    local function drawTextRotated(text, font, x, y, color, alignX, alignY, angle, scaleX, scaleY, o)
    	text = text or "NIL"
    	--render.PushFilterMag( TEXFILTER.ANISOTROPIC )
    	--render.PushFilterMin( TEXFILTER.ANISOTROPIC )
    	scaleX = scaleX or 1
    	scaleY = scaleY or scaleX
    	local m = Matrix()
    	m:Translate(Vector(x, y, 0))
    	m:SetAngles(Angle(0, angle, 0))
    	m:SetScale(Vector(scaleX, scaleY, 1))
    	surface.SetFont(font)
    	local w, h = surface.GetTextSize(text)
    	m:Translate(Vector(-w / 2, -h / 2, 0))
    	cam.PushModelMatrix(m, true)
    	if not o then
    		draw.SimpleText(text, font, w / 2, h / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    	else
    		draw.SimpleTextOutlined(text, font, w / 2, h / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, isnumber(o) and o or 2, color_black)
    	end
    	cam.PopModelMatrix()
    	--render.PopFilterMag()
    	--render.PopFilterMin()
    end
    local color_red = Color(255,0,0)
    local a = false
    local reason
    function shitbanned()
        if a then return end a = true
        if IsValid(LocalPlayer()) then lp = LocalPlayer() end
        hook.Add("HUDPaint","ulx_rb_shitban",function()
            if lp and getnwbool(lp,"shitbanned") then
                local time = getnwint(lp,"shitbanned_time",0)
                if time == -1 then
                    time = "perma :|"
                else
                    time = ULib.secondsToStringTime(time)
                end
                drawTextRotated("shitbanned! | " .. lp:SteamID(),"BudgetLabel",ScrW() / 2,ScreenScaleH(32),color_red,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,math.sin(CurTime() * math.pi * 0.1) * 6,1.75 + math.cos(CurTime() * math.pi) * 0.05,1.75 + math.sin(CurTime() * math.pi) * 0.2)
                drawTextRotated(time,"BudgetLabel",ScrW() / 2,ScreenScaleH(52),color_red,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,math.cos(CurTime() * math.pi * 0.1) * 6,1.75 + math.sin(CurTime() * math.pi) * 0.05,1.75 + math.cos(CurTime() * math.pi) * 0.2)
                if reason then
                    drawTextRotated(reason,"BudgetLabel",ScrW() / 2,ScreenScaleH(72),color_red,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,math.sin(CurTime() * math.pi * 0.5) * 4,2 + math.cos(CurTime() * math.pi) * 0.2,2 + math.sin(CurTime() * math.pi) * 0.15)
                end
            end
        end)
    end
    net.Receive("shitban_reason",function()
        reason = net.ReadString()
    end)
else
    util.AddNetworkString("shitban_reason")
end

hook.Add("StartCommand","ulx_rb_shitban",function(ply,cmd)
    if getnwbool(ply,"shitbanned") then
        cmd:RemoveKey(IN_SPEED)
        if CLIENT then shitbanned() end
    end
end,HOOK_MONITOR_HIGH)

hook.Add("Tick","ulx_rb_shitban",function()
    for _,ply in player.Iterator() do
        if ulx.shitbanned[steamid(ply)] then
            shiton(ply)
        end
    end
end,HOOK_MONITOR_HIGH)

hook.Add("PlayerNoClip","ulx_rb_shitban",function(ply, desiredState)
    if ulx.shitbanned[steamid(ply)] then
        return not desiredState
    end
end,HOOK_HIGH)

local vehicledmgfix = function(veh)
    if not veh:IsVehicle() --[[fuck this bullshit, why?]] then return veh end
    local driver = getdriver(veh)
    if isvalid(driver) then
        return driver
    end
    return veh
end

hook.Add("EntityTakeDamage","ulx_rb_shitban",function(_, dmg)
    local att = getatt(dmg)
    if isvalid(att) then
        att = vehicledmgfix(att) or att
        if isply(att) and ulx.shitbanned[steamid(att)] then
            scaledmg(dmg,0.01)
        end
    end
end,HOOK_MONITOR_HIGH)

hook.Add("PlayerCanPickupWeapon","ulx_rb_shitban",function(ply,wep)
    if isvalid(wep) and ulx.shitbanned[steamid(ply)] then
        local class = getclass(wep)
        return class == "weapon_physgun" or class == "gmod_tool" or class == "weapon_crowbar"
    end
end,HOOK_HIGH)

hook.Add("CanTool","ulx_rb_shitban",function(ply)
    if getnwbool(ply,"shitbanned") then return false end
end,HOOK_HIGH)

hook.Add("CanArmDupe","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnObject","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerCheckLimit","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerGiveSWEP","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnSWEP","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnProp","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnSENT","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnRagdoll","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnNPC","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("PlayerSpawnEffect","ulx_rb_shitban",function(ply)
    if ulx.shitbanned[steamid(ply)] then return false end
end,HOOK_HIGH)

hook.Add("ShouldCollide","ulx_rb_shitban",function(a,b)
    if isply(a) and isply(b) then
        if getnwbool(a,"shitbanned") or getnwbool(b,"shitbanned") then return false end
    end
end,HOOK_HIGH)

hook.Add("PhysgunPickup","ulx_rb_shitban",function(a)
    if getnwbool(a,"shitbanned") then return false end
end,HOOK_HIGH)

if SERVER then
    -- https://github.com/TeamUlysses/ulib/blob/147657e31a15bdcc5b5fec89dd9f5650aebeb54a/lua/ulib/server/bans.lua#L17-L51
    ulx.ShitBanMessage = [[
    -------===== [ SHITBANNED ] =====-------

    ---= Reason =---
    {{REASON}}

    ---= Time Left =---
    {{TIME_LEFT}} ]]

    function ulx.getShitBanMessage( steamid, banData, templateMessage )
    	banData = banData or ulx.shitbanned[ steamid ]
    	if not banData then return end
    	templateMessage = templateMessage or ulx.ShitBanMessage

    	local replacements = {
    		BANNED_BY = "(Unknown)",
    		BAN_START = "(Unknown)",
    		REASON = "(None given)",
    		TIME_LEFT = "(Permaban)",
    		STEAMID = steamid,
    		STEAMID64 = util.SteamIDTo64( steamid ),
    	}

    	if banData.admin and banData.admin ~= "" then
    		replacements.BANNED_BY = banData.admin
    	end

    	local time = tonumber( banData.time )
    	if time and time > 0 then
    		replacements.BAN_START = os.date( "%c", time )
    	end

    	if banData.reason and banData.reason ~= "" then
    		replacements.REASON = banData.reason
    	end

    	local unban = tonumber( banData.unban )
    	if unban and unban > 0 then
    		replacements.TIME_LEFT = ULib.secondsToStringTime( unban - os.time() )
    	end

      	local banMessage = templateMessage:gsub( "{{([%w_]+)}}", replacements )
    	return banMessage
    end

    hook.Add("PlayerInitialSpawn","ulx_rb_shitban",function(ply)
        if ulx.shitbanned[steamid(ply)] then
            ply:ChatPrint(ulx.getShitBanMessage(steamid(ply)))
            local t = ulx.shitbanned[steamid(ply)]
            if t.reason then
                net.Start("shitban_reason")
                net.WriteString(t.reason)
                net.Send(ply,true)
            end
        end
    end)

    hook.Add("PlayerSpawn","ulx_rb_shitban",function(ply)
        ply:EnableCustomCollisions()
        if ulx.shitbanned[steamid(ply)] then
            ply:CollisionRulesChanged()
        end
    end)


    -- let's add shitban to ULib table cuz i am retarded!11!!!
    -- nah,ulx table
    -- https://github.com/TeamUlysses/ulib/blob/147657e31a15bdcc5b5fec89dd9f5650aebeb54a/lua/ulib/server/bans.lua#L106-L126

    local function escapeOrNull( str )
    	if not str then return "NULL"
    	else return sql.SQLStr(str) end
    end

    local function writeBan( bandata )
    	sql.Query(
    		"REPLACE INTO rb_shitbans (steamid, time, unban, reason, name, admin, modified_admin, modified_time) " ..
    		string.format( "VALUES (%s, %i, %i, %s, %s, %s, %s, %s)",
    			util.SteamIDTo64( bandata.steamID ),
    			bandata.time or 0,
    			bandata.unban or 0,
    			escapeOrNull( bandata.reason ),
    			escapeOrNull( bandata.name ),
    			escapeOrNull( bandata.admin ),
    			escapeOrNull( bandata.modified_admin ),
    			escapeOrNull( bandata.modified_time )
    		)
    	)
    end

    -- copied from ULib.addBan
    -- https://github.com/TeamUlysses/ulib/blob/147657e31a15bdcc5b5fec89dd9f5650aebeb54a/lua/ulib/server/bans.lua#L147
    -- credit whoever wrote this function please
    function ulx.addshitban(steamid,time,reason,name,admin)
        if reason == "" then reason = nil end

    	local admin_name
    	if admin then
    		if isstring(admin) then
    			admin_name = admin
    		elseif not IsValid(admin) then
    			admin_name = "(Console)"
    		elseif admin:IsPlayer() then
    			admin_name = string.format("%s(%s)", admin:Name(), admin:SteamID())
    		end
    	end

    	-- Clean up passed data
    	local t = {}
    	local timeNow = os.time()
    	if ulx.shitbanned[ steamid ] then
    		t = ulx.shitbanned[ steamid ]
    		t.modified_admin = admin_name
    		t.modified_time = timeNow
    	else
    		t.admin = admin_name
    	end
    	t.time = t.time or timeNow
    	if time > 0 then
    		t.unban = ( ( time * 60 ) + timeNow )
    	else
    		t.unban = 0
    	end
    	t.reason = reason
    	t.name = name
    	t.steamID = steamid

        writeBan(t)
    	ulx.shitbanned[ steamid ] = t
        xgui.shitbans_processBans()
    end

    -- https://github.com/TeamUlysses/ulib/blob/147657e31a15bdcc5b5fec89dd9f5650aebeb54a/lua/ulib/server/bans.lua#L221-L253
    function ulx.iunshitban( steamid, admin )
        if ulx.shitbanned[steamid] then
            local ply = player.GetBySteamID(steamid)
            if isvalid(ply) then
                ply:ChatPrint("You have been unshitbanned!")
                spawn(ply)
                setnwbool(ply,"shitbanned",false)
            end
        end
    	ulx.shitbanned[steamid] = nil
    	sql.Query( "DELETE FROM rb_shitbans WHERE steamid=" .. util.SteamIDTo64( steamid ) )
        xgui.shitbans_processBans()
    end

    local function nilIfNull(data)
    	if data == "NULL" then return nil
    	else return data end
    end

    -- Init our bans table
    if not sql.TableExists( "rb_shitbans" ) then
    	sql.Query( "CREATE TABLE IF NOT EXISTS rb_shitbans ( " ..
    		"steamid INTEGER NOT NULL PRIMARY KEY, " ..
    		"time INTEGER NOT NULL, " ..
    		"unban INTEGER NOT NULL, " ..
    		"reason TEXT, " ..
    		"name TEXT, " ..
    		"admin TEXT, " ..
    		"modified_admin TEXT, " ..
    		"modified_time INTEGER " ..
    		");" )
    	sql.Query( "CREATE INDEX IDX_ULIB_RBBANS_TIME ON rb_shitbans ( time DESC );" )
    	sql.Query( "CREATE INDEX IDX_ULIB_RBBANS_UNBAN ON rb_shitbans ( unban DESC );" )
    end

    function ulx.refreshshitbans()
    	local results = sql.Query( "SELECT * FROM rb_shitbans" )

    	ulx.shitbanned = {}
    	if results then
    		for i=1, #results do
    			local r = results[i]

    			r.steamID = util.SteamIDFrom64( r.steamid )
    			r.steamid = nil
    			r.reason = nilIfNull( r.reason )
    			r.name = nilIfNull( r.name )
    			r.admin = nilIfNull( r.admin )
    			r.modified_admin = nilIfNull( r.modified_admin )
    			r.modified_time = nilIfNull( r.modified_time )
    			ulx.shitbanned[r.steamID] = r
    		end
    	end
    end
    hook.Add( "Initialize", "rb_shitbans", ulx.refreshshitbans, HOOK_MONITOR_HIGH )

    ulx.refreshshitbans()
    timer.Create("rb_unshitbans",10,0,function()
        for id, ban in pairs(ulx.shitbanned) do
            if tonumber(ban.unban) ~= 0 and tonumber(ban.unban) <= os.time() then ulx.iunshitban(id) end
        end
    end)

    local nextrefresh = 0
    function rb_refreshbans()
        timer.Adjust("rb_unshitbans",0)
        timer.Adjust("rb_refreshbans",0)
        nextrefresh = 0
    end
    timer.Create("rb_refreshbans",1,0,function()
        if nextrefresh > CurTime() then return end
        nextrefresh = CurTime() + 15
        local lookup = {}
        for _,ply in player.Iterator() do
            lookup[steamid(ply)] = ply
        end
        for id, ban in pairs(ulx.shitbanned) do
            if lookup[id] and ban.reason then
                net.Start("shitban_reason")
                net.WriteString(ban.reason)
                net.Send(lookup[id],true)
            end
        end
    end)
end

local CATEGORY_NAME = "NIL UTILS"
-- https://github.com/TeamUlysses/ulx/blob/07aafe3748f9d6c2fa70b67564eb5d8daae45f4b/lua/ulx/modules/sh/util.lua#L86-L169
function ulx.shitban( calling_ply, target_ply, minutes, reason )
	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A shitbanned #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
    ulx.addshitban(target_ply:SteamID(), minutes, reason,target_ply:Nick(), calling_ply)
    rb_refreshbans()
    target_ply:EnableCustomCollisions()
    target_ply:CollisionRulesChanged()
end
local shitban = ulx.command( CATEGORY_NAME, "ulx shitban", ulx.shitban, "!shitban", false, false, true )
shitban:addParam{ type=ULib.cmds.PlayerArg }
shitban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
shitban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
shitban:defaultAccess( ULib.ACCESS_ADMIN )
shitban:help( "Make target unable to play the game normally." )

------------------------------ BanID ------------------------------
function ulx.shitbanid( calling_ply, steamid, minutes, reason )
	steamid = steamid:upper()
	if (not ULib.isValidSteamID( steamid )) and steamid ~= "BOT" then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	local name, target_ply
	local plys = player.GetAll()
	for i=1, #plys do
		if plys[ i ]:SteamID() == steamid then
			target_ply = plys[ i ]
            target_ply:EnableCustomCollisions()
            target_ply:CollisionRulesChanged()
			name = target_ply:Nick()
			break
		end
	end

	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A shitbanned steamid #s "
	displayid = steamid
	if name then
		displayid = displayid .. "(" .. name .. ") "
	end
	str = str .. time
	if reason and reason ~= "" then str = str .. " (#4s)" end
	ulx.fancyLogAdmin( calling_ply, str, displayid, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ulx.addshitban, steamid, minutes, reason, name, calling_ply )
end
local shitbanid = ulx.command( CATEGORY_NAME, "ulx shitbanid", ulx.shitbanid, "!shitbanid", false, false, true )
shitbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
shitbanid:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
shitbanid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
shitbanid:defaultAccess( ULib.ACCESS_ADMIN )
shitbanid:help( "Make target(SteamID) unable to play the game normally." )

function ulx.unshitban( calling_ply, steamid )
	steamid = steamid:upper()
    if (not ULib.isValidSteamID( steamid )) and steamid ~= "BOT" then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	name = ULib.bans[ steamid ] and ULib.bans[ steamid ].name

	ulx.iunshitban( steamid, calling_ply )
	if name then
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid .. " (" .. name .. ")" )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid )
	end
end
local unshitban = ulx.command( CATEGORY_NAME, "ulx unshitban", ulx.unshitban, "!unshitban", false, false, true )
unshitban:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
unshitban:defaultAccess( ULib.ACCESS_ADMIN )
unshitban:help( "Unshitbans steamid." )
