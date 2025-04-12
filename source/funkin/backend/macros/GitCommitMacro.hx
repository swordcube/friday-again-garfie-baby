package funkin.backend.macros;

#if macro
import sys.io.Process;
#end
import haxe.macro.Expr;

class GitCommitMacro {
    public static macro function getCommitHash() {
        #if macro
        try {
			var proc = new Process('git', ['rev-parse', '--short', 'HEAD'], false);
			proc.exitCode(true);
			return macro $v{proc.stdout.readLine()};
		} catch(e)
            Sys.println('Error occured getting git commit hash: ' + e);
        
        return macro $v{"-"};
        #else
        return macro $v{"-"};
        #end
    }

    public static macro function getBranch() {
        #if macro
        try {
			var proc = new Process('git', ['branch', '--show-current'], false);
			proc.exitCode(true);
			return macro $v{proc.stdout.readLine()};
		} catch(e)
            Sys.println('Error occured getting git branch: ' + e);
        
        return macro $v{"-"};
        #else
        return macro $v{"-"};
        #end
    }

    public static macro function getCommitNumber() {
        #if macro
        try {
			var proc = new Process('git', ['rev-list', 'HEAD', '--count'], false);
			proc.exitCode(true);
			return macro $v{Std.parseInt(proc.stdout.readLine())};
		} catch(e)
            Sys.println('Error occured getting git commit hash: ' + e);
        
        return macro $v{0};
        #else
        return macro $v{0};
        #end
    }
}