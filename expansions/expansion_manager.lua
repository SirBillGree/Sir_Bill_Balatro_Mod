--[[

Author:         SirBillGree
File:           Consumables.lua
Creation Date:  1/1/2026
-----------------------------------------------------------------------------------------------
Description:
    This is part of the restructuring process. The purpose is to make the game more modable by 
consolidating as much of the disperate elements needed to add new cards into one place. 
    This is the mod manager. It will go and define what objects are avilable based off the mods
enabled. 

]]--

--[[

what we will need:
[ ] - fetch and add cards to pool from a module
[ ] - add types to self.P_CENTER_POOLS (like contracts)
[ ] - access card functions
[ ] - a way to edit which modules are active

functions in other files that need edits or restructuring:
[ ] - Game:init_item_prototypes()

]]--


require "vanilla/consumables"
--require "vanilla/jokers"

card_functions = {}


----- UTILITY FUNCTION------------------------
function append_table(mainTable,appendedTable)
    for k, v in pairs(appendedTable) do
        mainTable[k] = v
    end
end
----- UTILITY FUNCTION------------------------


function define_card_functions()
    append_table(card_functions,vanilla_consumables_return_functions())
end

function append_pools()
    append_table(G.P_CENTERS, vanilla_consumables_set)
end

function get_card_functions(id)
    if (not card_functions[id]) then define_card_functions() end
    return card_functions[id]
end