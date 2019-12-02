/*
PDP-13
Copyright (C) 2019 Joe <iauit@gmx.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#pragma once

#include "lua_api/l_base.h"

class ModApiPdp13 : public ModApiBase
{
private:
    static int l_create(lua_State *L);
    static int l_clear(lua_State *L);
    static int l_loadaddr(lua_State *L);
    static int l_deposit(lua_State *L);
    static int l_examine(lua_State *L);
    static int l_get_vm(lua_State *L);
    static int l_set_vm(lua_State *L);
    static int l_read_mem(lua_State *L);
    static int l_write_mem(lua_State *L);
    static int l_get_cpu_reg(lua_State *L);
    static int l_run(lua_State *L);
    static int l_get_event(lua_State *L);
    static int l_event_response(lua_State *L);
    static int l_destroy(lua_State *L);

public:
    static void Initialize(lua_State *L, int top);
};
