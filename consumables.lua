--[[

Author:         SirBillGree
File:           Consumables.lua
Creation Date:  12/16/2025
-----------------------------------------------------------------------------------------------
Description:
    This is part of the restructuring process. The purpose is to make the game more modable by 
consolidating as much of the disperate elements needed to add new cards into one place. 
    Functions called when using and testing if consumables can be used is consolidated here and
passed to the card object. 

]]--

--[[

Params all consumables will need:
[x] use function
[x] can_use function
[x] UI gen arguments (localization will remain it's own file)

functions in other files that need edits or restructuring:
[x] card:can_use_consumeable()          -- ITITAL BLOCK REQUIRED
[x] card:use_consumeable()
[x] card:set_ability()                  -- set new params
[x] common_events:generate_card_ui()    -- arguments for all instances of a card

]]--

local consumables_set = {
    -- Tarots
    c_fool=             {id = 'c_fool', order = 1,     discovered = false, cost = 3, consumeable = true, name = "The Fool", pos = {x=0,y=0}, set = "Tarot", effect = "Disable Blind Effect", cost_mult = 1.0, config = {}},
    c_magician=         {id = 'c_magician', order = 2,     discovered = false, cost = 3, consumeable = true, name = "The Magician", pos = {x=1,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_lucky', max_highlighted = 2}},
    c_high_priestess=   {id = 'c_high_priestess', order = 3,     discovered = false, cost = 3, consumeable = true, name = "The High Priestess", pos = {x=2,y=0}, set = "Tarot", effect = "Round Bonus", cost_mult = 1.0, config = {planets = 2}},
    c_empress=          {id = 'c_empress', order = 4,     discovered = false, cost = 3, consumeable = true, name = "The Empress", pos = {x=3,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_mult', max_highlighted = 2}},
    c_emperor=          {id = 'c_emperor', order = 5,     discovered = false, cost = 3, consumeable = true, name = "The Emperor", pos = {x=4,y=0}, set = "Tarot", effect = "Round Bonus", cost_mult = 1.0, config = {tarots = 2}},
    c_heirophant=       {id = 'c_heirophant', order = 6,     discovered = false, cost = 3, consumeable = true, name = "The Hierophant", pos = {x=5,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_bonus', max_highlighted = 2}},
    c_lovers=           {id = 'c_lovers', order = 7,     discovered = false, cost = 3, consumeable = true, name = "The Lovers", pos = {x=6,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_wild', max_highlighted = 1}},
    c_chariot=          {id = 'c_chariot', order = 8,     discovered = false, cost = 3, consumeable = true, name = "The Chariot", pos = {x=7,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_steel', max_highlighted = 1}},
    c_justice=          {id = 'c_justice', order = 9,     discovered = false, cost = 3, consumeable = true, name = "Justice", pos = {x=8,y=0}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_glass', max_highlighted = 1}},
    c_hermit=           {id = 'c_hermit', order = 10,    discovered = false, cost = 3, consumeable = true, name = "The Hermit", pos = {x=9,y=0}, set = "Tarot", effect = "Dollar Doubler", cost_mult = 1.0, config = {extra = 20}},
    c_wheel_of_fortune= {id = 'c_wheel_of_fortune', order = 11,    discovered = false, cost = 3, consumeable = true, name = "The Wheel of Fortune", pos = {x=0,y=1}, set = "Tarot", effect = "Round Bonus", cost_mult = 1.0, config = {extra = 4}},
    c_strength=         {id = 'c_strength', order = 12,    discovered = false, cost = 3, consumeable = true, name = "Strength", pos = {x=1,y=1}, set = "Tarot", effect = "Round Bonus", cost_mult = 1.0, config = {mod_conv = 'up_rank', max_highlighted = 2}},
    c_hanged_man=       {id = 'c_hanged_man', order = 13,    discovered = false, cost = 3, consumeable = true, name = "The Hanged Man", pos = {x=2,y=1}, set = "Tarot", effect = "Card Removal", cost_mult = 1.0, config = {remove_card = true, max_highlighted = 2}},
    c_death=            {id = 'c_death', order = 14,    discovered = false, cost = 3, consumeable = true, name = "Death", pos = {x=3,y=1}, set = "Tarot", effect = "Card Conversion", cost_mult = 1.0, config = {mod_conv = 'card', max_highlighted = 2, min_highlighted = 2}},
    c_temperance=       {id = 'c_temperance', order = 15,    discovered = false, cost = 3, consumeable = true, name = "Temperance", pos = {x=4,y=1}, set = "Tarot", effect = "Joker Payout", cost_mult = 1.0, config = {extra = 50}},
    c_devil=            {id = 'c_devil', order = 16,    discovered = false, cost = 3, consumeable = true, name = "The Devil", pos = {x=5,y=1}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_gold', max_highlighted = 1}},
    c_tower=            {id = 'c_tower', order = 17,    discovered = false, cost = 3, consumeable = true, name = "The Tower", pos = {x=6,y=1}, set = "Tarot", effect = "Enhance", cost_mult = 1.0, config = {mod_conv = 'm_stone', max_highlighted = 1}},
    c_star=             {id = 'c_star', order = 18,    discovered = false, cost = 3, consumeable = true, name = "The Star", pos = {x=7,y=1}, set = "Tarot", effect = "Suit Conversion", cost_mult = 1.0, config = {suit_conv = 'Diamonds', max_highlighted = 3}},
    c_moon=             {id = 'c_moon', order = 19,    discovered = false, cost = 3, consumeable = true, name = "The Moon", pos = {x=8,y=1}, set = "Tarot", effect = "Suit Conversion", cost_mult = 1.0, config = {suit_conv = 'Clubs', max_highlighted = 3}},
    c_sun=              {id = 'c_sun', order = 20,    discovered = false, cost = 3, consumeable = true, name = "The Sun", pos = {x=9,y=1}, set = "Tarot", effect = "Suit Conversion", cost_mult = 1.0, config = {suit_conv = 'Hearts', max_highlighted = 3}},
    c_judgement=        {id = 'c_judgement', order = 21,    discovered = false, cost = 3, consumeable = true, name = "Judgement", pos = {x=0,y=2}, set = "Tarot", effect = "Random Joker", cost_mult = 1.0, config = {}},
    c_world=            {id = 'c_world', order = 22,    discovered = false, cost = 3, consumeable = true, name = "The World", pos = {x=1,y=2}, set = "Tarot", effect = "Suit Conversion", cost_mult = 1.0, config = {suit_conv = 'Spades', max_highlighted = 3}},

    --Planets
    c_mercury=          {id = 'c_mercury', order = 1,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Mercury", pos = {x=0,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Pair'}},
    c_venus=            {id = 'c_venus', order = 2,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Venus", pos = {x=1,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Three of a Kind'}},
    c_earth=            {id = 'c_earth', order = 3,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Earth", pos = {x=2,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Full House'}},
    c_mars=             {id = 'c_mars', order = 4,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Mars", pos = {x=3,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Four of a Kind'}},
    c_jupiter=          {id = 'c_jupiter', order = 5,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Jupiter", pos = {x=4,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Flush'}},
    c_saturn=           {id = 'c_saturn', order = 6,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Saturn", pos = {x=5,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Straight'}},
    c_uranus=           {id = 'c_uranus', order = 7,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Uranus", pos = {x=6,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Two Pair'}},
    c_neptune=          {id = 'c_neptune', order = 8,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Neptune", pos = {x=7,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Straight Flush'}},
    c_pluto=            {id = 'c_pluto', order = 9,    discovered = false, cost = 3, consumeable = true, freq = 1, name = "Pluto", pos = {x=8,y=3}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'High Card'}},
    c_planet_x=         {id = 'c_planet_x', order = 10,   discovered = false, cost = 3, consumeable = true, freq = 1, name = "Planet X", pos = {x=9,y=2}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Five of a Kind', softlock = true}},
    c_ceres=            {id = 'c_ceres', order = 11,   discovered = false, cost = 3, consumeable = true, freq = 1, name = "Ceres", pos = {x=8,y=2}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Flush House', softlock = true}},
    c_eris=             {id = 'c_eris', order = 12,   discovered = false, cost = 3, consumeable = true, freq = 1, name = "Eris", pos = {x=3,y=2}, set = "Planet", effect = "Hand Upgrade", cost_mult = 1.0, config = {hand_type = 'Flush Five', softlock = true}},

    --Spectral
    c_familiar=         {id = 'c_familiar', order = 1,    discovered = false, cost = 4, consumeable = true, name = "Familiar", pos = {x=0,y=4}, set = "Spectral", config = {remove_card = true, extra = 3}},
    c_grim=             {id = 'c_grim', order = 2,    discovered = false, cost = 4, consumeable = true, name = "Grim",     pos = {x=1,y=4}, set = "Spectral", config = {remove_card = true, extra = 2}},
    c_incantation=      {id = 'c_incantation', order = 3,    discovered = false, cost = 4, consumeable = true, name = "Incantation", pos = {x=2,y=4}, set = "Spectral", config = {remove_card = true, extra = 4}},
    c_talisman=         {id = 'c_talisman', order = 4,    discovered = false, cost = 4, consumeable = true, name = "Talisman", pos = {x=3,y=4}, set = "Spectral", config = {extra = 'Gold', max_highlighted = 1}},
    c_aura=             {id = 'c_aura', order = 5,    discovered = false, cost = 4, consumeable = true, name = "Aura", pos = {x=4,y=4}, set = "Spectral", config = {}},
    c_wraith=           {id = 'c_wraith', order = 6,    discovered = false, cost = 4, consumeable = true, name = "Wraith", pos = {x=5,y=4}, set = "Spectral", config = {}},
    c_sigil=            {id = 'c_sigil', order = 7,    discovered = false, cost = 4, consumeable = true, name = "Sigil", pos = {x=6,y=4}, set = "Spectral", config = {}},
    c_ouija=            {id = 'c_ouija', order = 8,    discovered = false, cost = 4, consumeable = true, name = "Ouija", pos = {x=7,y=4}, set = "Spectral", config = {}},
    c_ectoplasm=        {id = 'c_ectoplasm', order = 9,    discovered = false, cost = 4, consumeable = true, name = "Ectoplasm", pos = {x=8,y=4}, set = "Spectral", config = {}},
    c_immolate=         {id = 'c_immolate', order = 10,   discovered = false, cost = 4, consumeable = true, name = "Immolate", pos = {x=9,y=4}, set = "Spectral", config = {remove_card = true, extra = {destroy = 5, dollars = 20}}},
    c_ankh=             {id = 'c_ankh', order = 11,   discovered = false, cost = 4, consumeable = true, name = "Ankh", pos = {x=0,y=5}, set = "Spectral", config = {extra = 2}},
    c_deja_vu=          {id = 'c_deja_vu', order = 12,   discovered = false, cost = 4, consumeable = true, name = "Deja Vu", pos = {x=1,y=5}, set = "Spectral", config = {extra = 'Red', max_highlighted = 1}},
    c_hex=              {id = 'c_hex', order = 13,   discovered = false, cost = 4, consumeable = true, name = "Hex", pos = {x=2,y=5}, set = "Spectral", config = {extra = 2}},
    c_trance=           {id = 'c_trance', order = 14,   discovered = false, cost = 4, consumeable = true, name = "Trance", pos = {x=3,y=5}, set = "Spectral", config = {extra = 'Blue', max_highlighted = 1}},
    c_medium=           {id = 'c_medium', order = 15,   discovered = false, cost = 4, consumeable = true, name = "Medium", pos = {x=4,y=5}, set = "Spectral", config = {extra = 'Purple', max_highlighted = 1}},
    c_cryptid=          {id = 'c_cryptid', order = 16,   discovered = false, cost = 4, consumeable = true, name = "Cryptid", pos = {x=5,y=5}, set = "Spectral", config = {extra = 2, max_highlighted = 1}},
    c_soul=             {id = 'c_soul', order = 17,   discovered = false, cost = 4, consumeable = true, name = "The Soul", pos = {x=2,y=2}, set = "Spectral", effect = "Unlocker", config = {}, hidden = true},
    c_black_hole=       {id = 'c_black_hole', order = 18,   discovered = false, cost = 4, consumeable = true, name = "Black Hole", pos = {x=9,y=3}, set = "Spectral", config = {}, hidden = true},
}



local consumsables_functions = {
    c_fool=             {can_use = fool_condition(),            use = give_last_tarot_planet(), ui = uidef_fool()},
    c_magician=         {can_use = selected_card_limit(2),      use = conversion(enhance_conv('m_lucky')), ui = uidef_enhancer_tarot(2, 'm_lucky')},
    c_high_priestess=   {can_use = have_consumable_space(),     use = give_consumables(2, "Planets", 'pri'), ui = uidef({2})},
    c_empress=          {can_use = selected_card_limit(2),      use = conversion(enhance_conv('m_mult')), ui = uidef_enhancer_tarot(2, 'm_mult')},
    c_emperor=          {can_use = have_consumable_space(),     use = give_consumables(2, "Tarots", 'emp'), ui = uidef({2})},
    c_heirophant=       {can_use = selected_card_limit(2),      use = conversion(enhance_conv('m_bonus')), ui = uidef_enhancer_tarot(2, 'm_bonus')},
    c_lovers=           {can_use = selected_card_limit(1),      use = conversion(enhance_conv('m_wild')), ui = uidef_enhancer_tarot(1, 'm_wild')},
    c_chariot=          {can_use = selected_card_limit(1),      use = conversion(enhance_conv('m_steel')), ui = uidef_enhancer_tarot(1, 'm_steel')},
    c_justice=          {can_use = selected_card_limit(1),      use = conversion(enhance_conv('m_glass')), ui = uidef_enhancer_tarot(1, 'm_glass')},
    c_hermit=           {can_use = can_always_use(),            use = double_money(20), ui = uidef({money = 20})},
    c_wheel_of_fortune= {can_use = have_editionless_jokers(),   use = random_joker_give_edition('random', 'wheel_of_fortune', wheel_spin(4), nil), ui = uidef_wheel()},
    c_strength=         {can_use = selected_card_limit(2),      use = conversion(value_up_conv()), ui = uidef({2})},
    c_hanged_man=       {can_use = selected_card_limit(2),      use = remove_selected_cards(), ui = uidef({2})},
    c_death=            {can_use = selected_card_limit(2,2),    use = conversion(left_to_right_conv()), ui = uidef({2})},
    c_temperance=       {can_use = can_always_use(),            use = give_joker_sell_value(50), ui = uidef_temperance()},
    c_devil=            {can_use = selected_card_limit(1),      use = conversion(enhance_conv('m_gold')), ui = uidef_enhancer_tarot(1, 'm_gold')},
    c_tower=            {can_use = selected_card_limit(1),      use = conversion(enhance_conv('m_stone')), ui = uidef_enhancer_tarot(1, 'm_stone')},
    c_star=             {can_use = selected_card_limit(3),      use = conversion(suit_conv('Diamonds')), ui = uidef_suit_tarot(3, 'Diamonds')},
    c_moon=             {can_use = selected_card_limit(3),      use = conversion(suit_conv('Clubs')), ui = uidef_suit_tarot(3, 'Clubs')},
    c_sun=              {can_use = selected_card_limit(3),      use = conversion(suit_conv('Hearts')), ui = uidef_suit_tarot(3, 'Hearts')},
    c_judgement=        {can_use = have_joker_space(),          use = give_joker(false, 'jud'), ui = uidef()},
    c_world=            {can_use = selected_card_limit(3),      use = conversion(suit_conv('Spades')), ui = uidef_suit_tarot(3, 'Spades')},

    c_mercury=          {can_use = can_always_use(), use = hand_level_up('Pair'), ui = uidef_planet('Pair')},
    c_venus=            {can_use = can_always_use(), use = hand_level_up('Three of a Kind'), ui = uidef_planet('Three of a Kind')},
    c_earth=            {can_use = can_always_use(), use = hand_level_up('Full House'), ui = uidef_planet('Full House')},
    c_mars=             {can_use = can_always_use(), use = hand_level_up('Four of a Kind'), ui = uidef_planet('Four of a Kind')},
    c_jupiter=          {can_use = can_always_use(), use = hand_level_up('Flush'), ui = uidef_planet('Flush')},
    c_saturn=           {can_use = can_always_use(), use = hand_level_up('Straight'), ui = uidef_planet('Straight')},
    c_uranus=           {can_use = can_always_use(), use = hand_level_up('Two Pair'), ui = uidef_planet('Two Pair')},
    c_neptune=          {can_use = can_always_use(), use = hand_level_up('Straight Flush'), ui = uidef_planet('Straight Flush')},
    c_pluto=            {can_use = can_always_use(), use = hand_level_up('High Card'), ui = uidef_planet('High Card')},
    c_planet_x=         {can_use = can_always_use(), use = hand_level_up('Five of a Kind'), ui = uidef_planet('Five of a Kind')},
    c_ceres=            {can_use = can_always_use(), use = hand_level_up('Flush House'), ui = uidef_planet('Flush House')},
    c_eris=             {can_use = can_always_use(), use = hand_level_up('Flush Five'), ui = uidef_planet('Flush Five')},

    c_familiar=         {can_use = have_hand(),                 use = destroy_cards_for_reward(1,for_cards(3,{'J', 'Q', 'K'},{'S','H','D','C'},'familiar_create')), ui = uidef({3})},
    c_grim=             {can_use = have_hand(),                 use = destroy_cards_for_reward(1,for_cards(2,{'A'},{'S','H','D','C'},'grim_create')), ui = uidef({2})},
    c_incantation=      {can_use = have_hand(),                 use = destroy_cards_for_reward(1,for_cards(4,{'2', '3', '4', '5', '6', '7', '8', '9', 'T'},{'S','H','D','C'},'incantation_create')), ui = uidef({4})},
    c_talisman=         {can_use = selected_card_limit(1),      use = add_seal("Gold"), ui = uidef_seal_spectral('gold')},
    c_aura=             {can_use = selected_card_limit(1),      use = give_card_edition(), ui = uidef(nil,{G.P_CENTERS.e_foil,G.P_CENTERS.e_holo,G.P_CENTERS.e_polychrome})},
    c_wraith=           {can_use = have_joker_space(),          use = get_rare(), ui = uidef()},
    c_sigil=            {can_use = have_hand(),                 use = alter_hand_cards(same_random_suit_alter()), ui = uidef()},
    c_ouija=            {can_use = have_hand(),                 use = alter_hand_cards(same_random_rank_alter()), ui = uidef()},
    c_ectoplasm=        {can_use = have_editionless_jokers(),   use = random_joker_give_edition({negative = true},'ectoplasm',nil,reduce_hand_size()), ui = uidef_ectoplasm()},
    c_immolate=         {can_use = have_hand(),                 use = destroy_cards_for_reward(for_money(20)), ui = uidef({5,20})},
    c_ankh=             {can_use = have_one_joker(),            use = double_joker(), ui = uidef_ankh()},
    c_deja_vu=          {can_use = selected_card_limit(1),      use = add_seal("Red"), ui = uidef_seal_spectral('red')},
    c_hex=              {can_use = have_editionless_jokers(),   use = random_joker_give_edition({polychrome = true},'hex',nil,destory_all_other_jokers()), ui = uidef({},{G.P_CENTERS.e_polychrome})},
    c_trance=           {can_use = selected_card_limit(1),      use = add_seal("Blue"), ui = uidef_seal_spectral('blue')},
    c_medium=           {can_use = selected_card_limit(1),      use = add_seal("Purple"), ui = uidef_seal_spectral('purple')},
    c_cryptid=          {can_use = selected_card_limit(1),      use = make_playing_card_copy(2), ui = uidef({2})},
    c_soul=             {can_use = have_joker_space(),          use = give_joker(true, 'sol'), ui = uidef()},
    c_black_hole=       {can_use = can_always_use(),            use = level_up_all_hands(), ui = uidef()},
}



function add_consumables(CENTERS)
    for k, v in pairs(consumables_set) do
        CENTERS[k] = v
    end
    return CENTERS
end

function get_consumable_functions(id)
    return consumsables_functions[id]
end

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                       UI_DEFINITION FUNCTIONS                         --
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- input external: varied, given in card c_ table
-- output external: interal function
-- input: info_queue
-- output: text_vars, info_queue, descript_nodes

-------------------------------------------
--               General                 --
-------------------------------------------

-- Generic ui function. DO NOT USE IF VALUES CHANGE.
function uidef(text_vars, info_add)
    text_vars = text_vars or {}
    info_add = info_add or nil
    return function(info_queue)
        if info_add then
            for _, v in ipairs(info_add) do
                info_queue[#info_queue+1] = v
            end
        end
        return text_vars, info_queue, {}
    end
end

function uidef_planet(hand_type)
    return function(info_queue)
        local text_vars = {
            G.GAME.hands[hand_type].level,localize(hand_type, 'poker_hands'), G.GAME.hands[hand_type].l_mult, G.GAME.hands[hand_type].l_chips,
            colours = {(G.GAME.hands[hand_type].level==1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, G.GAME.hands[hand_type].level)])}
        }
        return text_vars, info_queue, {}
    end
end

function uidef_enhancer_tarot(max_select, enhancement)
    return function(info_queue)
        local text_vars = {max_select, localize{type = 'name_text', set = 'Enhanced', key = enhancement}}
        info_queue[#info_queue+1] = G.P_CENTERS[enhancement]
        return text_vars, info_queue, {}
    end
end

function uidef_suit_tarot(max_select, suit)
    return function(info_queue)
        local text_vars = {max_select,  localize(suit, 'suits_plural'), colours = {G.C.SUITS[suit]}}
        return text_vars, info_queue, {}
    end
end

function uidef_seal_spectral(color)
    return function(info_queue)
        info_queue[#info_queue+1] = {key = color..'_seal', set = 'Other'}
        return {}, info_queue, {}
    end
end

-------------------------------------------
--               Specific                --
-------------------------------------------

function uidef_ankh()
    return function(info_queue)
        local des_node
        if G.jokers and G.jokers.cards then
            for k, v in ipairs(G.jokers.cards) do
                if (v.edition and v.edition.negative) and (G.localization.descriptions.Other.remove_negative)then 
                    info_queue[#info_queue+1] = G.P_CENTERS.e_negative
                    des_node = {}
                    localize{type = 'other', key = 'remove_negative', nodes = des_node, vars = {}}
                    des_node = des_node[1]
                    break
                end
            end
        end
        return {}, info_queue, des_node
    end
end

function uidef_fool()
    return function(info_queue)
        local fool_c = G.GAME.last_tarot_planet and G.P_CENTERS[G.GAME.last_tarot_planet] or nil
        local last_tarot_planet = fool_c and localize{type = 'name_text', key = fool_c.key, set = fool_c.set} or localize('k_none')
        local colour = (not fool_c or fool_c.name == 'The Fool') and G.C.RED or G.C.GREEN
        local des_node = {
            {n=G.UIT.C, config={align = "bm", padding = 0.02}, nodes={
                {n=G.UIT.C, config={align = "m", colour = colour, r = 0.05, padding = 0.05}, nodes={
                    {n=G.UIT.T, config={text = ' '..last_tarot_planet..' ', colour = G.C.UI.TEXT_LIGHT, scale = 0.3, shadow = true}},
                }}
            }}
        }
        local text_vars = {last_tarot_planet}
        if not (not fool_c or fool_c.name == 'The Fool') then
            info_queue[#info_queue+1] = fool_c
        end
    return text_vars, info_queue, des_node
    end
end

function uidef_temperance()
    return function(info_queue)
        local _money = 0
        if G.jokers then
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i].ability.set == 'Joker' then
                    _money = _money + G.jokers.cards[i].sell_cost
                end
            end
        end
    local text_vars = {50, math.min(50, _money)}
    return  text_vars, info_queue, {}
    end
end

-------------------------------------------------
--                Changing Vars                --
-------------------------------------------------

function uidef_wheel()
    return function(info_queue)
        local text_vars = {G.GAME.probabilities.normal, 4}
        info_queue[#info_queue+1] = G.P_CENTERS.e_foil
        info_queue[#info_queue+1] = G.P_CENTERS.e_holo
        info_queue[#info_queue+1] = G.P_CENTERS.e_polychrome
        return text_vars, info_queue, {}
    end
end

function uidef_ectoplasm()
    return function(info_queue)
        local text_vars = {G.GAME.ecto_minus or 1}
        info_queue[#info_queue+1] = G.P_CENTERS.e_negative
        return text_vars, info_queue, {}
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                          ON USE FUNCTIONS                             --
---------------------------------------------------------------------------
---------------------------------------------------------------------------


-------------------------------------------
--               Planets                 --
-------------------------------------------

function hand_level_up(hand_type)
    return function(used_tarot)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize(hand_type, 'poker_hands'),chips = G.GAME.hands[hand_type].chips, mult = G.GAME.hands[hand_type].mult, level=G.GAME.hands[hand_type].level})
        level_up_hand(used_tarot, hand_type)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
    end
end

-------------------------------------------
--           Seal Spectrals              --
-------------------------------------------

function add_seal(seal_type) -- "Red", "Blue", "Purple", "Gold"
    return function(used_tarot)
        local conv_card = G.hand.highlighted[1]
        G.E_MANAGER:add_event(Event({func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        
        G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
            conv_card:set_seal(seal_type, nil, true)
            return true end }))
        
        delay(0.5)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
    end
end

-------------------------------------------
--           Single Instance             --
-------------------------------------------

function level_up_all_hands()
    return function(used_tarot)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize('k_all_hands'),chips = '...', mult = '...', level=''})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.8, 0.5)
            G.TAROT_INTERRUPT_PULSE = true
            return true end }))
        update_hand_text({delay = 0}, {mult = '+', StatusText = true})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.8, 0.5)
            return true end }))
        update_hand_text({delay = 0}, {chips = '+', StatusText = true})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.8, 0.5)
            G.TAROT_INTERRUPT_PULSE = nil
            return true end }))
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.9, delay = 0}, {level='+1'})
        delay(1.3)
        for k, v in pairs(G.GAME.hands) do
            level_up_hand(used_tarot, k, true)
        end
        update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
    end
end

function give_card_edition() -- aura
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            local over = false
            local edition = poll_edition('aura', nil, true, true)
            local aura_card = G.hand.highlighted[1]
            aura_card:set_edition(edition, true)
            used_tarot:juice_up(0.3, 0.5)
        return true end }))
    end
end

function make_playing_card_copy(copies) -- cryptid,  copies = 2
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({
            func = function()
                local _first_dissolve = nil
                local new_cards = {}
                for i = 1, copies do
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(G.hand.highlighted[1], nil, nil, G.playing_card)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    _card:start_materialize(nil, _first_dissolve)
                    _first_dissolve = true
                    new_cards[#new_cards+1] = _card
                end
                playing_card_joker_effects(new_cards)
                return true
            end
        })) 
    end
end

function remove_selected_cards()
    return function(used_tarot)
        local destroyed_cards = {}
        for i=#G.hand.highlighted, 1, -1 do
            destroyed_cards[#destroyed_cards+1] = G.hand.highlighted[i]
        end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function() 
                for i=#G.hand.highlighted, 1, -1 do
                    local card = G.hand.highlighted[i]
                    if card.ability.name == 'Glass Card' then 
                        card:shatter()
                    else
                        card:start_dissolve(nil, i == #G.hand.highlighted)
                    end
                end
                return true end }))
    end
end

function give_last_tarot_planet()
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            if G.consumeables.config.card_limit > #G.consumeables.cards then
                play_sound('timpani')
                local card = create_card('Tarot_Planet', G.consumeables, nil, nil, nil, nil, G.GAME.last_tarot_planet, 'fool')
                card:add_to_deck()
                G.consumeables:emplace(card)
                used_tarot:juice_up(0.3, 0.5)
            end
            return true end }))
        delay(0.6)
    end
end

function double_money(max)
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            used_tarot:juice_up(0.3, 0.5)
            ease_dollars(math.max(0,math.min(G.GAME.dollars, max)), true)
            return true end }))
        delay(0.6)
    end
end

function give_joker_sell_value(max)
    return function(used_tarot)
        local joker_value = 0
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i].ability.set == 'Joker' then
               joker_value = joker_value + G.jokers.cards[i].sell_cost
            end
        end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            used_tarot:juice_up(0.3, 0.5)
            ease_dollars(math.max(0,math.min(joker_value, max)), true)
            return true end }))
        delay(0.6)
    end
end


-------------------------------------------
--           Give Consumables            --
-------------------------------------------

function give_consumables(amt, type, pseudorandom_seed)
    return function(used_tarot)
        for i = 1, math.min(amt, G.consumeables.config.card_limit - #G.consumeables.cards) do
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                if G.consumeables.config.card_limit > #G.consumeables.cards then
                    play_sound('timpani')
                    local card = create_card(type, G.consumeables, nil, nil, nil, nil, nil, pseudorandom_seed)
                    card:add_to_deck()
                    G.consumeables:emplace(card)
                    used_tarot:juice_up(0.3, 0.5)
                end
                return true end }))
        end
        delay(0.6)
    end
end

-------------------------------------------
--              Give Joker               --
-------------------------------------------

function give_joker(legendary, pseudorandom_seed)
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            local card = create_card('Joker', G.jokers, legendary, nil, nil, nil, nil, pseudorandom_seed)
            card:add_to_deck()
            G.jokers:emplace(card)
            if legendary then check_for_unlock{type = 'spawn_legendary'} end
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        delay(0.6)
    end
end

function double_joker()
    return function(used_tarot)
        --Need to check for edgecases - if there are max Jokers and all are eternal OR there is a max of 1 joker this isn't possible already
        --If there are max Jokers and exactly 1 is not eternal, that joker cannot be the one selected
        --otherwise, the selected joker can be totally random and all other non-eternal jokers can be removed
        local deletable_jokers = {}
        for k, v in pairs(G.jokers.cards) do
            if not v.ability.eternal then deletable_jokers[#deletable_jokers + 1] = v end
        end
        local chosen_joker = pseudorandom_element(G.jokers.cards, pseudoseed('ankh_choice'))
        local _first_dissolve = nil
        G.E_MANAGER:add_event(Event({trigger = 'before', delay = 0.75, func = function()
            for k, v in pairs(deletable_jokers) do
                if v ~= chosen_joker then 
                    v:start_dissolve(nil, _first_dissolve)
                    _first_dissolve = true
                end
            end
            return true end }))
        G.E_MANAGER:add_event(Event({trigger = 'before', delay = 0.4, func = function()
            local card = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
            card:start_materialize()
            card:add_to_deck()
            if card.edition and card.edition.negative then
                card:set_edition(nil, true)
            end
            G.jokers:emplace(card)
            return true end }))
    end
end

function get_rare()
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            local card = create_card('Joker', G.jokers, nil, 0.99, nil, nil, nil, 'wra')
            card:add_to_deck()
            G.jokers:emplace(card)
            used_tarot:juice_up(0.3, 0.5)
            if G.GAME.dollars ~= 0 then
                ease_dollars(-G.GAME.dollars, true)
            end
            return true end }))
        delay(0.6)
    end
end

-------------------------------------------
--      Card Conversion Consumables      --
-------------------------------------------
-- Example: death implementation => conversion(left_to_right_conv())
-- Example: magician implementation => conversion(enhance_conv('m_lucky'))


-- Base conversion function
function conversion(conversion_function)
    return function(used_tarot)
        update_hand_text({immediate = true, nopulse = true, delay = 0}, {mult = 0, chips = 0, level = '', handname = ''})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        for i=1, #G.hand.highlighted do
            local percent = 1.15 - (i-0.999)/(#G.hand.highlighted-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('card1', percent);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
        end
        delay(0.2)
        conversion_function() -- do specific conversion function
        for i=1, #G.hand.highlighted do
            local percent = 0.85 + (i-0.999)/(#G.hand.highlighted-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('tarot2', percent, 0.6);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
        end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
        delay(0.5)
    end
end

-- parameter functions

function left_to_right_conv()
    return function()
        local rightmost = G.hand.highlighted[1]
        for i=1, #G.hand.highlighted do if G.hand.highlighted[i].T.x > rightmost.T.x then rightmost = G.hand.highlighted[i] end end
        for i=1, #G.hand.highlighted do
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
                if G.hand.highlighted[i] ~= rightmost then
                    copy_card(rightmost, G.hand.highlighted[i])
                end
                return true end }))
        end
    end
end

function value_up_conv()
    return function()
        for i=1, #G.hand.highlighted do
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
                local card = G.hand.highlighted[i]
                local suit_prefix = string.sub(card.base.suit, 1, 1)..'_'
                local rank_suffix = card.base.id == 14 and 2 or math.min(card.base.id+1, 14)
                if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
                elseif rank_suffix == 10 then rank_suffix = 'T'
                elseif rank_suffix == 11 then rank_suffix = 'J'
                elseif rank_suffix == 12 then rank_suffix = 'Q'
                elseif rank_suffix == 13 then rank_suffix = 'K'
                elseif rank_suffix == 14 then rank_suffix = 'A'
                end
                card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            return true end }))
        end
    end
end

function suit_conv(suit)
    return function()
        for i=1, #G.hand.highlighted do
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function() G.hand.highlighted[i]:change_suit(suit);return true end }))
        end
    end
end

function enhance_conv(enhancement)
    return function()
        for i=1, #G.hand.highlighted do
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function() G.hand.highlighted[i]:set_ability(G.P_CENTERS[enhancement]);return true end }))
        end 
    end
end

-------------------------------------------
--        Alter All Cards In Hand        --
-------------------------------------------

-- Base alter function
function alter_hand_cards(alter_function)
    return function(used_tarot)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        for i=1, #G.hand.cards do
            local percent = 1.15 - (i-0.999)/(#G.hand.cards-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.cards[i]:flip();play_sound('card1', percent);G.hand.cards[i]:juice_up(0.3, 0.3);return true end }))
        end
        delay(0.2)
        alter_function() -- do param function
        for i=1, #G.hand.cards do
            local percent = 0.85 + (i-0.999)/(#G.hand.cards-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.cards[i]:flip();play_sound('tarot2', percent, 0.6);G.hand.cards[i]:juice_up(0.3, 0.3);return true end }))
        end
        delay(0.5)
    end
end

-- parameter functions

function same_random_rank_alter()
    return function()
        local _suit = pseudorandom_element({'S','H','D','C'}, pseudoseed('sigil'))
        for i=1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local card = G.hand.cards[i]
                local suit_prefix = _suit..'_'
                local rank_suffix = card.base.id < 10 and tostring(card.base.id) or
                                    card.base.id == 10 and 'T' or card.base.id == 11 and 'J' or
                                    card.base.id == 12 and 'Q' or card.base.id == 13 and 'K' or
                                    card.base.id == 14 and 'A'
                card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            return true end }))
        end  
    end
end

function same_random_suit_alter()
    return function()
        local _rank = pseudorandom_element({'2','3','4','5','6','7','8','9','T','J','Q','K','A'}, pseudoseed('ouija'))
            for i=1, #G.hand.cards do
                G.E_MANAGER:add_event(Event({func = function()
                    local card = G.hand.cards[i]
                    local suit_prefix = string.sub(card.base.suit, 1, 1)..'_'
                    local rank_suffix =_rank
                    card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
                return true end }))
            end  
        G.hand:change_size(-1)
    end
end

-------------------------------------------
--       Destroy Cards for Rewards       --
-------------------------------------------

-- Base function
function destroy_cards_for_reward(amt, reward_function)
    return function(used_tarot)
        local destroyed_cards = {}
        for i=1,amt do destroyed_cards[#destroyed_cards+1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy')) end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function() 
                for i=#destroyed_cards, 1, -1 do
                    local card = destroyed_cards[i]
                    if card.ability.name == 'Glass Card' then 
                        card:shatter()
                    else
                        card:start_dissolve(nil, i ~= #destroyed_cards)
                    end
                end
                return true end }))
        reward_function()
        delay(0.3)
        for i = 1, #G.jokers.cards do
            G.jokers.cards[i]:calculate_joker({remove_playing_cards = true, removed = destroyed_cards})
        end
    end
end

-- parameter functions

function for_money(amt) -- immolate (has slightly different implementation in vanilla)
    return function()
        ease_dollars(amt)
    end
end

function for_cards(amt, valid_ranks, valid_suits, pseudorandom_seed)
    valid_ranks = valid_ranks or {'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'}
    valid_suits = valid_suits or {'S','H','D','C'}
    return function()
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.7,
            func = function() 
                local cards = {}
                for i=1, amt do
                    cards[i] = true
                    local _suit, _rank = nil, nil
                    _rank = pseudorandom_element(valid_ranks, pseudoseed(pseudorandom_seed))
                    _suit = pseudorandom_element(valid_suits, pseudoseed(pseudorandom_seed))
                    _suit = _suit or 'S'; _rank = _rank or 'A'
                    local cen_pool = {}
                    for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                        if v.key ~= 'm_stone' then 
                            cen_pool[#cen_pool+1] = v
                        end
                    end
                    create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))}, G.hand, nil, i ~= 1, {G.C.SECONDARY_SET.Spectral})
                end
                playing_card_joker_effects(cards)
                return true end }))
    end
end

-----------------------------------------
--         Enhance Random Joker        --
-----------------------------------------

-- edition = {<name> = true} or poll_edition('wheel_of_fortune', nil, true, true)
function random_joker_give_edition(edition, pseudorandom_seed, fail_func, consquence_func)
    fail_func = fail_func or (function() end)
    consquence_func = consquence_func or (function() end)
    return function(used_tarot)
        if edition == 'random' then edition = poll_edition('wheel_of_fortune', nil, true, true) end
        local temp_pool = {}
        for k, v in pairs(G.jokers.cards) do
                if v.ability.set == 'Joker' and (not v.edition) then
                    table.insert(temp_pool, v)
                end
            end
        if fail_func(used_tarot) then return end -- if fail, break early
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            local eligible_card = pseudorandom_element(temp_pool, pseudoseed(pseudorandom_seed))
            eligible_card:set_edition(edition, true)
            check_for_unlock({type = 'have_edition'})
            consquence_func(eligible_card)
            used_tarot:juice_up(0.3, 0.5)
        return true end }))
    end
end


function destory_all_other_jokers()
    return function(eligible_card)
        local _first_dissolve = nil
        for k, v in pairs(G.jokers.cards) do
            if v ~= eligible_card and (not v.ability.eternal) then v:start_dissolve(nil, _first_dissolve);_first_dissolve = true end
        end
    end
end

function reduce_hand_size()
    return function(eligible_card)
        G.GAME.ecto_minus = G.GAME.ecto_minus or 1
        G.hand:change_size(-G.GAME.ecto_minus)
        G.GAME.ecto_minus = G.GAME.ecto_minus + 1
    end
end

function wheel_spin(chance)
    return function(used_tarot)
        if pseudorandom('wheel_of_fortune') < G.GAME.probabilities.normal/chance then return false end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                attention_text({
                    text = localize('k_nope_ex'),
                    scale = 1.3, 
                    hold = 1.4,
                    major = used_tarot,
                    backdrop_colour = G.C.SECONDARY_SET.Tarot,
                    align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
                    offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
                    silent = true
                    })
                    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                        play_sound('tarot2', 0.76, 0.4);return true end}))
                    play_sound('tarot2', 1, 0.4)
                    used_tarot:juice_up(0.3, 0.5)
            return true end }))
        return true
    end
end

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      CAN_USE CHECK FUNCTIONS                          --
---------------------------------------------------------------------------
---------------------------------------------------------------------------

function can_always_use() -- planets use this one 
    return function()
        return true
    end
end

function have_editionless_jokers()
    return function()
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and (not v.edition) then
                return true
            end
        end
    end
end

function have_one_joker()
    return function()
        for k, v in pairs(G.jokers.cards) do
            if v.ability.set == 'Joker' and G.jokers.config.card_limit > 1 then 
                return true
            end
        end
    end
end

function selected_editionless_card()
    return function()
        if G.hand and (#G.hand.highlighted == 1) and G.hand.highlighted[1] and (not G.hand.highlighted[1].edition) then return true end
    end
end

function have_consumable_space()
    return function()
        if #G.consumeables.cards < G.consumeables.config.card_limit or self.area == G.consumeables then return true end
    end
end

function fool_condition()
    return function()
        if have_consumable_space() and G.GAME.last_tarot_planet and G.GAME.last_tarot_planet ~= 'c_fool' then return true end
    end
end

function have_joker_space()
    return function()
        if #G.jokers.cards < G.jokers.config.card_limit or self.area == G.jokers then return true end
    end
end

function have_hand()
    return function()
        if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.TAROT_PACK or 
        G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.PLANET_PACK then 
            if #G.hand.cards > 1 then return true end
        end
    end
end

function selected_card_limit(max, min)
    min = min or 1
    return function()
        if max >= #G.hand.highlighted and #G.hand.highlighted >= min then
            return true
        end
    end
end



--function Card:check_use()
    -- if self.ability.name == 'Ankh' then 
    --     if #G.jokers.cards >= G.jokers.config.card_limit then  
    --         alert_no_space(self, G.jokers)
    --         return true
    --     end
    -- end
--end