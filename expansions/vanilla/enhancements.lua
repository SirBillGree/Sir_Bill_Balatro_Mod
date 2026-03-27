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
        m_steel =   {max = 500, order = 6, name = "Steel Card", set = "Enhanced", pos = {x=6,y=1}, effect = "Steel Card", label = "Steel Card", config = {x_mult = 1.5}},
        m_stone =   {max = 500, order = 7, name = "Stone Card", set = "Enhanced", pos = {x=5,y=0}, effect = "Stone Card", label = "Stone Card", config = {chips = 50, faceless = true}},
        m_gold =    {max = 500, order = 8, name = "Gold Card", set = "Enhanced", pos = {x=6,y=0}, effect = "Gold Card", label = "Gold Card", config = {dollars = 3}},
        m_lucky =   {max = 500, order = 9, name = "Lucky Card", set = "Enhanced", pos = {x=4,y=1}, effect = "Lucky Card", label = "Lucky Card", config = {mult=20, dollars = 20, extra={mult_chance = 5, dollar_chance = 15}}},
}
-- This adds the id and sprite atlas variables to every item in the above table.
-- This is way faster than adding them manually
for k, v in pairs(vanilla_enhancements_set) do
    vanilla_enhancements_set[k].id = k
    vanilla_enhancements_set[k].atlas = "centers"
end


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

    -- both bonus and stone cards
    local function score_chips()
        return function(self, context)
            if context.cardarea == G.play then return {chips = self.ability.chips}
            else return {} end
        end
    end

    local function score_mult()
        return function(self, context)
            if context.cardarea == G.play then return {mult = self.ability.mult}
            else return {} end
        end
    end

    local function score_glass()
        return function(self, context)
            if context.cardarea == G.play then return {x_mult = self.ability.x_mult}
            else return {} end
        end
    end

    local function score_steel()
        return function(self, context)
            if context.cardarea == G.hand and context.score then return {x_mult = self.ability.x_mult}
            else return {} end
        end
    end

    local function score_gold()
        return function(self, context)
            if context.cardarea == G.hand and context.end_of_round == true then return {dollars = self.ability.dollars}
            else return {} end
        end
    end

    local function score_lucky()
        return function(self, context)
            if context.cardarea == G.play then 
                local score = {}
                if pseudorandom('lucky_mult') < G.GAME.probabilities.normal/self.ability.extra.mult_chance then score.mult = self.ability.mult end
                if pseudorandom('lucky_money') < G.GAME.probabilities.normal/self.ability.extra.dollar_chance then score.dollars = self.ability.dollars end
                if score.mult or score.dollars then -- lucky trigger
                    for i=1,#G.jokers.cards do
                        G.jokers.cards[i]:trigger_card({lucky_trigger=true})
                    end
                end
                return score
            else return {} end
        end
    end
    
    local enhancement_functions = {

        c_base =        {},

        m_bonus =       {score=score_chips()},

        m_mult =        {score=score_mult()},

        m_wild =        {},

        m_glass =       {score=score_glass(),
                            remove_graphic = function(self) self:shatter() end},

        m_steel =       {score=score_steel()},

        m_stone =       {score=score_chips()},

        m_gold =        {score=score_gold()},

        m_lucky =       {score=score_lucky()},

    }
    return enhancement_functions
end

function vanilla_enhancement_function_collector()
    return define_enhancement_functions()
end

-- Playing Card Function
function Card:shatter()
    local dissolve_time = 0.7
    self.shattered = true
    self.dissolve = 0
    self.dissolve_colours = {{1,1,1,0.8}}
    self:juice_up()
    local childParts = Particles(0, 0, 0,0, {
        timer_type = 'TOTAL',
        timer = 0.007*dissolve_time,
        scale = 0.3,
        speed = 4,
        lifespan = 0.5*dissolve_time,
        attach = self,
        colours = self.dissolve_colours,
        fill = true
    })
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  0.5*dissolve_time,
        func = (function() childParts:fade(0.15*dissolve_time) return true end)
    }))
    G.E_MANAGER:add_event(Event({
        blockable = false,
        func = (function()
                play_sound('glass'..math.random(1, 6), math.random()*0.2 + 0.9,0.5)
                play_sound('generic1', math.random()*0.2 + 0.9,0.5)
            return true end)
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'ease',
        blockable = false,
        ref_table = self,
        ref_value = 'dissolve',
        ease_to = 1,
        delay =  0.5*dissolve_time,
        func = (function(t) return t end)
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  0.55*dissolve_time,
        func = (function() self:remove() return true end)
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  0.51*dissolve_time,
    }))
end
