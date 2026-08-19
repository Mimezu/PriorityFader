-- This intentionally contains no Frame Gambit behavior. Its only role is to
-- let WoW load the old PriorityFader.lua SavedVariables package one final time
-- and hand that table to the renamed addon before PLAYER_LOGIN.
if type(PriorityFaderDB) == "table" and type(FrameGambit_AdoptLegacySettings) == "function" then
    FrameGambit_AdoptLegacySettings(PriorityFaderDB)
end
