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
