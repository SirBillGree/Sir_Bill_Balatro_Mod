--[[

Author:         SirBillGree
File:           Consumables.lua
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
[ ] additonal Trigger -> Trigger effect dictionary (optional)
[ ] Scoring function (optional)
[ ] values specific to an instance of a joker (example: x_mult on lucky cat) (add to config)
[ ] UI Functions
[ ] Pool filters
[ ] Unlock Conditions

functions in other files that need edits or restructuring:
[x] card:calculate_joker()
[ ] card:set_ability()                  -- Remove setting specific vars
[ ] common_events:generate_card_ui()    -- arguments for all instances of a card
[ ] common_events:get_current_pool()    -- import filter conditions as function
[ ] state_events:check_for_unlock()     -- add all unlock conditions to an array of functions to check
[ ] common_events:reset_<joker>         -- trigger system ^^

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

vanilla_jokers_set = {
        -- ^ Implemented UI ^ --
        j_joker=            {order = 1,  unlocked = true,   start_alerted = true, discovered = true,  blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 2, name = "Joker", pos = {x=0,y=0}, set = "Joker", effect = "Mult", cost_mult = 1.0, config = {mult = 4}},
        j_greedy_joker=     {order = 2,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Greedy Joker", pos = {x=6,y=1}, set = "Joker", effect = "Suit Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Diamonds'}}},
        j_lusty_joker=      {order = 3,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Lusty Joker", pos = {x=7,y=1}, set = "Joker", effect = "Suit Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Hearts'}}},
        j_wrathful_joker=   {order = 4,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Wrathful Joker", pos = {x=8,y=1}, set = "Joker", effect = "Suit Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Spades'}}},
        j_gluttenous_joker= {order = 5,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Gluttonous Joker", pos = {x=9,y=1}, set = "Joker", effect = "Suit Mult", cost_mult = 1.0, config = {mult = 3, extra = {suit = 'Clubs'}}},
        j_jolly=            {order = 6,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 3, name = "Jolly Joker", pos = {x=2,y=0}, set = "Joker", effect = "Type Mult", cost_mult = 1.0, config = {mult = 8, type = 'Pair'}},
        j_zany=             {order = 7,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Zany Joker", pos = {x=3,y=0}, set = "Joker", effect = "Type Mult", cost_mult = 1.0, config = {mult = 12, type = 'Three of a Kind'}},
        j_mad=              {order = 8,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Mad Joker", pos = {x=4,y=0}, set = "Joker", effect = "Type Mult", cost_mult = 1.0, config = {mult = 10, type = 'Two Pair'}},
        j_crazy=            {order = 9,  unlocked = true,   discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Crazy Joker", pos = {x=5,y=0}, set = "Joker", effect = "Type Mult", cost_mult = 1.0, config = {mult = 12, type = 'Straight'}},
        j_droll=            {order = 10,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Droll Joker", pos = {x=6,y=0}, set = "Joker", effect = "Type Mult", cost_mult = 1.0, config = {mult = 10, type = 'Flush'}},
        j_sly=              {order = 11,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 3, name = "Sly Joker",set = "Joker", effect = "Type Chips", config = {chips = 50, type = 'Pair'}, pos = {x=0,y=14}},
        j_wily=             {order = 12,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Wily Joker",set = "Joker", effect = "Type Chips", config = {chips = 100, type = 'Three of a Kind'}, pos = {x=1,y=14}},
        j_clever=           {order = 13,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Clever Joker",set = "Joker", effect = "Type Chips", config = {chips = 80, type = 'Two Pair'}, pos = {x=2,y=14}},
        j_devious=          {order = 14,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Devious Joker",set = "Joker", effect = "Type Chips", config = {chips = 100, type = 'Straight'}, pos = {x=3,y=14}},
        j_crafty=           {order = 15,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Crafty Joker",set = "Joker", effect = "Type Chips", config = {chips = 80, type = 'Flush'}, pos = {x=4,y=14}},

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
        -- ^ Implemented functionality ^ --
        j_card_sharp=       {order = 62,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Card Sharp", pos = {x=6,y=11}, set = "Joker", cost_mult = 1.0, config = {x_mult = 3}},
        j_red_card=         {order = 63,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 5, name = "Red Card", pos = {x=7,y=11}, set = "Joker", cost_mult = 1.0, config = {extra = 3}},
        j_madness=          {order = 64,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Madness", pos = {x=8,y=11}, set = "Joker", cost_mult = 1.0, config = {extra = 0.5}},
        j_square=           {order = 65,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 1, cost = 4, name = "Square Joker", pos = {x=9,y=11}, scale={W=1,H=0.75}, set = "Joker", cost_mult = 1.0, config = {chips = 0, extra = {chip_mod = 4}}},
        j_seance=           {order = 66,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Seance", pos = {x=0,y=12}, set = "Joker", cost_mult = 1.0, config = {extra = {poker_hand = 'Straight Flush'}}},
        -- j_riff_raff=        {order = 67,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Riff-raff", pos = {x=1,y=12}, set = "Joker", cost_mult = 1.0, config = {extra = 2}},
        -- j_vampire=          {order = 68,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Vampire",set = "Joker", config = {extra = 0.1, x_mult = 1},  pos = {x=2,y=12}},
        -- j_shortcut=         {order = 69,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Shortcut",set = "Joker", config = {},  pos = {x=3,y=12}},
        -- j_hologram=         {order = 70,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 7, name = "Hologram",set = "Joker", config = {extra = 0.25, x_mult = 1},  pos = {x=4,y=12}, soul_pos = {x=2, y=9},},
        -- j_vagabond=         {order = 71,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Vagabond",set = "Joker", config = {extra = 4}, pos = {x=5,y=12}},
        -- j_baron=            {order = 72,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Baron",set = "Joker", config = {extra = 1.5}, pos = {x=6,y=12}},
        -- j_cloud_9=          {order = 73,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Cloud 9",set = "Joker", config = {extra = 1}, pos = {x=7,y=12}},
        -- j_rocket=           {order = 74,  unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Rocket",set = "Joker", config = {extra = {dollars = 1, increase = 2}}, pos = {x=8,y=12}},
        -- j_obelisk=          {order = 75,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 3, cost = 8, name = "Obelisk",set = "Joker", config = {extra = 0.2, x_mult = 1}, pos = {x=9,y=12}},

        -- j_midas_mask=       {order = 76,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Midas Mask",set = "Joker", config = {}, pos = {x=0,y=13}},
        -- j_luchador=         {order = 77,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 5, name = "Luchador",set = "Joker", config = {}, pos = {x=1,y=13}},
        -- j_photograph=       {order = 78,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Photograph",set = "Joker", config = {extra = 2}, pos = {x=2,y=13}, scale={W=1,H=1/1.2}},
        -- j_gift=             {order = 79,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Gift Card",set = "Joker", config = {extra = 1}, pos = {x=3,y=13}},
        -- j_turtle_bean=      {order = 80,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Turtle Bean",set = "Joker", config = {extra = {h_size = 5, h_mod = 1}}, pos = {x=4,y=13}},
        -- j_erosion=          {order = 81,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Erosion",set = "Joker", config = {extra = 4}, pos = {x=5,y=13}},
        -- j_reserved_parking= {order = 82,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Reserved Parking",set = "Joker", config = {extra = {odds = 2, dollars = 1}}, pos = {x=6,y=13}},
        -- j_mail=             {order = 83,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Mail-In Rebate",set = "Joker", config = {extra = 5}, pos = {x=7,y=13}},
        -- j_to_the_moon=      {order = 84,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "To the Moon",set = "Joker", config = {extra = 1}, pos = {x=8,y=13}},
        -- j_hallucination=    {order = 85,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Hallucination",set = "Joker", config = {extra = 2}, pos = {x=9,y=13}},
        -- j_fortune_teller=   {order = 86,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Fortune Teller", pos = {x=7,y=5}, set = "Joker", effect = "", config = {extra = 1}},
        -- j_juggler=          {order = 87,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Juggler", pos = {x=0,y=1}, set = "Joker", effect = "Hand Size", cost_mult = 1.0, config = {h_size = 1}},
        -- j_drunkard=         {order = 88,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Drunkard", pos = {x=1,y=1}, set = "Joker", effect = "Discard Size", cost_mult = 1.0, config = {d_size = 1}},
        -- j_stone=            {order = 89,  unlocked = true,  discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Stone Joker", pos = {x=9,y=0}, set = "Joker", effect = "Stone Card Buff", cost_mult = 1.0, config = {extra = 25}, enhancement_gate = 'm_stone'},
        -- j_golden=           {order = 90,  unlocked = true,  discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 6, name = "Golden Joker", pos = {x=9,y=2}, set = "Joker", effect = "Bonus dollars", cost_mult = 1.0, config = {extra = 4}},

        -- j_lucky_cat=        {order = 91,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Lucky Cat",set = "Joker", config = {x_mult = 1, extra = 0.25}, pos = {x=5,y=14}, enhancement_gate = 'm_lucky'},
        -- j_baseball=         {order = 92,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Baseball Card",set = "Joker", config = {extra = 1.5}, pos = {x=6,y=14}},
        -- j_bull=             {order = 93,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Bull",set = "Joker", config = {extra = 2}, pos = {x=7,y=14}},
        -- j_diet_cola=        {order = 94,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Diet Cola",set = "Joker", config = {}, pos = {x=8,y=14}},
        -- j_trading=          {order = 95,   unlocked = true, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Trading Card",set = "Joker", config = {extra = 3}, pos = {x=9,y=14}},
        -- j_flash=            {order = 96,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 5, name = "Flash Card",set = "Joker", config = {extra = 2, mult = 0}, pos = {x=0,y=15}},
        -- j_popcorn=          {order = 97,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 1, cost = 5, name = "Popcorn",set = "Joker", config = {mult = 20, extra = 4}, pos = {x=1,y=15}},
        -- j_trousers=         {order = 98,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Spare Trousers",set = "Joker", config = {extra = 2}, pos = {x=4,y=15}},
        -- j_ancient=          {order = 99,   unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Ancient Joker",set = "Joker", config = {extra = 1.5}, pos = {x=7,y=15}},
        -- j_ramen=            {order = 100,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Ramen",set = "Joker", config = {x_mult = 2, extra = 0.01}, pos = {x=2,y=15}},
        -- j_walkie_talkie=    {order = 101,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Walkie Talkie",set = "Joker", config = {extra = {chips = 10, mult = 4}}, pos = {x=8,y=15}},
        -- j_selzer=           {order = 102,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 6, name = "Seltzer",set = "Joker", config = {extra = {rounds = 10, reps = 1}}, pos = {x=3,y=15}},
        -- j_castle=           {order = 103,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Castle",set = "Joker", config = {extra = {chips = 0, chip_mod = 3}}, pos = {x=9,y=15}},
        -- j_smiley=           {order = 104,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Smiley Face",set = "Joker", config = {extra = 5}, pos = {x=6,y=15}},
        -- j_campfire=         {order = 105,  unlocked = true, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 9, name = "Campfire",set = "Joker", config = {extra = 0.25}, pos = {x=5,y=15}},

        -- j_ticket=           {order = 106,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Golden Ticket", pos = {x=5,y=3}, set = "Joker", effect = "dollars for Gold cards", cost_mult = 1.0, config = {extra = 4},unlock_condition = {type = 'hand_contents', extra = 'Gold'}, enhancement_gate = 'm_gold'},
        -- j_mr_bones=         {order = 107,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 2, cost = 5, name = "Mr. Bones", pos = {x=3,y=4}, set = "Joker", effect = "Prevent Death", cost_mult = 1.0, config = {},unlock_condition = {type = 'c_losses', extra = 5}},
        -- j_acrobat=          {order = 108,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Acrobat", pos = {x=2,y=1}, set = "Joker", effect = "Shop size", cost_mult = 1.0, config = {extra = 3},unlock_condition = {type = 'c_hands_played', extra = 200}},
        -- j_sock_and_buskin=  {order = 109,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Sock and Buskin", pos = {x=3,y=1}, set = "Joker", effect = "Face card double", cost_mult = 1.0, config = {extra = {reps=1}},unlock_condition = {type = 'c_face_cards_played', extra = 300}},
        -- j_swashbuckler=     {order = 110,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Swashbuckler", pos = {x=9,y=5}, set = "Joker", effect = "Set Mult", cost_mult = 1.0, config = {mult = 1},unlock_condition = {type = 'c_jokers_sold', extra = 20}},
        -- j_troubadour=       {order = 111,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Troubadour", pos = {x=0,y=2}, set = "Joker", effect = "Hand Size, Plays", cost_mult = 1.0, config = {extra = {h_size = 2, h_plays = -1}}, unlock_condition = {type = 'round_win', extra = 5}},
        -- j_certificate=      {order = 112,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Certificate", pos = {x=8,y=8}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'double_gold'}},
        -- j_smeared=          {order = 113,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Smeared Joker", pos = {x=4,y=6}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'modify_deck', extra = {count = 3, enhancement = 'Wild Card', e_key = 'm_wild'}}},
        -- j_throwback=        {order = 114,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Throwback", pos = {x=5,y=7}, set = "Joker", effect = "", config = {extra = 0.25}, unlock_condition = {type = 'continue_game'}},        
        -- j_hanging_chad=     {order = 115,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 4, name = "Hanging Chad", pos = {x=9,y=6}, set = "Joker", effect = "", config = {extra = {reps=2}}, unlock_condition = {type = 'round_win', extra = 'High Card'}},
        -- j_rough_gem=        {order = 116,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Rough Gem", pos = {x=9,y=7}, set = "Joker", effect = "", config = {extra = 1}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Diamonds'}}},
        -- j_bloodstone=       {order = 117,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Bloodstone", pos = {x=0,y=8}, set = "Joker", effect = "", config = {extra = {odds = 2, x_mult = 1.5}}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Hearts'}}},
        -- j_arrowhead=        {order = 118,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Arrowhead", pos = {x=1,y=8}, set = "Joker", effect = "", config = {extra = 50}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Spades'}}},
        -- j_onyx_agate=       {order = 119,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Onyx Agate", pos = {x=2,y=8}, set = "Joker", effect = "", config = {extra = 7}, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Clubs'}}},
        -- j_glass=            {order = 120,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 2, cost = 6, name = "Glass Joker", pos = {x=1,y=3}, set = "Joker", effect = "Glass Card", cost_mult = 1.0, config = {extra = 0.75, x_mult = 1}, unlock_condition = {type = 'modify_deck', extra = {count = 5, enhancement = 'Glass Card', e_key = 'm_glass'}}, enhancement_gate = 'm_glass'},

        -- j_ring_master=      {order = 121,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 5, name = "Showman", pos = {x=6,y=5}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'ante_up', ante = 4}},
        -- j_flower_pot=       {order = 122,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Flower Pot", pos = {x=0,y=6}, set = "Joker", effect = "", config = {extra = 3}, unlock_condition = {type = 'ante_up', ante = 8}},
        j_blueprint=        {order = 123,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 10,name = "Blueprint", pos = {x=0,y=3}, set = "Joker", effect = "Copycat", cost_mult = 1.0, config = {},unlock_condition = {type = 'win_custom'}},
        -- j_wee=              {order = 124,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = false, eternal_compat = true, rarity = 3, cost = 8, name = "Wee Joker", pos = {x=0,y=0}, scale={H=0.7,W=0.7} set = "Joker", effect = "", config = {extra = {chips = 0, chip_mod = 8}}, unlock_condition = {type = 'win', n_rounds = 18}},
        -- j_merry_andy=       {order = 125,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Merry Andy", pos = {x=8,y=0}, set = "Joker", effect = "", cost_mult = 1.0, config = {d_size = 3, h_size = -1}, unlock_condition = {type = 'win', n_rounds = 12}},
        j_oops=             {order = 126,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 4, name = "Oops! All 6s", pos = {x=5,y=6}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'chip_score', chips = 10000}},
        -- j_idol=             {order = 127,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "The Idol", pos = {x=6,y=7}, set = "Joker", effect = "", config = {extra = 2}, unlock_condition = {type = 'chip_score', chips = 1000000}},
        -- j_seeing_double=    {order = 128,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Seeing Double", pos = {x=4,y=4}, set = "Joker", effect = "X1.5 Mult club 7", cost_mult = 1.0, config = {extra = 2},unlock_condition = {type = 'hand_contents', extra = 'four 7 of Clubs'}},
        -- j_matador=          {order = 129,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Matador", pos = {x=4,y=5}, set = "Joker", effect = "", config = {extra = 8}, unlock_condition = {type = 'round_win'}},
        -- j_hit_the_road=     {order = 130,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Hit the Road", pos = {x=8,y=5}, set = "Joker", effect = "Jack Discard Effect", cost_mult = 1.0, config = {extra = 0.5}, unlock_condition = {type = 'discard_custom'}},
        -- j_duo=              {order = 131,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Duo", pos = {x=5,y=4}, set = "Joker", effect = "X1.5 Mult", cost_mult = 1.0, config = {x_mult = 2, type = 'Pair'}, unlock_condition = {type = 'win_no_hand', extra = 'Pair'}},
        -- j_trio=             {order = 132,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Trio", pos = {x=6,y=4}, set = "Joker", effect = "X2 Mult", cost_mult = 1.0, config = {x_mult = 3, type = 'Three of a Kind'}, unlock_condition = {type = 'win_no_hand', extra = 'Three of a Kind'}},
        -- j_family=           {order = 133,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Family", pos = {x=7,y=4}, set = "Joker", effect = "X3 Mult", cost_mult = 1.0, config = {x_mult = 4, type = 'Four of a Kind'}, unlock_condition = {type = 'win_no_hand', extra = 'Four of a Kind'}},
        -- j_order=            {order = 134,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Order", pos = {x=8,y=4}, set = "Joker", effect = "X3 Mult", cost_mult = 1.0, config = {x_mult = 3, type = 'Straight'}, unlock_condition = {type = 'win_no_hand', extra = 'Straight'}},
        -- j_tribe=            {order = 135,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "The Tribe", pos = {x=9,y=4}, set = "Joker", effect = "X3 Mult", cost_mult = 1.0, config = {x_mult = 2, type = 'Flush'}, unlock_condition = {type = 'win_no_hand', extra = 'Flush'}},
        
        -- j_stuntman=         {order = 136,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 7, name = "Stuntman", pos = {x=8,y=6}, set = "Joker", effect = "", config = {extra = {h_size = 2, chip_mod = 250}}, unlock_condition = {type = 'chip_score', chips = 100000000}},
        -- j_invisible=        {order = 137,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = false, rarity = 3, cost = 8, name = "Invisible Joker", pos = {x=1,y=7}, set = "Joker", effect = "", config = {extra = 2}, unlock_condition = {type = 'win_custom'}},
        j_brainstorm=       {order = 138,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 10, name = "Brainstorm", pos = {x=7,y=7}, set = "Joker", effect = "Copycat", config = {}, unlock_condition = {type = 'discard_custom'}},
        -- j_satellite=        {order = 139,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Satellite", pos = {x=8,y=7}, set = "Joker", effect = "", config = {extra = 1}, unlock_condition = {type = 'money', extra = 400}},
        -- j_shoot_the_moon=   {order = 140,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 1, cost = 5, name = "Shoot the Moon", pos = {x=2,y=6}, set = "Joker", effect = "", config = {extra = 13}, unlock_condition = {type = 'play_all_hearts'}},
        -- j_drivers_license=  {order = 141,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 7, name = "Driver's License", pos = {x=0,y=7}, set = "Joker", effect = "", config = {extra = 3}, unlock_condition = {type = 'modify_deck', extra = {count = 16, tally = 'total'}}},
        -- j_cartomancer=      {order = 142,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "Cartomancer", pos = {x=7,y=3}, set = "Joker", effect = "Tarot Buff", cost_mult = 1.0, config = {}, unlock_condition = {type = 'discover_amount', tarot_count = 22}},
        -- j_astronomer=       {order = 143,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 8, name = "Astronomer", pos = {x=2,y=7}, set = "Joker", effect = "", config = {}, unlock_condition = {type = 'discover_amount', planet_count = 12}},
        -- j_burnt=            {order = 144,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 3, cost = 8, name = "Burnt Joker", pos = {x=3,y=7}, set = "Joker", effect = "", config = {h_size = 0, extra = 4}, unlock_condition = {type = 'c_cards_sold', extra = 50}},
        -- j_bootstraps=       {order = 145,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 7, name = "Bootstraps", pos = {x=9,y=8}, set = "Joker", effect = "", config = {extra = {mult = 2, dollars = 5}}, unlock_condition = {type = 'modify_jokers', extra = {polychrome = true, count = 2}}},
        -- j_caino=            {order = 146,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Caino", pos = {x=3,y=8}, soul_pos = {x=3, y=9}, set = "Joker", effect = "", config = {extra = 1}, unlock_condition = {type = '', extra = '', hidden = true}},
        -- j_triboulet=        {order = 147,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Triboulet", pos = {x=4,y=8}, soul_pos = {x=4, y=9}, set = "Joker", effect = "", config = {extra = 2}, unlock_condition = {type = '', extra = '', hidden = true}},
        -- j_yorick=           {order = 148,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Yorick", pos = {x=5,y=8}, soul_pos = {x=5, y=9}, set = "Joker", effect = "", config = {extra = {x_mult = 1, discards = 23}}, unlock_condition = {type = '', extra = '', hidden = true}},
        -- j_chicot=           {order = 149,  unlocked = false, discovered = false, blueprint_compat = false, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Chicot", pos = {x=6,y=8}, soul_pos = {x=6, y=9}, set = "Joker", effect = "", config = {}, unlock_condition = {type = '', extra = '', hidden = true}},
        -- j_perkeo=           {order = 150,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 4, cost = 20, name = "Perkeo", pos = {x=7,y=8}, soul_pos = {x=7, y=9}, set = "Joker", effect = "", config = {}, unlock_condition = {type = '', extra = '', hidden = true}},
}
-- This adds the id and sprite atlas variables to every item in the above table.
-- This is way faster than adding them manually
for k, v in pairs(vanilla_jokers_set) do
    vanilla_jokers_set[k].id = k
    vanilla_jokers_set[k].atlas = 'Joker'
end


local joker_functions = {}

local function define_joker_functions()

    -------------------------------------------------------------
    -------------------------------------------------------------
    --                     SCORE FUNCTIONS                     --
    -------------------------------------------------------------
    -------------------------------------------------------------
    --- ALL MUST INCLUDE A CHECK FOR: context.cardarea == G.jokers and context.score

    -- val_name: string = 'chips', 'mult', 'x_mult', 'dollars'
    -- cond (condition): function, takes (self, context), returns true/false
    local function score_value(val_name, cond)
        cond = cond or function(x, xx) return true end
        return function(self, context)
            local ret = {}
            if context.cardarea == G.jokers and context.score and cond(self, context) then ret[val_name] = self.ability[val_name] end
            return ret
        end
    end

    local function score_hand_jokers() return function(self, context)
        if context.cardarea == G.jokers and context.score and #context.poker_hands[self.ability.type] > 0 then
            return {
                    mult = (self.ability.mult > 0 and self.ability.mult) or nil,
                    chips = (self.ability.chips > 0 and self.ability.chips) or nil,
                    card = self
                }
        end
    end end

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

    local function score_copy() return function(self, context)
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

    ---------------------------------------------------------------
    ---------------------------------------------------------------
    --                     TRIGGER FUNCTIONS                     --
    ---------------------------------------------------------------
    ---------------------------------------------------------------

    --------------------------------------------------------
    --                     BUFF CARDS                     --
    --------------------------------------------------------

    -- Base Version --
    local function trigger_card_buff(cond, val) 
        cond = cond or function(x, xx) return true end
        if type(val) == "string" then val = {val} end
        return function(self, context)
            if context.individual and context.cardarea == G.play and cond(self,context) then
                local r = {card = self}
                for _,v in pairs(val) do r[v] = self.ability[v] end
                return r
            end
    end end

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

    ----------------------------------------------------------
    --                     BEFORE ROUND                     --
    ----------------------------------------------------------

    local function trigger_dagger() return function(self, context)
        if not context.blueprint and context.setting_blind and not self.getting_sliced then
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
        if not context.blueprint and context.setting_blind and not (context.blueprint_card or self).getting_sliced then
            G.E_MANAGER:add_event(Event({func = function()
                ease_discard(-G.GAME.current_round.discards_left, nil, true)
                ease_hands_played(self.ability.extra)
                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_hands', vars = {self.ability.extra}}})
            return true end }))
        end
    end end

    --------------------------------------------------------------
    --                     USING CONSUMABLE                     --
    --------------------------------------------------------------

    local function trigger_constellation() return function(self, context)
        if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == 'Planet' then
            self.ability.x_mult = self.ability.x_mult + self.ability.extra
            G.E_MANAGER:add_event(Event({
                func = function() card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_x_mult',vars={self.ability.x_mult}}}); return true
                end}))
            return
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
    

    -------------------------------------------------------------------
    --                     END ROUND MONEY BONUS                     --
    -------------------------------------------------------------------
    
    local function trigger_end_round_money_bonus(cond, calc) 
        cond = cond or function(x, xx) return true end
        return function(self, context)
            if context.end_round_dollar_bonus and not self.debuff and not context.blueprint and cond(self, context) then
                return calc(self)
            end
    end end

    --------------------------------------------------------------
    --                     FIRST HAND DRAWN                     --
    --------------------------------------------------------------
    
    local function trigger_first_hand_ability_jiggle() return function(self, context)
        if context.first_hand_drawn and not context.blueprint then
            juice_card_until(self, function() return G.GAME.current_round.hands_played == 0 end, true)
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

    local function trigger_copy() return function(self, context)
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

    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --                     ADD/REMOVE FUNCTIONS                     --
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    ---Required: function(self,context)
    
    local function add_remove_chaos(mod_rerolls) return function(self)
        G.GAME.current_round.free_rerolls = G.GAME.current_round.free_rerolls + mod_rerolls
        calculate_reroll_cost(true)
    end end

    ---------------------------------------------------------------
    ---------------------------------------------------------------
    --                     COMMON CONDITIONS                     --
    ---------------------------------------------------------------
    ---------------------------------------------------------------
    
    -- ranks is a list of <int>
    local function other_card_rank_cond(ranks) return function(self, context)
        if context.other_card then
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
    local function update_steel_joker() return function (self, context)
        self.ability.steel_tally = 0
        for k, v in pairs(G.playing_cards) do
            if v.config.center == G.P_CENTERS.m_steel then self.ability.steel_tally = self.ability.steel_tally+1 end
        end
        self.ability.x_mult = 1 + (self.ability.extra * self.ability.steel_tally)
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

    ------------------------------------------------------
    ------------------------------------------------------
    --                     END ROUND                    --
    ------------------------------------------------------
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

    -------------------------------------------------------------
    -------------------------------------------------------------
    --                     GET REPETITIONS                     --
    -------------------------------------------------------------
    -------------------------------------------------------------

    -- Base Version --

    local function get_repitions(cond)
        cond = cond or function(x, xx) return true end
        return function(self, context)
            if context.repetition and cond(self, context) then
                return {
                        message = localize('k_again_ex'),
                        repetitions = self.ability.extra.reps,
                        card = self
                    }
            end
        end
    end

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
                        target = nil
                        self.ability.blueprint_target = nil
                    end
                end
            else
                self.ability.blueprint_target = nil
            end
    end end



    -- I chose to make a loop instead of define a table so that I could save time
    -- and not have to write out "vanilla_jokers_set.j_<joker>.config.<var>"
    -- a billion times, which seems hard to maintain. "c.<var>" is much better.
    -- Yes, it's slower (O(n^2) instead of O(n)), but this should only run once.
    for k,v in pairs(vanilla_jokers_set) do
        local c = v.config

        -- place function defs here --
        if k == 'j_joker' then joker_functions[k] =                             {score=score_value('mult')}
        elseif k == 'j_blueprint' then joker_functions[k] =                     {score=score_copy(), triggers={trigger_copy()}, update=upd_copy({type="rel",pos=1})} -- chance for optimization (update)
        elseif k == 'j_brainstorm' then joker_functions[k] =                    {score=score_copy(), triggers={trigger_copy()}, update=upd_copy({type="abs",pos=1})}
        elseif k == 'j_half' then joker_functions[k] =                          {score=score_value('mult', function (self,context) return #context.full_hand <= self.ability.extra.size end)}
        elseif k == 'j_stencil' then joker_functions[k] =                       {score=score_value('x_mult', function (self,context) return self.ability.x_mult > 1 end), update=upd_stencil_joker()}
        elseif k == 'j_mime' then joker_functions[k] =                          {triggers={get_repitions(function(self,context) return context.cardarea == G.hand end)}}
        elseif k == 'j_credit_card' then joker_functions[k] =                   {add_deck = function(self,context) G.GAME.bankrupt_at = G.GAME.bankrupt_at - self.ability.extra end, remove_deck = function(self,context) G.GAME.bankrupt_at = G.GAME.bankrupt_at + self.ability.extra end}
        elseif k == 'j_ceremonial' then joker_functions[k] =                    {score=score_value('mult'), triggers={trigger_dagger()}}
        elseif k == 'j_banner' then joker_functions[k] =                        {score=score_value('chips', function (self,context) return G.GAME.current_round.discards_left > 0 end), update=function(self,context) self.ability.chips = G.GAME.current_round.discards_left * self.ability.extra end}
        elseif k == 'j_mystic_summit' then joker_functions[k] =                 {score=score_value('mult', function (self,context) return G.GAME.current_round.discards_left == self.ability.extra.d_remaining end)}
        elseif k == 'j_marble' then joker_functions[k] =                        {triggers={trigger_marble()}}
        elseif k == 'j_loyalty_card' then joker_functions[k] =                  {score=score_value('x_mult', function (self,context) return self.ability.extra.loyalty_remaining == self.ability.extra.every end), triggers={trigger_loyalty_iter()}}  
        elseif k == 'j_8_ball' then joker_functions[k] =                        {triggers={trigger_8_ball()}}
        elseif k == 'j_oops' then joker_functions[k] =                          {add_deck=function(self,context) for k,v in pairs(G.GAME.probabilities) do G.GAME.probabilities[k] = v*2 end end, remove_deck = function(self,context) for k,v in pairs(G.GAME.probabilities) do G.GAME.probabilities[k] = v/2 end end}
        elseif k == 'j_misprint' then joker_functions[k] =                      {score=function(self,context) return {mult=pseudorandom('misprint', self.ability.extra.min, self.ability.extra.max)} end}
        elseif k == 'j_dusk' then joker_functions[k] =                          {triggers={get_repitions(function(self,context) return G.GAME.current_round.hands_left == 0 and context.cardarea == G.play end)}}
        elseif k == 'j_raised_fist' then joker_functions[k] =                   {triggers={trigger_lowest_raised_fist(),trigger_set_lowest_for_raised_fist()}}
        elseif k == 'j_chaos' then joker_functions[k] =                         {add_deck=add_remove_chaos(1), remove_deck=add_remove_chaos(-1)}
        elseif k == 'j_fibonacci' then joker_functions[k] =                     {triggers={trigger_card_buff(other_card_rank_cond({14, 2, 3, 5, 8}), 'mult')}}
        elseif k == 'j_steel_joker' then joker_functions[k] =                   {score=score_value('x_mult'), update = update_steel_joker()} -- chance for optimization (update)
        elseif k == 'j_scary_face' then joker_functions[k] =                    {triggers={trigger_card_buff(function(self,context) return context.other_card:is_face() end, 'chips')}}
        elseif k == 'j_abstract' then joker_functions[k] =                      {score= function(self,context) return {mult=(G.jokers and G.jokers.cards and #G.jokers.cards or 0)*self.ability.extra} end}
        elseif k == 'j_delayed_grat' then joker_functions[k] =                  {triggers={trigger_end_round_money_bonus(function(self, context) return G.GAME.current_round.discards_used == 0 and G.GAME.current_round.discards_left > 0 end, function(self) return G.GAME.current_round.discards_left*self.ability.extra end)}}
        elseif k == 'j_hack' then joker_functions[k] =                          {triggers={get_repitions(other_card_rank_cond({2,3,4,5}))}}
        elseif k == 'j_gros_michel' then joker_functions[k] =                   {score= score_value('mult'), triggers={trigger_extinct('gros_michel')}}
        elseif k == 'j_cavendish' then joker_functions[k] =                     {score= score_value('x_mult'), triggers={trigger_extinct('cavendish')}}
        elseif k == 'j_even_steven' then joker_functions[k] =                   {triggers={trigger_card_buff(other_card_rank_cond({2,4,6,8,10}), 'mult')}}
        elseif k == 'j_odd_todd' then joker_functions[k] =                      {triggers={trigger_card_buff(other_card_rank_cond({14,3,5,7,9}), 'chips')}}
        elseif k == 'j_scholar' then joker_functions[k] =                       {triggers={trigger_card_buff(other_card_rank_cond({14}), {'chips','mult'})}}
        elseif k == 'j_business' then joker_functions[k] =                      {triggers={trigger_card_buff(function(self,context) return context.other_card:is_face() and pseudorandom('business') < G.GAME.probabilities.normal/self.ability.extra.chance end, 'dollars')}}
        elseif k == 'j_supernova' then joker_functions[k] =                     {score=function(self,context) return {mult = G.GAME.hands[context.scoring_name].played} end}
        elseif k == 'j_ride_the_bus' then joker_functions[k] =                  {score=score_value('mult'), triggers={trigger_ride_the_bus()}}
        elseif k == 'j_space' then joker_functions[k] =                         {triggers={trigger_space_joker()}}
        elseif k == 'j_egg' then joker_functions[k] =                           {triggers={trigger_egg()}}
        elseif k == 'j_burglar' then joker_functions[k] =                       {triggers={trigger_burglar()}}
        elseif k == 'j_blackboard' then joker_functions[k] =                    {score=score_value("x_mult", blackboard_cond())}
        elseif k == 'j_runner' then joker_functions[k] =                        {score=score_value('chips'), triggers={trigger_runner_upgrade()}}
        elseif k == 'j_ice_cream' then joker_functions[k] =                     {score=score_value('chips'), triggers={trigger_ice_cream_iter()}}
        elseif k == 'j_dna' then joker_functions[k] =                           {triggers={trigger_first_hand_ability_jiggle(), trigger_DNA_make_copy()}}
        elseif k == 'j_blue_joker' then joker_functions[k] =                    {score=function(self,context) if #G.deck.cards > 0 then return {chips = #G.deck.cards*self.ability.extra} end end}
        elseif k == 'j_sixth_sense' then joker_functions[k] =                   {triggers={trigger_first_hand_ability_jiggle(), trigger_sixth_sense()}}
        elseif k == 'j_constellation' then joker_functions[k] =                 {score=score_value("x_mult", function(self,context) return self.ability.x_mult > 1 end), triggers={trigger_constellation()}}
        elseif k == 'j_hiker' then joker_functions[k] =                         {triggers={trigger_hiker()}}
        elseif k == 'j_faceless' then joker_functions[k] =                      {triggers={trigger_faceless_joker()}}
        elseif k == 'j_green_joker' then joker_functions[k] =                   {score=score_value('mult'),triggers={trigger_green_joker_discard(),trigger_green_joker_play()}}
        elseif k == 'j_superposition' then joker_functions[k] =                 {score=trigger_superposition()}
        elseif k == 'j_todo_list' then joker_functions[k] =                     {score=score_value('dollars', function(self,context) return context.scoring_name == self.ability.extra.poker_hand end), on_create=create_todo_list(), triggers={trigger_reset_todo()}}
        elseif k == 'j_card_sharp' then joker_functions[k] =                    {score=score_value('x_mult', function(self,context) return G.GAME.hands[context.scoring_name] and G.GAME.hands[context.scoring_name].played_this_round > 1 end)}
        elseif k == 'j_red_card' then joker_functions[k] =                      {score=score_value('mult'), triggers={trigger_red_card_skip()}}
        elseif k == 'j_madness' then joker_functions[k] =                       {score=score_value('x_mult'), triggers={trigger_madness()}}
        elseif k == 'j_square' then joker_functions[k] =                        {score=score_value('chips'), triggers={trigger_square_upgrade()}}
        elseif k == 'j_seance' then joker_functions[k] =                        {score=trigger_seance()}
        --elseif k == 'j_' then joker_functions[k] =                         
        --elseif k == 'j_' then joker_functions[k] =                         
        --elseif k == 'j_' then joker_functions[k] =                         
        --elseif k == 'j_' then joker_functions[k] =                         
        elseif v.effect then
            if v.effect == "Suit Mult" then joker_functions[k] =                {triggers={trigger_card_buff(function(self,context) return context.other_card:is_suit(self.ability.extra.suit) end, 'mult')}}
            elseif v.effect == "Type Mult" or
                   v.effect == "Type Chips" then joker_functions[k] =           {score=score_hand_jokers()}
            end
        end

    end
end

function vanilla_joker_function_collector()
    define_joker_functions()
    return joker_functions
end




--------------------------------------------------------------------------

function reset_idol_card()
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
end

function reset_mail_rank()
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
end

function reset_ancient_card()
    local ancient_suits = {}
    for k, v in ipairs({'Spades','Hearts','Clubs','Diamonds'}) do
        if v ~= G.GAME.current_round.ancient_card.suit then ancient_suits[#ancient_suits + 1] = v end
    end
    local ancient_card = pseudorandom_element(ancient_suits, pseudoseed('anc'..G.GAME.round_resets.ante))
    G.GAME.current_round.ancient_card.suit = ancient_card
end

function reset_castle_card()
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