package funkin.utilities;

// i wanna jump in The Pool:tm:!
class Pool<T> {
    private var _index:Int = 0;
    private var _items:Array<T> = [];
    private var _objectFactory:Void->T;

    public function new(objectFactory:Void->T, initialItems:Int = 1) {
        _items.resize(initialItems);
        _objectFactory = objectFactory;

        for(i in 0...initialItems)
            _items[i] = objectFactory();
    }

    public function next():T {
        final prevIndex:Int = _index;
        if(++_index >= _items.length) {
            final prevLength:Int = _items.length;
            _items.resize(prevLength * 2);

            for(i in prevLength...(prevLength * 2))
                _items[i] = _objectFactory();
        }
        return _items[prevIndex];
    }

    public function prev():T {
        return _items[_index--];
    }
}