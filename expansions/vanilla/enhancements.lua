--[[

Author:         SirBillGree
File:           Consumables.lua
Creation Date:  1/10/2026
-----------------------------------------------------------------------------------------------
Description:
    This is part of the restructuring process. The purpose is to make the game more modable by 
consolidating as much of the disperate elements needed to add new cards into one place. 
    Functions called for scoring enhancements are consolidated here. This will also include triggers for 

]]--


--[[
Params all enhancements will need:
[X] Scoring function
[ ] UI Functions
[ ] Pool filters

functions in other files that need edits or restructuring:
[X] card:set_ability()                  -- enhancement id = ability.id
[ ] card:<scoring functions>            -- Remove entirely
[ ] common_event:score()                 -- Restructure
[ ] common_events:generate_card_ui()    -- arguments for all instances of a card

[ ] !!! any and all instances of checking for a specific enhancement !!!

]]--

vanilla_enhancements_set = {
        c_base =    {max = 500, freq = 1, line = 'base', name = "Default Base", pos = {x=1,y=0}, set = "Default", label = 'Base Card', effect = "Base", cost_mult = 1.0, config = {}},
        
        m_bonus =   {max = 500, order = 2, name = "Bonus", set = "Enhanced", pos = {x=1,y=1}, effect = "Bonus Card", label = "Bonus Card", config = {chips=30}},
        m_mult =    {max = 500, order = 3, name = "Mult", set = "Enhanced", pos = {x=2,y=1}, effect = "Mult Card", label = "Mult Card", config = {mult = 4}},
        m_wild =    {max = 500, order = 4, name = "Wild Card", set = "Enhanced", pos = {x=3,y=1}, effect = "Wild Card", label = "Wild Card", config = {}},
        m_glass =   {max = 500, order = 5, name = "Glass Card", set = "Enhanced", pos = {x=5,y=1}, effect = "Glass Card", label = "Glass Card", config = {x_mult = 2, extra = 4}},
        m_steel =   {max = 500, order = 6, name = "Steel Card", set = "Enhanced", pos = {x=6,y=1}, effect = "Steel Card", label = "Steel Card", config = {h_x_mult = 1.5}},
        m_stone =   {max = 500, order = 7, name = "Stone Card", set = "Enhanced", pos = {x=5,y=0}, effect = "Stone Card", label = "Stone Card", config = {chips = 50, faceless = true}},
        m_gold =    {max = 500, order = 8, name = "Gold Card", set = "Enhanced", pos = {x=6,y=0}, effect = "Gold Card", label = "Gold Card", config = {h_dollars = 3}},
        m_lucky =   {max = 500, order = 9, name = "Lucky Card", set = "Enhanced", pos = {x=4,y=1}, effect = "Lucky Card", label = "Lucky Card", config = {mult=20, p_dollars = 20}},
}
-- This adds the id and sprite atlas variables to every item in the above table.
-- This is way faster than adding them manually
for k, v in pairs(vanilla_enhancements_set) do
    vanilla_enhancements_set[k].id = k
    vanilla_enhancements_set[k].atlas = "centers"
end


local enhancement_functions = {}


-- functions passed exist in this function and are passed to game --
local function define_enhancement_functions()

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    --                           SCORING FUNCTIONS                           --
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- input external: varied, given in card consumables_functions table
    -- output external: interal function
    -- input: self, context
    -- output: <score_unit> => {} | {card, chips, mult, x_mult, dollars, extra}

    local function score_none()
        return function(self, context)
            return {}
        end
    end

    -- both bonus and stone cards
    local function score_chips(amt)
        return function(self, context)
            if context.cardarea == G.play then return {chips = amt}
            else return {} end
        end
    end

    local function score_mult(amt)
        return function(self, context)
            if context.cardarea == G.play then return {mult = amt}
            else return {} end
        end
    end

    local function score_glass(amt)
        return function(self, context)
            if context.cardarea == G.play then return {x_mult = amt}
            else return {} end
        end
    end

    local function score_steel(amt)
        return function(self, context)
            if context.cardarea == G.hand then return {x_mult = amt}
            else return {} end
        end
    end

    local function score_gold(amt)
        return function(self, context)
            if context.cardarea == G.hand and context.end_of_round == true then return {dollars = amt} 
            else return {} end
        end
    end

    local function score_lucky(chance1, mult, chance2, dollars)
        return function(self, context)
            if context.cardarea == G.play then 
                local score = {}
                if pseudorandom('lucky_mult') < G.GAME.probabilities.normal/chance1 then score.mult = mult end
                if pseudorandom('lucky_money') < G.GAME.probabilities.normal/chance2 then score.dollars = dollars end
                if score.mult or score.dollars then self.lucky_trigger = true end
                return score
            else return {} end
        end
    end

    -- I chose to make a loop instead of define a table so that I could save time
    -- and not have to write out "vanilla_enhancements_set.j_<enhancement>.config.<var>"
    -- a billion times, which seems hard to maintain. "c.<var>" is much better.
    -- Yes, it's slower (O(n) instead of O(1)), but this should only run once.
    for k,v in pairs(vanilla_enhancements_set) do
        local c = v.config

        -- place function defs here --
        if k == 'c_base' then enhancement_functions[k] =        {score=score_none()}
        
        elseif k == 'm_bonus' then enhancement_functions[k] =   {score=score_chips(c.chips)}
        elseif k == 'm_mult' then enhancement_functions[k] =    {score=score_mult(c.mult)}
        elseif k == 'm_wild' then enhancement_functions[k] =    {score=score_none()}
        elseif k == 'm_glass' then enhancement_functions[k] =   {score=score_glass(c.x_mult)}
        elseif k == 'm_steel' then enhancement_functions[k] =   {score=score_steel(c.h_x_mult)}
        elseif k == 'm_stone' then enhancement_functions[k] =   {score=score_chips(c.chips)}
        elseif k == 'm_gold' then enhancement_functions[k] =    {score=score_gold(c.h_dollars)}
        elseif k == 'm_lucky' then enhancement_functions[k] =   {score=score_lucky(5,c.mult,15,c.p_dollars)}
        else end
    end
end

function vanilla_enhancement_function_collector()
    define_enhancement_functions()
    return enhancement_functions
end

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                           SCORING FUNCTIONS                           --
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- input external: varied, given in card consumables_functions table
-- output external: interal function
-- input: self, context
-- output: <score_unit> => {} | {card, chips, mult, x_mult, dollars, extra}


-- local function score_none()
--     return function(self, context)
--         return {}
--     end
-- end

-- -- both bonus and stone cards
-- local function score_chips(amt)
--     return function(self, context)
--         if context.cardarea == G.play then return {chips = amt}
--         else return {} end
--     end
-- end

-- local function score_mult(amt)
--     return function(self, context)
--         if context.cardarea == G.play then return {mult = amt}
--         else return {} end
--     end
-- end

-- local function score_glass(amt)
--     return function(self, context)
--         if context.cardarea == G.play then return {x_mult = amt}
--         else return {} end
--     end
-- end

-- local function score_steel(amt)
--     return function(self, context)
--         if context.cardarea == G.hand then return {x_mult = amt}
--         else return {} end
--     end
-- end

-- local function score_gold(amt)
--     return function(self, context)
--         if context.cardarea == G.hand and context.end_of_round == true then return {dollars = amt} 
--         else return {} end
--     end
-- end

-- local function score_lucky(chance1, mult, chance2, dollars)
--     return function(self, context)
--         if context.cardarea == G.play then 
--             local score = {}
--             if pseudorandom('lucky_mult') < G.GAME.probabilities.normal/chance1 then score.mult = mult end
--             if pseudorandom('lucky_money') < G.GAME.probabilities.normal/chance2 then score.dollars = dollars end
--             if score.mult or score.dollars then self.lucky_trigger = true end
--             return score
--         else return {} end
--     end
-- end


