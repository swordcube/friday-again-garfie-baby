package funkin.scripting.helpers;

import sys.thread.Thread;

class ThreadHelper {
	/**
		Returns the current thread.
	**/
	public static function current():Thread {
        return Thread.current();
    }

	/**
		Creates a new thread that will execute the `job` function, then exit.

		This function does not setup an event loop for a new thread.
	**/
	public static function create(job:()->Void):Thread {
        return Thread.create(job);
    }

	/**
		Simply execute `job` if current thread already has an event loop.

		But if current thread does not have an event loop: setup event loop,
		run `job` and then destroy event loop. And in this case this function
		does not return until no more events left to run.
	**/
	public static function runWithEventLoop(job:()->Void):Void {
        Thread.runWithEventLoop(job);
    }

	/**
		This is logically equal to `Thread.create(() -> Thread.runWithEventLoop(job));`
	**/
	public static function createWithEventLoop(job:()->Void):Thread {
        return Thread.createWithEventLoop(job);
    }

	/**
		Reads a message from the thread queue. If `block` is true, the function
		blocks until a message is available. If `block` is false, the function
		returns `null` if no message is available.
	**/
	public static function readMessage(block:Bool):Dynamic {
        return Thread.readMessage(block);
    }

	/**
		Run event loop of the current thread
	**/
	public static function processEvents():Void {
        return Thread.processEvents();
    }
}