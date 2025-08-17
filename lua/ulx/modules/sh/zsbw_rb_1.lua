if engine.ActiveGamemode() ~= "zs_banditwarfare" then return end

--local trans.catname = "ZS:BW"
--local gamemode_error = "Current gamemode isn't ZS:Bandit Warfare!"
--local slang = system.GetCountry()
local glang = GetConVar("gmod_language"):GetString()
local trans = {
    ["def"] = {
        ["catname"] = "ZS:BW",
        ["gmerror"] = "Current gamemode isn't ZS:Bandit Warfare!",
        ["restarthelp"] = "Restart the round and set the mode. Set mode to -1 if you don't want to change it.",
        ["currentscore"] = "Print Current Score.",
        ["forceteam"] = "Make target(s) join the specified team",
        ["waveactive"] = "Start or end the wave",
        ["waveactive_active"] = "Active",
        ["wavetime"] = "Set time until wave start/end",
        ["wavetime_time"] = "time (0 starts/ends wave)",
        ["givepoints"] = "Give Points to target(s)",
    },
    ["zh-CN"] = {
        ["catname"] = "ZS:BW",
        ["gmerror"] = "目前模式不是ZSB",
        ["restarthelp"] = "重启一回合，并且设置模式。如果不想改变模式，可以设置为-1。",
        ["currentscore"] = "打印目前2队的分数。",
        ["forceteam"] = "使目标加入指定的队伍。",
        ["waveactive"] = "开始或结束一波。",
        ["waveactive_active"] = "开始",
        ["wavetime"] = "设置一波的时间",
        ["wavetime_time"] = "时间（秒数），设置为0会直接开始或结束",
        ["givepoints"] = "将点数给予目标。",
    },
    ["zh-TW"] = {
        ["catname"] = "ZS:BW",
        ["gmerror"] = "目前模式不是ZSB",
        ["restarthelp"] = "重啟一回合，並且設置模式。如果不想改變模式，可以設置為-1。",
        ["currentscore"] = "打印目前2隊的分數。",
        ["forceteam"] = "使目標加入指定的隊伍。",
        ["waveactive"] = "開始或結束一波。",
        ["waveactive_active"] = "開始",
        ["wavetime"] = "設置一波的時間",
        ["wavetime_time"] = "時間（秒數），設置為0會直接開始或結束",
        ["givepoints"] = "將點數給予目標。",
    },
}

local check_gamemode = function() return engine.ActiveGamemode() ~= "zs_banditwarfare" end

trans = trans[glang] or trans["def"]

ulx.zsb_trans = trans
local modes = {"keep", "classic", "samples", "trans"}
local modes_id = {
    keep = -1,
    classic = 2,
    samples = 1,
    trans = 0
}
local RESTARTING = false
function ulx.restartround(calling_ply, mode)
    if check_gamemode() then return end
    if RESTARTING then return end
    RESTARTING = true

    if modes_id[mode] then mode = modes_id[mode] else return end
    if mode ~= -1 then GAMEMODE:SetRoundMode(mode) end
    timer.Simple(0, function() gamemode.Call("PreRestartRound") end)
    timer.Simple(0.5, function()
        gamemode.Call("RestartRound")
        RESTARTING = false
    end)
end

local restartround = ulx.command(trans.catname, "ulx restartround", ulx.restartround, {"!restartround"})
restartround:addParam{
    type = ULib.cmds.StringArg,
    completes = modes,
    hint = "mode",
    error = "invalid mode \"%s\" specified",
    ULib.cmds.restrictToCompletes
}

restartround:defaultAccess(ULib.ACCESS_ADMIN)
restartround:help(trans.restarthelp)
function ulx.printcurrentscore(calling_ply)
    if check_gamemode() then return end
    local print = function(e)
        if IsValid(calling_ply) then
            calling_ply:ChatPrint(e)
        else
            print(e)
        end
    end

    print("Human: " .. GAMEMODE:GetHumanScore())
    print("Bandit: " .. GAMEMODE:GetBanditScore())
end

local currentscore = ulx.command(trans.catname, "ulx currentscore", ulx.printcurrentscore, {"!currentscore"})
currentscore:defaultAccess(ULib.ACCESS_ALL)
currentscore:help(trans.currentscore)

function ulx.forceteam(caller, targets, teamName)
    if check_gamemode() then return end
    local teams = {
        bandit = TEAM_BANDITS,
        human = TEAM_SURVIVOR,
        humans = TEAM_SURVIVOR
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

local forceteam = ulx.command(trans.catname, "ulx forceteam", ulx.forceteam, "!forceteam")
forceteam:addParam{
    type = ULib.cmds.PlayersArg
}

forceteam:addParam{
    type = ULib.cmds.StringArg,
    hint = "team",
    completes = {"bandit", "humans"},
    ULib.cmds.restrictToCompletes
}

forceteam:defaultAccess(ULib.ACCESS_ADMIN)
forceteam:help(trans.forceteam)


function ulx.waveactive(caller, active)
    if check_gamemode() then return end
    if active ~= gamemode.Call("GetWaveActive") then
        gamemode.Call("SetWaveActive", active)
        ulx.fancyLogAdmin(caller, "#A #s the wave", active and "started" or "ended")
    end
end

local waveactive = ulx.command(trans.catname, "ulx waveactive", ulx.waveactive, "!waveactive")
waveactive:addParam{
    type = ULib.cmds.BoolArg,
    default = false,
    hint = trans.waveactive_active
}
waveactive:defaultAccess(ULib.ACCESS_ADMIN)
waveactive:help(trans.waveactive)


function ulx.wavetime(caller, time)
    if check_gamemode() then return end
    if time > 0 then
        gamemode.Call(gamemode.Call("GetWaveActive") and "SetWaveEnd" or "SetWaveStart", CurTime() + time)
        ulx.fancyLogAdmin(caller, "#A set time until wave start/end to #s", ULib.secondsToStringTime(time))
    else
        local active = not gamemode.Call("GetWaveActive")
        gamemode.Call("SetWaveActive", active)
        ulx.fancyLogAdmin(caller, "#A #s the wave", active and "started" or "ended")
    end
end

local wavetime = ulx.command(trans.catname, "ulx wavetime", ulx.wavetime, "!wavetime")
wavetime:addParam{
    type = ULib.cmds.NumArg,
    hint = trans.wavetime_time,
    min = 0,
    max = 60000,
}

wavetime:defaultAccess(ULib.ACCESS_ADMIN)
wavetime:help(trans.wavetime)
function ulx.givepoints(caller, targets, points)
    if check_gamemode() then return end

    for i = 1, #targets do
        local target = targets[i]
        target:SetPoints(target:GetPoints() + points)
    end

    ulx.fancyLogAdmin(caller, "#A gave #i points to #T", points, targets)
end

local givepoints = ulx.command(trans.catname, "ulx givepoints", ulx.givepoints, "!givepoints")
givepoints:addParam{
    type = ULib.cmds.PlayersArg
}

givepoints:addParam{
    type = ULib.cmds.NumArg,
    hint = "points"
}

givepoints:defaultAccess(ULib.ACCESS_ADMIN)
givepoints:help(trans.givepoints)
local BALANCING = false
function ulx.balance(caller, enable)
    if check_gamemode() then return end
    if BALANCING then return end
    BALANCING = true
    timer.Simple(5, function() gamemode.Call("ShuffleTeams", false) BALANCING = false end)
    PrintTranslatedMessage(HUD_PRINTCENTER, "teambalance_shuffle_in_5_seconds")
    ulx.fancyLogAdmin(caller, "#A balanced team")
end

local balance = ulx.command(trans.catname, "ulx balance", ulx.balance, "!balance")
balance:defaultAccess(ULib.ACCESS_ADMIN)
balance:help(trans.balance)

function ulx.suddendeath(caller, active)
    if check_gamemode() then return end
    if GAMEMODE.SuddenDeath then return end
    GAMEMODE.SuddenDeath = true
    GAMEMODE:SetCurrentWaveWinner(nil)
    GAMEMODE:SetWave(21)
    GAMEMODE:SetHumanScore(10)
    GAMEMODE:SetBanditScore(10)
	net.Start("zs_suddendeath")
		net.WriteBool( true )
	net.Broadcast()
end

local suddendeath = ulx.command(trans.catname, "ulx suddendeath", ulx.suddendeath, "!suddendeath")
suddendeath:defaultAccess(ULib.ACCESS_ADMIN)
suddendeath:help(trans.waveactive)

function ulx.getobjectiveplacer(calling_ply)
    calling_ply:Give("weapon_zs_objectiveplacer")
end

local getobjectiveplacer = ulx.command(trans.catname, "ulx getobjectiveplacer", ulx.printcurrentscore, {"!gop"})
getobjectiveplacer:defaultAccess(ULib.ACCESS_SUPERADMIN)
getobjectiveplacer:help("Give yourself an objective placer.")