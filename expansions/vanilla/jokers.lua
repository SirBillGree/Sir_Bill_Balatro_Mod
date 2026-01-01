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
[ ] Pool functions

functions in other files that need edits or restructuring:
[ ] card:calculate_joker()
[ ] card:set_ability()                  -- Remove setting specific vars
[ ] common_events:generate_card_ui()    -- arguments for all instances of a card
[ ] common_events:get_current_pool()    -- import filter conditions as function

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