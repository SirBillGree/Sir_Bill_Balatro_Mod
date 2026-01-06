
--[[ 
    Add functions to fuction lists
    ------------------------------------
    func_list = {{name, func},{name, func} ...}
    new_func = {name = <str>, func = <function>(loc_vars)}
    target_func = <str> (optional: places function at end of list)
    relation = <str> (optional: defaults to 'before')
]]--
function edit_func_list(func_list, new_func, target_func, relation)
    -- if no target specified, append to end of the list
    if target_func == nil then table.insert(func_list, new_func) end
    relation = relation or 'b'
    for i,v in pairs(func_list) do
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

function remove_from_func_list(func_list, target_func)
    for i,v in pairs(func_list) do
        if v.name == target_func then 
            table.remove(func_list, i)
            return
        end
    end
end


function remove_money(amt)
    return function(loc_vars)
        ease_dollars(-amt)
    end
end

edit_func_list(new_round_funcs, {name='rm',func=remove_money(1)})
