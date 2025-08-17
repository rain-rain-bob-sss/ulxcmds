if engine.ActiveGamemode() ~= "terrortown" then return end
if not CR_VERSION then print("ttt_rb_1.lua loaded,but TTT CR isn't installed.") return end
function ulx.celebrate(caller, targets)
    for i = 1, #targets do
        local target = targets[i]
        net.Start("TTT_JesterDeathCelebration")
        net.WritePlayer(target)
        net.WriteBool(true)
        net.WriteBool(true)
        net.Broadcast()
    end

    ulx.fancyLogAdmin(caller, "#A made #T celebrate", target)
end

local celebrate = ulx.command("TTT", "ulx celebrate", ulx.celebrate, "!celebrate")
celebrate:defaultAccess(ULib.ACCESS_ADMIN)
celebrate:addParam{
    type = ULib.cmds.PlayersArg
}