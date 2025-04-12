package funkin.graphics.shader;

import haxe.io.Path;

class CustomShader extends RuntimeShader {
    public function new(name:String, ?glslVer:String = "320 es") {
        final fragPath:String = Paths.frag('shaders/${name}');
        fragFileName = Path.withoutDirectory(fragPath);

        final vertPath:String = Paths.vert('shaders/${name}');
        vertFileName = Path.withoutDirectory(vertPath);

        if(!FlxG.assets.exists(fragPath) && !FlxG.assets.exists(vertPath))
            Logs.error('Shader at ${fragPath.replace(".frag", "")} doesn\'t exist.');

        super(
            (FlxG.assets.exists(fragPath)) ? FlxG.assets.getText(fragPath) : null,
            (FlxG.assets.exists(vertPath)) ? FlxG.assets.getText(vertPath) : null,
            glslVer
        );
    }
}