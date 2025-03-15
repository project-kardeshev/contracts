# AO MFA

This package is designed to enable MFA on your AOS processes.

It does so by intercepting and storing all messages sent, with filters for
predicating which messages need approval.

These messages are stored with a configurable TTL in an LRU-like cache.

### Process features

- start with a prepended handler
  - could have a coroutine running to sort the handlers.list table to enforce
    this, but maybe start without that
  - initial message comes in, adds the message to the list of pending messages,
    uses Handlers.recieve to await continuation of the message
  - controller is notified of the message, sends vote
  - quorum is met for message pattern and handled (cancelled/continued)
  - end of handling for MFA
- APM package to easily/clearly install via Eval
- add/remove controllers
- MFA threshold
- set message filter (tags)
- control for max pending approvals (defaults to 100)
- ttl for pending approvals (defaults to 1 week)

### App features

- dryruns eval for reading process data, compatible with any AOS based process.
- Wallet support
  - Arweave kit (browser/pwa)
  - JWK local wallet
  - evm PK local wallet
  - hardware wallet
- QR code scanning for address copying
- import process ID's to track notifications on processes, with integrations for
  auto-importing contracts with MFA enabled
  - arns integration
  - arlink integration
  - bazar profiles integration
  - beacon wallet integration
  - ...other smart wallets
  - have a integration contributor guide

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
luarocks purge && luarocks install name-0-0-1.rockspec
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

And add the package to the `dependencies` table in the `name-0-0-1.rockspec`
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
