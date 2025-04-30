package funkin.graphics.shader;

import haxe.Exception;
import hscript.IHScriptCustomBehaviour;
import flixel.system.FlxAssets.FlxShader;

import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display.ShaderParameterType;
import lime.utils.Float32Array;

using StringTools;

import openfl.display.ShaderParameter;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;

import flixel.graphics.FlxGraphic;

@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class RuntimeShader extends FlxShader implements IHScriptCustomBehaviour {
	private static var __instanceFields = Type.getInstanceFields(RuntimeShader);
	private static var __programErrors:Map<String, String> = [];
	private static var __linkErrors:Map<String, String> = [];

	public var glslVer:String = "320 es";
	public var fragFileName:String;
	public var vertFileName:String;

	/**
	 * Creates a new shader from the specified fragment and vertex source.
	 * Accepts `#pragma header`.
	 * @param frag Fragment source (pass `null` to use default)
	 * @param vert Vertex source (pass `null` to use default)
	 * @param glslVer Version of GLSL to use (defaults to 320 es)
	 */
	public override function new(frag:String, vert:String, glslVer:String = "320 es") {
		if (frag == null) frag = ShaderTemplates.defaultFragmentSource;
		if (vert == null) vert = ShaderTemplates.defaultVertexSource;
		this.glFragmentSource = frag;
		this.glVertexSource = vert;

		this.glslVer = glslVer;
		super();
	}

	var ERROR_POS_REGEX = ~/(\d+):(\d+): (.*)/g;
	var ERROR_REGEX = ~/ERROR: (\d+):(\d+): (.*)/g;
	var ERROR_REGEX_2 = ~/(\d+)\((\d+)\) : error ([^:]+): (.*)/g;
	@:noCompletion private override function __createGLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		var shaderInfoLog = gl.getShaderInfoLog(shader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "";
		var compileStatus = gl.getShaderParameter(shader, gl.COMPILE_STATUS);

		if (hasInfoLog || compileStatus == 0)
		{
			var isVertexShader = type == gl.VERTEX_SHADER;
			var messageBuf = new StringBuf();
			messageBuf.add((compileStatus == 0) ? "Error" : "Info");
			if(isVertexShader) {
				messageBuf.add(" compiling vertex shader");
				if(vertFileName != null && vertFileName.length > 0) {
					messageBuf.add(" (" + vertFileName + ")");
				}
			} else {
				messageBuf.add(" compiling fragment shader");
				if(fragFileName != null && fragFileName.length > 0) {
					messageBuf.add(" (" + fragFileName + ")");
				}
			}
			messageBuf.add("\n");
			var errorPositions = [];
			var regex = null;
			var tmp = shaderInfoLog;
			if(shaderInfoLog.contains(" : error ")) {
				regex = ERROR_REGEX_2;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(4)));
					tmp = regex.matchedRight();
				}
			} else if(shaderInfoLog.contains("ERROR: ")) {
				regex = ERROR_REGEX;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(3)));
					tmp = regex.matchedRight();
				}
			} else {
				regex = ERROR_POS_REGEX;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(3)));
					tmp = regex.matchedRight();
				}
			}
			var splitSource = source.split("\n");
			for(error in errorPositions) {
				messageBuf.add("ERROR: Line: " + error.line);
				if(error.column > 0) {
					messageBuf.add(", Column: " + error.column);
				}
				messageBuf.add(", " + error.message);
				if(error.line < splitSource.length) {
					messageBuf.add("\nLine: ");
					messageBuf.add(splitSource[error.line-1].trim());
				}
				messageBuf.add("\n\n");
			}
			var hasErrorPosition = errorPositions.length > 0;
			if(hasErrorPosition) {
				messageBuf.add("Raw shader info log:\n");
			}
			messageBuf.add(shaderInfoLog);
			messageBuf.add("\n");
			messageBuf.add(source);

			var message = messageBuf.toString();
			if (compileStatus == 0)
			{
				__programErrors.set(source, message);
				Logs.error(message);
			}
			else
				__programErrors.remove(source);
		}

		return shader;
	}

	@:noCompletion private override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		var gl = __context.gl;
		var rawID:String = vertexSource + fragmentSource;

		var vertexShader = __createGLShader(vertexSource, gl.VERTEX_SHADER);
		var fragmentShader = __createGLShader(fragmentSource, gl.FRAGMENT_SHADER);

		var program = gl.createProgram();

		for (param in __paramFloat)
		{
			if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
			{
				gl.bindAttribLocation(program, 0, param.name);
				break;
			}
		}

		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			var messageBuf = new StringBuf();
			messageBuf.add("Unable to initialize the shader program");
			messageBuf.add("\n");
			messageBuf.add(gl.getProgramInfoLog(program));
			
			var message = messageBuf.toString();
			Logs.error(message);

			__linkErrors.set(rawID, message);
		}
		else
			__linkErrors.remove(rawID);
		
		return program;
	}

	var glRawFragmentSource:String;
	var glRawVertexSource:String;

	@:noCompletion override private function set_glFragmentSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultFragmentSource;
		glRawFragmentSource = value;
		value = value.replace("#pragma header", ShaderTemplates.fragHeader).replace("#pragma body", ShaderTemplates.fragBody).replace("gl_FragColor", "flx_FragColor");
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion override private function set_glVertexSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultVertexSource;
		glRawVertexSource = value;

		var useBackCompat:Bool = true;
		for (regex in ShaderTemplates.vertBackCompatVarList) if (!regex.match(value)) useBackCompat = false;
		
		value = value.replace("#pragma header", useBackCompat ? ShaderTemplates.vertHeaderBackCompat : ShaderTemplates.vertHeader).replace("#pragma body", useBackCompat ? ShaderTemplates.vertBodyBackCompat : ShaderTemplates.vertBody);
		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}

	@:noCompletion private override function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
			{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "in");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}
		if (__context != null && program == null)
		{
			var prefixBuf = new StringBuf();
			prefixBuf.add('#version ${glslVer}\n');

			var gl = __context.gl;

			prefixBuf.add("#ifdef GL_ES\n");
			if (precisionHint == FULL) {
				prefixBuf.add("#ifdef GL_FRAGMENT_PRECISION_HIGH\n");
				prefixBuf.add("precision highp float;\n");
				prefixBuf.add("#else\n");
				prefixBuf.add("precision mediump float;\n");
				prefixBuf.add("#endif\n");
			} else {
				prefixBuf.add("precision lowp float;\n");
			}
			prefixBuf.add("#endif\n");

			var prefix = prefixBuf.toString();

			var vertex = prefix + glVertexSource;
			var fragment = prefix + glFragmentSource;

			var rawID:String = vertex + fragment;
			if (__context.__programs.exists(rawID))
			{
				program = __context.__programs.get(rawID);

				var programError = __programErrors.get(vertex);
				if (programError != null)
					Logs.error(programError);

				var programError = __programErrors.get(fragment);
				if (programError != null)
					Logs.error(programError);

				var linkError = __linkErrors.get(rawID);
				if (linkError != null)
					Logs.error(linkError);
			}
			else
			{
				program = __context.createProgram(GLSL);
				program.__glProgram = __createGLProgram(vertex, fragment);
				__context.__programs.set(rawID, program);
			}

			if (program != null)
			{
				glProgram = program.__glProgram;

				for (input in __inputBitmapData) {

					if (input.__isUniform) {
						input.index = gl.getUniformLocation(glProgram, input.name);
					} else {
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
			// initInstance(vertex, fragment); // btw make sure to disable the prefixes for ._isInstance
		}
	}

	@:noCompletion private override function __processGLData(source:String, storageType:String):Void
	{
		var lastMatch = 0, position, regex, name, type;

		if (storageType == "uniform")
		{
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}
		else
		{
			regex = ~/in ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
			{
				continue;
			}

			var isUniform = (storageType == "uniform");

			if (StringTools.startsWith(type, "sampler"))
			{
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name)
				{
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);
				try{Reflect.setField(this, name, input);} catch(e) {}
			}
			else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null)
			{
				var parameterType:ShaderParameterType = switch (type)
				{
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType)
				{
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType)
				{
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
						{
							__hasColorTransform = parameter;
						}

						Reflect.setField(__data, name, parameter);
						try{Reflect.setField(this, name, parameter);} catch(e) {}

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);
						Reflect.setField(__data, name, parameter);
						try{Reflect.setField(this, name, parameter);} catch(e) {}

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_"))
						{
							switch (name)
							{
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);
						try{Reflect.setField(this, name, parameter);} catch(e) {}
				}
			}

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}

	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_${name}')) {
			return Reflect.getProperty(this, name);
		}
		if (!Reflect.hasField(data, name)) return null;
		var field = Reflect.field(data, name);
		var cl = Type.getClassName(Type.getClass(field));

		// little problem we are facing boys...

		// cant do "field is ShaderInput" because ShaderInput has the @:generic metadata
		// aka instead of ShaderInput<Float> it gets built as ShaderInput_Float
		// this should be fine tho because we check the class, and the fields dont vary based on the type

		// thanks for looking in the code cne fans :D!! -lunar

		if (cl.startsWith("openfl.display.ShaderParameter"))
			return (field.__length > 1) ? field.value : field.value[0];
		else if (cl.startsWith("openfl.display.ShaderInput"))
			return field.input;
		return field;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}

		if (!Reflect.hasField(data, name)) {
			Reflect.setField(data, name, val);
			return val;
		} else {
			var field = Reflect.field(data, name);
			var cl = Type.getClassName(Type.getClass(field));
			var isNotNull = val != null;
			// cant do "field is ShaderInput" for some reason
			if (cl.startsWith("openfl.display.ShaderParameter")) {
				if (field.__length <= 1) {
					// that means we wait for a single number, instead of an array
					if (field.__isInt && isNotNull && !(val is Int)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Int');
						return null;
					} else
					if (field.__isBool && isNotNull && !(val is Bool)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Bool');
						return null;
					} else
					if (field.__isFloat && isNotNull && !(val is Float)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Float');
						return null;
					}
					return field.value = (isNotNull) ? [val] : null;
				} else {
					if (isNotNull && !(val is Array)) {
						throw new ShaderTypeException(name, Type.getClass(val), Array);
						return null;
					}
					return field.value = val;
				}
			} else if (cl.startsWith("openfl.display.ShaderInput")) {
				// shader input!!
				var bitmap:BitmapData;

				if (!isNotNull)
					bitmap = null;
				
				else if (val is FlxGraphic)
					bitmap = val.bitmap;

				else if (val is BitmapData)
					bitmap = val;

				else {
					throw new ShaderTypeException(name, Type.getClass(val), BitmapData);
					return null;
				}
				field.input = bitmap;
			}
		}

		return val;
	}

    /**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve a float parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloat(name:String):Null<Float>
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getInt(name:String):Null<Int>
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBool(name:String):Null<Bool>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setSampler2D(name:String, value:BitmapData):Void
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			FlxG.log.warn('Shader sampler2D input "$name" not found.');
			return;
		}

		shaderInput.input = value;
	}

	/**
	 * Retrieve a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getSampler2D(name:String):Null<BitmapData>
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			FlxG.log.warn('Shader sampler2D input "$name" not found.');
			return null;
		}

		return shaderInput.input;
	}
}

class ShaderTemplates {
	public static final fragHeader:String = "layout(location = 0) out vec4 flx_FragColor;
in float openfl_Alphav;
in vec4 openfl_ColorMultiplierv;
in vec4 openfl_ColorOffsetv;
in vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 applyFlixelEffects(vec4 color) {
	if(!hasTransform) {
		return color;
	}

	if(color.a == 0.0) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}

	if(!hasColorTransform) {
		return color * openfl_Alphav;
	}

	color.rgb = color.rgb / color.a;
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);

	if(color.a > 0.0) {
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	vec4 color = texture(bitmap, coord);
	return applyFlixelEffects(color);
}

uniform vec4 _camSize;

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
}
vec4 textureCam(sampler2D bitmap, vec2 pos) {
	return flixel_texture2D(bitmap, camToOg(pos));
}";

	public static final fragBody:String = "flx_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);";
	public static final vertHeader:String = "in float openfl_Alpha;
in vec4 openfl_ColorMultiplier;
in vec4 openfl_ColorOffset;
in vec4 openfl_Position;
in vec2 openfl_TextureCoord;

out float openfl_Alphav;
out vec4 openfl_ColorMultiplierv;
out vec4 openfl_ColorOffsetv;
out vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;

in float alpha;
in vec4 colorMultiplier;
in vec4 colorOffset;
uniform bool hasColorTransform;";

	public static final vertBody:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if(openfl_HasColorTransform) {
	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
}

openfl_Alphav = openfl_Alpha * alpha;

if(hasColorTransform) {
	openfl_ColorOffsetv = colorOffset / 255.0;
	openfl_ColorMultiplierv = colorMultiplier;
}

gl_Position = openfl_Matrix * openfl_Position;";

// TODO: make this ignore comments
public static final vertBackCompatVarList:Array<EReg> = [
	~/in float alpha/,
	~/in vec4 colorMultiplier/,
	~/in vec4 colorOffset/,
	~/uniform bool hasColorTransform/
];

public static final vertHeaderBackCompat:String = "in float openfl_Alpha;
in vec4 openfl_ColorMultiplier;
in vec4 openfl_ColorOffset;
in vec4 openfl_Position;
in vec2 openfl_TextureCoord;

out float openfl_Alphav;
out vec4 openfl_ColorMultiplierv;
out vec4 openfl_ColorOffsetv;
out vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;";

public static final vertBodyBackCompat:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if(openfl_HasColorTransform) {
	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
}

gl_Position = openfl_Matrix * openfl_Position;";

	public static final defaultVertexSource:String = "#pragma header

void main(void) {
	#pragma body
}";

	public static final defaultFragmentSource:String = "#pragma header

void main(void) {
	#pragma body
}";
}

class ShaderTypeException extends Exception {
	var has:Class<Dynamic>;
	var want:Class<Dynamic>;
	var name:String;

	public function new(name:String, has:Class<Dynamic>, want:Dynamic) {
		this.has = has;
		this.want = want;
		this.name = name;
		super('ShaderTypeException - Tried to set the shader uniform "${name}" as a ${Type.getClassName(has)}, but the shader uniform is a ${Std.string(want)}.');
	}
}

class ShaderErrorPosition {
	public var column:Int;
	public var line:Int;
	public var message:String;

	public function new(line:String, column:String, message:String) {
		this.line = Std.parseInt(line);
		this.column = Std.parseInt(column);
		this.message = message;
	}
}