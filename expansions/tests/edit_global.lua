
--[[ 
    function used to edit fuction lists
    ------------------------------------
    func_list = {{name, func},{name, func} ...}
    new_func = {name = <str>, func = <function>(e, loc_vars)}
    relation = <str>
    target_func = <str> 
]]--
function edit_func_list(func_list, new_func, relation, target_func)
    for k, v, i in ipairs(func_list) do
        if v.name == target_func then
            if relation == 'b' or relation == 'before' then
                table.insert(func_list,i,new_func)
                return
            elseif relation == 'a' or relation == 'after' then
                table.insert(func_list,i+1,new_func)
                return
            elseif relation == 'r' or relation == 'replace' then
                func_list[i] = new_func
            else end
        end
    end
end


function remove_money(amt)
    return function(e, loc_vars)
        ease_dollars(-amt)
    end
end

edit_func_list(G.FUNCS.draw_from_deck_to_hand_funcs, {name='rm',remove_money(1)}, 'b', 'draw')
