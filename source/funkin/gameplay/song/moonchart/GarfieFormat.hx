package funkin.gameplay.song.moonchart;

#if USE_MOONCHART
import haxe.Json;
import sys.io.File;

import moonchart.backend.Util;
import moonchart.backend.Timing;

import moonchart.backend.FormatData;
import moonchart.backend.FormatData.Format;

import moonchart.formats.BasicFormat;

import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;
import moonchart.formats.fnf.legacy.FNFLegacy;

class GarfieFormat extends BasicFormat<ChartData, SongMetadata> {
    public var inputFormatName:String;

    public static function __getFormat():FormatData {
		return {
			ID: "FNF_GARFIE",
			name: "FNF (Garfie Baby)",
			description: "gay sex simulator 2025",
			extension: "json",
            formatFile: formatFile,
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
            specialValues: ['_"n":', '_"e":', '_"n":', '_"e":', '_"n":', '_"e":', '_"n":', '_"e":', '_"n":', '_"e":'],
            findMeta: (files) -> {
				for(file in files) {
					if(FlxG.assets.getText(file).contains('"game":'))
						return file;
				}
				return files[0];
			},
			handler: GarfieFormat
		}
	}

    public static function formatFile(title:String, diff:String):Array<String> {
		return ['chart', 'metadata'];
	}

    public function new(?data:ChartData, ?meta:SongMetadata) {
        super({timeFormat: MILLISECONDS, supportsDiffs: true, supportsEvents: true});
        this.data = data;
        this.meta = meta;
    }

    public function validateChart(data:ChartData):ChartData {
        data.events.sort((a, b) -> Std.int(a.time - b.time));
        
        final noteTypes:Array<String> = [];
        for(d => notes in data.notes) {
            notes.sort((a, b) -> Std.int(a.time - b.time));
            for(note in notes) {
                if(noteTypes.contains(note.type))
                    continue;

                noteTypes.push(note.type);
            }
            for(type in noteTypes) {
                for(dir in 0...Constants.KEY_COUNT) {
                    var lastNote:NoteData = null;
                    var dirNotes:Array<NoteData> = notes.filter((n) -> n.direction == dir && n.type == type);
                    
                    for(note in dirNotes) {
                        if(lastNote != null && Math.abs(lastNote.time - note.time) < 2)
                            notes.remove(note);
                        
                        lastNote = note;
                    }
                }
            }
            notes.sort((a, b) -> Std.int(a.time - b.time));
        }
        return data;
    }

    public function fromGarfie(path:String, metaContents:StringInput, ?diff:FormatDifficulty):GarfieFormat {
        if(path != null && path.length != 0) {
            final parser:JsonParser<ChartData> = new JsonParser<ChartData>();
		    parser.ignoreUnknownVariables = true;
            data = parser.fromJson(FlxG.assets.getText(path));
        }
        if(metaContents != null) {
            var foundMeta:String = null;
            for(c in metaContents.resolve()) {
                if(FlxG.assets.exists(c)) {
                    foundMeta = c;
                    break;
                }
            }
            final parser:JsonParser<SongMetadata> = new JsonParser<SongMetadata>();
            parser.ignoreUnknownVariables = true;
            meta = parser.fromJson(foundMeta);
        }
        if(data != null)
            data = validateChart(data);
        
        final resolved:Array<String> = diff?.resolve();
        this.diffs = resolved ?? ["normal"];
        return this;
    }

    override function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):GarfieFormat {
        return fromGarfie((path != null) ? FlxG.assets.getText(path) : null, FlxG.assets.getText(meta), diff);
    }

    override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):GarfieFormat {
        final chartResolve = resolveDiffsNotes(chart, diff);
		final chartDiff:String = chartResolve.diffs[0];
        
        final basicMeta:BasicMetaData = chart.meta;
        final basicEvents:Array<BasicEvent> = chart.data.events;

        final notes:Map<String, Array<NoteData>> = [];
        final events:Array<EventData> = [];
        final timingPoints:Array<TimingPoint> = [];

        final firstChange = basicMeta.bpmChanges[0];
        final timeSig:TimeSignature = [
            basicMeta.extraData.get("beatsPerMeasure") ?? Std.int(firstChange.beatsPerMeasure),
            basicMeta.extraData.get("stepsPerBeat") ?? Std.int(firstChange.stepsPerBeat)
        ];
        if(timeSig.getNumerator() <= 0)
            timeSig.setNumerator(4);

        if(timeSig.getDenominator() <= 0)
            timeSig.setDenominator(4);

        for(i in 1...basicMeta.bpmChanges.length) {
            final bpmChange = basicMeta.bpmChanges[i];
            final curTimeSig:TimeSignature = [
                Std.int(bpmChange.beatsPerMeasure),
                Std.int(bpmChange.stepsPerBeat)
            ];
            if(curTimeSig.getNumerator() <= 0)
                curTimeSig.setNumerator(4);

            if(curTimeSig.getDenominator() <= 0)
                curTimeSig.setDenominator(4);

            timingPoints.push({
                time: Math.max(bpmChange.time, 0.0),
                bpm: bpmChange.bpm,
                step: 0,
                beat: 0,
                measure: 0,
                timeSignature: curTimeSig
            });
        }
        timingPoints.insert(0, {
            time: 0.0,
            bpm: firstChange.bpm,
            step: 0,
            beat: 0,
            measure: 0,
            timeSignature: timeSig
        });
        inline function pushNotes(basicNotes:Array<BasicNote>, diff:String) {
            notes.set(diff, []);
            for(basicNote in basicNotes) {
                notes.get(diff).push({
                    time: basicNote.time,
                    direction: basicNote.lane % 8,
                    length: basicNote.length,
                    type: (basicNote.type != null && basicNote.type.length > 0) ? basicNote.type : "Default",
                });
            }
            notes.get(diff).sort((a, b) -> Std.int(a.time - b.time));
        }
        if(diff != null && diff.resolve().length != 0) {
            for(d in diff.resolve())
                pushNotes(chartResolve.notes.get(d), d);
        } else {
            for(d in chartResolve.diffs)
                pushNotes(chartResolve.notes.get(d), d);
        }
        for(basicEvent in basicEvents) {
            var parsedParams:Dynamic = null;
            if(basicEvent.data is Array)
                parsedParams = {array: basicEvent.data};
            else {
                if(Type.typeof(basicEvent.data) == TObject)
                    parsedParams = basicEvent.data;
                else
                    parsedParams = {array: [basicEvent.data]};
            }
            switch(basicEvent.name) {
                case FNFLegacy.FNF_LEGACY_MUST_HIT_SECTION_EVENT: // Convert legacy "mustHitSection" to Camera Pan events
                    events.push({
                        time: basicEvent.time,
                        params: {char: (parsedParams.mustHitSection ?? true) ? 1 : 0},
                        type: "Camera Pan"
                    });

                case FNFVSlice.VSLICE_FOCUS_EVENT:
                    final char:Int = (parsedParams.array != null) ? parsedParams.array[0] : parsedParams.char;
                    events.push({
                        time: basicEvent.time,
                        params: {char: (char < 2) ? 1 - char : char}, // vslice is stupid
                        type: "Camera Pan"
                    });

                case FNFCodename.CODENAME_CAM_MOVEMENT:
                    events.push({
                        time: basicEvent.time,
                        params: {char: parsedParams.array[0]},
                        type: "Camera Pan"
                    });

                default:
                    // this method of handling engine specific
                    // versions of events is kinda stupid
                    //
                    // but it'll do until moonchart's fnf resolver stuff
                    // gets all finished up
                    switch(inputFormatName) {
                        case Format.FNF_CODENAME:
                            switch(basicEvent.name) {
                                case "Add Camera Zoom":
                                    events.push({
                                        time: basicEvent.time,
                                        params: {
                                            zoom: parsedParams.array[0],
                                            camera: (parsedParams.array[1] == "camHUD") ? "hud" : "game"
                                        },
                                        type: "Add Camera Zoom"
                                    });
                            }   

                        default:
                            events.push({
                                time: basicEvent.time,
                                params: parsedParams,
                                type: basicEvent.name 
                            });
                    }
            }
        }
        events.sort((a, b) -> Std.int(a.time - b.time));

        final legallyObtainedScrollSpeeds:Map<String, Float> = [];
        for(diff => scrollSpeed in basicMeta.scrollSpeeds)
            legallyObtainedScrollSpeeds.set(diff, scrollSpeed);

        final extraVariants:Array<String> = basicMeta.extraData.get("mixes") ?? basicMeta.extraData.get("variants");
        final realDiffs:Array<String> = [];

        for(i in chart.data.diffs.keys())
            realDiffs.push(i);

        this.diffs = realDiffs;
        this.meta = {
            song: {
                title: (basicMeta.extraData.get("displayName") ?? basicMeta.title),
                
                mixes: extraVariants ?? [],
                difficulties: realDiffs,

                timingPoints: timingPoints,

                artist: basicMeta.extraData.get(SONG_ARTIST) ?? (basicMeta.extraData.get("artist") ?? "Unknown"),
                charter: basicMeta.extraData.get(SONG_CHARTER) ?? (basicMeta.extraData.get("charter") ?? "Unknown")
            },
            freeplay: {
                ratings: basicMeta.extraData.get("ratings") ?? new Map<String, Int>(),

                album: basicMeta.extraData.get("album") ?? "vol1",
                icon: basicMeta.extraData.get("icon") ?? "bf"
            },
            game: {
                characters: [
                    "opponent" => basicMeta.extraData.get(PLAYER_2) ?? (basicMeta.extraData.get("opponent") ?? (basicMeta.extraData.get("dad") ?? "bf")),
                    "spectator" => basicMeta.extraData.get(PLAYER_3) ?? (basicMeta.extraData.get("spectator") ?? (basicMeta.extraData.get("girlfriend") ?? "gf")),
                    "player" => basicMeta.extraData.get(PLAYER_1) ?? (basicMeta.extraData.get("player") ?? (basicMeta.extraData.get("boyfriend") ?? "bf"))
                ],
                stage: basicMeta.extraData.get(STAGE) ?? (basicMeta.extraData.get("stage") ?? "stage"),
                noteSkin: basicMeta.extraData.get("noteSkin") ?? "default",
                uiSkin: basicMeta.extraData.get("uiSkin") ?? "default",
                scrollSpeed: legallyObtainedScrollSpeeds
            }
        };
        final shitNotes:Map<String, Array<NoteData>> = [];
        for(diff => leNotes in notes)
            shitNotes.set(diff, leNotes);
        
        this.data = validateChart({
            meta: meta,
            notes: shitNotes,
            events: events
        });
        return this;
    }

    override function getNotes(?diff:String):Array<BasicNote> {
		final notes:Array<BasicNote> = [];
        inline function pushNotes(leNotes:Array<NoteData>) {
            for(note in leNotes) {
                notes.push({
                    time: note.time,
                    lane: note.direction,
                    length: note.length,
                    type: (note.type != null && note.type.length > 0) ? note.type : "Default"
                }); 
            }
        }
        if(diff != null && diff.length > 0) {
            pushNotes(data.notes.get(diff));
        } else {
            for(diff => notesInDiff in data.notes)
                pushNotes(notesInDiff); // probably not a good way to handle unspecified diffs but whatever idc rn lol
        }
		return notes;
	}

    override function getEvents():Array<BasicEvent> {
        final events:Array<BasicEvent> = [];
        for(event in data.events) {
            events.push({
                time: event.time,
                name: event.type,
                data: event.params
            });
		}
        return events;
    }

    override function getChartMeta():BasicMetaData {
        final bpmChanges:Array<TimingPoint> = meta.song.timingPoints.copy();
        final basicBPMChanges:Array<BasicBPMChange> = [];

        for(event in bpmChanges) {
            basicBPMChanges.push({
                time: event.time,
                bpm: event.bpm,
                beatsPerMeasure: event.timeSignature[0],
                stepsPerBeat: event.timeSignature[1]
            });
        }
        return {
            title: meta.song.title,
            bpmChanges: basicBPMChanges,
            offset: 0.0,
            scrollSpeeds: meta.game.scrollSpeed,
            extraData: [
                "icon" => meta.freeplay.icon,
                "album" => meta.freeplay.album,

                "mixes" => meta.song.mixes,
                "difficulties" => meta.song.difficulties,

                "artist" => meta.song.artist,
                "charter" => meta.song.charter,

                "opponent" => meta.game.characters.get("opponent"),
                "spectator" => meta.game.characters.get("spectator"),
                "player" => meta.game.characters.get("player"),
                
                "stage" => meta.game.stage,
                "uiSkin" => meta.game.uiSkin
            ]
        };
    }

    override function stringify() {
        return {
            data: ChartData.stringify(data),
            meta: SongMetadata.stringify(meta)
        };
    }
}
#end