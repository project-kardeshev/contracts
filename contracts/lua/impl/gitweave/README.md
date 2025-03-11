# Gitweave

Gitweave is a Lua AO Process network that acts as a remote git repository.

It leverages lua git, and custom apis using the Handlers module from AOS to
create message handlers.

## TODO:
[ ] - git repo process
        - Upload manager for multipart uploads due to 10mb restriction on MU's
            - this entails creating an upload plan, chunking the blob into 10mb base64 strings, uploading, and recombining them
            - good candidate for coroutines, eg `once` handlers that expect a file upload part. (once handlers should behave in an LRU manner with a max concurrent jobs)
        - LRU branch pruning to maintain memory limits. Can have callback notices on messages "process full, delete some stuff"
            - ideally this actually pushes old branches to remote processes... maybe a FUSE-VFS where the remote is an ao process?

[ ] - PubSub process
[ ] - Observability manager
[ ] - actions process


## APIs

### Info

Provides all the relevant info to display the repository

### Git

Git apis provide access to things like pushing commits, creating refs (branches,
tags), creating pull requests, etc...

#### Commits

#### Refs (branches, tags)

#### Pull Requests

#### Releases

#### Issues
mut
### Actions

### Pubsub

The pubsub mechanism operates with a permissioned proxy pub sub contract. All
publishes go through that, and all subscriptions that this process is interested
in are provided by the pubsub proxy.

### Metrics

The metrics mechanism operates with a proxy contract for maintaining a database
of metrics for all system components (actions runners, pubsub, git, etc). This
contract can be used for powering dashboards. Its a bucket for all metrics in
the gitweave network.

- memory usage
- GC performance (later)
- FS/SQL DB stats (rows, columns) "disk usage" (later)
- git history stats
- runtime of messages
- active users
- Coroutine monitoring variables
- error rates

### Logs

### Traces


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
