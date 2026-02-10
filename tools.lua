-- Merge two list-like tables and remove duplicates
-- Input: 2 tables
-- Output: new table
function set_merge(t1, t2)
  local nt = {}
  for i=1,#t1 do table.insert(nt,t1[i]) end
  for i=1,#t2 do
    local present = false
    for j=1,#nt do
      if t2[i] == nt[j] then present = true; break end
    end
    if present == false then table.insert(nt,t2[i]) end
    end
  return nt
end