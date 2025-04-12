package funkin.graphics;

enum abstract AtlasType(String) from String to String {
    final SPARROW = "sparrow";
    final GRID = "grid";
    final ANIMATE = "animate";
    final IMAGE = "image"; // only used for specific things like ratings & combo
}