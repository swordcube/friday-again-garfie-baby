local Native = cometreq("native") --- @type comet.Native

--- @class funkin.util.FLog
local FLog = {}

function FLog.init()
    print = FLog.print
end

function FLog.output(type, fgColor, bgColor, ...)
    Native.setConsoleColors(Native.ConsoleColor.NONE, Native.ConsoleColor.NONE)

    io.stdout:write("[ ")
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.MAGENTA, Native.ConsoleColor.NONE)
    
    io.stdout:write(os.date("%H:%M:%S"))
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.NONE, Native.ConsoleColor.NONE)

    io.stdout:write(" ] ")
    io.stdout:flush()
    
    Native.setConsoleColors(Native.ConsoleColor.NONE, bgColor)
    
    io.stdout:write("[ ")
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.CYAN, bgColor)
    
    io.stdout:write("FUNKIN")
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.NONE, bgColor)
    
    io.stdout:write(" | ")
    io.stdout:flush()

    Native.setConsoleColors(fgColor, bgColor)
    
    io.stdout:write(type)
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.NONE, bgColor)
    
    io.stdout:write(" ] ")
    io.stdout:flush()

    Native.setConsoleColors(Native.ConsoleColor.NONE, Native.ConsoleColor.NONE)

    local str = table.join(table.pack(...), ", ") .. "\n"
    io.stdout:write(str)
    io.stdout:flush()
end

function FLog.print(...)
    FLog.output(" PRINT ", Native.ConsoleColor.CYAN, Native.ConsoleColor.NONE, ...)
end

function FLog.warn(...)
    FLog.output("WARNING", Native.ConsoleColor.YELLOW, Native.ConsoleColor.NONE, ...)
end

function FLog.error(...)
    FLog.output(" ERROR ", Native.ConsoleColor.RED, Native.ConsoleColor.NONE, ...)
end

function FLog.verbose(...)
    if comet.isDebug() then
        FLog.output("VERBOSE", Native.ConsoleColor.MAGENTA, Native.ConsoleColor.NONE, ...)
    end
end

return FLog