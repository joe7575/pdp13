# PDP-13

To add the VM code to Minetest:

1. Place the 4 cpp/h files into the folder `minetest/src/script/lua_api/`

   

2. Add two lines to `minetest51/src/script/lua_api/CMakeLists.txt`

```c
set(common_SCRIPT_LUA_API_SRCS
    ...
    ${CMAKE_CURRENT_SOURCE_DIR}/l_pdp13.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/l_vm13.cpp
    PARENT_SCOPE)
```



3. Add the following lines to `minetest51/src/script/scripting_mainmenu.cpp`

- after `#include "lua_api/l_settings.h"`:
  `#include "lua_api/l_pdp13.h"`

- after `ModApiSound::Initialize(L, top);`:
  `ModApiPdp13::Initialize(L, top);`

