function PrintLog(text)
    local file = io.open("LOG.txt", "a")
    file:write(text)
    file:close()
end