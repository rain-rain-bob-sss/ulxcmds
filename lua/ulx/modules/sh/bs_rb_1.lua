if not engine.ActiveGamemode():match("bloodshed") and not engine.ActiveGamemode():match("bsrrf") then return end

function ulx.givemoney(caller, targets, points)
    for i = 1, #targets do
        local target = targets[i]
        target:AddMoney(points)
    end

    ulx.fancyLogAdmin(caller, "#A gave $#i to #T", points, targets)
end

local givem = ulx.command("Bloodshed", "ulx givemoney", ulx.givemoney, "!givemoney")
givem:defaultAccess(ULib.ACCESS_ADMIN)
givem:addParam{
    type = ULib.cmds.PlayersArg
}

givem:addParam{
    type = ULib.cmds.NumArg,
    hint = "money"
}

function ulx.setguilt(caller, targets, guilt)
    for i = 1, #targets do
        local target = targets[i]
        target:SetNWFloat("Guilt", guilt)
    end

    ulx.fancyLogAdmin(caller, "#A set #T's guilt to #i", targets, guilt)
end

local setguilt = ulx.command("Bloodshed", "ulx setguilt", ulx.setguilt, "!setguilt")
setguilt:defaultAccess(ULib.ACCESS_ADMIN)
setguilt:addParam{
    type = ULib.cmds.PlayersArg
}

setguilt:addParam{
    type = ULib.cmds.NumArg,
    hint = "guilt"
}

function ulx.settime(caller, time)
    MuR.TimerEndTime = (CurTime() + time)
    ulx.fancyLogAdmin(caller, "#A set the timer to #i", time)
end

local settime = ulx.command("Bloodshed", "ulx settime", ulx.settime, "!settime")
settime:defaultAccess(ULib.ACCESS_ADMIN)
settime:addParam{
    type = ULib.cmds.NumArg,
    hint = "time"
}

function ulx.setrole(caller, targets, role)
    for i = 1, #targets do
        local target = targets[i]
        local pos,ang = target:GetPos(),target:EyeAngles()
        target.ForceSpawn = true
        target:SetNW2String("Class", role)
        target:Spawn()
        target.ForceSpawn = false
        target:SetPos(pos)
        target:SetEyeAngles(ang)
    end

    ulx.fancyLogAdmin(caller, "#A set #T's role to #s", targets, role)
end

local setrole = ulx.command("Bloodshed", "ulx setrole", ulx.setrole, "!setrole")
setrole:defaultAccess(ULib.ACCESS_ADMIN)
setrole:addParam{
    type = ULib.cmds.PlayersArg
}

local COMPLETES = {}

timer.Create("Refresh MuR_Role COMPLETES", 0.5, 1, function()
	table.Empty(COMPLETES)
	for class in pairs(GAMEMODE:GetRoles()) do
		COMPLETES[#COMPLETES + 1] = class
	end
	table.sort(COMPLETES,function(a,b) return b>a end)
end)


setrole:addParam{
    type = ULib.cmds.StringArg,
    hint = "role",
    completes = COMPLETES
}
