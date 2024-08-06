I started programming just before the start of the pandemic. I programmed almost entirely in Go for two years, learning the fundamentals of programming and backend web development.

I then attended the fall 2022 batch at the [Recurse Center](https://recurse.org), where I really got to see how great programmers work. I spent the first half of my time there working on small web projects, learning JavaScript and TypeScript, and chatting with others. Throughout my batch, I read through all of *Designing Data-Intensive Applications*, a book by Martin ... about distributed system principles and design, as part of a weekly reading group. I learned a ton about the engineering mindset of tradeoffs in system design, along with fundamentals such as synchronization, replication, consistency, sharding, and more.

During the second half of my RC batch, I worked on designing and implementing a collaborative text editor called [PairPad](https://github.com/burntcarrot/pairpad), along with [Aadhav](). PairPad uses [CRDTs]() as the underlying data structure to maintain consistency between different clients that are simultaneously editing a text document. Making PairPad made me interact much more intimately with Go's concurrency primitives, having to avoid data races and make sure our implementation of the [WOOT]() algorithm was correct.

After RC, I worked on learning a bunch of fundamentals I had missed, like algorithms and data structures, regular expressions, and computer architecture. I also started learning Python.

Around this time, I started working on the backend for [ProductScope](). ProductScope is a web application meant to help people market their products on Amazon. I was initially in charge of designing and implementing an image editing pipeline, powered by AI. I used AWS lambda functions, written in Python, to handle the logic of manipulating the image data, as well as making requests to several external AI services. I learned a ton from this experience, especially about system design, and working with serverless cloud providers.

While I was working on ProductScope, I started helping with the development of [ArchiveBox](). ArchiveBox is a powerful tool for creating and managing your own personal archive of the internet. Initially, I helped with smaller things like bug-fixing, configuration, and auth. Recently, I've been working on adding more extractors to ArchiveBox, including writing my own.

I started writing [papers-dl](), an extractor focused on interfacing with scientific papers that are available on the internet. papers-dl aims to be fast, general-purpose, and convenient. It's written in Python, and uses the asynchronous HTTP package `aiohttp` to make it fast to search dozens of scientific repositories simultaneously.

In the background, I've been following Casey Muratori's [Performance-Aware Programming]() course. I learned Zig, a new systems level programming language, along with a ton about CPUs and how to think about them while programming.

I've also taken the [boot.dev]() course to learn more about backend programming.

