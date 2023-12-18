---
title: "Monitor Goroutines"
date: 2023-06-14T11:55:00-05:00
summary: "A simple way to work with shared memory in Go"
draft: false
---
This is about a small refactoring I did to fix some data races using basic Go concurrency primitives. This might be interesting to you if you're familiar with Go's concurrency model but haven't played with it much.

Recently, I had to deal with data races for the first time while working on a [collaborative terminal text editor](https://github.com/burntcarrot/pairpad). After adding a new feature, I ran the program through Go's handy dandy [data race detector](https://go.dev/doc/articles/race_detector), and unfortunately, it was not very happy with me. I set about fixing the detected races. Halfway through some refactoring, I came upon the idea of [monitor](https://en.wikipedia.org/wiki/Monitor_(synchronization)) goroutines in [The Go Programming Language](https://gopl.io) as a way to protect shared memory. This idea was already pretty similar to our original design, and the natural implementation kind of fell out of the concurrency primitives in Go, so I found it a helpful way to think about solving conflicting memory access.

Here's a rough sketch of what our code used to look like:
```go
// Editor holds all the state of an editing session.
type Editor struct {
	Text [][]string
	StatusMsg string
	// other stuff...
}

// listenForInput listens for input events and sends them over the
// returned channel
func listenForInput() chan InputEvent {
	inputChan := make(chan InputEvent)
	go func() {
		for {
			inputChan <- PollEvent()
		}
	}()
	return inputChan
}

// listenForMessages listens over the connection for JSON messages
// and sends them over the returned  channel.
func listenForMessages() chan Message {
	messageChan := make(chan Message)
	go func() {
		for {
			// get some JSON message from connection
			messageChan <- someJSONMessage
		}
	}
	return messageChan
}

// mainLoop listens on the local and remote message channels to
// update the editor contents.
func (e *Editor) mainLoop() {
	inputChan := listenForInput()
	messageChan := listenForMessages()
	
	for {
		select {
		case input := <- inputChan:
			e.LocalUpdate(input)
		case message := <- messageChan:
			e.RemoteUpdate(message)	
		}
	}
}

// LocalUpdate updates editor contents with the contents of the user
// input event using the CRDT insertion/deletion, and renders the result.
func (e *Editor) LocalUpdate(input InputEvent) {
	// ...update editor state
	e.Draw()
}

// RemoteUpdate updates the editor contents with the contents of the
// remote message using the CRDT insertion/deletion, and renders the result.
func (e *Editor) RemoteUpdate(message Message) {
	// ...update editor state
	e.Draw()
}

// Draw renders the editor contents to the terminal.
func (e *Editor) Draw() {
	for lineNumber, line := range e.Text {
		// ...render text buffer to terminal
	}

	// ...render e.StatusMsg to last line in terminal
}
```

Our actual implementation wasn't exactly like this, and I've left out all the details, but this should be sufficient for now. 

From what I've shown here, this design seems fine, because all editor access happens in the `for` loop in the `mainLoop` function. `LocalUpdate` and `RemoteUpdate` don't spawn their own goroutines, so that `select` statement actually blocks the goroutines while each case is executing its update and render. It's not an optimal use of computer resources, but it's a simple way to get concurrency safety.

The problem with our design was how we implemented updating the status message. The status messag was (in part) for alerting the user to errors like failing to save to a file, or a message indicating you had disconnected from the server, and would be displayed on the last line of the terminal window.

In order to get timely updates on exactly when something went wrong, we were updating the status message (`Editor.StatusMsg`)  and calling `Editor.Draw()` the moment the error was detected. Errors could happen at any time in multiple active goroutines. Instead of having a pipeline sending messages from each place there could be an error, we were updating and drawing the status message all over the place. It was messy and full of trivial data races.

If you're faced with data races and don't know exactly what to do, consider the advice at the top of [the article on Go's memory model](https://go.dev/ref/mem): "Programs that modify data being simultaneously accessed by multiple goroutines must serialize such access. To serialize access, protect the data with channel operations".

They make it sound so simple! And while data races can be [very tricky]([uber](https://www.uber.com/en-MX/blog/data-race-patterns-in-go/)), in our case it does seem to be relatively simple.

Let's start from the inside-out. `Editor.Draw()` accesses a bunch of state at once, like the text buffer and the status message. How do we serialize it? Let's try using a channel:

```go
func drawLoop() {
	for <- e.DrawChan {
		e.Draw()
	}
}

func (e *Editor) SendDraw() {
	e.DrawChan <- 1
}
```

So what does this mean? We're using a channel to serialize access to the draw function. So if we replace all of the instances of calling `Editor.Draw()` in-line with `Editor.SendDraw()`, the channel receive operation in the `drawLoop` (the `<- e.DrawChan` part) will block any concurrent calls to `Editor.SendDraw()` until the current `e.Draw()` call finishes. Just like that, `e.Draw()` is serialized.

Note that this is reminiscent of our previous design: 

```go
func (e *Editor) mainLoop() {
	inputChan := listenForInput()
	messageChan := listenForMessages()
	
	for {
		select {
		case input := <- inputChan:
			e.LocalUpdate(input)
		case message := <- messageChan:
			e.RemoteUpdate(message)	
		}
	}
}
```

`Editor.LocalUpdate` and `Editor.RemoteUpdate` both contain a call to `Draw`, but there won't be a data race between them because they're in the same goroutine. The trouble with the design comes when you try to scale to contain more goroutines with more calls to `Draw` (like for updating the status bar). With the old design, to safely deal with more goroutines, you have to set up a separate pipeline of messages, and add a channel to the select statement, even if all you're doing is a read of the text buffer (like when you're drawing the text to the terminal). With the new design, we don't have to worry so much about the plumbing, because `e.Draw` is hidden behind the `drawChan` that will act as our "monitor". If everyone shares the same pipeline, then everyone has to wait in line to get to what's at the end of the pipe. No racing allowed!

Now, to finish up, we just have to call `go drawLoop()` sometime before our main loop, and it will be there waiting patiently any time we have to update the terminal.

There's still the question of how exactly to fix status updates, since the status bar isn't included in this pipeline. The solution I went with uses another monitor. Now, every time we want to update the status message, which can happen from any goroutine, we send the new status message to the `StatusChan`, ensuring status updates are serialized. We have another goroutine running a `for` loop that listens for messages on the `StatusChan`, updates the status message behind a lock, and sends draw requests with `Editor.SendDraw()`, where access to the status message is also protected by a lock. The monitor (`StatusChan`) isn't strictly necessary here, because I'm still using a lock to allow for concurrent access of the `StatusMsg` by `Editor.Draw`. I could have just called `updateStatusMessage()` directly at the point where the error occurs, but that would potentially allow for a bunch of lock contention if multiple status updates happen at once, and they would block execution of the main threads. Using the combination of the monitor and locks
1. allows for concurrent access by two time sensitive goroutines (updating status and updating the display)
2. reduces lock contention because write access is serialized
3. doesn't impact the execution of the main threads, since now status updates are just sent into the background for processing instead of being called in place

This seemed like the right balance to me.

Monitor goroutines are relatively simple to reason about and implement and a pretty essential tool to have in the eternal struggle against concurrency bugs. I'll be quick to consider this pattern next time I'm faced with one.

### See also:
- [Monitors and Mutexes: a (light) survey](https://medium.com/dm03514-tech-blog/golang-monitors-and-mutexes-a-light-survey-84f04f9b7c09)
- [Monitors: An Operating System Structuring Concept](https://dl.acm.org/doi/pdf/10.1145/355620.361161)

