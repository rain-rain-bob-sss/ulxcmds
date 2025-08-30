if engine.ActiveGamemode() ~= "zombiesurvival" then return end
local CATEGORY_NAME = "Zombie Survival"
local function redeemHumans(callingPlayer)
	local players = player.GetAll()
	for _, player in ipairs(players) do
		if player:IsPlayer() and not player:IsBot() and player:Team() == TEAM_UNDEAD then player:Redeem() end
	end

	ulx.fancyLogAdmin(callingPlayer, "#A redeemed all human players")
end

-- ULX command to redeem all human players
local cmd = ulx.command(CATEGORY_NAME, "ulx redeemhumans", redeemHumans, "!redeemhumans")
cmd:defaultAccess(ULib.ACCESS_ADMIN)
cmd:help("Redeem all human players.")
local function teleportTeamToMe(callingPlayer, targetTeam)
	local players = team.GetPlayers(targetTeam)
	local destination = callingPlayer:GetPos()
	for _, player in ipairs(players) do
		player:SetPos(destination)
	end

	ulx.fancyLogAdmin(callingPlayer, "#A teleported team #s to their location", team.GetName(targetTeam))
end

local cmd = ulx.command(CATEGORY_NAME, "ulx tpzombies", function(callingPlayer) teleportTeamToMe(callingPlayer, TEAM_UNDEAD) end, "!tpzombies")
cmd:defaultAccess(ULib.ACCESS_ADMIN)
cmd:help("Teleport the undead team to the calling player's location.")
local cmd2 = ulx.command(CATEGORY_NAME, "ulx tphumans", function(callingPlayer) teleportTeamToMe(callingPlayer, TEAM_HUMAN) end, "!tphumans")
cmd2:defaultAccess(ULib.ACCESS_ADMIN)
cmd2:help("Teleport the human team to the calling player's location.")
function ulx.forceclass2(calling_ply, target_plys, className, respawn) --CONFLICT WITH D3BOT,RENAMED TO FORCECLASS2
	local affected = {}
	local fclass
	for classKey, class in ipairs(GAMEMODE.ZombieClasses) do
		if class.Name:lower() == className:lower() then fclass = class end
	end

	if not fclass then return end
	for i = 1, #target_plys do
		local ply = target_plys[i]
		local oclass = ply.DeathClass or ply:GetZombieClass()
		if ply:IsFrozen() then
			ULib.tsayError(calling_ply, ply:Nick() .. " is frozen!", true)
		elseif ply:Team() == TEAM_HUMAN then
			ULib.tsayError(calling_ply, ply:Nick() .. " is a human!", true)
		else
			local oldclass = ply.DeathClass or ply:GetZombieClass()
			local pos, ang = ply:GetPos(), ply:EyeAngles()
			ply:KillSilent()
			ply:SetZombieClassName(fclass.Name)
			ply.DeathClass = nil
			ply:DoHulls(fclass.Index, TEAM_UNDEAD)
			ply:UnSpectateAndSpawn()
			ply.DeathClass = oclass
			table.insert(affected, ply)
			if not respawn then
				ply:SetPos(pos)
				ply:SetEyeAngles(ang)
			end
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A forced #T to class #s", affected, className)
end

local forceclass = ulx.command(CATEGORY_NAME, "ulx forceclass2", ulx.forceclass2, "!forceclass2")
forceclass:addParam{
	type = ULib.cmds.PlayersArg
}

local FORCECLASS_COMPLETES = {}
forceclass:addParam{
	type = ULib.cmds.StringArg,
	hint = "Classname",
	completes = FORCECLASS_COMPLETES,
}

forceclass:addParam{
	type = ULib.cmds.BoolArg,
	hint = "Respawn",
	ULib.cmds.takeRestOfLine
}

timer.Create("Refresh FORCECLASS_COMPLETES", 0.5, 1, function()
	table.Empty(FORCECLASS_COMPLETES)
	for classKey, class in ipairs(GAMEMODE.ZombieClasses) do
		FORCECLASS_COMPLETES[#FORCECLASS_COMPLETES + 1] = class.Name
	end
	table.sort(FORCECLASS_COMPLETES,function(a,b) return b>a end)
end)

forceclass:defaultAccess(ULib.ACCESS_ADMIN)
forceclass:help("Sets the selected players to a zombie class! This function is case sensitive.")
function ulx.setwave(calling_ply, wave)
	if wave then
		GAMEMODE:SetWave(wave)
		ulx.fancyLogAdmin(calling_ply, "#A set the wave to #s", wave)
	end
end

local setwave = ulx.command(CATEGORY_NAME, "ulx setwave", ulx.setwave, "!setwave")
setwave:addParam{
	type = ULib.cmds.NumArg,
	min = 0,
	default = 0,
	hint = "wave",
	ULib.cmds.round
}

function ulx.setmaxwave(calling_ply, wave)
	if wave then
		SetGlobalInt("numwaves", wave)
		ulx.fancyLogAdmin(calling_ply, "#A set the max wave to #s", wave)
	end
end

local setmaxwave = ulx.command(CATEGORY_NAME, "ulx setmaxwave", ulx.setmaxwave, "!setmaxwave")
setmaxwave:addParam{
	type = ULib.cmds.NumArg,
	min = 1,
	default = 6,
	hint = "max wave",
	ULib.cmds.round
}
setmaxwave:defaultAccess(ULib.ACCESS_ADMIN)


setwave:defaultAccess(ULib.ACCESS_ADMIN)
setwave:help("Set the wave.")
function ulx.setwavetime(calling_ply, time)
	if not GAMEMODE:GetWaveActive() then
		GAMEMODE:SetWaveStart(CurTime() + time)
	else
		GAMEMODE:SetWaveEnd(CurTime() + time)
	end

	ulx.fancyLogAdmin(calling_ply, "#A set the wave time to #s", time)
end

local setwavetime = ulx.command(CATEGORY_NAME, "ulx setwavetime", ulx.setwavetime, "!setwavetime")
setwavetime:addParam{
	type = ULib.cmds.NumArg,
	min = 0,
	default = 0,
	hint = "time",
	ULib.cmds.round
}

setwavetime:defaultAccess(ULib.ACCESS_ADMIN)
setwavetime:help("Add more time to the current wave or the start time of wave 0.")
function ulx.restartmap(calling_ply)
	ulx.fancyLogAdmin(calling_ply, "#A restarted the map.")
	RunConsoleCommand("changelevel",game.GetMap())
end

local restartmap = ulx.command(CATEGORY_NAME, "ulx restartmap", ulx.restartmap, "!restartmap")
restartmap:defaultAccess(ULib.ACCESS_ADMIN)
restartmap:help("Reloads the level.")
function ulx.restartround(calling_ply)
	timer.Simple(0, function() gamemode.Call("PreRestartRound") end)
	timer.Simple(1, function() gamemode.Call("RestartRound") end)
	ulx.fancyLogAdmin(calling_ply, "#A restarted round.")
end

local restartround = ulx.command(CATEGORY_NAME, "ulx restartround", ulx.restartround, "!restartround")
restartround:defaultAccess(ULib.ACCESS_ADMIN)
restartround:help("Restart round.")

local ammoCompletes = {}

timer.Simple(1,function()
	for i,v in ipairs(game.GetAmmoTypes()) do 
		table.insert(ammoCompletes,v)
	end
	table.sort(ammoCompletes,function(a,b) return a < b end)
end)

--Give Ammo--
function ulx.giveammo(calling_ply, target_plys, amount, ammotype)

	if IsValid(calling_ply) then
		local wep = calling_ply:GetActiveWeapon()
		if IsValid(wep) then
			if ammotype == "current1" then 
				ammotype = wep:GetPrimaryAmmoType()
			elseif ammotype == "current2" then 
				ammotype = wep:GetSecondaryAmmoType()
			end
		end
	end

	local a = game.GetAmmoTypes()

	local oammotype = ammotype
	ammotype = isstring(ammotype) and game.GetAmmoID(ammotype) or ammotype
	if not a[ammotype] then 
		ULib.tsayError(calling_ply, "ammo " .. oammotype .. " doesn't exist!", true)
		return
	end
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if v:IsValid() and v:Alive() then --[[and v:Team() == TEAM_HUMAN]]
			v:GiveAmmo(amount, oammotype)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #s #s ammo to #T", amount, game.GetAmmoName(ammotype) or ammotype, target_plys)
end

local giveammo = ulx.command(CATEGORY_NAME, "ulx giveammo", ulx.giveammo, "!giveammo")
giveammo:addParam{
	type = ULib.cmds.PlayersArg
}

giveammo:addParam{
	type = ULib.cmds.NumArg,
	hint = "Ammo Amount"
}

giveammo:addParam{
	type = ULib.cmds.StringArg,
	hint = "Ammo Type",
	completes = ammoCompletes
}

giveammo:defaultAccess(ULib.ACCESS_ADMIN)
giveammo:help("Gives the specified ammo to the target player(s).")

--Heal--
function ulx.healplayer(calling_ply, target_plys, amount)

	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if v:IsValid() and v:Alive() and v:Team() == TEAM_HUMAN then
			v:HealPlayer(calling_ply,amount)
			table.insert(affected_plys,v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A healed #T(AMOUNT: #s)",affected_plys,amount)
end

local healplayer = ulx.command(CATEGORY_NAME, "ulx healplayer", ulx.healplayer, "!heal")
healplayer:addParam{
	type = ULib.cmds.PlayersArg
}

healplayer:addParam{
	type = ULib.cmds.NumArg,
	hint = "Amount"
}

healplayer:defaultAccess(ULib.ACCESS_ADMIN)
healplayer:help("Heal target(s). - !heal")

--Give Points--
function ulx.givepoints(calling_ply, target_plys, amount)
	for i = 1, #target_plys do
		target_plys[i]:AddPoints(amount)
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #i points to #T", amount, target_plys)
end

local takepoints = ulx.command(CATEGORY_NAME, "ulx givepoints", ulx.givepoints, "!givepoints")
takepoints:addParam{
	type = ULib.cmds.PlayersArg
}

takepoints:addParam{
	type = ULib.cmds.NumArg,
	hint = "points",
	ULib.cmds.round
}

takepoints:defaultAccess(ULib.ACCESS_ADMIN)
takepoints:help("Gives points to target(s).")
function ulx.givexp(calling_ply, target_plys, amount)
	for i = 1, #target_plys do
		target_plys[i]:AddZSXP(amount)
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #i XP to #T", amount, target_plys)
end

local givexp = ulx.command(CATEGORY_NAME, "ulx givexp", ulx.givexp, "!givexp")
givexp:addParam{
	type = ULib.cmds.PlayersArg
}

givexp:addParam{
	type = ULib.cmds.NumArg,
	hint = "xp",
	ULib.cmds.round
}

givexp:defaultAccess(ULib.ACCESS_ADMIN)
givexp:help("Gives XP to target(s).")

local itemCompletes = {}
timer.Simple(1,function()
	for type,_ in pairs(GAMEMODE.ZSInventoryItemData) do
		if isnumber(type) then continue end
		itemCompletes[#itemCompletes + 1] = type
	end
	table.sort(itemCompletes,function(a,b)
		return b>a
	end)
end)

--Give Item--
function ulx.giveitem(calling_ply, target_plys, type)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if v:Alive() and v:Team() == TEAM_HUMAN then
			v:AddInventoryItem(type)
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #T item: #s", affected_plys, type)
end

local giveitem = ulx.command(CATEGORY_NAME, "ulx giveitem", ulx.giveitem, "!giveitem")
giveitem:addParam{
	type = ULib.cmds.PlayersArg
}

giveitem:addParam{
	type = ULib.cmds.StringArg,
	hint = "comp_sawblade",
	completes = itemCompletes,
	ULib.cmds.takeRestOfLine
}

giveitem:defaultAccess(ULib.ACCESS_ADMIN)
giveitem:help("Give a player a item - !giveitem")

function ulx.weaponComplete( ply, args )
	local targs = string.Trim( args )
	local List = {}

	local maxResults = 100
	for _, SWEP in ipairs( weapons.GetList() ) do
		if #List > maxResults then break end
		if SWEP.QualityTier and SWEP.QualityTier >= 1 then continue end
		if targs:len() == 0 or SWEP.ClassName:sub( 1, targs:len() ) == targs then
			table.insert(List, SWEP.ClassName)
		end
	end

	table.sort(List,function(a,b)
		return a < b 
	end)

	return List
end

local weaponCompletes = {}
timer.Simple(1,function() table.Empty(weaponCompletes) for i,v in pairs(ulx.weaponComplete(_,"")) do weaponCompletes[i] = v end end)

--Give Weapon--
function ulx.giveweapon(calling_ply, target_plys, weapon)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if not v:Alive() then
			--ULib.tsayError(calling_ply, v:Nick() .. " is dead", true)
		else
			v:Give(weapon)
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #T weapon #s", affected_plys, weapon)
end

local giveweapon = ulx.command(CATEGORY_NAME, "ulx giveweapon", ulx.giveweapon, "!giveweapon")
giveweapon:addParam{
	type = ULib.cmds.PlayersArg
}

giveweapon:addParam{
	type = ULib.cmds.StringArg,
	hint = "weapon_zs_crowbar",
	autocomplete_fn = ulx.weaponComplete,
	completes = weaponCompletes,
	ULib.cmds.takeRestOfLine
}

giveweapon:defaultAccess(ULib.ACCESS_ADMIN)
giveweapon:help("Give a player a weapon - !giveweapon")
function ulx.forcegiveweapon(calling_ply, target_plys, weapon)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if not v:Alive() then
			--ULib.tsayError(calling_ply, v:Nick() .. " is dead", true)
		else
			local ent = ents.Create(weapon)
			if not IsValid(ent) then ULib.tsayError(calling_ply, "This weapon does not exist!", true) break end
			ent:SetPos(v:GetPos())
			ent:Spawn()
			ent:Activate()
			if ent.ZombieOnly then
				local old = ent.Holster
				function ent:Holster(...) --ALLOW HOLSTER!
					old(...)
					return true
				end
			end
			v:PickupWeapon(ent)
			v:SelectWeapon(weapon)
			v:SetActiveWeapon(v:GetWeapon(weapon))
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A force gave #T weapon #s", affected_plys, weapon)
end

local forcegiveweapon = ulx.command(CATEGORY_NAME, "ulx forcegiveweapon", ulx.forcegiveweapon, "!forcegiveweapon")
forcegiveweapon:addParam{
	type = ULib.cmds.PlayersArg
}

forcegiveweapon:addParam{
	type = ULib.cmds.StringArg,
	hint = "weapon_zs_nightmare",
	autocomplete_fn = ulx.weaponComplete,
	completes = weaponCompletes,
	ULib.cmds.takeRestOfLine
}

forcegiveweapon:defaultAccess(ULib.ACCESS_ADMIN)
forcegiveweapon:help("Force(Ignore limits,example: zombie only weapons) Give a player a weapon - !forcegiveweapon")
--Redeem Player--
function ulx.redeem(calling_ply, target_plys)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if ulx.getExclusive(v, calling_ply) then
			ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
		elseif v:Team() ~= TEAM_UNDEAD then
			--ULib.tsayError(calling_ply, v:Nick() .. " is human!", true)
		else
			v:Redeem()
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A redeemed #T", affected_plys)
end

local redeem = ulx.command(CATEGORY_NAME, "ulx redeem", ulx.redeem, "!redeem")
redeem:addParam{
	type = ULib.cmds.PlayersArg
}

redeem:defaultAccess(ULib.ACCESS_ADMIN)
redeem:help("Redeems target(s).")

--Redeem Player--
function ulx.fredeem(calling_ply, target_plys)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if ulx.getExclusive(v, calling_ply) then
			ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
		else
			v:Redeem()
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A force redeemed #T", affected_plys)
end

local fredeem = ulx.command(CATEGORY_NAME, "ulx fredeem", ulx.fredeem, "!fredeem")
fredeem:addParam{
	type = ULib.cmds.PlayersArg
}

fredeem:defaultAccess(ULib.ACCESS_ADMIN)
fredeem:help("Force redeems target(s).")

--Wave Active--
function ulx.waveactive(calling_ply, state)
	GAMEMODE:SetWaveActive(state)
end

local waveactive = ulx.command(CATEGORY_NAME, "ulx waveactive", ulx.waveactive, "!waveactive")
waveactive:addParam{
	type = ULib.cmds.BoolArg,
	hint = "Wave Active"
}

waveactive:defaultAccess(ULib.ACCESS_ADMIN)
waveactive:help("Sets the current wave to active or inactive")
--Force Boss--
function ulx.forceboss(calling_ply, target_plys)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if v:IsFrozen() then
			ULib.tsayError(calling_ply, v:Nick() .. " is frozen!", true)
		elseif v:Team() == TEAM_HUMAN then
			ULib.tsayError(calling_ply, v:Nick() .. " is a human!", true)
		else
			GAMEMODE:SpawnBossZombie(v)
			table.insert(affected_plys, v)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A forced #T to be boss.", affected_plys)
end

local forceboss = ulx.command(CATEGORY_NAME, "ulx forceboss", ulx.forceboss, "!forceboss")
forceboss:addParam{
	type = ULib.cmds.PlayersArg
}

forceboss:defaultAccess(ULib.ACCESS_ALL)
forceboss:help("Sets target(s) as boss.")
function ulx.forceteam(caller, targets, teamName)
	local teams = {
		bandit = TEAM_UNDEAD, --WHAT THE FUCK!
		human = TEAM_SURVIVOR,
		humans = TEAM_SURVIVOR,
		zombie = TEAM_UNDEAD,
		undead = TEAM_UNDEAD,
		zombies = TEAM_UNDEAD,
		undeads = TEAM_UNDEAD,
		survivor = TEAM_SURVIVOR,
		survivors = TEAM_SURVIVOR,
	}

	local affected = {}
	local teamIndex = teams[teamName]
	if not teamIndex then return end
	for i = 1, #targets do
		local target = targets[i]
		if target:Team() ~= teamIndex then
			target:SetTeam(teamIndex)
			table.insert(affected, target)
		end
	end

	ulx.fancyLogAdmin(caller, "#A made #T join #s", affected, team.GetName(teamIndex))
end

local forceteam = ulx.command(CATEGORY_NAME, "ulx forceteam", ulx.forceteam, "!forceteam")
forceteam:addParam{
	type = ULib.cmds.PlayersArg
}

forceteam:addParam{
	type = ULib.cmds.StringArg,
	hint = "team",
	completes = {"zombie", "humans"},
}

forceteam:defaultAccess(ULib.ACCESS_ADMIN)
forceteam:help("FORCE TEAM(DANGEROUS!)")
function ulx.endround(caller, winner)
	local teams = {
		bandit = TEAM_UNDEAD, --WHAT THE FUCK, AGAIN!
		human = TEAM_SURVIVOR,
		humans = TEAM_SURVIVOR,
		zombie = TEAM_UNDEAD,
		undead = TEAM_UNDEAD,
		zombies = TEAM_UNDEAD,
		undeads = TEAM_UNDEAD,
		survivor = TEAM_SURVIVOR,
		survivors = TEAM_SURVIVOR,
	}

	local team = teams[winner]
	if not team then return end
	GAMEMODE:EndRound(team)
	ulx.fancyLogAdmin(caller, "#A made #s won this round.", winner)
end

local endround = ulx.command(CATEGORY_NAME, "ulx endround", ulx.endround, "!endround")
endround:addParam{
	type = ULib.cmds.StringArg,
	hint = "winner",
	completes = {"zombie", "humans"},
}

endround:defaultAccess(ULib.ACCESS_ADMIN)
endround:help("End Round.")

--FRIENDLY FIRE MODE--
--aka pvp mode--


--FIX BULLETS HIT
--AND MELEE TRACES
--yes,this overrides Entity:FireBulletsLua and Player:MeleeTrace

--This should be correct.
--I hope it is correct and doesn't break anything.
function PlayerCanDamageTeam(att,vic)
	--Why NWBool? Because prediction. Haha, source engine bullcrap
	if GetGlobalBool("zs_rb_1_friendlyfiremode") then return true end
	if not IsValid(att) then return vic:GetNWBool("AllowTeamDamage") end
	if not IsValid(vic) then return att:GetNWBool("AllowTeamDamage") end
	return att:GetNWBool("AllowTeamDamage") or vic:GetNWBool("AllowTeamDamage")
end

function PlayerZSDamageTeam(att,vic)
	if not IsValid(att) then return vic:GetNWBool("AllowTeamDamage") end
	if not IsValid(vic) then return att:GetNWBool("AllowTeamDamage") end
	return att:GetNWBool("AllowTeamDamage") or vic:GetNWBool("AllowTeamDamage")
end

--This runs before gamemode caches it.
local meta = FindMetaTable("Player")
meta.OldTeam_ZS_RB_1 = meta.OldTeam_ZS_RB_1 or meta.Team
local overrideteam
function meta:Team(...)
	if overrideteam and self ~= MySelf then return overrideteam end
	return self:OldTeam_ZS_RB_1(...)
end

local function DelayedChangeToZombie(pl)
	if pl:IsValid() then
		if pl.ChangeTeamFrags then
			pl:SetFrags(pl.ChangeTeamFrags)
			pl.ChangeTeamFrags = 0
		end

		pl:ChangeTeam(TEAM_UNDEAD)
	end
end

hook.Add("Initialize","ZS_RB_1_FRIENDLYFIREMODE_FIXBULLETS",function()
	local meta = FindMetaTable("Player")
	meta.OldMeleeTrace_ZS_RB_1 = meta.OldMeleeTrace_ZS_RB_1 or meta.MeleeTrace
	function meta:MeleeTrace(distance, size, start, dir, hit_team_members, override_team, override_mask, ...)
		hit_team_members = hit_team_members or PlayerCanDamageTeam(self)
		return self:OldMeleeTrace_ZS_RB_1(distance, size, start, dir, hit_team_members, override_team, override_mask, ...)
	end
	
	local P_Team = meta.Team
	meta.OldShouldNotCollide_ZS_RB_1 = meta.OldShouldNotCollide_ZS_RB_1 or meta.ShouldNotCollide
	function meta:ShouldNotCollide(ent,...)
		if getmetatable(ent) == meta then
			if P_Team(self) == P_Team(ent) and PlayerCanDamageTeam(self,ent) then --We shall collide because we're "enemies" now.
				return false
			end
		end
		return self:OldShouldNotCollide_ZS_RB_1(ent,...)
	end

	local GM = GAMEMODE
	if CLIENT then
		local old_PrePlayerDraw = GM._PrePlayerDraw
		function GM:_PrePlayerDraw(pl,...)
			if P_Team(pl) == P_Team(MySelf) and PlayerCanDamageTeam(MySelf,pl) then
				overrideteam = 99999
			end
			local r = old_PrePlayerDraw(self,pl,...)
			overrideteam = nil
			return r
		end
	else
		local old_EntityTakeDamage = GM.EntityTakeDamage
		function GM:EntityTakeDamage(ent, dmginfo,...)
			local result = old_EntityTakeDamage(self,ent,dmginfo,...)

			local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
			if dmginfo:GetDamage() ~= 0 then
				if ent:IsPlayer() then
					local w = false
					if attacker.PBAttacker and attacker.PBAttacker:IsValid() then
						attacker = attacker.PBAttacker
					end

					if attacker:IsValid() and attacker:IsPlayer() and PlayerCanDamageTeam(attacker,ent) then
						ent:SetLastAttacker(attacker)

						local myteam = attacker:Team()
						local otherteam = ent:Team()

						if myteam == otherteam then
							local damage = math.min(dmginfo:GetDamage(), ent:Health())
							if damage > 0 then
								local time = CurTime()

								attacker.DamageDealt[myteam] = attacker.DamageDealt[myteam] + damage
								local points = damage / 100 * 15
								if POINTSMULTIPLIER then
									points = points * POINTSMULTIPLIER
								end
								if ent.PointsMultiplier then
									points = points * ent.PointsMultiplier
								end
								attacker.PointQueue = attacker.PointQueue + points

								GAMEMODE.StatTracking:IncreaseElementKV(STATTRACK_TYPE_WEAPON, inflictor:GetClass(), "PointsEarned", points)
								GAMEMODE.StatTracking:IncreaseElementKV(STATTRACK_TYPE_WEAPON, inflictor:GetClass(), "Damage", damage)

								local pos = ent:GetPos()
								pos.z = pos.z + 32
								attacker.LastDamageDealtPos = pos
								attacker.LastDamageDealtTime = time
							end
							w = not PlayerZSDamageTeam(attacker,ent) -- ZS ALLOWS DAMAGE NUMBER IF AllowTeamDamage is true,wow
						end
					end

					local dmg = dmginfo:GetDamage()
					if w and dmg > 0 then
						local dmgpos = dmginfo:GetDamagePosition()
						local hasdmgsess = attacker:IsPlayer() and attacker:HasDamageNumberSession()
						if not hasdmgsess then
							self:DamageFloater(attacker, ent, dmgpos, dmg)
						else
							attacker:CollectDamageNumberSession(dmg, dmgpos, ent:IsPlayer())
						end
					end
				end
			end
			
			return result
		end

		local old_DoPlayerDeath = GM.DoPlayerDeath
		function GM:DoPlayerDeath(pl, attacker, dmginfo,...)
			if attacker:IsPlayer() and pl:Team() == attacker:Team() and PlayerCanDamageTeam(attacker,pl) and pl:Team() == TEAM_HUMAN then 
				pl:RemoveEphemeralStatuses()
				pl:Extinguish()
				pl:SetPhantomHealth(0)
				pl:Freeze(false)
				pl:SetLastAttacker()

				local headshot = pl:WasHitInHead()

				local ct = CurTime()
				local suicide = attacker == pl or attacker:IsWorld()
				local plteam = pl:Team()

				if suicide then attacker = pl:GetLastAttacker() or attacker end

				pl:SetLastAttacker()

				if attacker.PBAttacker and attacker.PBAttacker:IsValid() then
					attacker = attacker.PBAttacker
				end

				if headshot then
					local effectdata = EffectData()
						effectdata:SetOrigin(dmginfo:GetDamagePosition())
						local force = dmginfo:GetDamageForce()
						effectdata:SetMagnitude(force:Length() * 3)
						effectdata:SetNormal(force:GetNormalized())
						effectdata:SetEntity(pl)
					util.Effect("headshot", effectdata, true, true)
				end

				if pl:Health() <= -70 and not pl.NoGibs and not self.ZombieEscape then
					pl:Gib(dmginfo)
				elseif not pl.KnockedDown then
					pl:CreateRagdoll()
				end

				pl.NextSpawnTime = ct + 4
				timer.Simple(0, function() DelayedChangeToZombie(pl) end) -- We don't want people shooting barrels near teammates.
				pl:PlayDeathSound()
				pl:DropAll()
				self.PreviouslyDied[pl:UniqueID()] = CurTime()
				if self:GetWave() == 0 then
					pl.DiedDuringWave0 = true
				end

				local frags = pl:Frags()
				if frags < 0 then
					pl.ChangeTeamFrags = math.ceil(frags / 5)
				else
					pl.ChangeTeamFrags = 0
				end

				if pl.SpawnedTime then
					pl.SurvivalTime = math.max(ct - pl.SpawnedTime, pl.SurvivalTime or 0)
					pl.SpawnedTime = nil
				end

				if team.NumPlayers(TEAM_HUMAN) <= 1 then
					self.LastHumanPosition = pl:WorldSpaceCenter()

					net.Start("zs_lasthumanpos")
						net.WriteVector(self.LastHumanPosition)
					net.Broadcast()
				end

				local hands = pl:GetHands()
				if IsValid(hands) then
					hands:Remove()
				end

				local inflictor = dmginfo:GetInflictor()

				if inflictor == NULL then inflictor = attacker end

				if inflictor == attacker and attacker:IsPlayer() then
					local wep = attacker:GetActiveWeapon()
					if wep:IsValid() then
						inflictor = wep
					end
				end

				net.Start("zs_pl_kill_pl")
					net.WriteEntity(pl)
					net.WriteEntity(attacker)
					net.WriteString(inflictor:GetClass())
					net.WriteUInt(plteam, 8)
					net.WriteUInt(attacker:Team(), 8)
					net.WriteBit(headshot)
				net.Broadcast()
				return
			end
			return old_DoPlayerDeath(self, pl, attacker, dmginfo,...)
		end
	end



	local meta = FindMetaTable("Entity") --THIS ISN'T ON PLAYER! THIS IS ON ENTITY METATABLE!!
	meta.OldFireBulletsLua_ZS_RB_1 = meta.OldFireBulletsLua_ZS_RB_1 or meta.FireBulletsLua
	function meta:FireBulletsLua(src, dir, spread, num, damage, attacker, force_mul, tracer, callback, hull_size, hit_own_team, max_distance, filter, inflictor)
		hit_own_team = hit_own_team or PlayerCanDamageTeam(self) or GAMEMODE:GetEndRound()
		return self:OldFireBulletsLua_ZS_RB_1(src, dir, spread, num, damage, attacker, force_mul, tracer, callback, hull_size, hit_own_team, max_distance, filter, inflictor)
	end
end)


function ulx.friendlyfire(calling_ply, state)
	local addhook = function(event,name,func)
		if state then hook.Add(event,name,func) else hook.Remove(event,name) end
	end

	addhook("PlayerShouldTakeDamage","ZS_RB_1_FRIENDLYFIREMODE",function(pl)
		return true
	end)
	SetGlobalBool("zs_rb_1_friendlyfiremode",state) --EVERYONE IS ALLOWED TO KILL TEAMMATES!!! CHAOS!!
	ulx.fancyLogAdmin(calling_ply, state and "#A enabled friendly fire" or "#A disabled friendly fire")
end

local friendlyfire = ulx.command(CATEGORY_NAME, "ulx friendlyfire", ulx.friendlyfire, "!friendlyfire")
friendlyfire:addParam{
	type = ULib.cmds.BoolArg,
	hint = "Enabled"
}

friendlyfire:defaultAccess(ULib.ACCESS_ADMIN)
friendlyfire:help("Enables Friendly Fire mode")

function ulx.friendlyfire2(calling_ply, plys, state)
	for i,v in pairs(plys) do 
		v.AllowTeamDamage = state
		v:SetNWBool("AllowTeamDamage",state) --PREDICTION
	end
	ulx.fancyLogAdmin(calling_ply, state and "#A enabled friendly fire on #T" or "#A disabled friendly fire on #T",plys)
end

local friendlyfire2 = ulx.command(CATEGORY_NAME, "ulx friendlyfire2", ulx.friendlyfire2, "!friendlyfire2")

friendlyfire2:addParam{
	type = ULib.cmds.PlayersArg
}

friendlyfire2:addParam{
	type = ULib.cmds.BoolArg,
	hint = "Enabled"
}

friendlyfire2:defaultAccess(ULib.ACCESS_ADMIN)
friendlyfire2:help("Enables Friendly Fire mode on target(s)")

function ulx.zskd(cp, p, n)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply:KnockDown(n) end
	end

	ulx.fancyLogAdmin(cp, "#A knock #T down for #i seconds", p, n)
end

function ulx.zsrm(cp, p, n)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply:SetZSRemortLevel(n) end
	end

	ulx.fancyLogAdmin(cp, "#A set #T's remort to #i", p, n)
end

function ulx.zsspm(cp, p, n)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply.PointIncomeMul = n end
	end

	ulx.fancyLogAdmin(cp, "#A set #T's point mul to #i", p, n)
end

function ulx.zsda(cp, p)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply:DropAll() end
	end

	ulx.fancyLogAdmin(cp, "#A made #T drop everything.", p)
end

local dumbtracee = {
	FractionLeftSolid = 0,
	HitNonWorld       = true,
	HitWorld = false,
	Fraction          = 0,
	Entity            = NULL,
	HitPos            = Vector(0, 0, 0),
	HitNormal         = Vector(0, 0, 0),
	HitBox            = 0,
	Normal            = Vector(1, 0, 0),
	Hit               = true,
	HitGroup          = 0,
	MatType           = 0,
	StartPos          = Vector(0, 0, 0),
	PhysicsBone       = 0,
	WorldToLocal      = Vector(0, 0, 0),
}
local function dumbtrace(entity, pos)
	if entity then 
		dumbtracee.Entity = entity 
		dumbtracee.HitNonWorld = entity ~= game.GetWorld()
		dumbtracee.HitWorld = not dumbtracee.HitNonWorld
	end
	if pos then dumbtracee.HitPos = pos end
	return dumbtracee
end

function ulx.zsfn(cp, call, unremoveable, nailtoworld, mul, str)
	if cp:IsValid() then
		local aimvec = cp:GetAimVector()
		local tr = cp:GetEyeTrace()
		local trent = tr.Entity
		if trent:IsValid() then
			local tr2 = util.TraceLine({
				start = tr.HitPos,
				endpos = tr.HitPos + aimvec * 24000,
				filter = table.Add({cp, trent}, GAMEMODE.CachedInvisibleEntities),
				mask = MASK_SOLID
			})

			if nailtoworld then 
				tr2 = dumbtrace(game.GetWorld(),tr.HitPos)
			end

			local tr2ent = tr2.Entity
			if tr2.HitWorld or tr2ent:IsValid() then
				local cons = constraint.Weld(trent, tr2ent, tr.PhysicsBone, tr2.PhysicsBone, 0, true)
				if cons ~= nil then
					for _, oldcons in pairs(constraint.FindConstraints(trent, "Weld")) do
						if oldcons.Ent1 == ent or oldcons.Ent2 == ent then
							cons = oldcons.Constraint
							break
						end
					end
				end

				if not cons and not trent:IsNailed() then return end
				local nail = ents.Create(str)
				if nail:IsValid() then
					nail:SetActualOffset(tr.HitPos, trent)
					nail:SetPos(tr.HitPos - aimvec * 8)
					nail:SetAngles(aimvec:Angle())
					nail.HealthMultiplier = mul
					nail:AttachTo(trent, tr2ent, tr.PhysicsBone, tr2.PhysicsBone)
					nail:Spawn()
					nail:SetDeployer(cp)
					if unremoveable then nail.m_NailUnremovable = true end
					if not trent:IsNailed() then cons:DeleteOnRemove(nail) end
					if call == true then gamemode.Call("OnNailCreated", trent, tr2ent, nail) end
					nail:EmitSound(string.format("weapons/melee/crowbar/crowbar_hit-%d.ogg", math.random(4)))
					ulx.fancyLogAdmin(cp, "#A force nailed a prop.")
				end
			end
		end
	end
end

function ulx.zsfrp(cp, health)
	if cp:IsValid() then
		local tr = cp:GetEyeTrace()
		local trent = tr.Entity
		if trent:IsValid() then
			local oh = trent:GetMaxBarricadeHealth()
			local old = trent:GetBarricadeHealth()
			local new = math.min(trent:GetMaxBarricadeHealth(), trent:GetBarricadeHealth() + health)
			trent:SetBarricadeHealth(new)
			local healed = new - old
			gamemode.Call("PlayerRepairedObject", cp, trent, healed, cp)
			local ed = EffectData()
			ed:SetOrigin(tr.HitPos)
			ed:SetNormal(tr.HitNormal)
			ed:SetMagnitude(1)
			util.Effect("nailrepaired", ed, true, true)
			ulx.fancyLogAdmin(cp, "#A force repaired a prop (REPAIRED: #s HP).",healed)
		end
	end
end

function ulx.zsd(cp, str, num, health)
	if cp:IsValid() then
		local gr = Angle(270, 0, 0)
		local yaw = cp:GetAngles().yaw
		local tr = util.TraceLine({
			start = cp:GetShootPos(),
			endpos = cp:GetShootPos() + cp:GetAimVector() * 60000,
			mask = MASK_SOLID_BRUSHONLY,
			collisiongroup = COLLISION_GROUP_NONE,
			ignoreworld = false,
			output = nil
		})

		local trn = tr.HitNormal
		local trp = tr.HitPos
		local ea = trn:Angle()
		ea:RotateAroundAxis(ea:Right(), gr.pitch)
		ea:RotateAroundAxis(ea:Up(), gr.yaw)
		ea:RotateAroundAxis(ea:Forward(), gr.roll)
		ea:RotateAroundAxis(ea["Up"](ea), cp:GetAngles().yaw)
		local obj = ents.Create(str)
		if obj:IsValid() then
			obj:SetPos(trp)
			obj:SetAngles(ea)
			obj.PreOwn = cp
			obj:Spawn()
			obj.MaxAmmo = num
			if health > 0 then
				pcall(function(n) obj:SetObjectMaxHealth(n) end, health)
				pcall(function(n) obj:SetObjectHealth(n) end, health)
			end

			pcall(function(n) obj:SetAmmo(n) end, num)
			pcall(function(n) obj:SetObjectOwner(n) end, cp)
			ulx.fancyLogAdmin(cp, "#A placed a deployable(#s).",str)
		end
	end
end

local zskd
zskd = ulx.command(CATEGORY_NAME, "ulx knockdown", ulx.zskd, "!zskd", true)
zskd:addParam{
	type = ULib.cmds.PlayersArg,
	default = "@",
	ULib.cmds.optional
}

zskd:addParam{
	type = ULib.cmds.NumArg,
	default = 69,
	hint = "Knockdown time"
}

zskd:help("Knockdown")
zskd:defaultAccess(ULib.ACCESS_ADMIN)
local zsda
zsda = ulx.command(CATEGORY_NAME, "ulx dropall", ulx.zsda, "!zsda", true)
zsda:addParam{
	type = ULib.cmds.PlayersArg,
	default = "^",
	ULib.cmds.optional
}

zsda:help("Makes target drop all wep and ammo and items")
zsda:defaultAccess(ULib.ACCESS_ADMIN)
local zsfn
zsfn = ulx.command(CATEGORY_NAME, "ulx forcenail", ulx.zsfn, "!zsnail", true)
zsfn:addParam{
	type = ULib.cmds.BoolArg,
	default = true,
	hint = "Call gamemode hook?",
	ULib.cmds.optional
}

zsfn:addParam{
	type = ULib.cmds.BoolArg,
	default = false,
	hint = "Unremoveable",
	ULib.cmds.optional
}

zsfn:addParam{
	type = ULib.cmds.BoolArg,
	default = true,
	hint = "Nail To World",
	ULib.cmds.optional
}


zsfn:addParam{
	type = ULib.cmds.NumArg,
	default = 1,
	hint = "Health mul",
	ULib.cmds.optional
}

zsfn:addParam{
	type = ULib.cmds.StringArg,
	hint = "prop_nail",
	default = "prop_nail",
	ULib.cmds.optional
}

zsfn:help("Force nail a prop.")
zsfn:defaultAccess(ULib.ACCESS_ADMIN)
local zsfrp
zsfrp = ulx.command(CATEGORY_NAME, "ulx forcerepair", ulx.zsfrp)
zsfrp:addParam{
	type = ULib.cmds.NumArg,
	min = 1,
	max = 99999999,
	default = 6900,
	hint = "Repair hp"
}

zsfrp:help("Force to repair the prop (Ignore max repair)")
zsfrp:defaultAccess(ULib.ACCESS_ADMIN)
local zsddps = {"prop_resupplybox", "prop_aegisboard", "prop_gunturret", "prop_gunturret_rocket", "prop_arsenalcrate", "prop_remantler", "prop_zapper", "prop_zapper_arc"}
local zsd
zsd = ulx.command(CATEGORY_NAME, "ulx placedeploy", ulx.zsd, "!zspd", true)
zsd:addParam{
	type = ULib.cmds.StringArg,
	completes = zsddps,
	hint = "prop_gunturret"
}

zsd:addParam{
	type = ULib.cmds.NumArg,
	hint = "Ammo"
}

zsd:addParam{
	type = ULib.cmds.NumArg,
	hint = "Health(-1=default)"
}

zsd:help("Place a deployable")
zsd:defaultAccess(ULib.ACCESS_ADMIN)
local zsrm
zsrm = ulx.command(CATEGORY_NAME, "ulx setremort", ulx.zsrm, "!zsrm", true)
zsrm:addParam{
	type = ULib.cmds.PlayersArg,
	default = "^",
	ULib.cmds.optional
}

zsrm:addParam{
	type = ULib.cmds.NumArg,
	default = 0,
	hint = "num"
}

zsrm:help("Set target(s)'s remort")
zsrm:defaultAccess(ULib.ACCESS_ADMIN)
local zsrm
zsrm = ulx.command(CATEGORY_NAME, "ulx setpointmul", ulx.zsspm, "!zsspm", true)
zsrm:addParam{
	type = ULib.cmds.PlayersArg,
	default = "^",
	ULib.cmds.optional
}

zsrm:addParam{
	type = ULib.cmds.NumArg,
	default = 0,
	hint = "num"
}

zsrm:help("Set target(s)'s point mul")
zsrm:defaultAccess(ULib.ACCESS_ADMIN)