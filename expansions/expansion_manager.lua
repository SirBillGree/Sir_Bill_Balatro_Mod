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
[X] - fetch and add cards to pool from a module
[ ] - add types to self.P_CENTER_POOLS (like contracts)
[ ] - access card functions
[ ] - a way to edit which modules are active

functions in other files that need edits or restructuring:
[ ] - Game:init_item_prototypes()

]]--


-- Add the path to your expansion here --
require "expansions/vanilla"
require "expansions/tests"

-----------------------------------------

-- Add your sets go here ----------------
local sets = {
    {set_type = 'P_CENTERS', set = vanilla_consumables_set},
    {set_type = 'P_CENTERS', set = vanilla_enhancements_set},
}
-----------------------------------------

-- Add your function collectors here ----
local get_functions = {
    vanilla_consumables_function_collector,
    vanilla_enhancement_function_collector,
}
-----------------------------------------



-- UTILITY FUNCTION
function append_table(mainTable,appendedTable)
    for k, v in pairs(appendedTable) do
        mainTable[k] = v
    end
end

card_functions = {}


function define_card_functions()
    for i=1,#get_functions do
        append_table(card_functions,get_functions[i]())
    end
end

-- Note: replace with a function that defines all P_ tables on its own
function append_pools(G_set, set_type)
    for i=1,#sets do
        if set_type == sets[i].set_type then append_table(G_set,sets[i].set) end
    end
end
--

function get_card_functions(id)
    if (not card_functions[id]) then define_card_functions() end
    return card_functions[id]
end

