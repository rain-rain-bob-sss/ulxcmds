if engine.ActiveGamemode() ~= "bloodshed" then return end

function ulx.givemoney(caller, targets, points)
    for i = 1, #targets do
        local target = targets[i]
        target:AddMoney(points)
    end

    ulx.fancyLogAdmin(caller, "#A gave #i money to #T", points, targets)
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

    ulx.fancyLogAdmin(caller, "#A set #T's guilt to #i", target, guilt)
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
    if not MuR.SetEndTime then return end
    MuR:SetEndTime(CurTime() + time)
end

local settime = ulx.command("Bloodshed", "ulx settime", ulx.settime, "!settime")
settime:defaultAccess(ULib.ACCESS_ADMIN)
settime:addParam{
    type = ULib.cmds.NumArg,
    hint = "time"
}