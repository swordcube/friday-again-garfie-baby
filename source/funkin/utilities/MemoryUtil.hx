package funkin.utilities;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import openfl.system.System;
import funkin.backend.native.*;

class MemoryUtil {
    /**
     * Forces a minor garbage collection to run.
     */
    public static function clearMinor():Void {
        #if (cpp || java || neko)
        Gc.run(false);
        #end
    }

    /**
     * Forces a major garbage collection to run.
     */
    public static function clearMajor():Void {
        #if cpp
        Gc.run(true);
        Gc.compact();
        #elseif hl
        Gc.major();
        #elseif (java || neko)
        Gc.run(true);
        #end
    }

    /**
     * Forces both a major and minor garbage collection to run.
     * 
     * ! `[WARNING]` - This can be expensive!
     */
    public static function clearAll():Void {
        clearMajor();
        clearMinor();
    }

    public static function enable():Void {
        #if (cpp || hl)
        Gc.enable(true);
        #end
    }

    public static function disable():Void {
        #if (cpp || hl)
        Gc.enable(false);
        #end
    }

    public static function currentMemUsage():Float {
        #if cpp
        return Gc.memInfo64(Gc.MEM_INFO_USAGE);
        #elseif hl
        return Gc.stats().currentMemory;
        #elseif sys
        return cast(cast(System.totalMemory, UInt), Float);
        #else
        return 0;
        #end
    }

    public static function getTotalMem():Float {
        #if windows
        return Windows.getTotalRam();
        #elseif mac
        return Mac.getTotalRam();
        #elseif linux
        return Linux.getTotalRam();
        #else
        return 0;
        #end
    }

    public static function getMemType():String {
        #if windows
        var memoryMap:Map<Int, String> = [
            0 => "Unknown",
            1 => "Other",
            2 => "DRAM",
            3 => "Synchronous DRAM",
            4 => "Cache DRAM",
            5 => "EDO",
            6 => "EDRAM",
            7 => "VRAM",
            8 => "SRAM",
            9 => "RAM",
            10 => "ROM",
            11 => "Flash",
            12 => "EEPROM",
            13 => "FEPROM",
            14 => "EPROM",
            15 => "CDRAM",
            16 => "3DRAM",
            17 => "SDRAM",
            18 => "SGRAM",
            19 => "RDRAM",
            20 => "DDR",
            21 => "DDR2",
            22 => "DDR2 FB-DIMM",
            24 => "DDR3",
            25 => "FBD2",
            26 => "DDR4"
        ];
        var memoryOutput:Int = -1;

        var process = new HiddenProcess("wmic", ["memorychip", "get", "SMBIOSMemoryType"]);
        if(process.exitCode() == 0)
            memoryOutput = Std.int(Std.parseFloat(process.stdout.readAll().toString().trim().split("\n")[1]));
        
        if(memoryOutput != -1)
            return memoryMap[memoryOutput];
        
        #elseif mac
        var process = new HiddenProcess("system_profiler", ["SPMemoryDataType"]);

        var reg = ~/Type: (.+)/;
        reg.match(process.stdout.readAll().toString());

        if(process.exitCode() == 0)
            return reg.matched(1);

        #elseif linux
        var process = new HiddenProcess("sudo", ["dmidecode", "--type", "17"]);
        if(process.exitCode() != 0)
            return "Unknown";
        
        var lines:Array<String> = process.stdout.readAll().toString().split("\n");
        for(line in lines) {
            if(line.indexOf("Type:") == 0)
                return line.substring("Type:".length).trim();
        }
        #end
        return "Unknown";
    }
}