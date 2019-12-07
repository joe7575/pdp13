# PDP-13

To add the VM code to Minetest:

1. Copy the content of folder `pdp13` to `/minetest/src/script/pdp13`

   

2. Add two lines to `./minetest/src/script/CMakeLists.txt`

```c
add_subdirectory(pdp13)

# Used by server and client
set(common_SCRIPT_SRCS
	...
	${common_SCRIPT_PDP13_SRCS}
```



3. Add the following lines to `./minetest/src/script/scripting_server.cpp`:

```c
extern "C" {
#include "lualib.h"
#include "pdp13/pdp13.h" 				// <== add this line
}
```

and:

```c
ModApiStorage::Initialize(L, top);
ModApiChannels::Initialize(L, top);
luaopen_pdp13(L);  						// <== add this line
```

