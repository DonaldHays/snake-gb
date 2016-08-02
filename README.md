# Snake for Game Boy

## Building

The build pipeline has a dependency on [node.js](http://nodejs.org). You'll need to install it.

`cd` into `builder/` and run `npm install`.

Also in `builder/`, create a folder called `bin` and copy RGBDS' `asm`, `lib`, `link`, and `rgbfix` files into it.

`cd` back to the project root directory. Run `node build`. The output will be in `build/bin/`. Also note that the build process will generate `asm` files in `img/`. You can look at, but not modify, those files (they're rewritten every time you build).
