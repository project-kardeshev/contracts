package = "name"
version = "0.0-1"
rockspec_format = "3.0"
source = {
    url = "src/init.lua"
}
dependencies = {
    "busted >= 2.2.0",
    "luacov >= 0.15.0",
    "luacheck >= 1.1.2",
    "luacov-html >=1.0.0"
}
test = {
  type = "busted",
}
