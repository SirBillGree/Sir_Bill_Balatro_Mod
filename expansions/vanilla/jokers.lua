--[[

Author:         SirBillGree
File:           Jokers.lua
Creation Date:  12/18/2025
-----------------------------------------------------------------------------------------------
Description:
    This is part of the restructuring process. The purpose is to make the game more modable by 
consolidating as much of the disperate elements needed to add new cards into one place. 
    Functions called when using and testing if jokers can be used is consolidated here and
passed to the card object. 

]]--


--[[
Params all jokers will need:
[x] additonal Trigger -> Trigger effect dictionary (optional)
[x] Scoring function (optional)
[x] values specific to an instance of a joker (example: yorick_discards) (add to config)
[x] UI Functions
[ ] Pool filters
[ ] Unlock Conditions

functions in other files that need edits or restructuring:
[x] card:trigger_card()
[x] card:set_ability()                  -- Remove setting specific vars
[x] common_events:generate_card_ui()    -- arguments for all instances of a card
[ ] common_events:get_current_pool()    -- import filter conditions as function
[ ] state_events:check_for_unlock()     -- add all unlock conditions to an array of functions to check
[x] common_events:reset_<joker>        

contexts:
- open_booster
- buy_self
- sell_self
- sell_card
- reroll
- leave_shop
- skip_blind
- skip_booster
- playing_card_added
- cards_destroyed
- first_hand_drawn
- setting_blind
- using_consumeable
- debuffed_hand
- pre_discard
- discard
- end_of_round
- individual (card)
    - before_scoring
    - after_scoring
    - (scoring)
]]--


--------------------------------------------------------------------
--------------------------------------------------------------------
--                     GLOBAL JOKER FUNCTIONS                     --
--------------------------------------------------------------------
--------------------------------------------------------------------
--- Functions that can and should be used by other creators

-- val_name: string = 'chips', 'mult', 'x_mult', 'dollars'
-- cond (condition): function, takes (self, context), returns true/false
function score_value(val, cond) 
    cond = cond or function(x, xx) return true end
    if type(val) == "string" then val = {val} end
    return function(self, context)
        if cond(self,context) then
            local r = {card = self}
            for _,v in pairs(val) do r[v] = self.ability[v] end
            return r
        end
    end
end

function trigger_card_buff(cond, val) 
    cond = cond or function(x, xx) return true end
    if type(val) == "string" then val = {val} end
    return function(self, context)
        if context.individual and cond(self,context) then
            local r = {card = self}
            for _,v in pairs(val) do r[v] = self.ability[v] end
            return r
        end
    end
end

function trigger_end_round_money_bonus(cond, calc) 
    cond = cond or function(x, xx) return true end
    return function(self, context)
        if context.end_round_dollar_bonus and not self.debuff and not context.blueprint and cond(self, context) then
            return calc(self)
        end
end end

function trigger_first_hand_ability_jiggle() return function(self, context)
    if context.first_hand_drawn and not context.blueprint then
        juice_card_until(self, function() return G.GAME.current_round.hands_played == 0 end, true)
    end 
end end

function trigger_first_discard_ability_jiggle() return function(self, context)
    if context.first_hand_drawn and not context.blueprint then
        local eval = function() return G.GAME.current_round.discards_used == 0 and not G.RESET_JIGGLES end
        juice_card_until(self, eval, true)
    end 
end end

-- Next Four are for blueprint jokers --

function score_copy() return function(self, context)
    local target = self.ability.blueprint_target or nil
    if target then 
        local ret
        context.blueprint = true
        local card_funcs = get_card_functions(target.ability.id)
        if card_funcs and card_funcs.score then ret = card_funcs.score(target,context) end
        if context.blueprint then context.blueprint = nil end
        return ret or nil
    end
end end

function trigger_copy() return function(self, context)
    local target = self.ability.blueprint_target or nil
    if target then 
        local ret
        -- add blueprint to context
        context.blueprint = true
        context.blueprint_card = self
        local card_funcs = get_card_functions(target.ability.id)
        -- if copied cards has triggers
        if card_funcs and card_funcs.triggers then 
            for i=1,#card_funcs.triggers do 
                -- Problem: what if a cards triggers several times in a context?
                local o = card_funcs.triggers[i](target,context)
                if o then ret = o end
            end
        end
        -- Jiggle blueprint instead of copied joker during scoring
        if ret and ret.card ~= self then ret.card = self end
        -- remove blueprint from context
        if context.blueprint then context.blueprint = nil end
        if context.blueprint_card then context.blueprint_card = nil end
        return ret or nil
    end
end end

-- input: target_conf = {type="abs"|"rel", pos=<int>} | {custom=<function>}
-- "abs" = absolute: copy joker in position <int>
-- "rel" = relitive: copy joker at <this_card's_position> + <int>
local function upd_copy(target_conf) 
    local get_target = function() end
    if target_conf.type == "abs" then get_target = function(self, target_conf) return G.jokers.cards[target_conf.pos] end
    elseif target_conf.type == "rel" then
        get_target = function(self,target_conf)
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == self then return G.jokers.cards[i+target_conf.pos] end
            end
        end
    elseif target_conf.custom then get_target = target_conf.custom end
    return function(self, context)
        local target = get_target(self,target_conf)
        if target and target.config.center.blueprint_compat == true and target ~= self then
            self.ability.blueprint_target = target
            -- double check that we aren't in a loop [example: {blueprint,brainstorm}]
            while target and target.ability.blueprint_target do
                -- if target's target isn't self, target = target's target
                if target.ability.blueprint_target ~= self then
                    target = target.ability.blueprint_target
                    self.ability.blueprint_target = target
                -- if target is self, target = nil, break
                else
                    self.ability.blueprint_target = nil
                end
            end
            self.ability.blueprint_compat = 'compatible'
        else
            self.ability.blueprint_target = nil
        end
        if self.ability.blueprint_target == nil then self.ability.blueprint_compat = 'incompatible' end
end end

function ui_copy() return function(self)
    self.ability.blueprint_compat_ui = self.ability.blueprint_compat_ui or ''; self.ability.blueprint_compat_check = nil
    local main_end = (self.area and self.area == G.jokers) and {
        {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
            {n=G.UIT.C, config={ref_table = self, align = "m", colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06, func = 'blueprint_compat'}, nodes={
                {n=G.UIT.T, config={ref_table = self.ability, ref_value = 'blueprint_compat_ui',colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.8}},
            }}
        }}
    } or nil
    return {main_end=main_end}
end end


-----------------------------------------------------------------------
-----------------------------------------------------------------------
--                     DEFINE FUNCTIONS FUNCTION                     --
-----------------------------------------------------------------------
-----------------------------------------------------------------------

local function define_joker_functions()

    -------------------------------------------------------------
    -------------------------------------------------------------
    --                     SCORE FUNCTIONS                     --
    -------------------------------------------------------------
    -------------------------------------------------------------

    local function score_hand_jokers(val) return function(self, context)
        if context.cardarea == G.jokers and context.score and next(context.poker_hands[self.ability.type]) then
            local ret = {card=self}
            ret[val] = self.ability[val]
            return ret
        end
    end end

    -- conditions --

    local function suit_count_cond(cond) return function(self, context)
        local suits = {
            ['Hearts'] = 0,
            ['Diamonds'] = 0,
            ['Spades'] = 0,
            ['Clubs'] = 0
        }
        for i = 1, #context.scoring_hand do
            if context.scoring_hand[i].ability.name ~= 'Wild Card' then
                if context.scoring_hand[i]:is_suit('Hearts', true) and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                elseif context.scoring_hand[i]:is_suit('Diamonds', true) and suits["Diamonds"] == 0  then suits["Diamonds"] = suits["Diamonds"] + 1
                elseif context.scoring_hand[i]:is_suit('Spades', true) and suits["Spades"] == 0  then suits["Spades"] = suits["Spades"] + 1
                elseif context.scoring_hand[i]:is_suit('Clubs', true) and suits["Clubs"] == 0  then suits["Clubs"] = suits["Clubs"] + 1 end
            end
        end
        for i = 1, #context.scoring_hand do
            if context.scoring_hand[i].ability.name == 'Wild Card' then
                if context.scoring_hand[i]:is_suit('Hearts') and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                elseif context.scoring_hand[i]:is_suit('Diamonds') and suits["Diamonds"] == 0  then suits["Diamonds"] = suits["Diamonds"] + 1
                elseif context.scoring_hand[i]:is_suit('Spades') and suits["Spades"] == 0  then suits["Spades"] = suits["Spades"] + 1
                elseif context.scoring_hand[i]:is_suit('Clubs') and suits["Clubs"] == 0  then suits["Clubs"] = suits["Clubs"] + 1 end
            end
        end
        return cond(suits)
    end end

    local function flower_cond() return function(suits)
        if suits["Hearts"] > 0 and
        suits["Diamonds"] > 0 and
        suits["Spades"] > 0 and
        suits["Clubs"] > 0 then
            return true
        end
    end end

    local function seeing_double_cond() return function(suits)
        if (suits["Hearts"] > 0 or
        suits["Diamonds"] > 0 or
        suits["Spades"] > 0) and
        suits["Clubs"] > 0 then
            return true
        end
    end end

    ---------------------------------------------------------------------
    --                     TRIGGERS DURING SCORING                     --
    ---------------------------------------------------------------------

    local function trigger_superposition() return function(self, context)
        if context.cardarea == G.jokers and context.score then
            local aces = 0
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:get_id() == 14 then aces = aces + 1 end
            end
            if aces >= 1 and next(context.poker_hands["Straight"]) then
                local card_type = 'Tarot'
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card(card_type,G.consumeables, nil, nil, nil, nil, nil, 'sup')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                return {
                    message = localize('k_plus_tarot'),
                    colour = G.C.SECONDARY_SET.Tarot,
                    card = self
                }
            end
        end
    end end

    local function trigger_seance() return function(self, context)
        if context.cardarea == G.jokers and context.score and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            if next(context.poker_hands[self.ability.extra.poker_hand]) then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Spectral',G.consumeables, nil, nil, nil, nil, nil, 'sea')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                return {
                    message = localize('k_plus_spectral'),
                    colour = G.C.SECONDARY_SET.Spectral,
                    card = self
                }
            end
        end
    end end

    local function trigger_vagabond() return function(self, context)
        if context.cardarea == G.jokers and context.score and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            if G.GAME.dollars <= self.ability.extra then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'vag')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                return {
                    message = localize('k_plus_tarot'),
                    card = self
                }
            end
        end
    end end


    ---------------------------------------------------------------
    ---------------------------------------------------------------
    --                     TRIGGER FUNCTIONS                     --
    ---------------------------------------------------------------
    ---------------------------------------------------------------
    
    ------------------------------------------------------
    --                     ADD CARD                     --
    ------------------------------------------------------
    
    local function trigger_hologram() return function(self, context)
        if context.playing_card_added and not self.getting_sliced and not context.blueprint and context.cards and context.cards[1] then
                self.ability.x_mult = self.ability.x_mult + #context.cards*self.ability.extra
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_x_mult', vars = {self.ability.x_mult}}})
        end
    end end

    ---------------------------------------------------------
    --                     AFTER SCORE                     --
    ---------------------------------------------------------

    local function trigger_ice_cream_iter() return function(self, context)
        if context.after and not context.individual and not context.repetition and not context.blueprint then
            if self.ability.chips - self.ability.extra.chip_mod <= 0 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                return {
                    message = localize('k_melted_ex'),
                    colour = G.C.CHIPS
                }
            else
                self.ability.chips = self.ability.chips - self.ability.extra.chip_mod
                return {
                    message = localize{type='variable',key='a_chips_minus',vars={self.ability.chips}},
                    colour = G.C.CHIPS
                }
            end
        end
    end end

    local function trigger_seltzer_iter() return function(self, context)
        if context.after and not context.individual and not context.repetition and not context.blueprint then
            if self.ability.extra.hands - 1 <= 0 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                return {
                    message = localize('k_drank_ex'),
                    colour = G.C.FILTER
                }
            else
                self.ability.extra.hands = self.ability.extra.hands - 1
                return {
                    message = self.ability.extra.hands..'',
                    colour = G.C.FILTER
                }
            end
        end
    end end

    local function trigger_perkeo() return function(self, context)
        if context.ending_shop then
            if G.consumeables.cards[1] then
                G.E_MANAGER:add_event(Event({
                    func = function() 
                        local card = copy_card(pseudorandom_element(G.consumeables.cards, pseudoseed('perkeo')), nil)
                        card:set_edition({negative = true}, true)
                        card:add_to_deck()
                        G.consumeables:emplace(card) 
                        return true
                    end}))
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
            end
        end
    end end

    ----------------------------------------------------------
    --                     BEFORE SCORE                     --
    ----------------------------------------------------------

    local function trigger_set_lowest_for_raised_fist() return function(self, context)
        if context.before_score then
            -- defines which card should trigger the raised fist effect
            self.ability.trigger_card = G.hand.cards[1]
            for _,card in pairs(G.hand.cards) do
                if card.base.nominal < self.ability.trigger_card.base.nominal then self.ability.trigger_card = card end
            end
        end
    end end

    local function trigger_set_first_for_photograph() return function(self, context)
        if context.before_score then
            -- defines which card should trigger the photograph effect
            for _,card in pairs(G.play.cards) do
                if card:is_face() then 
                    self.ability.trigger_card = card
                    return
                end
            end
        end
    end end

    local function trigger_ride_the_bus() return function(self, context)
        if context.before_score and not context.blueprint then
            local faces = false
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:is_face() then faces = true end
            end
            if faces then
                local last_mult = self.ability.mult
                self.ability.mult = 0
                if last_mult > 0 then 
                    return {
                        card = self,
                        message = localize('k_reset')
                    }
                end
            else
                self.ability.mult = self.ability.mult + self.ability.extra
            end
        end
    end end

    local function trigger_space_joker() return function(self, context)
        if context.before_score and pseudorandom('space') < G.GAME.probabilities.normal/self.ability.extra then
            level_up_hand(self,context.scoring_name, false)
            return {
                card = self,
                message = localize('k_level_up_ex')
            }
        end
    end end

    local function trigger_runner_upgrade() return function(self, context)
        if context.before_score and not context.repetition and next(context.poker_hands['Straight']) and not context.blueprint then
            self.ability.chips = self.ability.chips + self.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                card = self
            }
        end
    end end

    local function trigger_square_upgrade() return function(self, context)
        if context.before_score and not context.repetition and #context.full_hand == 4 and not context.blueprint then
            self.ability.chips = self.ability.chips + self.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                card = self
            }
        end
    end end

    local function trigger_DNA_make_copy() return function(self, context)
        if context.before_score and not context.repetition and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 then
            G.playing_card = (G.playing_card and G.playing_card + 1) or 1
            local _card = copy_card(context.full_hand[1], nil, nil, G.playing_card)
            _card:add_to_deck()
            G.deck.config.card_limit = G.deck.config.card_limit + 1
            table.insert(G.playing_cards, _card)
            G.hand:emplace(_card)
            _card.states.visible = nil

            G.E_MANAGER:add_event(Event({
                func = function()
                    _card:start_materialize()
                    return true
                end
            })) 
            return {
                message = localize('k_copied_ex'),
                colour = G.C.CHIPS,
                card = self,
                playing_cards_created = {true}
            }
        end
    end end

    local function trigger_sixth_sense() return function(self, context)
        if context.before_score and not context.repetition and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 and context.full_hand[1]:get_id() == 6 then
            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Spectral',G.consumeables, nil, nil, nil, nil, nil, 'sixth')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_plus_spectral'), colour = G.C.SECONDARY_SET.Spectral})
            end
        end 
    end end

    local function trigger_green_joker_play() return function(self, context)
        if context.before_score and not context.blueprint then
            self.ability.mult = self.ability.mult + self.ability.extra.hand_add
            return {
                card = self,
                message = localize{type='variable',key='a_mult',vars={self.ability.extra.hand_add}}
            }
        end
    end end

    local function trigger_vampire() return function(self, context)
        if context.before_score and not context.blueprint then
            -- find and un-enhance all played enhanced cards
            local enhanced = {}
            for k, v in ipairs(context.scoring_hand) do
                if v.config.center ~= G.P_CENTERS.c_base and not v.debuff and not v.vampired then 
                    enhanced[#enhanced+1] = v
                    v.vampired = true
                    v:set_ability(G.P_CENTERS.c_base, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            v:juice_up()
                            v.vampired = nil
                            return true
                        end
                    })) 
                end
            end
            -- If any cards were enhanced, print vampire message
            if #enhanced > 0 then 
                self.ability.x_mult = self.ability.x_mult + self.ability.extra*#enhanced
                return {
                    message = localize{type='variable',key='a_x_mult',vars={self.ability.x_mult}},
                    colour = G.C.MULT,
                    card = self
                }
            end
        end
    end end

    local function trigger_obelisk() return function(self, context)
        if context.before_score and not context.blueprint then
            local reset = true
            local play_more_than = (G.GAME.hands[context.scoring_name].played or 0)
            for k, v in pairs(G.GAME.hands) do
                if k ~= context.scoring_name and v.played >= play_more_than and v.visible then
                    reset = false
                end
            end
            if reset then
                if self.ability.x_mult > 1 then
                    self.ability.x_mult = 1
                    return {
                        card = self,
                        message = localize('k_reset')
                    }
                end
            else
                self.ability.x_mult = self.ability.x_mult + self.ability.extra
            end
        end
    end end

    local function trigger_midas_mask() return function(self, context)
        if context.before_score and not context.blueprint then
            local faces = {}
            for k, v in ipairs(context.scoring_hand) do
                if v:is_face() then 
                    faces[#faces+1] = v
                    v:set_ability(G.P_CENTERS.m_gold, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            v:juice_up()
                            return true
                        end
                    })) 
                end
            end
            if #faces > 0 then 
                return {
                    message = localize('k_gold'),
                    colour = G.C.MONEY,
                    card = self
                }
            end
        end
    end end

    local function trigger_trousers() return function(self, context)
        if context.before_score and (next(context.poker_hands['Two Pair']) or next(context.poker_hands['Full House'])) and not context.blueprint then
            self.ability.mult = self.ability.mult + self.ability.extra
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.RED,
                card = self
            }
        end
    end end

    ----------------------------------------------------------
    --                     BEFORE ROUND                     --
    ----------------------------------------------------------

    local function trigger_dagger() return function(self, context)
        if context.setting_blind and not context.blueprint and not self.getting_sliced then
            local my_pos = nil
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == self then my_pos = i; break end
            end
            if my_pos and G.jokers.cards[my_pos+1] and not self.getting_sliced and not G.jokers.cards[my_pos+1].ability.eternal and not G.jokers.cards[my_pos+1].getting_sliced then 
                local sliced_card = G.jokers.cards[my_pos+1]
                sliced_card.getting_sliced = true
                G.GAME.joker_buffer = G.GAME.joker_buffer - 1
                G.E_MANAGER:add_event(Event({func = function()
                    G.GAME.joker_buffer = 0
                    self.ability.mult = self.ability.mult + sliced_card.sell_cost*2
                    self:juice_up(0.8, 0.8)
                    sliced_card:start_dissolve({HEX("57ecab")}, nil, 1.6)
                    play_sound('slice1', 0.96+math.random()*0.08)
                return true end }))
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_mult', vars = {self.ability.mult+2*sliced_card.sell_cost}}, colour = G.C.RED, no_juice = true})
            end
        end
    end end

    local function trigger_madness() return function(self, context)
        if context.setting_blind and not self.getting_sliced and self.ability.name == 'Madness' and not context.blueprint and not context.blind.boss then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            -- filter out jokers that can't be destroyed
            local destructable_jokers = {}
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] ~= self and not G.jokers.cards[i].ability.eternal and not G.jokers.cards[i].getting_sliced then destructable_jokers[#destructable_jokers+1] = G.jokers.cards[i] end
            end
            -- choose joker
            local joker_to_destroy = #destructable_jokers > 0 and pseudorandom_element(destructable_jokers, pseudoseed('madness')) or nil
            -- destroy joker
            if joker_to_destroy and not (context.blueprint_card or self).getting_sliced then 
                joker_to_destroy.getting_sliced = true
                G.E_MANAGER:add_event(Event({func = function()
                    (context.blueprint_card or self):juice_up(0.8, 0.8)
                    joker_to_destroy:start_dissolve({G.C.RED}, nil, 1.6)
                return true end }))
            end
            -- print new x_mult
            if not (context.blueprint_card or self).getting_sliced then
                card_eval_status_text((context.blueprint_card or self), 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_x_mult', vars = {self.ability.x_mult}}})
            end
        end
    end end

    local function trigger_marble() return function(self, context)
        if context.setting_blind and not (context.blueprint_card or self).getting_sliced  then
            G.E_MANAGER:add_event(Event({
                func = function() 
                    local front = pseudorandom_element(G.P_CARDS, pseudoseed('marb_fr'))
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local card = Card(G.play.T.x + G.play.T.w/2, G.play.T.y, G.CARD_W, G.CARD_H, front, G.P_CENTERS.m_stone, {playing_card = G.playing_card})
                    card:start_materialize({G.C.SECONDARY_SET.Enhanced})
                    G.play:emplace(card)
                    table.insert(G.playing_cards, card)
                    return true
                end}))
            card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_plus_stone'), colour = G.C.SECONDARY_SET.Enhanced})

            G.E_MANAGER:add_event(Event({
                func = function() 
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    return true
                end}))
                draw_card(G.play,G.deck, 90,'up', nil)  

            playing_card_joker_effects({true})
        end
    end end

    local function trigger_burglar() return function(self, context)
        if context.setting_blind and not (context.blueprint_card or self).getting_sliced then
            G.E_MANAGER:add_event(Event({func = function()
                ease_discard(-G.GAME.current_round.discards_left, nil, true)
                ease_hands_played(self.ability.extra)
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_hands', vars = {self.ability.extra}}})
            return true end }))
        end
    end end

    local function trigger_riff_raff() return function(self, context)
        if context.setting_blind and not (context.blueprint_card or self).getting_sliced and #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
            local jokers_to_create = math.min(2, G.jokers.config.card_limit - (#G.jokers.cards + G.GAME.joker_buffer))
            G.GAME.joker_buffer = G.GAME.joker_buffer + jokers_to_create
            G.E_MANAGER:add_event(Event({
                func = function() 
                    for i = 1, jokers_to_create do
                        local card = create_card('Joker', G.jokers, nil, 0, nil, nil, nil, 'rif')
                        card:add_to_deck()
                        G.jokers:emplace(card)
                        card:start_materialize()
                        G.GAME.joker_buffer = 0
                    end
                    return true
                end}))   
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_plus_joker'), colour = G.C.BLUE}) 
        end
    end end

    local function trigger_cartomancer() return function(self, context)
        if context.setting_blind and not (context.blueprint_card or self).getting_sliced and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                func = (function()
                    G.E_MANAGER:add_event(Event({
                        func = function() 
                            local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'car')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                            return true
                        end}))   
                        card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})                       
                    return true
                end)}))
        end
    end end

    local function trigger_chicot() return function(self, context)
        if context.setting_blind and not self.getting_sliced and not context.blueprint and context.blind.boss and not self.getting_sliced then
            G.E_MANAGER:add_event(Event({func = function()
                G.E_MANAGER:add_event(Event({func = function()
                    G.GAME.blind:disable()
                    play_sound('timpani')
                    delay(0.4)
                    return true end }))
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
            return true end }))
        end
    end end

    --------------------------------------------------------
    --                     BUFF CARDS                     --
    --------------------------------------------------------

    -- Base Version --
    -- local function trigger_card_buff(cond, val) 
    --     cond = cond or function(x, xx) return true end
    --     if type(val) == "string" then val = {val} end
    --     return function(self, context)
    --         if context.individual and cond(self,context) then
    --             local r = {card = self}
    --             for _,v in pairs(val) do r[v] = self.ability[v] end
    --             return r
    --         end
    --     end
    -- end

    -- conditions --

    local function blackboard_cond() return function(self, context)
        for _,card in pairs(G.hand.cards) do 
            if not(card:is_suit("Clubs") or card:is_suit("Spades")) then return end 
        end
        return true
    end end

    -- Specific Versions --

    local function trigger_lowest_raised_fist() return function(self, context)
        if context.individual and context.cardarea == G.hand then
            -- Trigger card if smallest (trigger card set in "trigger_set_lowest_for_raised_fist()")
            if self.ability.trigger_card == context.other_card then
                return {
                    mult = 2*context.other_card.base.nominal,
                    card = self
                }
            end
        end
    end end

    local function trigger_8_ball() return function(self, context)
        if context.individual and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            if (context.other_card:get_id() == 8) and (pseudorandom('8ball') < G.GAME.probabilities.normal/self.ability.extra) then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                return {
                    extra = {focus = self, message = localize('k_plus_tarot'), func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.0,
                            func = (function()
                                    local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, '8ba')
                                    card:add_to_deck()
                                    G.consumeables:emplace(card)
                                    G.GAME.consumeable_buffer = 0
                                return true
                            end)}))
                    end},
                    colour = G.C.SECONDARY_SET.Tarot,
                    card = self
                }
            end
        end
    end end

    local function trigger_hiker() return function(self,context)
        if context.individual and context.cardarea == G.play then
            context.other_card.perma.chips = context.other_card.perma.chips + self.ability.extra
            return {
                extra = {message = localize('k_upgrade_ex'), colour = G.C.CHIPS},
                card = self
            }
        end
    end end

    local function trigger_wee_upgrade() return function(self,context)
        if context.individual and context.cardarea == G.play and context.other_card:get_id() == 2 and not context.blueprint then
            self.ability.chips = self.ability.chips + self.ability.extra
            return {
                extra = {focus = self, message = localize('k_upgrade_ex')},
                card = self,
                colour = G.C.CHIPS
            }
        end 
    end end


    ---------------------------------------------------------
    --                     BUFF JOKERS                     --
    ---------------------------------------------------------
    
    local function trigger_baseball() return function(self,context)
        if context.individual and context.cardarea == G.jokers and context.other_card.config.center.rarity == 2 then
            return {x_mult = self.ability.x_mult, card = self}
        end
    end end


    -------------------------------------------------------------
    --                     CONSUMABLE USED                     --
    -------------------------------------------------------------

    local function trigger_constellation() return function(self, context)
        if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == 'Planet' then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            G.E_MANAGER:add_event(Event({
                func = function() card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_x_mult',vars={self.ability.x_mult}}}); return true
                end}))
            return
        end
    end end

    local function trigger_fortune_teller_iter() return function(self, context)
        if context.using_consumeable and not context.blueprint and (context.consumeable.ability.set == "Tarot") then
            G.E_MANAGER:add_event(Event({
                func = function() card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_mult',vars={G.GAME.consumeable_usage_total.tarot}}}); return true
                end}))
        end
    end end

    -----------------------------------------------------------
    --                     DEBUFFED HAND                     --
    -----------------------------------------------------------
    
    local function trigger_matador() return function(self, context)
        if G.GAME.blind.triggered then 
            --ease_dollars(self.ability.dollars)
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + self.ability.dollars
            G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
            return {
                dollars = self.ability.dollars,
            }
        end
    end end


    -----------------------------------------------------
    --                     DISCARD                     --
    -----------------------------------------------------

    local function trigger_faceless_joker() return function(self, context)
                               -- only triggers on last card discarded                  --
        if context.discard and context.other_card == context.full_hand[#context.full_hand] then
            local face_cards = 0
            for k, v in ipairs(context.full_hand) do
                if v:is_face() then face_cards = face_cards + 1 end
            end
            if face_cards >= self.ability.extra.faces then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        ease_dollars(self.ability.dollars)
                        card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('$')..self.ability.dollars,colour = G.C.MONEY, delay = 0.45})
                        return true
                    end}))
                return
            end
        end
    end end


    local function trigger_green_joker_discard() return function(self, context)
        if context.discard and not context.blueprint and context.other_card == context.full_hand[#context.full_hand] and self.ability.mult ~= 0 then
            self.ability.mult = self.ability.mult - self.ability.extra.discard_sub
            return {
                message = localize{type='variable',key='a_mult_minus',vars={self.ability.extra.discard_sub}},
                colour = G.C.RED,
                card = self
            }
        end
    end end

    local function trigger_mail_in() return function(self, context)
        if context.discard and not context.other_card.debuff and context.other_card:get_id() == G.GAME.current_round.mail_card.id then
                ease_dollars(self.ability.extra)
                return {
                    message = localize('$')..self.ability.extra,
                    colour = G.C.MONEY,
                    card = self
                }
        end
    end end

    local function trigger_trading_card() return function(self, context)
        if context.discard and not context.blueprint and G.GAME.current_round.discards_used <= 0 and #context.full_hand == 1 then
            ease_dollars(self.ability.dollars)
            return {
                message = localize('$')..self.ability.dollars,
                colour = G.C.MONEY,
                delay = 0.45, 
                remove = true,
                card = self
            }
        end
    end end

    local function trigger_ramen_iter() return function(self, context)
        if context.discard and not context.blueprint then
            if self.ability.x_mult - self.ability.extra <= 1 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                return {
                    message = localize('k_eaten_ex'),
                    colour = G.C.FILTER
                }
            else
                self.ability.x_mult = self.ability.x_mult - self.ability.extra
                return {
                    delay = 0.2,
                    message = localize{type='variable',key='a_x_mult_minus',vars={self.ability.extra}},
                    colour = G.C.RED
                }
            end
        end
    end end

    local function trigger_castle_upgrade() return function(self, context)
        if context.discard and not context.blueprint and not context.other_card.debuff and context.other_card:is_suit(G.GAME.current_round.castle_card.suit) then
            self.ability.chips = self.ability.chips + self.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                card = self,
                colour = G.C.CHIPS
            }
        end
    end end

    local function trigger_hit_the_road_upgrade() return function(self, context)
        if context.discard and not context.blueprint and not context.other_card.debuff and context.other_card:get_id() == 11 and not context.blueprint then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            return {
                message = localize{type='variable',key='a_x_mult',vars={self.ability.x_mult}},
                    colour = G.C.RED,
                    delay = 0.45, 
                card = self
            }
        end
    end end

    local function trigger_yorick_discard() return function(self, context)
        if context.discard and not context.blueprint then
            if self.ability.extra.current_discards <= 1 then
                self.ability.extra.current_discards = self.ability.extra.discards
                self.ability.x_mult = self.ability.x_mult + self.ability.extra.x_mult
                return {
                    delay = 0.2,
                    message = localize{type='variable',key='a_x_mult',vars={self.ability.x_mult}},
                    colour = G.C.RED
                }
            else
                self.ability.extra.current_discards = self.ability.extra.current_discards - 1
            end
        end
    end end

    -------------------------------------------------------------
    --                     DISCARD (BEFORE)                    --
    -------------------------------------------------------------

    local function trigger_burnt() return function(self, context)
        if context.pre_discard and G.GAME.current_round.discards_used <= 0 and not context.hook then
            local text,disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')})
            update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize(text, 'poker_hands'),chips = G.GAME.hands[text].chips, mult = G.GAME.hands[text].mult, level=G.GAME.hands[text].level})
            level_up_hand(context.blueprint_card or self, text, nil, 1)
            update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
        end
    end end

    ------------------------------------------------------
    --                     END ROUND                    --
    ------------------------------------------------------

    local function trigger_extinct(pseed) return function (self, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            if pseudorandom(pseed) < G.GAME.probabilities.normal/self.ability.extra.odds then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                if self.ability.name == 'Gros Michel' then G.GAME.pool_flags.gros_michel_extinct = true end
                return {
                    message = localize('k_extinct_ex')
                }
            else
                return {
                    message = localize('k_safe_ex')
                }
            end
        end
    end end

    local function trigger_egg() return function(self, context) 
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            self.ability.extra_value = self.ability.extra_value + self.ability.extra
            self:set_cost()
            return {
                message = localize('k_val_up'),
                colour = G.C.MONEY
            }
        end
    end end

    local function trigger_reset_todo() return function(self, context) 
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            local _poker_hands = {}
            for k, v in pairs(G.GAME.hands) do
                if v.visible and k ~= self.ability.extra.poker_hand then _poker_hands[#_poker_hands+1] = k end
            end
            self.ability.extra.poker_hand = pseudorandom_element(_poker_hands, pseudoseed('to_do'))
            return {
                message = localize('k_reset')
            }
        end
    end end

    local function trigger_rocket_up() return function(self, context) 
        if context.end_of_round and not context.individual and not context.repetition and not context.blueprint and G.GAME.blind.boss then
            self.ability.dollars = self.ability.dollars + self.ability.extra.increase
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MONEY
            }
        end
    end end

    local function trigger_gift_card() return function(self, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            for k, v in ipairs(G.jokers.cards) do
                if v.set_cost then 
                    v.ability.extra_value = (v.ability.extra_value or 0) + self.ability.extra
                    v:set_cost()
                end
            end
            for k, v in ipairs(G.consumeables.cards) do
                if v.set_cost then 
                    v.ability.extra_value = (v.ability.extra_value or 0) + self.ability.extra
                    v:set_cost()
                end
            end
            return {
                message = localize('k_val_up'),
                colour = G.C.MONEY
            }
        end
    end end

    local function trigger_turtle_bean_down() return function(self, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            if self.ability.extra.h_size - self.ability.extra.h_mod <= 0 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                return {
                    message = localize('k_eaten_ex'),
                    colour = G.C.FILTER
                }
            else
                self.ability.extra.h_size = self.ability.extra.h_size - self.ability.extra.h_mod
                G.hand:change_size(- self.ability.extra.h_mod)
                return {
                    message = localize{type='variable',key='a_handsize_minus',vars={self.ability.extra.h_mod}},
                    colour = G.C.FILTER
                }
            end
        end
    end end

    local function trigger_popcorn_iter() return function(self, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            if self.ability.mult - self.ability.extra <= 0 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        self.T.r = -0.2
                        self:juice_up(0.3, 0.4)
                        self.states.drag.is = true
                        self.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                    G.jokers:remove_card(self)
                                    self:remove()
                                    self = nil
                                return true; end})) 
                        return true
                    end
                })) 
                return {
                    message = localize('k_eaten_ex'),
                    colour = G.C.RED
                }
            else
                self.ability.mult = self.ability.mult - self.ability.extra
                return {
                    message = localize{type='variable',key='a_mult_minus',vars={self.ability.extra}},
                    colour = G.C.MULT
                }
            end
        end
    end end

    local function trigger_campfire_reset() return function(self, context)
        if context.end_of_round and not context.blueprint and G.GAME.blind.boss and self.ability.x_mult > 1 then
            self.ability.x_mult = 1
            return {
                message = localize('k_reset'),
                colour = G.C.RED
            }
        end
    end end

    local function trigger_hit_the_road_reset() return function(self, context)
        if context.end_of_round and not context.blueprint and self.ability.x_mult > 1 then
            self.ability.x_mult = 1
            return {
                message = localize('k_reset'),
                colour = G.C.RED
            }
        end
    end end

    local function trigger_invisable_iter() return function(self, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            self.ability.extra.current_rounds = self.ability.extra.current_rounds + 1
            if self.ability.extra.current_rounds == self.ability.extra.init_rounds then 
                local eval = function(card) return not card.REMOVED end
                juice_card_until(self, eval, true)
            end
            return {
                message = (self.ability.extra.current_rounds < self.ability.extra.init_rounds) and (self.ability.extra.current_rounds..'/'..self.ability.extra.init_rounds) or localize('k_active_ex'),
                colour = G.C.FILTER
            }
        end
    end end

    -------------------------------------------------------------------
    --                     END ROUND MONEY BONUS                     --
    -------------------------------------------------------------------
    
    -- local function trigger_end_round_money_bonus(cond, calc) 
    --     cond = cond or function(x, xx) return true end
    --     return function(self, context)
    --         if context.end_round_dollar_bonus and not self.debuff and not context.blueprint and cond(self, context) then
    --             return calc(self)
    --         end
    -- end end

    -- conds and calcs --
    local function trigger_satellite()
        return trigger_end_round_money_bonus(
            function(self,context) -- cond
                for k, v in pairs(G.GAME.consumeable_usage) do 
                    if v.set == 'Planet' then return true end 
                end 
            end, 
            function(self) -- calc
                local planets_used = 0
                for k, v in pairs(G.GAME.consumeable_usage) do 
                    if v.set == 'Planet' then planets_used = planets_used + 1 end 
                end 
                return planets_used 
            end
        ) 
    end

    --------------------------------------------------------------
    --                     FIRST HAND DRAWN                     --
    --------------------------------------------------------------
    
    -- local function trigger_first_hand_ability_jiggle() return function(self, context)
    --     if context.first_hand_drawn and not context.blueprint then
    --         juice_card_until(self, function() return G.GAME.current_round.hands_played == 0 end, true)
    --     end 
    -- end end

    -- local function trigger_first_discard_ability_jiggle() return function(self, context)
    --     if context.first_hand_drawn and not context.blueprint then
    --         local eval = function() return G.GAME.current_round.discards_used == 0 and not G.RESET_JIGGLES end
    --         juice_card_until(self, eval, true)
    --     end 
    -- end end

    local function trigger_certificate() return function(self, context)
        if context.first_hand_drawn then
            G.E_MANAGER:add_event(Event({
                func = function() 
                    local _card = create_playing_card({
                        front = pseudorandom_element(G.P_CARDS, pseudoseed('cert_fr')), 
                        center = G.P_CENTERS.c_base}, G.hand, nil, nil, {G.C.SECONDARY_SET.Enhanced})
                    local seal_type = pseudorandom(pseudoseed('certsl'))
                    if seal_type > 0.75 then _card:set_seal('Red', true)
                    elseif seal_type > 0.5 then _card:set_seal('Blue', true)
                    elseif seal_type > 0.25 then _card:set_seal('Gold', true)
                    else _card:set_seal('Purple', true)
                    end
                    G.GAME.blind:debuff_card(_card)
                    G.hand:sort()
                    if context.blueprint_card then context.blueprint_card:juice_up() else self:juice_up() end
                    return true
                end}))

            playing_card_joker_effects({true})
        end
    end end

    -------------------------------------------------------
    --                     GAME OVER                     --
    -------------------------------------------------------

    local function trigger_mr_bones() return function(self, context)
        if context.game_over and G.GAME.chips/G.GAME.blind.chips >= 0.25 then
            G.E_MANAGER:add_event(Event({
                func = function()
                    G.hand_text_area.blind_chips:juice_up()
                    G.hand_text_area.game_chips:juice_up()
                    play_sound('tarot1')
                    self:start_dissolve()
                    return true
                end
            })) 
            return {
                message = localize('k_saved_ex'),
                saved = true,
                colour = G.C.RED
            }
        end
    end end

    -------------------------------------------------------
    --                     OPEN PACK                     --
    -------------------------------------------------------

    local function trigger_hallucination() return function(self, context)
        if context.open_booster and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            if pseudorandom('halu'..G.GAME.round_resets.ante) < G.GAME.probabilities.normal/self.ability.extra then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'hal')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
            end
        end
    end end

    ------------------------------------------------------------------
    --                     REMOVE PLAYING CARDs                     --
    ------------------------------------------------------------------

    local function trigger_glass_joker() return function(self, context)
        if context.remove_playing_cards and not context.blueprint then
            local glass_cards = 0
            for k, val in ipairs(context.removed) do
                if val.shattered then glass_cards = glass_cards + 1 end
            end
            if glass_cards > 0 then 
                G.E_MANAGER:add_event(Event({
                    func = function()
                G.E_MANAGER:add_event(Event({
                    func = function()
                        self.ability.x_mult = self.ability.x_mult + self.ability.extra*glass_cards
                    return true
                    end
                }))
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_x_mult', vars = {self.ability.x_mult + self.ability.extra*glass_cards}}})
                return true
                    end
                }))
            end
            return
        end
    end end

    local function trigger_caino_upgrade() return function(self, context)
        if context.remove_playing_cards and not context.blueprint then
            local face_cards = 0
            for k, val in ipairs(context.removed) do
                if val:is_face() then face_cards = face_cards + 1 end
            end
            if face_cards > 0 then
                self.ability.x_mult = self.ability.x_mult + face_cards*self.ability.extra
                G.E_MANAGER:add_event(Event({
                func = function() card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_x_mult', vars = {self.ability.x_mult}}}); return true
                end}))
            end
            return
        end
    end end

    ----------------------------------------------------------
    --                     RE-ROLL SHOP                     --
    ----------------------------------------------------------

    local function trigger_flash_card() return function(self, context)
        if context.reroll_shop and not context.blueprint then
            self.ability.mult = self.ability.mult + self.ability.extra
            G.E_MANAGER:add_event(Event({
                func = (function()
                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_mult', vars = {self.ability.mult}}, colour = G.C.MULT})
                return true
            end)}))
        end
    end end

    -------------------------------------------------------------
    --                     SELL OTHER CARD                     --
    -------------------------------------------------------------

    local function trigger_campfire_upgrade() return function(self, context)
        if context.selling_card and not context.blueprint then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            G.E_MANAGER:add_event(Event({
                func = function() card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')}); return true
                end}))
        end
    end end

    -------------------------------------------------------
    --                     SELL SELF                     --
    -------------------------------------------------------

    local function trigger_luchador() return function(self, context)
        if context.selling_self then
            if G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == 'Boss')) then 
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
                G.GAME.blind:disable()
            end
        end
    end end

    local function trigger_diet_cola() return function(self, context)
        if context.selling_self then
            G.E_MANAGER:add_event(Event({
                func = (function()
                    add_tag(Tag('tag_double'))
                    play_sound('generic1', 0.9 + math.random()*0.1, 0.8)
                    play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                    return true
                end)
            }))
        end
    end end

    local function trigger_invisable_sell() return function(self, context)
        if context.selling_self and (self.ability.extra.current_rounds >= self.ability.extra.init_rounds) and not context.blueprint then
            local jokers = {}
            for i=1, #G.jokers.cards do 
                if G.jokers.cards[i] ~= self then
                    jokers[#jokers+1] = G.jokers.cards[i]
                end
            end
            if #jokers > 0 then 
                if #G.jokers.cards <= G.jokers.config.card_limit then 
                    card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
                    local chosen_joker = pseudorandom_element(jokers, pseudoseed('invisible'))
                    local card = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
                    if card.ability.invis_rounds then card.ability.invis_rounds = 0 end
                    card:add_to_deck()
                    G.jokers:emplace(card)
                else
                    card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_no_room_ex')})
                end
            else
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('k_no_other_jokers')})
            end
        end
    end end

    --------------------------------------------------------
    --                     SKIP BLIND                     --
    --------------------------------------------------------

    local function trigger_throwback() return function(self, context)
        if context.skip_blind and not context.blueprint then
            G.E_MANAGER:add_event(Event({
                func = function() 
                    card_eval_status_text(self, 'extra', nil, nil, nil, {
                        message = localize{type = 'variable', key = 'a_x_mult', vars = {1 + G.GAME.skips*self.ability.extra}},
                            colour = G.C.RED,
                        card = self
                    }) 
                    return true
                end}))
        end
    end end

    ------------------------------------------------------------
    --                     SKIP CARD PACK                     --
    ------------------------------------------------------------

    local function trigger_red_card_skip() return function(self, context)
        if context.skipping_booster and not context.blueprint then
            self.ability.mult = self.ability.mult + self.ability.extra
            G.E_MANAGER:add_event(Event({
                func = function() 
                    card_eval_status_text(self, 'extra', nil, nil, nil, {
                        message = localize{type = 'variable', key = 'a_mult', vars = {self.ability.extra}},
                        colour = G.C.RED,
                        delay = 0.45, 
                        card = self
                    }) 
                    return true
                end}))
        end 
    end end


    local function trigger_loyalty_iter() return function(self, context)
        if context.cardarea == G.jokers and context.score then
            if not context.blueprint then
                self.ability.extra.loyalty_remaining = (self.ability.extra.every-1-(G.GAME.hands_played - self.ability.hands_played_at_create))%(self.ability.extra.every+1)
            end
            if self.ability.extra.loyalty_remaining == 0 then
                local eval = function(card) return (card.ability.extra.loyalty_remaining == 0) end
                juice_card_until(self, eval, true)
            end
        end
    end end

    -- local function trigger_copy() return function(self, context)
    --     local target = self.ability.blueprint_target or nil
    --     if target then 
    --         local ret
    --         -- add blueprint to context
    --         context.blueprint = true
    --         context.blueprint_card = self
    --         local card_funcs = get_card_functions(target.ability.id)
    --         -- if copied cards has triggers
    --         if card_funcs and card_funcs.triggers then 
    --             for i=1,#card_funcs.triggers do 
    --                 -- Problem: what if a cards triggers several times in a context?
    --                 local o = card_funcs.triggers[i](target,context)
    --                 if o then ret = o end
    --             end
    --         end
    --         -- Jiggle blueprint instead of copied joker during scoring
    --         if ret and ret.card ~= self then ret.card = self end
    --         -- remove blueprint from context
    --         if context.blueprint then context.blueprint = nil end
    --         if context.blueprint_card then context.blueprint_card = nil end
    --         return ret or nil
    --     end
    -- end end

    -----------------------------------------------------------
    --                     LUCKY TRIGGER                     --
    -----------------------------------------------------------

    local function trigger_lucky_cat() return function(self, context)
        if context.lucky_trigger and not context.blueprint then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            card_eval_status_text(self,'extra',nil,nil,nil,{
                focus = self, 
                message = localize('k_upgrade_ex'), 
                colour = G.C.MULT
            })
        end
    end end

    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --                     ADD/REMOVE FUNCTIONS                     --
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    ---Required: function(self,context)
    
    local function add_remove_chaos(sign) return function(self)
        G.GAME.current_round.free_rerolls = G.GAME.current_round.free_rerolls + (self.ability.extra*sign)
        calculate_reroll_cost(true)
    end end

    -- sign 1 to add, sign -1 to remove
    local function add_remove_hand_size(sign) return function(self)
        G.hand:change_size(self.ability.extra.h_size*sign)
    end end

    -- sign 1 to add, sign -1 to remove
    local function add_remove_discards(sign) return function(self)
        G.GAME.round_resets.discards = G.GAME.round_resets.discards + (self.ability.extra.d_size*sign)
        ease_discard(self.ability.extra.d_size*sign)
    end end

    -- sign 1 to add, sign -1 to remove
    local function add_remove_troubadour(sign) return function(self)
        G.hand:change_size(self.ability.extra.h_size*sign)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + self.ability.extra.h_plays*sign
    end end

    -- sign 1 to add, sign -1 to remove
    local function add_remove_merry_andy(sign) return function(self)
        G.GAME.round_resets.discards = G.GAME.round_resets.discards + (self.ability.extra.d_size*sign)
        ease_discard(self.ability.extra.d_size*sign)
        G.hand:change_size(-self.ability.extra.h_size*sign)
    end end

    local function add_chicot_disable_current_blind() return function(self)
        if G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
            G.GAME.blind:disable()
            play_sound('timpani')
            card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
        end
    end end

    ---------------------------------------------------------------
    ---------------------------------------------------------------
    --                     COMMON CONDITIONS                     --
    ---------------------------------------------------------------
    ---------------------------------------------------------------
    
    -- ranks is a list of <int>
    local function other_card_rank_cond(ranks, other_cond) 
        other_cond = other_cond or function(x,xx) return end
        return function(self, context)
            if context.other_card and other_cond(self, context) then
                for _,r in pairs(ranks) do
                    if r == context.other_card:get_id() then return true end
                end
            end
    end end

    ------------------------------------------------------
    ------------------------------------------------------
    --                     ON CREATE                    --
    ------------------------------------------------------
    ------------------------------------------------------
    --- Effects triggered when the card is created
    
    -- calculate the amount of steel cards there are when this card is created
    local function update_tally(card_type, func) return function (self, context)
        self.ability.tally = 0
        for k, v in pairs(G.playing_cards) do
            if v.config.center == G.P_CENTERS[card_type] then self.ability.tally = self.ability.tally+1 end
        end
        func(self)
    end end

    local function create_todo_list() return function (self, context)
        local _poker_hands = {}
        for k, v in pairs(G.GAME.hands) do
            if v.visible then _poker_hands[#_poker_hands+1] = k end
        end
        local old_hand = self.ability.extra.poker_hand
        self.ability.extra.poker_hand = nil

        while not self.ability.extra.poker_hand do
            self.ability.extra.poker_hand = pseudorandom_element(_poker_hands, pseudoseed((self.area and self.area.config.type == 'title') and 'false_to_do' or 'to_do'))
            if self.ability.extra.poker_hand == old_hand then self.ability.extra.poker_hand = nil end
        end
    end end


    -------------------------------------------------------------
    -------------------------------------------------------------
    --                     GET REPETITIONS                     --
    -------------------------------------------------------------
    -------------------------------------------------------------

    local function get_repitions(cond)
        cond = cond or function(x, xx) return true end
        return function(self, context)
            if context.repetition and cond(self, context) then
                return {
                        repetitions = self.ability.extra.reps,
                        card = self,
                }
            end
        end
    end

    ----------------------------------------------------------
    ----------------------------------------------------------
    --                     UI FUNCTIONS                     --
    ----------------------------------------------------------
    ----------------------------------------------------------

    local function ui_misprint() return function(self)
        local r_mults = {}
        for i = self.ability.extra.min, self.ability.extra.max do
            r_mults[#r_mults+1] = tostring(i)
        end
        local loc_mult = ' '..(localize('k_mult'))..' '
        local glitched_text = {
            {n=G.UIT.T, config={text = '  +',colour = G.C.MULT, scale = 0.32}},
            {n=G.UIT.O, config={object = DynaText({string = r_mults, colours = {G.C.RED},pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0})}},
            {n=G.UIT.O, config={object = DynaText({string = {
                {string = 'rand()', colour = G.C.JOKER_GREY},{string = "#@"..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1,1) or 'D'), colour = G.C.RED},
                loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult},
            colours = {G.C.UI.TEXT_DARK},pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.2011, scale = 0.32, min_cycle_time = 0})}},
        }
        return {main_start = glitched_text}
    end end

    local function ui_luchador() return function(self)
        local has_message= (G.GAME and self.area and (self.area == G.jokers))
        if has_message then
            local disableable = G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == 'Boss'))
            local main_end = {
                {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
                    {n=G.UIT.C, config={ref_table = self, align = "m", colour = disableable and G.C.GREEN or G.C.RED, r = 0.05, padding = 0.06}, nodes={
                        {n=G.UIT.T, config={text = ' '..localize(disableable and 'k_active' or 'ph_no_boss_active')..' ',colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.9}},
                    }}
                }}
            }
            return {main_end=main_end}
        end
    end end

    local function ui_satellite() return function(self)
        local planets_used = 0
        for k, v in pairs(G.GAME.consumeable_usage) do if v.set == 'Planet' then planets_used = planets_used + 1 end end
        return {vars = {self.ability.extra, planets_used*self.ability.extra}}
    end end

    local function ui_invisible() return function(self)
        local main_end = {}
        if G.jokers and G.jokers.cards then
            for k, v in ipairs(G.jokers.cards) do
                if (v.edition and v.edition.negative) and (G.localization.descriptions.Other.remove_negative)then 
                    main_end = {}
                    localize{type = 'other', key = 'remove_negative', nodes = main_end, vars = {}}
                    main_end = main_end[1]
                    break
                end
            end
        end 
        return {vars={self.ability.extra.init_rounds, self.ability.extra.current_rounds}, main_end = main_end}
    end end


    --------------------------------------------------------------
    --------------------------------------------------------------
    --                     UPDATE FUNCTIONS                     --
    --------------------------------------------------------------
    --------------------------------------------------------------
    
    local function upd_stencil_joker() return function(self, context)
        self.ability.x_mult = (G.jokers.config.card_limit - #G.jokers.cards)
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i].ability.name == 'Joker Stencil' then self.ability.x_mult = self.ability.x_mult + 1 end
        end
    end end

    local function upd_cloud_9() return function(self, context)
        self.ability.nine_tally = 0
        for k, v in pairs(G.playing_cards) do
            if v:get_id() == 9 then self.ability.nine_tally = self.ability.nine_tally+1 end
        end
    end end

    local function upd_swashbuckler() return function(self, context)
        local sell_cost = 0
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] ~= self and (G.jokers.cards[i].area and G.jokers.cards[i].area == G.jokers) then
                sell_cost = sell_cost + G.jokers.cards[i].sell_cost
            end
        end
        self.ability.mult = sell_cost
    end end

    local function upd_drivers_license() return function(self, context)
        self.ability.driver_tally = 0
        for k, v in pairs(G.playing_cards) do
            if v.config.center ~= G.P_CENTERS.c_base then self.ability.driver_tally = self.ability.driver_tally+1 end
        end
    end end

    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --                     JOKER FUNCTION TABLE                     --
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    -- Joker function table: a table defining individual functions that are called by the game in various places 
    -- using <card>.ability.id
    -- NOTE: Only one function from "triggers" can be called from a card at a time. 

    local joker_functions = {

        --[[ Priority list
        j_example =         {score =
                                triggers=
                                add_deck=
                                remove_deck=
                                update=
                                ui_args=
                                ui_unlock=
                                }
        ]]--
        
    -- 1: ------------------------------------------------------
        j_joker =           {score=score_value('mult'), 
                                ui_args = function(self) return {vars={self.ability.mult}} end},

        j_blueprint =       {score=score_copy(), 
                                triggers={trigger_copy()}, 
                                update=upd_copy({type="rel",pos=1}), -- chance for optimization (update)
                                ui_args = ui_copy(),
                                ui_unlock = nil},

        j_brainstorm =      {score=score_copy(), 
                                triggers={trigger_copy()}, 
                                update=upd_copy({type="abs",pos=1}),
                                ui_args = ui_copy(),
                                ui_unlock = nil},

        j_half =            {score=score_value('mult', function (self,context) return #context.full_hand <= self.ability.extra.size end),
                                ui_args = function(self) return {vars={self.ability.mult, self.ability.extra.size}} end},
                                
        j_stencil =         {score=score_value('x_mult', function (self,context) return self.ability.x_mult > 1 end), 
                                update=upd_stencil_joker(),
                                ui_args = function(self) return {vars = {self.ability.x_mult}} end},

        j_mime =            {triggers={get_repitions(function(self,context) return context.cardarea == G.hand end)},
                                ui_args = nil},

        j_credit_card =     {add_deck = function(self,context) G.GAME.bankrupt_at = G.GAME.bankrupt_at - self.ability.extra end, 
                                remove_deck = function(self,context) G.GAME.bankrupt_at = G.GAME.bankrupt_at + self.ability.extra end,
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_ceremonial =      {score=score_value('mult'), 
                                triggers={trigger_dagger()},
                                ui_args = function(self) return {vars={self.ability.mult}} end},

        j_banner =          {score=score_value('chips', function (self,context) return G.GAME.current_round.discards_left > 0 end), 
                                update=function(self,context) self.ability.chips = G.GAME.current_round.discards_left * self.ability.extra end,
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_mystic_summit =   {score=score_value('mult', function (self,context) return G.GAME.current_round.discards_left == self.ability.extra.d_remaining end),
                                ui_args = function(self) return {vars={self.ability.mult, self.ability.extra.d_remaining}} end},

        j_marble =          {triggers={trigger_marble()},
                                ui_args = function(self) return {info_queue={G.P_CENTERS.m_stone}} end},


    -- 11: -----------------------------------------------------
        j_loyalty_card =    {score=score_value('x_mult', function (self,context) return self.ability.extra.loyalty_remaining == self.ability.extra.every end), 
                                triggers={trigger_loyalty_iter()},
                                ui_args = function(self) return {vars={self.ability.x_mult, self.ability.extra.every + 1, localize{type = 'variable', key = (self.ability.extra.loyalty_remaining == 0 and 'loyalty_active' or 'loyalty_inactive'), vars = {self.ability.extra.loyalty_remaining}}}} end},

        j_8_ball =          {triggers={trigger_8_ball()},
                                ui_args = function(self) return {vars={''..(G.GAME and G.GAME.probabilities.normal or 1),self.ability.extra}} end},

        j_oops =            {add_deck=function(self,context) for k,v in pairs(G.GAME.probabilities) do G.GAME.probabilities[k] = v*2 end end, 
                                remove_deck = function(self,context) for k,v in pairs(G.GAME.probabilities) do G.GAME.probabilities[k] = v/2 end end,
                                ui_args = nil,
                                ui_unlock = function(_c) return {vars={number_format(_c.unlock_condition.chips)}} end},

        j_misprint =        {score=function(self,context) return {mult=pseudorandom('misprint', self.ability.extra.min, self.ability.extra.max)} end,
                                ui_args = ui_misprint()},

        j_dusk =            {triggers={get_repitions(function(self,context) return G.GAME.current_round.hands_left == 0 and context.cardarea == G.play end)},
                                ui_args = nil},

        j_raised_fist =     {triggers={trigger_lowest_raised_fist(),trigger_set_lowest_for_raised_fist()},
                                ui_args = nil},

        j_chaos =           {add_deck=add_remove_chaos(1), 
                                remove_deck=add_remove_chaos(-1),
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_fibonacci =       {triggers={trigger_card_buff(other_card_rank_cond({14, 2, 3, 5, 8}, function(self,context) return context.cardarea == G.play end), 'mult')},
                                ui_args = function(self) return {vars={self.ability.mult}} end},

        j_steel_joker =     {score=score_value('x_mult'), 
                                update = update_tally("m_steel",function(self) self.ability.x_mult = 1 + (self.ability.extra * self.ability.tally) end), -- chance for optimization (update)
                                ui_args = function(self) return {vars={self.ability.extra, 1 + self.ability.extra*(self.ability.tally or 0)}, info_queue={G.P_CENTERS.m_steel}} end}, 

        j_scary_face =      {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_face() end, 'chips')},
                                ui_args = function(self) return {vars={self.ability.chips}} end},

        j_abstract =        {score= function(self,context) return {mult=(G.jokers and G.jokers.cards and #G.jokers.cards or 0)*self.ability.extra} end,
                                ui_args = function(self) return {vars={self.ability.extra, (G.jokers and G.jokers.cards and #G.jokers.cards or 0)*self.ability.extra}} end},

    -- 21: -----------------------------------------------------
        j_delayed_grat =    {triggers={trigger_end_round_money_bonus(function(self, context) return G.GAME.current_round.discards_used == 0 and G.GAME.current_round.discards_left > 0 end, function(self) return G.GAME.current_round.discards_left*self.ability.extra end)},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_hack =            {triggers={get_repitions(other_card_rank_cond({2,3,4,5}))},
                                ui_args = function(self) return {vars={self.ability.extra.reps+1}} end},

        j_gros_michel =     {score= score_value('mult'), 
                                triggers={trigger_extinct('gros_michel')},
                                ui_args = function(self) return {vars={self.ability.mult, ''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra.odds}} end},

        j_cavendish =       {score= score_value('x_mult'), 
                                triggers={trigger_extinct('cavendish')},
                                ui_args = function(self) return {vars={self.ability.x_mult, ''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra.odds}} end},

        j_even_steven =     {triggers={trigger_card_buff(other_card_rank_cond({2,4,6,8,10}, function(self,context) return context.cardarea == G.play end), 'mult')},
                                ui_args = function(self) return {vars={self.ability.mult}} end},

        j_odd_todd =        {triggers={trigger_card_buff(other_card_rank_cond({14,3,5,7,9}, function(self,context) return context.cardarea == G.play end), 'chips')},
                                ui_args = function(self) return {vars={self.ability.chips}} end},

        j_scholar =         {triggers={trigger_card_buff(other_card_rank_cond({14}, function(self,context) return context.cardarea == G.play end), {'chips','mult'})},
                                ui_args = function(self) return {vars={self.ability.mult, self.ability.chips}} end},

        j_business =        {triggers={trigger_card_buff(function(self,context) return context.other_card:is_face() and pseudorandom('business') < G.GAME.probabilities.normal/self.ability.extra.chance end, 'dollars')},
                                ui_args = function(self) return {vars={''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra.chance, self.ability.dollars}} end},

        j_supernova =       {score=function(self,context) return {mult = G.GAME.hands[context.scoring_name].played} end,
                                ui_args = nil},

        j_ride_the_bus =    {score=score_value('mult'), 
                                triggers={trigger_ride_the_bus()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.mult}} end},

        j_space =           {triggers={trigger_space_joker()},
                                ui_args = function(self) return {vars={''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra}} end},

    -- 31: -----------------------------------------------------
        j_egg =             {triggers={trigger_egg()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_burglar =         {triggers={trigger_burglar()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_blackboard =      {score=score_value("x_mult", blackboard_cond()),
                                ui_args = function(self) return {vars={self.ability.x_mult, localize('Spades', 'suits_plural'), localize('Clubs', 'suits_plural')}} end},

        j_runner =          {score=score_value('chips'), 
                                triggers={trigger_runner_upgrade()},
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.extra.chip_mod}} end},

        j_ice_cream =       {score=score_value('chips'), 
                                triggers={trigger_ice_cream_iter()},
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.extra.chip_mod}} end},

        j_dna =             {triggers={trigger_first_hand_ability_jiggle(), trigger_DNA_make_copy()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_blue_joker =      {score=function(self,context) if #G.deck.cards > 0 then return {chips = #G.deck.cards*self.ability.extra} end end,
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.extra*((G.deck and G.deck.cards) and #G.deck.cards or 52)}} end},

        j_sixth_sense =     {triggers={trigger_first_hand_ability_jiggle(), trigger_sixth_sense()},
                                ui_args = nil},

        j_constellation =   {score=score_value("x_mult", function(self,context) return self.ability.x_mult > 1 end), 
                                triggers={trigger_constellation()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

        j_hiker =           {triggers={trigger_hiker()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_faceless =        {triggers={trigger_faceless_joker()},
                                ui_args = function(self) return {vars={self.ability.dollars, self.ability.extra.faces}} end},

    -- 41: -----------------------------------------------------                            
        j_green_joker =     {score=score_value('mult'),
                                triggers={trigger_green_joker_discard(),trigger_green_joker_play()},
                                ui_args = function(self) return {vars={self.ability.extra.hand_add, self.ability.extra.discard_sub, self.ability.mult}} end},

        j_superposition =   {score=trigger_superposition(),
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_todo_list =       {score=score_value('dollars', function(self,context) return context.scoring_name == self.ability.extra.poker_hand end), 
                                on_create=create_todo_list(), 
                                triggers={trigger_reset_todo()},
                                ui_args = function(self) return {vars={self.ability.dollars, localize(self.ability.extra.poker_hand, 'poker_hands')}} end},

        j_card_sharp =      {score=score_value('x_mult', function(self,context) return G.GAME.hands[context.scoring_name] and G.GAME.hands[context.scoring_name].played_this_round > 1 end),
                                ui_args = function(self) return {vars={self.ability.x_mult}} end},

        j_red_card =        {score=score_value('mult'), 
                                triggers={trigger_red_card_skip()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.mult}} end},

        j_madness =         {score=score_value('x_mult'), 
                                triggers={trigger_madness()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

        j_square =          {score=score_value('chips'), triggers={trigger_square_upgrade()},
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.extra.chip_mod}} end},

        j_seance =          {score=trigger_seance(),
                                ui_args = function(self) return {vars={localize(self.ability.extra.poker_hand, 'poker_hands')}} end},

        j_riff_raff =       {triggers={trigger_riff_raff()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_vampire =         {score=score_value('x_mult'), 
                                triggers={trigger_vampire()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

        j_hologram =        {score=score_value('x_mult'), 
                                triggers={trigger_hologram()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

    -- 51: -----------------------------------------------------                            
        j_vagabond =        {score=trigger_vagabond(),
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_baron =           {triggers={trigger_card_buff(other_card_rank_cond({13}, function(self,context) return context.cardarea == G.hand and context.score end), 'x_mult')},
                                ui_args = function(self) return {vars={self.ability.x_mult}} end},

        j_cloud_9 =         {triggers={trigger_end_round_money_bonus(function(self,context) return self.ability.nine_tally > 0 end,function(self) return self.ability.nine_tally end)}, 
                                update=upd_cloud_9(),
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.extra*(self.ability.nine_tally or 0)}} end},

        j_rocket =          {triggers={trigger_rocket_up(), trigger_end_round_money_bonus(nil, function(self) return self.ability.dollars end)},
                                ui_args = function(self) return {vars={self.ability.dollars, self.ability.extra.increase}} end},

        j_obelisk =         {score=score_value('x_mult'), 
                                triggers={trigger_obelisk()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

        j_midas_mask =      {triggers={trigger_midas_mask()},
                                ui_args = function(self) return {info_queue={G.P_CENTERS.m_gold}} end},

        j_luchador =        {triggers={trigger_luchador()},
                                ui_args = ui_luchador()},

        j_photograph =      {triggers={trigger_set_first_for_photograph(), trigger_card_buff(function(self,context) return context.other_card == self.ability.trigger_card and context.cardarea == G.play end, "x_mult")},
                                ui_args = function(self) return {vars={self.ability.x_mult}} end},

        j_gift =            {triggers={trigger_gift_card()},
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_turtle_bean =     {add_deck=function(self,context) G.hand:change_size(self.ability.extra.h_size) end, 
                                remove_deck=function(self,context) G.hand:change_size(-self.ability.extra.h_size) end, 
                                triggers={trigger_turtle_bean_down()},
                                ui_args = function(self) return {vars={self.ability.extra.h_size, self.ability.extra.h_mod}} end},

    -- 61: -----------------------------------------------------                            
        j_erosion =         {score=function(self,context) if (G.GAME.starting_deck_size-#G.playing_cards) > 0 then return {mult=(G.GAME.starting_deck_size-#G.playing_cards)*self.ability.extra} end end,
                                ui_args = function(self) return {vars={self.ability.extra, math.max(0,self.ability.extra*(G.playing_cards and (G.GAME.starting_deck_size - #G.playing_cards) or 0)), G.GAME.starting_deck_size}} end},

        j_reserved_parking = {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.hand and context.other_card:is_face() and pseudorandom('parking') < G.GAME.probabilities.normal/self.ability.extra.odds end, "dollars")},
                                ui_args = function(self) return {vars={self.ability.dollars, ''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra.odds}} end},

        j_mail =            {triggers={trigger_mail_in()},
                                ui_args = function(self) return {vars={self.ability.extra, localize(G.GAME.current_round.mail_card.rank, 'ranks')}} end},

        j_to_the_moon =     {add_deck=function(self,context) G.GAME.interest_amount = G.GAME.interest_amount+self.ability.extra end,
                                remove_deck=function(self,context) G.GAME.interest_amount = G.GAME.interest_amount-self.ability.extra end,
                                ui_args = function(self) return {vars={self.ability.extra}} end},

        j_hallucination =   {triggers={trigger_hallucination()},
                                ui_args = function(self) return {vars={G.GAME.probabilities.normal, self.ability.extra}} end},

        j_fortune_teller =  {score=function(self,context) return {mult=G.GAME.consumeable_usage_total.tarot} end, 
                                triggers={trigger_fortune_teller_iter()},
                                ui_args = function(self) return {vars={self.ability.extra, (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot or 0)}} end},

        j_juggler =         {add_deck=add_remove_hand_size(1), 
                                remove_deck=add_remove_hand_size(-1),
                                ui_args = function(self) return {vars={self.ability.extra.h_size}} end},

        j_drunkard =        {add_deck=add_remove_discards(1), 
                                remove_deck=add_remove_discards(-1),
                                ui_args = function(self) return {vars={self.ability.extra.d_size}} end},

        j_stone =           {score=score_value('chips'), 
                                update = update_tally("m_stone", function(self) self.ability.chips = (self.ability.extra * self.ability.tally) end), -- chance for optimization (update)
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.extra*(self.ability.tally or 0)}, info_queue={G.P_CENTERS.m_stone}} end}, 

        j_golden =          {triggers={trigger_end_round_money_bonus(nil, function(self) return self.ability.dollars end)},
                                ui_args = function(self) return {vars={self.ability.dollars}} end},

    -- 71: -----------------------------------------------------
        j_lucky_cat =       {score=score_value('x_mult'), 
                                triggers={trigger_lucky_cat()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}, info_queue={G.P_CENTERS.m_lucky}} end},

        j_baseball =        {triggers={trigger_baseball()},
                                ui_args = function(self) return {vars={self.ability.x_mult}} end},

        j_bull =            {score=function(self,context) if G.GAME.dollars>0 then return {chips=self.ability.extra*math.max(0,G.GAME.dollars)} end end,
                                ui_args = function(self) return {vars={self.ability.extra, (self.ability.extra*math.max(0,G.GAME.dollars)) or 0}} end},

        j_diet_cola =       {triggers={trigger_diet_cola()},
                                ui_args = function(self) return {vars={localize{type = 'name_text', set = 'Tag', key = 'tag_double', nodes = {}}}, info_queue={{key = 'tag_double', set = 'Tag'}}} end},

        j_trading =         {triggers={trigger_trading_card(), trigger_first_discard_ability_jiggle()},
                                ui_args = function(self) return {vars={self.ability.dollars}} end},

        j_flash =           {score=score_value('mult'), 
                                triggers={trigger_flash_card()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.mult}} end},

        j_popcorn =         {score=score_value('mult'), 
                                triggers={trigger_popcorn_iter()},
                                ui_args = function(self) return {vars={self.ability.mult, self.ability.extra}} end},

        j_trousers =        {score=score_value('mult'), 
                                triggers={trigger_trousers()},
                                ui_args = function(self) return {vars={self.ability.extra, localize('Two Pair', 'poker_hands'), self.ability.mult}} end},

        j_ancient =         {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit(G.GAME.current_round.ancient_card.suit) end, 'x_mult')},
                                ui_args = function(self) return {vars={self.ability.x_mult, localize(G.GAME.current_round.ancient_card.suit, 'suits_singular'), colours = {G.C.SUITS[G.GAME.current_round.ancient_card.suit]}}} end},

        j_ramen =           {score=score_value('x_mult'), 
                                triggers={trigger_ramen_iter()},
                                ui_args = function(self) return {vars={self.ability.x_mult, self.ability.extra}} end},

    -- 81: -----------------------------------------------------
        j_walkie_talkie =   {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and (context.other_card:get_id() == 10 or context.other_card:get_id() == 4) end, {'chips','mult'})},
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.mult}} end},

        j_selzer =          {triggers={trigger_seltzer_iter(), get_repitions(function(self,context) return context.cardarea == G.play end)},
                                ui_args = function(self) return {vars={self.ability.extra.hands}} end},

        j_castle =          {score=score_value('chips'), 
                                triggers={trigger_castle_upgrade()},
                                ui_args = function(self) return {vars={self.ability.extra.chip_mod, localize(G.GAME.current_round.castle_card.suit, 'suits_singular'), self.ability.chips, colours = {G.C.SUITS[G.GAME.current_round.castle_card.suit]}}} end},

        j_smiley =          {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_face() end, "mult")},
                                ui_args = function(self) return {vars={self.ability.mult}} end},

        j_campfire =        {score=score_value('x_mult'), 
                                triggers={trigger_campfire_upgrade(), trigger_campfire_reset()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end},

        j_ticket =          {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card.ability.effect == "Gold Card" end, "dollars")},
                                ui_args = function(self) return {vars={self.ability.dollars}, info_queue={G.P_CENTERS.m_gold}} end, 
                                ui_unlock = nil},

        j_mr_bones =        {triggers={trigger_mr_bones()},
                                ui_args = nil, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra, G.PROFILES[G.SETTINGS.profile].career_stats.c_losses}} end},

        j_acrobat =         {score=score_value("x_mult", function(self,context) return G.GAME.current_round.hands_left == 0 end),
                                ui_args = function(self) return {vars={self.ability.x_mult}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra, G.PROFILES[G.SETTINGS.profile].career_stats.c_hands_played}} end},

        j_sock_and_buskin = {triggers={get_repitions(function(self,context) return context.other_card:is_face() end)},
                                ui_args = function(self) return {vars={self.ability.extra.reps+1}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra, G.PROFILES[G.SETTINGS.profile].career_stats.c_face_cards_played}} end},

        j_swashbuckler =    {score=score_value('mult'), 
                                update=upd_swashbuckler(),
                                ui_args = function(self) return {vars={self.ability.mult}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra, G.PROFILES[G.SETTINGS.profile].career_stats.c_jokers_sold}} end},

    -- 91: -----------------------------------------------------
        j_troubadour =      {add_deck=add_remove_troubadour(1), 
                                remove_deck=add_remove_troubadour(-1),
                                ui_args = function(self) return {vars={self.ability.extra.h_size, -self.ability.extra.h_plays}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra}} end},

        j_certificate =     {triggers={trigger_certificate()},
                                ui_args = function(self) return {vars={self.ability.extra}} end, 
                                ui_unlock=nil},

        j_smeared =         {ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count,localize{type = 'name_text', key = _c.unlock_condition.extra.e_key, set = 'Enhanced'}}} end},

        j_throwback =       {score= function(self,context) return {x_mult = 1 + G.GAME.skips*self.ability.extra} end, 
                                triggers={trigger_throwback()},
                                ui_args = function(self) return {vars={self.ability.extra, 1 + G.GAME.skips*self.ability.extra}} end, 
                                ui_unlock=nil},

        j_hanging_chad =    {triggers={get_repitions(function(self,context) return context.other_card == G.play.cards[1] end)},
                                ui_args = function(self) return {vars={self.ability.extra.reps}} end, 
                                ui_unlock=function(_c) return {vars={localize(_c.unlock_condition.extra, 'poker_hands')}} end},

        j_rough_gem =       {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit("Diamonds") end, "dollars")},
                                ui_args = function(self) return {vars={self.ability.dollars}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count, localize(_c.unlock_condition.extra.suit, 'suits_singular')}} end},

        j_bloodstone =      {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit("Hearts") and pseudorandom('bloodstone') < G.GAME.probabilities.normal/self.ability.extra.odds end, "x_mult")},
                                ui_args = function(self) return {vars={''..(G.GAME and G.GAME.probabilities.normal or 1), self.ability.extra.odds, self.ability.x_mult}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count, localize(_c.unlock_condition.extra.suit, 'suits_singular')}} end},

        j_arrowhead =       {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit("Spades") end, "chips")},
                                ui_args = function(self) return {vars={self.ability.chips}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count, localize(_c.unlock_condition.extra.suit, 'suits_singular')}} end},

        j_onyx_agate =      {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit("Clubs") end, "mult")},
                                ui_args = function(self) return {vars={self.ability.mult}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count, localize(_c.unlock_condition.extra.suit, 'suits_singular')}} end},

        j_glass =           {score=score_value('x_mult'), 
                                triggers={trigger_glass_joker()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}, info_queue={G.P_CENTERS.m_glass}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count, localize{type = 'name_text', key = _c.unlock_condition.extra.e_key, set = 'Enhanced'}}} end},


    -- 101: ----------------------------------------------------
        j_ring_master =     {ui_unlock=function(_c) return {vars={_c.unlock_condition.ante}} end},

        j_flower_pot =      {score=score_value('x_mult', suit_count_cond(flower_cond())),
                                ui_args = function(self) return {vars={self.ability.x_mult}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.ante}} end},
                            
        j_wee =             {score=score_value('chips'), 
                                triggers={trigger_wee_upgrade()},
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.extra}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.n_rounds}} end},

        j_merry_andy =      {add_deck=add_remove_merry_andy(1), 
                                remove_deck=add_remove_merry_andy(-1),
                                ui_args = function(self) return {vars={self.ability.extra.d_size, self.ability.extra.h_size}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.n_rounds}} end},

        j_idol =            {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:get_id() == G.GAME.current_round.idol_card.id and context.other_card:is_suit(G.GAME.current_round.idol_card.suit) end, "x_mult")},
                                ui_args = function(self) return {vars={self.ability.x_mult, localize(G.GAME.current_round.idol_card.rank, 'ranks'), localize(G.GAME.current_round.idol_card.suit, 'suits_plural'), colours = {G.C.SUITS[G.GAME.current_round.idol_card.suit]}}} end, 
                                ui_unlock=function(_c) return {vars={number_format(_c.unlock_condition.chips)}} end},

        j_seeing_double =   {score=score_value('x_mult', suit_count_cond(seeing_double_cond())),
                                ui_args = function(self) return {vars={self.ability.x_mult}} end, 
                                ui_unlock=function(_c) return {vars={localize("ph_4_7_of_clubs")}} end},

        j_matador =         {score=trigger_matador(),
                                ui_args = function(self) return {vars={self.ability.dollars}} end, 
                                ui_unlock=nil},

        j_hit_the_road =    {score=score_value('x_mult'),
                                triggers={trigger_hit_the_road_upgrade(), trigger_hit_the_road_reset()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end, 
                                ui_unlock=nil},

        j_stuntman =        {score=score_value('chips'), 
                                add_deck=add_remove_hand_size(-1), 
                                remove_deck=add_remove_hand_size(1),
                                ui_args = function(self) return {vars={self.ability.chips, self.ability.extra.h_size}} end, 
                                ui_unlock=function(_c) return {vars={number_format(_c.unlock_condition.chips)}} end},

        j_invisible =       {triggers={trigger_invisable_sell(), trigger_invisable_iter()},
                                ui_args = ui_invisible(), 
                                ui_unlock=nil},

    -- 111: ----------------------------------------------------
        j_satellite =       {triggers={trigger_satellite()},
                                ui_args = ui_satellite(), 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra}} end},

        j_shoot_the_moon =  {triggers={trigger_card_buff(other_card_rank_cond({12}, function(self,context) return context.cardarea == G.hand end), "mult")},
                                ui_args = function(self) return {vars={self.ability.mult}} end, 
                                ui_unlock=nil},

        j_drivers_license = {score=score_value('x_mult', function(self,context) return self.ability.driver_tally >= 16 end), 
                                update=upd_drivers_license(),
                                ui_args = function(self) return {vars={self.ability.x_mult, self.ability.driver_tally or '0'}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count}} end},

        j_cartomancer =     {triggers={trigger_cartomancer()},
                                ui_args = nil, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.tarot_count}} end},

        j_burnt =           {triggers={trigger_burnt()},
                                ui_args = nil, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra, G.PROFILES[G.SETTINGS.profile].career_stats.c_cards_sold}} end},

        j_bootstraps =      {score=function(self, context) if math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or 0))/self.ability.extra.dollars) >= 1 then return {mult = self.ability.extra.mult*math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or 0))/self.ability.extra.dollars)} end end,
                                ui_args = function(self) return {vars={self.ability.extra.mult, self.ability.extra.dollars, self.ability.extra.mult*math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or 0))/self.ability.extra.dollars)}} end, 
                                ui_unlock=function(_c) return {vars={_c.unlock_condition.extra.count}} end},

        j_caino =           {score=score_value("x_mult"), 
                                triggers={trigger_caino_upgrade()},
                                ui_args = function(self) return {vars={self.ability.extra, self.ability.x_mult}} end, 
                                ui_unlock=nil},

        j_triboulet =       {triggers={trigger_card_buff(other_card_rank_cond({12,13}, function(self,context) return context.cardarea == G.play end), "x_mult")},
                                ui_args = function(self) return {vars={self.ability.x_mult}} end, 
                                ui_unlock=nil},

        j_yorick =          {score=score_value("x_mult"), 
                                triggers={trigger_yorick_discard()},
                                ui_args = function(self) return {vars={self.ability.extra.x_mult, self.ability.extra.discards, self.ability.extra.current_discards, self.ability.x_mult}, info_queue={{key = 'e_negative_consumable', set = 'Edition', config = {extra = 1}}}} end, 
                                ui_unlock=nil},

        j_chicot =          {add_deck=add_chicot_disable_current_blind(),
                                triggers={trigger_chicot()},
                                ui_args = nil,
                                ui_unlock=nil},

    -- 121: ----------------------------------------------------
        j_perkeo =          {triggers={trigger_perkeo()},
                                ui_args = nil, 
                                ui_unlock=nil},

        ----------------- multi-card defitions -----------------
        
        Suit_Mult =         {triggers={trigger_card_buff(function(self,context) return context.cardarea == G.play and context.other_card:is_suit(self.ability.extra.suit) end, 'mult')},
                                ui_args = function(self) return {vars={self.ability.mult, localize(self.ability.extra.suit, 'suits_singular')}} end},

        Hand_Mult =         {score=score_hand_jokers("mult"),
                                ui_args = function(self) return {vars={self.ability.mult, localize(self.ability.type, 'poker_hands')}} end},

        Hand_Chips =        {score=score_hand_jokers("chips"),
                                ui_args = function(self) return {vars={self.ability.chips, localize(self.ability.type, 'poker_hands')}} end},
                                
        Hand_X_Mult =       {score=score_hand_jokers("x_mult"),
                                ui_args = function(self) return {vars={self.ability.x_mult, localize(self.ability.type, 'poker_hands')}} end, 
                                ui_unlock=function(_c) return {vars={localize(_c.unlock_condition.extra, 'poker_hands')}} end},
    }



    return joker_functions
end

vanilla_jokers_set = {
        -- ^ Removed all references to in base files ^ --
        j_joker=            {order = 1,  unlocked = true,   start_alerted = true, discovered = true,  blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 2, name = "Joker", pos = {x=0,y=0}, set = "Joker", effect = "Mult", cost_mult = 1.0, config = {mult = 4}},
        j_greedy_joker=     {order = 2,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Greedy Joker", pos = {x=6,y=1}, set = "Joker", id = "Suit_Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Diamonds'}}},
        j_lusty_joker=      {order = 3,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Lusty Joker", pos = {x=7,y=1}, set = "Joker", id = "Suit_Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Hearts'}}},
        j_wrathful_joker=   {order = 4,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Wrathful Joker", pos = {x=8,y=1}, set = "Joker", id = "Suit_Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Spades'}}},
        j_gluttenous_joker= {order = 5,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Gluttonous Joker", pos = {x=9,y=1}, set = "Joker", id = "Suit_Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Clubs'}}},
        j_jolly=            {order = 6,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 3, name = "Jolly Joker", pos = {x=2,y=0}, set = "Joker", id = "Hand_Mult", cost_mult = 1.0, config = {mult = 8, type = 'Pair'}},
        j_zany=             {order = 7,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Zany Joker", pos = {x=3,y=0}, set = "Joker", id = "Hand_Mult", cost_mult = 1.0, config = {mult = 12, type = 'Three of a Kind'}},
        j_mad=              {order = 8,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Mad Joker", pos = {x=4,y=0}, set = "Joker", id = "Hand_Mult", cost_mult = 1.0, config = {mult = 10, type = 'Two Pair'}},
        j_crazy=            {order = 9,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Crazy Joker", pos = {x=5,y=0}, set = "Joker", id = "Hand_Mult", cost_mult = 1.0, config = {mult = 12, type = 'Straight'}},
        j_droll=            {order = 10,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Droll Joker", pos = {x=6,y=0}, set = "Joker", id = "Hand_Mult", cost_mult = 1.0, config = {mult = 10, type = 'Flush'}},
        j_sly=              {order = 11,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 3, name = "Sly Joker",set = "Joker", id = "Hand_Chips", config = {chips = 50, type = 'Pair'}, pos = {x=0,y=14}},
        j_wily=             {order = 12,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Wily Joker",set = "Joker", id = "Hand_Chips", config = {chips = 100, type = 'Three of a Kind'}, pos = {x=1,y=14}},
        j_clever=           {order = 13,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Clever Joker",set = "Joker", id = "Hand_Chips", config = {chips = 80, type = 'Two Pair'}, pos = {x=2,y=14}},
        j_devious=          {order = 14,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Devious Joker",set = "Joker", id = "Hand_Chips", config = {chips = 100, type = 'Straight'}, pos = {x=3,y=14}},
        j_crafty=           {order = 15,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Crafty Joker",set = "Joker", id = "Hand_Chips", config = {chips = 80, type = 'Flush'}, pos = {x=4,y=14}},

        j_half=             {order = 16,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Half Joker", pos = {x=7,y=0}, scale={W=1,H=1/1.7}, set = "Joker", effect = "Hand Size Mult", cost_mult = 1.0, config = {mult = 20, extra = {size = 3}}},
        j_stencil=          {order = 17,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 8, name = "Joker Stencil", pos = {x=2,y=5}, set = "Joker", effect = "Hand Size Mult", cost_mult = 1.0, config = {}},
        j_four_fingers=     {order = 18,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Four Fingers", pos = {x=6,y=6}, set = "Joker", effect = "", config = {}},
        j_mime=             {order = 19,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Mime", pos = {x=4,y=1}, set = "Joker", effect = "Hand card double", cost_mult = 1.0, config = {extra = {reps=1}}},
        j_credit_card=      {order = 20,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 1, name = "Credit Card", pos = {x=5,y=1}, set = "Joker", effect = "Credit", cost_mult = 1.0, config = {extra = 20}},
        j_ceremonial=       {order = 21,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Ceremonial Dagger", pos = {x=5,y=5}, set = "Joker", effect = "", config = {mult = 0}},
        j_banner=           {order = 22,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Banner", pos = {x=1,y=2}, set = "Joker", effect = "Discard Chips", cost_mult = 1.0, config = {extra = 30}},
        j_mystic_summit=    {order = 23,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Mystic Summit", pos = {x=2,y=2}, set = "Joker", effect = "No Discard Mult", cost_mult = 1.0, config = {mult = 15, extra = {d_remaining = 0}}},
        j_marble=           {order = 24,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Marble Joker", pos = {x=3,y=2}, set = "Joker", effect = "Stone card hands", cost_mult = 1.0, config = {extra = 1}},
        j_loyalty_card=     {order = 25,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Loyalty Card", pos = {x=4,y=2}, set = "Joker", effect = "1 in 10 mult", cost_mult = 1.0, config = {x_mult = 4, extra = {every = 5, loyalty_remaining = 5, remaining = "5 remaining"}}},
        j_8_ball=           {order = 26,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "8 Ball", pos = {x=0,y=5}, set = "Joker", effect = "Spawn Tarot", cost_mult = 1.0, config = {extra=4}},
        j_misprint=         {order = 27,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Misprint", pos = {x=6,y=2}, set = "Joker", effect = "Random Mult", cost_mult = 1.0, config = {extra = {max = 23, min = 0}}},
        j_dusk=             {order = 28,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Dusk", pos = {x=4,y=7}, set = "Joker", effect = "", config = {extra = {reps=1}}, unlock_condition = {type = '', extra = '', hidden = true}},
        j_raised_fist=      {order = 29,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Raised Fist", pos = {x=8,y=2}, set = "Joker", effect = "Socialized Mult", cost_mult = 1.0, config = {}},
        j_chaos=            {order = 30,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Chaos the Clown", pos = {x=1,y=0}, set = "Joker", effect = "Bonus Rerolls", cost_mult = 1.0, config = {extra = 1}},
        
        j_fibonacci=        {order = 31,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 8, name = "Fibonacci", pos = {x=1,y=5}, set = "Joker", effect = "Card Mult", cost_mult = 1.0, config = {mult = 8}},
        j_steel_joker=      {order = 32,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Steel Joker", pos = {x=7,y=2}, set = "Joker", effect = "Steel Card Buff", cost_mult = 1.0, config = {x_mult = 1, extra = 0.2}, enhancement_gate = 'm_steel'},
        j_scary_face=       {order = 33,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Scary Face", pos = {x=2,y=3}, set = "Joker", effect = "Scary Face Cards", cost_mult = 1.0, config = {chips = 30}},
        j_abstract=         {order = 34,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Abstract Joker", pos = {x=3,y=3}, set = "Joker", effect = "Joker Mult", cost_mult = 1.0, config = {extra = 3}},
        j_delayed_grat=     {order = 35,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Delayed Gratification", pos = {x=4,y=3}, set = "Joker", effect = "Discard dollars", cost_mult = 1.0, config = {extra = 2}},
        j_hack=             {order = 36,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Hack", pos = {x=5,y=2}, set = "Joker", effect = "Low Card double", cost_mult = 1.0, config = {extra = {reps=1}}},
        j_pareidolia=       {order = 37,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Pareidolia", pos = {x=6,y=3}, set = "Joker", effect = "All face cards", cost_mult = 1.0, config = {}},
        j_gros_michel=      {order = 38,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 1, cost = 5, name = "Gros Michel", pos = {x=7,y=6}, set = "Joker", effect = "", config = {mult = 15, extra = {odds = 6}}, no_pool_flag = 'gros_michel_extinct'},
        j_even_steven=      {order = 39,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Even Steven", pos = {x=8,y=3}, set = "Joker", effect = "Even Card Buff", cost_mult = 1.0, config = {mult = 4}},
        j_odd_todd=         {order = 40,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Odd Todd", pos = {x=9,y=3}, set = "Joker", effect = "Odd Card Buff", cost_mult = 1.0, config = {chips = 31}},
        j_scholar=          {order = 41,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Scholar", pos = {x=0,y=4}, set = "Joker", effect = "Ace Buff", cost_mult = 1.0, config = {mult = 4, chips = 20}},
        j_business=         {order = 42,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Business Card", pos = {x=1,y=4}, set = "Joker", effect = "Face Card dollar Chance", cost_mult = 1.0, config = {dollars = 2, extra={chance=2}}},
        j_supernova=        {order = 43,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Supernova", pos = {x=2,y=4}, set = "Joker", effect = "Hand played mult", cost_mult = 1.0, config = {extra = 1}},
        j_ride_the_bus=     {order = 44,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 6, name = "Ride the Bus", pos = {x=1,y=6}, set = "Joker", effect = "", config = {mult = 0, extra = 1}, unlock_condition = {type = 'discard_custom'}},
        j_space=            {order = 45,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Space Joker", pos = {x=3,y=5}, set = "Joker", effect = "Upgrade Hand chance", cost_mult = 1.0, config = {extra = 4}},
        
        j_egg=              {order = 46,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = 'Egg', pos = {x = 0, y = 10}, set = 'Joker', config = {extra = 3}},
        j_burglar=          {order = 47,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = 'Burglar', pos = {x = 1, y = 10}, set = 'Joker', config = {extra = 3}},
        j_blackboard=       {order = 48,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = 'Blackboard', pos = {x = 2, y = 10}, set = 'Joker', config = {x_mult = 3}},
        j_runner=           {order = 49,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 5, name = 'Runner', pos = {x = 3, y = 10}, set = 'Joker', config = {extra = {chip_mod = 15}}},
        j_ice_cream=        {order = 50,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 1, cost = 5, name = 'Ice Cream', pos = {x = 4, y = 10}, set = 'Joker', config = {chips = 100, extra = {chip_mod = 5}}},
        j_dna=              {order = 51,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = 'DNA', pos = {x = 5, y = 10}, set = 'Joker', config = {}},
        j_splash=           {order = 52,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 3, name = 'Splash', pos = {x = 6, y = 10}, set = 'Joker', config = {}},
        j_blue_joker=       {order = 53,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = 'Blue Joker', pos = {x = 7, y = 10}, set = 'Joker', config = {extra = 2}},
        j_sixth_sense=      {order = 54,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = 'Sixth Sense', pos = {x = 8, y = 10}, set = 'Joker', config = {}},
        j_constellation=    {order = 55,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = 'Constellation', pos = {x = 9, y = 10}, set = 'Joker', config = {x_mult = 1, extra = 0.1}},
        j_hiker=            {order = 56,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = 'Hiker', pos = {x = 0, y = 11}, set = 'Joker', config = {extra = 5}},
        j_faceless=         {order = 57,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = 'Faceless Joker', pos = {x = 1, y = 11}, set = 'Joker', config = {dollars = 5, extra = {faces = 3}}},
        j_green_joker=      {order = 58,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 4, name = 'Green Joker', pos = {x = 2, y = 11}, set = 'Joker', config = {extra = {hand_add = 1, discard_sub = 1}}},
        j_superposition=    {order = 59,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = 'Superposition', pos = {x = 3, y = 11}, set = 'Joker', config = {}},
        j_todo_list=        {order = 60,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = 'To Do List', pos = {x = 4, y = 11}, set = 'Joker', config = {dollars = 4, extra = {poker_hand = 'High Card'}}},

        j_cavendish=        {order = 61,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 1, cost = 4, name = "Cavendish", pos = {x=5,y=11}, set = "Joker", cost_mult = 1.0, config = {x_mult = 3, extra = {odds = 1000}}, yes_pool_flag = 'gros_michel_extinct'},
        j_card_sharp=       {order = 62,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Card Sharp", pos = {x=6,y=11}, set = "Joker", cost_mult = 1.0, config = {x_mult = 3}},
        j_red_card=         {order = 63,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 5, name = "Red Card", pos = {x=7,y=11}, set = "Joker", cost_mult = 1.0, config = {extra = 3}},
        j_madness=          {order = 64,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Madness", pos = {x=8,y=11}, set = "Joker", cost_mult = 1.0, config = {extra = 0.5}},
        j_square=           {order = 65,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 4, name = "Square Joker", pos = {x=9,y=11}, scale={W=1,H=0.75}, set = "Joker", cost_mult = 1.0, config = {chips = 0, extra = {chip_mod = 4}}},
        j_seance=           {order = 66,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Seance", pos = {x=0,y=12}, set = "Joker", cost_mult = 1.0, config = {extra = {poker_hand = 'Straight Flush'}}},
        j_riff_raff=        {order = 67,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Riff-raff", pos = {x=1,y=12}, set = "Joker", cost_mult = 1.0, config = {extra = 2}},
        j_vampire=          {order = 68,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Vampire",set = "Joker", config = {extra = 0.1, x_mult = 1},  pos = {x=2,y=12}},
        j_shortcut=         {order = 69,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Shortcut",set = "Joker", config = {},  pos = {x=3,y=12}},
        j_hologram=         {order = 70,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Hologram",set = "Joker", config = {extra = 0.25, x_mult = 1},  pos = {x=4,y=12}, soul_pos = {x=2, y=9},},
        j_vagabond=         {order = 71,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Vagabond",set = "Joker", config = {extra = 4}, pos = {x=5,y=12}},
        j_baron=            {order = 72,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Baron",set = "Joker", config = {x_mult = 1.5}, pos = {x=6,y=12}},
        j_cloud_9=          {order = 73,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Cloud 9",set = "Joker", config = {extra = 1}, pos = {x=7,y=12}},
        j_rocket=           {order = 74,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Rocket",set = "Joker", config = {dollars = 1, extra = {increase = 2}}, pos = {x=8,y=12}},
        j_obelisk=          {order = 75,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 3, cost = 8, name = "Obelisk",set = "Joker", config = {extra = 0.2, x_mult = 1}, pos = {x=9,y=12}},

        j_midas_mask=       {order = 76,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Midas Mask",set = "Joker", config = {}, pos = {x=0,y=13}},
        j_luchador=         {order = 77,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 5, name = "Luchador",set = "Joker", config = {}, pos = {x=1,y=13}},
        j_photograph=       {order = 78,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Photograph",set = "Joker", config = {x_mult = 2}, pos = {x=2,y=13}, scale={W=1,H=1/1.2}},
        j_gift=             {order = 79,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Gift Card",set = "Joker", config = {extra = 1}, pos = {x=3,y=13}},
        j_turtle_bean=      {order = 80,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Turtle Bean",set = "Joker", config = {extra = {h_size = 5, h_mod = 1}}, pos = {x=4,y=13}},
        j_erosion=          {order = 81,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Erosion",set = "Joker", config = {extra = 4}, pos = {x=5,y=13}},
        j_reserved_parking= {order = 82,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Reserved Parking",set = "Joker", config = {dollars = 1, extra = {odds = 2}}, pos = {x=6,y=13}},
        j_mail=             {order = 83,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Mail-In Rebate",set = "Joker", config = {extra = 5}, pos = {x=7,y=13}},
        j_to_the_moon=      {order = 84,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "To the Moon",set = "Joker", config = {extra = 1}, pos = {x=8,y=13}},
        j_hallucination=    {order = 85,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Hallucination",set = "Joker", config = {extra = 2}, pos = {x=9,y=13}},
        j_fortune_teller=   {order = 86,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Fortune Teller", pos = {x=7,y=5}, set = "Joker", effect = "", config = {extra = 1}},
        j_juggler=          {order = 87,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Juggler", pos = {x=0,y=1}, set = "Joker", effect = "Hand Size", cost_mult = 1.0, config = {extra={h_size = 1}}},
        j_drunkard=         {order = 88,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Drunkard", pos = {x=1,y=1}, set = "Joker", effect = "Discard Size", cost_mult = 1.0, config = {extra={d_size = 1}}},
        j_stone=            {order = 89,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Stone Joker", pos = {x=9,y=0}, set = "Joker", effect = "Stone Card Buff", cost_mult = 1.0, config = {extra = 25}, enhancement_gate = 'm_stone'},
        j_golden=           {order = 90,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Golden Joker", pos = {x=9,y=2}, set = "Joker", effect = "Bonus dollars", cost_mult = 1.0, config = {dollars = 4}},

        j_lucky_cat=        {order = 91,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Lucky Cat",set = "Joker", config = {x_mult = 1, extra = 0.25}, pos = {x=5,y=14}, enhancement_gate = 'm_lucky'},
        j_baseball=         {order = 92,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Baseball Card",set = "Joker", config = {x_mult= 1.5}, pos = {x=6,y=14}},
        j_bull=             {order = 93,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Bull", set = "Joker", config = {extra = 2}, pos = {x=7,y=14}},
        j_diet_cola=        {order = 94,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Diet Cola",set = "Joker", config = {}, pos = {x=8,y=14}},
        j_trading=          {order = 95,   unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Trading Card",set = "Joker", config = {dollars = 3}, pos = {x=9,y=14}},
        j_flash=            {order = 96,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 5, name = "Flash Card",set = "Joker", config = {extra = 2, mult = 0}, pos = {x=0,y=15}},
        j_popcorn=          {order = 97,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 1, cost = 5, name = "Popcorn",set = "Joker", config = {mult = 20, extra = 4}, pos = {x=1,y=15}},
        j_trousers=         {order = 98,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Spare Trousers",set = "Joker", config = {extra = 2}, pos = {x=4,y=15}},
        j_ancient=          {order = 99,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Ancient Joker",set = "Joker", config = {x_mult = 1.5}, pos = {x=7,y=15}},
        j_ramen=            {order = 100,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Ramen",set = "Joker", config = {x_mult = 2, extra = 0.01}, pos = {x=2,y=15}},
        j_walkie_talkie=    {order = 101,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Walkie Talkie",set = "Joker", config = {chips = 10, mult = 4}, pos = {x=8,y=15}},
        j_selzer=           {order = 102,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Seltzer",set = "Joker", config = {extra = {hands = 10, reps = 1}}, pos = {x=3,y=15}},
        j_castle=           {order = 103,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Castle",set = "Joker", config = {chips = 0, extra = {chip_mod = 3}}, pos = {x=9,y=15}},
        j_smiley=           {order = 104,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Smiley Face",set = "Joker", config = {mult = 5}, pos = {x=6,y=15}},
        j_campfire=         {order = 105,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 9, name = "Campfire",set = "Joker", config = {extra = 0.25}, pos = {x=5,y=15}},

        j_ticket=           {order = 106,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Golden Ticket", pos = {x=5,y=3}, set = "Joker", effect = "dollars for Gold cards", cost_mult = 1.0, config = {dollars = 4},unlock_condition = {type = 'hand_contents', extra = 'Gold'}, enhancement_gate = 'm_gold'},
        j_mr_bones=         {order = 107,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 5, name = "Mr. Bones", pos = {x=3,y=4}, set = "Joker", effect = "Prevent Death", cost_mult = 1.0, config = {},unlock_condition = {type = 'c_losses', extra = 5}},
        j_acrobat=          {order = 108,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Acrobat", pos = {x=2,y=1}, set = "Joker", effect = "Shop size", cost_mult = 1.0, config = {x_mult = 3},unlock_condition = {type = 'c_hands_played', extra = 200}},
        j_sock_and_buskin=  {order = 109,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Sock and Buskin", pos = {x=3,y=1}, set = "Joker", effect = "Face card double", cost_mult = 1.0, config = {extra = {reps=1}},unlock_condition = {type = 'c_face_cards_played', extra = 300}},
        j_swashbuckler=     {order = 110,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Swashbuckler", pos = {x=9,y=5}, set = "Joker", effect = "Set Mult", cost_mult = 1.0, config = {mult = 0},unlock_condition = {type = 'c_jokers_sold', extra = 20}},
        j_troubadour=       {order = 111,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Troubadour", pos = {x=0,y=2}, set = "Joker", effect = "Hand Size, Plays", cost_mult = 1.0, config = {extra = {h_size = 2, h_plays = -1}}, unlock_condition = {type = 'round_win', extra = 5}},
        j_certificate=      {order = 112,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Certificate", pos = {x=8,y=8}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'double_gold'}},
        j_smeared=          {order = 113,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Smeared Joker", pos = {x=4,y=6}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'modify_deck', extra = {count = 3, enhancement = 'Wild Card', e_key = 'm_wild'}}},
        j_throwback=        {order = 114,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Throwback", pos = {x=5,y=7}, set = "Joker", effect = "", config = {extra = 0.25}, unlock_condition = {type = 'continue_game'}},
        j_hanging_chad=     {order = 115,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Hanging Chad", pos = {x=9,y=6}, set = "Joker", effect = "", config = {extra = {reps=2}}, unlock_condition = {type = 'round_win', extra = 'High Card'}},
        j_rough_gem=        {order = 116,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Rough Gem", pos = {x=9,y=7}, set = "Joker", effect = "", config = {dollars = 1}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Diamonds'}}},
        j_bloodstone=       {order = 117,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Bloodstone", pos = {x=0,y=8}, set = "Joker", effect = "", config = {x_mult = 1.5, extra = {odds = 2}}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Hearts'}}},
        j_arrowhead=        {order = 118,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Arrowhead", pos = {x=1,y=8}, set = "Joker", effect = "", config = {chips = 50}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Spades'}}},
        j_onyx_agate=       {order = 119,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Onyx Agate", pos = {x=2,y=8}, set = "Joker", effect = "", config = {mult = 7}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Clubs'}}},
        j_glass=            {order = 120,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Glass Joker", pos = {x=1,y=3}, set = "Joker", effect = "Glass Card", cost_mult = 1.0, config = {extra = 0.75, x_mult = 1}, unlock_condition = {type = 'modify_deck', extra = {count = 5, enhancement = 'Glass Card', e_key = 'm_glass'}}, enhancement_gate = 'm_glass'},
    
        j_ring_master=      {order = 121,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Showman", pos = {x=6,y=5}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'ante_up', ante = 4}},
        j_flower_pot=       {order = 122,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Flower Pot", pos = {x=0,y=6}, set = "Joker", effect = "", config = {x_mult = 3}, unlock_condition = {type = 'ante_up', ante = 8}},
        j_blueprint=        {order = 123,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 10,name = "Blueprint", pos = {x=0,y=3}, set = "Joker", effect = "Copycat", cost_mult = 1.0, config = {},unlock_condition = {type = 'win_custom'}},
        j_wee=              {order = 124,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 3, cost = 8, name = "Wee Joker", pos = {x=0,y=0}, scale={H=0.7,W=0.7,not_children=true}, set = "Joker", effect = "", config = {chips = 0, extra = 8}, unlock_condition = {type = 'win', n_rounds = 18}},
        j_merry_andy=       {order = 125,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Merry Andy", pos = {x=8,y=0}, set = "Joker", effect = "", cost_mult = 1.0, config = {extra={d_size = 3, h_size = -1}}, unlock_condition = {type = 'win', n_rounds = 12}},
        j_oops=             {order = 126,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 4, name = "Oops! All 6s", pos = {x=5,y=6}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'chip_score', chips = 10000}},
        j_idol=             {order = 127,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "The Idol", pos = {x=6,y=7}, set = "Joker", effect = "", config = {x_mult = 2}, unlock_condition = {type = 'chip_score', chips = 1000000}},
        j_seeing_double=    {order = 128,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Seeing Double", pos = {x=4,y=4}, set = "Joker", effect = "X1.5 Mult club 7", cost_mult = 1.0, config = {x_mult = 2},unlock_condition = {type = 'hand_contents', extra = 'four 7 of Clubs'}},
        j_matador=          {order = 129,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Matador", pos = {x=4,y=5}, set = "Joker", effect = "", config = {dollars = 8}, unlock_condition = {type = 'round_win'}},
        j_hit_the_road=     {order = 130,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Hit the Road", pos = {x=8,y=5}, set = "Joker", effect = "Jack Discard Effect", cost_mult = 1.0, config = {extra = 0.5}, unlock_condition = {type = 'discard_custom'}},
        j_duo=              {order = 131,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Duo", pos = {x=5,y=4}, set = "Joker", id = "Hand_X_Mult", cost_mult = 1.0, config = {x_mult = 2, type = 'Pair'}, unlock_condition = {type = 'win_no_hand', extra = 'Pair'}},
        j_trio=             {order = 132,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Trio", pos = {x=6,y=4}, set = "Joker", id = "Hand_X_Mult", cost_mult = 1.0, config = {x_mult = 3, type = 'Three of a Kind'}, unlock_condition = {type = 'win_no_hand', extra = 'Three of a Kind'}},
        j_family=           {order = 133,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Family", pos = {x=7,y=4}, set = "Joker", id = "Hand_X_Mult", cost_mult = 1.0, config = {x_mult = 4, type = 'Four of a Kind'}, unlock_condition = {type = 'win_no_hand', extra = 'Four of a Kind'}},
        j_order=            {order = 134,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Order", pos = {x=8,y=4}, set = "Joker", id = "Hand_X_Mult", cost_mult = 1.0, config = {x_mult = 3, type = 'Straight'}, unlock_condition = {type = 'win_no_hand', extra = 'Straight'}},
        j_tribe=            {order = 135,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Tribe", pos = {x=9,y=4}, set = "Joker", id = "Hand_X_Mult", cost_mult = 1.0, config = {x_mult = 2, type = 'Flush'}, unlock_condition = {type = 'win_no_hand', extra = 'Flush'}},
        
        j_stuntman=         {order = 136,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 7, name = "Stuntman", pos = {x=8,y=6}, set = "Joker", effect = "", config = {chips = 250, extra = {h_size = 2}}, unlock_condition = {type = 'chip_score', chips = 100000000}},
        j_invisible=        {order = 137,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 3, cost = 8, name = "Invisible Joker", pos = {x=1,y=7}, set = "Joker", effect = "", config = {extra = {init_rounds=2, current_rounds=0}}, unlock_condition = {type = 'win_custom'}},
        j_brainstorm=       {order = 138,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 10, name = "Brainstorm", pos = {x=7,y=7}, set = "Joker", effect = "Copycat", config = {}, unlock_condition = {type = 'discard_custom'}},
        j_satellite=        {order = 139,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Satellite", pos = {x=8,y=7}, set = "Joker", effect = "", config = {extra = 1}, unlock_condition = {type = 'money', extra = 400}},
        j_shoot_the_moon=   {order = 140,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Shoot the Moon", pos = {x=2,y=6}, set = "Joker", effect = "", config = {mult = 13}, unlock_condition = {type = 'play_all_hearts'}},
        j_drivers_license=  {order = 141,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 7, name = "Driver's License", pos = {x=0,y=7}, set = "Joker", effect = "", config = {x_mult = 3}, unlock_condition = {type = 'modify_deck', extra = {count = 16, tally = 'total'}}},
        j_cartomancer=      {order = 142,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Cartomancer", pos = {x=7,y=3}, set = "Joker", effect = "Tarot Buff", cost_mult = 1.0, config = {}, unlock_condition = {type = 'discover_amount', tarot_count = 22}},
        j_astronomer=       {order = 143,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 8, name = "Astronomer", pos = {x=2,y=7}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'discover_amount', planet_count = 12}},
        j_burnt=            {order = 144,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Burnt Joker", pos = {x=3,y=7}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'c_cards_sold', extra = 50}},
        j_bootstraps=       {order = 145,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Bootstraps", pos = {x=9,y=8}, set = "Joker", effect = "", config = {extra = {mult = 2, dollars = 5}}, unlock_condition = {type = 'modify_jokers', extra = {polychrome = true, count = 2}}},
        j_caino=            {order = 146,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Caino", pos = {x=3,y=8}, soul_pos = {x=3, y=9}, set = "Joker", effect = "", config = {extra = 1}, unlock_condition = {type = '', extra = '', hidden = true}},
        j_triboulet=        {order = 147,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Triboulet", pos = {x=4,y=8}, soul_pos = {x=4, y=9}, set = "Joker", effect = "", config = {x_mult = 2}, unlock_condition = {type = '', extra = '', hidden = true}},
        j_yorick=           {order = 148,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Yorick", pos = {x=5,y=8}, soul_pos = {x=5, y=9}, set = "Joker", effect = "", config = {extra = {x_mult = 1, discards = 23, current_discards=23}}, unlock_condition = {type = '', extra = '', hidden = true}},
        j_chicot=           {order = 149,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Chicot", pos = {x=6,y=8}, soul_pos = {x=6, y=9}, set = "Joker", effect = "", config = {}, unlock_condition = {type = '', extra = '', hidden = true}},
        j_perkeo=           {order = 150,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Perkeo", pos = {x=7,y=8}, soul_pos = {x=7, y=9}, set = "Joker", effect = "", config = {}, unlock_condition = {type = '', extra = '', hidden = true}},
}
-- This adds the id and sprite atlas variables to every item in the above table.
-- This is way faster than adding them manually
for k, v in pairs(vanilla_jokers_set) do
    if not vanilla_jokers_set[k].id then vanilla_jokers_set[k].id = k end
    vanilla_jokers_set[k].atlas = 'Joker'
end

function vanilla_joker_function_collector()
    return define_joker_functions()
end

-------------------------------------------------------------------
-------------------------------------------------------------------
---                     GLOBAL JOKER RESETS                     ---
-------------------------------------------------------------------
-------------------------------------------------------------------
--- Used for jokers that reset a global variable at the end of the round reguardless of if 
--- they're in the player's deck or not.
local resets = {
    function() --reset j_mail
        G.GAME.current_round.mail_card.rank = 'Ace'
        local valid_mail_cards = {}
        for k, v in ipairs(G.playing_cards) do
            if not v.ability.faceless then
                valid_mail_cards[#valid_mail_cards+1] = v
            end
        end
        if valid_mail_cards[1] then 
            local mail_card = pseudorandom_element(valid_mail_cards, pseudoseed('mail'..G.GAME.round_resets.ante))
            G.GAME.current_round.mail_card.rank = mail_card.base.value
            G.GAME.current_round.mail_card.id = mail_card.base.id
        end
    end,

    function() -- reset j_idol
        G.GAME.current_round.idol_card.rank = 'Ace'
        G.GAME.current_round.idol_card.suit = 'Spades'
        local valid_idol_cards = {}
        for k, v in ipairs(G.playing_cards) do
            if not v.ability.faceless then
                valid_idol_cards[#valid_idol_cards+1] = v
            end
        end
        if valid_idol_cards[1] then 
            local idol_card = pseudorandom_element(valid_idol_cards, pseudoseed('idol'..G.GAME.round_resets.ante))
            G.GAME.current_round.idol_card.rank = idol_card.base.value
            G.GAME.current_round.idol_card.suit = idol_card.base.suit
            G.GAME.current_round.idol_card.id = idol_card.base.id
        end
    end,

    function() -- reset j_ancient
        local ancient_suits = {}
        for k, v in ipairs({'Spades','Hearts','Clubs','Diamonds'}) do
            if v ~= G.GAME.current_round.ancient_card.suit then ancient_suits[#ancient_suits + 1] = v end
        end
        local ancient_card = pseudorandom_element(ancient_suits, pseudoseed('anc'..G.GAME.round_resets.ante))
        G.GAME.current_round.ancient_card.suit = ancient_card
    end,

    function() -- reset j_castle
        G.GAME.current_round.castle_card.suit = 'Spades'
        local valid_castle_cards = {}
        for k, v in ipairs(G.playing_cards) do
            if not v.ability.faceless then
                valid_castle_cards[#valid_castle_cards+1] = v
            end
        end
        if valid_castle_cards[1] then 
            local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('cas'..G.GAME.round_resets.ante))
            G.GAME.current_round.castle_card.suit = castle_card.base.suit
        end
    end
}

-- add to global_joker_resets
-- global_joker_resets used in state_events:end_round()
concat_table(global_joker_resets,resets)
--------------------------------------------------------------------------