# purescript-http-client-interface

This project explores ways of enabling a library to make HTTP requests without forcing the library's user to use the HTTP request chosen by the library author.

### Motivation

As I was looking at my project's JavaScript dependencies (e.g. JavaScript library maintained by Google to upload to Google Cloud Storage buckets), I see that my project had several different HTTP client libraries installed, due to various JS tools choosing to use different ones for whatever reasons.

My thoughts: I've been happily using the `http` node-native function for awhile now - why do I have `request` package installed now? Why can't the JavaScript ecosystem all use and be happy with a single HTTP client library? Why is the `request` package's HTTP client implementation soooo huge and do so many things (including OAuth, it seems, and 4 different ways of passing authentication to a request)? I dont want the `request` library in my project, because it's gross, why can't *I* choose the HTTP client to use and pass it into the libraries I use?

### Ideating a solution

So this reminded me of other languages' ecosystems which create and use a standard HTTP server interface which all server frameworks adopted, like Rack in the Ruby ecosystem, enabling HTTP server application developers free to swap out the HTTP server impementation they use. Can we get something similar to that, but for HTTP client requests?

Having a normalized interface for HTTP clients would serve the PureScript ecosystem well - browser apps can use `XMLHTTPRequest` HTTP client (ewww) or the `fetch` HTTP client, but on the server side, they need to choose from other choices, like te `xhr2` package, the `https` node-native functions, and the `request` and `fetch` packages.

### Implementation

This project is to explore how to implement that normalized HTTP client interface.

- A type-class, for getting the HTTP client from context like `ReaderT`?
- A `purescript-run` thing, which just puts the HTTP request runner in the runtime, so to speak?
- `Aff` or `Eff`?
- Simply pass the HTTP client as an argument to the function which needs to make the HTTP request?

I've made a start - take a look in the "src" directory. I'm still ideating, so I haven't compiled/type-checked this project yet or added dependencies. Feel free to contribute or fix ideas.

Thanks for your time! Stay warm in this cold weather, and be type-safe out there!
xoxo
- chexxor
