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

timer.Create("Refresh FORCECLASS_COMPLETES", 0.5, 3, function()
	table.Empty(FORCECLASS_COMPLETES)
	for classKey, class in ipairs(GAMEMODE.ZombieClasses) do
		FORCECLASS_COMPLETES[#FORCECLASS_COMPLETES + 1] = class.Name
	end
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

setwave:defaultAccess(ULib.ACCESS_ADMIN)
setwave:help("Set the wave.")
function ulx.setwavetime(calling_ply, additional_time)
	if not GAMEMODE:GetWaveActive() then
		GAMEMODE:SetWaveStart(CurTime() + additional_time)
	else
		GAMEMODE:SetWaveEnd(GAMEMODE:GetWaveEnd() + additional_time)
	end

	ulx.fancyLogAdmin(calling_ply, "#A set the wave time to #s", additional_time)
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
	game.ConsoleCommand("changelevel " .. string.format(game.GetMap(), ".bsp") .. "\n")
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
--Give Ammo--
function ulx.giveammo(calling_ply, target_plys, amount, ammotype)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]
		if v:IsValid() and v:Alive() then --[[and v:Team() == TEAM_HUMAN]]
			v:GiveAmmo(amount, ammotype)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave #s #s ammo to #T", amount, ammotype, target_plys)
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
	hint = "Ammo Type"
}

giveammo:defaultAccess(ULib.ACCESS_ADMIN)
giveammo:help("Gives the specified ammo to the target player(s).")
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
	hint = "weapon_zs_admin_nuke"
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
			ent:SetPos(v:GetPos())
			ent:Spawn()
			ent:Activate()
			v:PickupWeapon(ent)
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
	hint = "weapon_zs_admin_nuke"
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

	ulx.fancyLogAdmin(cp, "#A Set #T's remort to #i", p, n)
end

function ulx.zsspm(cp, p, n)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply.PointIncomeMul = n end
	end

	ulx.fancyLogAdmin(cp, "#A Set #T's Point mul to #i", p, n)
end

function ulx.zsda(cp, p)
	for _, ply in pairs(p) do
		if ply:IsValid() then ply:DropAll() end
	end

	ulx.fancyLogAdmin(cp, "#A Made #T drop everything.", p)
end

function ulx.zsfn(cp, call, unremoveable, mul, str)
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
					ulx.fancyLogAdmin(cp, "#A Force nailed a prop.")
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
			trent:SetBarricadeHealth(math.min(trent:GetMaxBarricadeHealth(), trent:GetBarricadeHealth() + health))
			local healed = trent:GetBarricadeHealth() - oh
			gamemode.Call("PlayerRepairedObject", cp, trent, healed, cp)
			local ed = EffectData()
			ed:SetOrigin(tr.HitPos)
			ed:SetNormal(tr.HitNormal)
			ed:SetMagnitude(1)
			util.Effect("nailrepaired", ed, true, true)
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