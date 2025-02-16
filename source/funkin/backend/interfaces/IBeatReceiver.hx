package funkin.backend.interfaces;

interface IBeatReceiver {
    public function stepHit(step:Int):Void;
    public function beatHit(beat:Int):Void;
    public function measureHit(measure:Int):Void;
}