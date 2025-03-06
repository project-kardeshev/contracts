# Gitweave

Gitweave is a Lua AO Process implementation that acts as a remote git repository.

It leverages LuaVFS, lua git, and custom apis using the Handlers module from AOS to create message handlers.

## Developers

### Requirements

- Lua 5.3 - [Download](https://www.lua.org/download.html)
- Luarocks - [Download](https://luarocks.org/)

### Lua Setup

#### With local script (MacOS and Linux only)

Note that we use lua 5.3 because that is what the
[ao-dev-cli](https://github.com/permaweb/ao/tree/main/dev-cli) uses

1. Clone the repository and navigate to the project directory.
2. run the following:

```shell
yarn install-lua-deps
```

#### Manually

1. Build and install lua

```shell
curl -R -O https://lua.org/ftp/lua-5.3.1.tar.gz
tar -xzvf lua-5.3.1.tar.gz
cd lua-5.3.1
make
make install
```

2. Build and install LuaRocks

Note that we do not specify the lua version, it will discover it.

```shell
curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-3.9.1.tar.gz
tar zxpf luarocks-3.9.1.tar.gz
cd luarocks-3.9.1
./configure --with-lua=/usr/local --with-lua-include=/usr/local/include
make build
sudo make install
```

If you ever need to refresh .luarocks, run the following command:

```sh
luarocks purge && luarocks install gitweave-0-0-1.rockspec
```

### aos

To load the module into the `aos` REPL, run the following command:

```sh
aos --load src/init.lua
```

### Code Formatting

The code is formatted using `stylua`. To install `stylua`, run the following
command:

```sh
cargo install stylua
stylua contract
```

### Testing

To run the tests, execute the following command:

```sh
busted .
```

To see the test coverage, run the following command:

```sh
luacov --reporter html && open luacov-html/index.html
```

### Dependencies

To add new dependencies, install using luarocks to the local directory

```sh
luarocks install <package>
```

And add the package to the `dependencies` table in the `gitweave-0-0-1.rockspec`
file.

```lua
-- rest of the file
dependencies = {
    "lua >= 5.3",
    "luaunit >= 3.3.0",
    "<package>"
}
```

# Additional Resources

- [AO Cookbook]

[AO Cookbook]: https://cookbook_ao.arweave.dev
