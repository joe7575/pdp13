/*
PDP-13
Copyright (C) 2019 Joe <iauit@gmx.de>

This file is part of PDP-13.

PDP-13 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PDP-13 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PDP-13.  If not, see <https://www.gnu.org/licenses/>.
*/


#include "l_pdp13.h"
#include "l_vm13.h"
#include "lua_api/l_internal.h"
#include "lua_api/l_inventory.h"
#include "common/c_content.h"
#include "serverenvironment.h"

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))


static void setfield(lua_State *L, const char *reg, int value) {
    lua_pushstring(L, reg);
    lua_pushnumber(L, (double)value);
    lua_settable(L, -3);
}

static void setstrfield(lua_State *L, const char *reg, const char *s) {
    lua_pushstring(L, reg);
    lua_pushstring(L, s);
    lua_settable(L, -3);
}

int ModApiPdp13::l_create(lua_State *L) {
    lua_Integer size = luaL_checkinteger(L, 1);
    cpu13_t *C = vm13_create((uint8_t) size);
    if(C != NULL) {
        lua_pushlightuserdata(L, (void*)C);
        return 1;
    }
    return 0;
}

int ModApiPdp13::l_clear(lua_State *L) {
    if(lua_islightuserdata(L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        if(C != NULL) {
            vm13_clear(C);
            lua_pushboolean(L, 1);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}

int ModApiPdp13::l_loadaddr(lua_State *L) {
    if(lua_islightuserdata(L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer addr = luaL_checkinteger(L, 2);
        if(C != NULL) {
            vm13_loadaddr(C, (uint16_t)addr);
            lua_pushboolean(L, 1);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}

int ModApiPdp13::l_deposit(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer value = luaL_checkinteger(L, 2);
        if(C != NULL) {
            vm13_deposit(C, (uint16_t)value);
            lua_pushboolean(L, 1);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}

int ModApiPdp13::l_examine(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        if(C != NULL) {
            uint16_t value = vm13_examine(C);
            lua_pushinteger(L, value);
            return 1;
        }
    }
    return 0;
}

int ModApiPdp13::l_get_vm(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        uint32_t size = vm13_get_vm_size(C);
        if(size > 0) {
            void *p_data = malloc(size);
            if(p_data != NULL) {
                uint32_t bytes = vm13_get_vm(C, size, (uint8_t*)p_data);
                lua_pushlstring(L, (const char *)p_data, bytes);
                free(p_data);
                return 1;
            }
        }
    }
    return 0;
}

int ModApiPdp13::l_set_vm(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        if(lua_isstring(L, 2)) {
            size_t size;
            const void *p_data = lua_tolstring(L, 2, &size);
            uint32_t res = vm13_set_vm(C, size, (uint8_t*)p_data);
            lua_pop(L, 2);
            lua_pushboolean(L, size == res);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}

int ModApiPdp13::l_read_mem(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer addr = luaL_checkinteger(L, 2);
        lua_Integer num = luaL_checkinteger(L, 3);
        num = MIN(num, 0x80);
        addr = MIN(addr, C->mem_size - num);
        uint16_t *p_data = (uint16_t*)malloc(num * 2);
        if((C != NULL) && (p_data != NULL) && (num > 0)) {
            uint16_t words = vm13_read_mem(C, addr, num, p_data);
            lua_newtable(L);
            for(int i = 0; i < words; i++) {
                lua_pushinteger(L, p_data[i]);
                lua_rawseti(L, -2, i+1);
            }
            free(p_data);
            return 1;
        }
    }
    return 0;
}

int ModApiPdp13::l_write_mem(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        uint16_t addr = (uint16_t)luaL_checkinteger(L, 2);
        if(lua_istable(L, 3)) {
            size_t num = lua_objlen(L, 3);
            num = MIN(num, 0x80);
            addr = MIN(addr, C->mem_size - num);
            uint16_t *p_data = (uint16_t*)malloc(num * 2);
            if((C != NULL) && (p_data != NULL)) {
                for(size_t i = 0; i < num; i++) {
                    lua_rawgeti(L, -1, i+1);
                    uint16_t value = luaL_checkinteger(L, -1);
                    p_data[i] = value;
                    lua_pop(L, 1);
                }
                uint16_t words = vm13_write_mem(C, addr, num, p_data);
                free(p_data);
                lua_pushinteger(L, words);
                return 1;
            }
        }
    }
    return 0;
}

int ModApiPdp13::l_run(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer cycles = luaL_checkinteger(L, 2);
        if(C != NULL) {
            uint32_t ran;
            int res = vm13_run(C, cycles, &ran);
            lua_pushinteger(L, res);
            lua_pushinteger(L, ran);
            return 2;
        }
    }
    lua_pushinteger(L, -1);
    return 1;
}

int ModApiPdp13::l_get_cpu_reg(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        if(C != NULL) {
            lua_newtable(L);               /* creates a table */
            setfield(L, "A", C->areg);
            setfield(L, "B", C->breg);
            setfield(L, "C", C->creg);
            setfield(L, "D", C->dreg);
            setfield(L, "X", C->xreg);
            setfield(L, "Y", C->yreg);
            setfield(L, "PC", C->pcnt);
            setfield(L, "SP", C->sptr);
            return 1;
        }
    }
    return 0;
}

int ModApiPdp13::l_get_event(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer type = luaL_checkinteger(L, 2);
        if(C != NULL) {
            lua_newtable(L); /* creates a table */
            switch(type) {
                case VM13_DELAY:
                    setstrfield(L, "type", "delay");
                    break;

                case VM13_IN:
                    setstrfield(L, "type", "input");
                    setfield(L, "addr", C->io_addr);
                    break;

                case VM13_OUT:
                    setstrfield(L, "type", "output");
                    setfield(L, "addr", C->io_addr);
                    setfield(L, "data", C->out_data);
                    break;

                case VM13_HALT:
                    setstrfield(L, "type", "halt");
                    break;

                case VM13_SYS:
                    setstrfield(L, "type", "system");
                    setfield(L, "addr", C->out_data);
                    setfield(L, "data", C->areg);
                    break;

                case VM13_ERROR:
                    setstrfield(L, "type", "VM invalid");
                    break;
                    
                default:
                    setstrfield(L, "type", "unknown");
                    break;
            }
            return 1;
        }
    }
    return 0;
}

int ModApiPdp13::l_event_response(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        lua_Integer type = luaL_checkinteger(L, 2);
        lua_Integer data = luaL_checkinteger(L, 3);
        if(C != NULL) {
            lua_newtable(L); /* creates a table */
            switch(type) {
                case VM13_IN:
                    *C->p_in_dest = (uint16_t)data;
                    break;

                case VM13_SYS:
                    C->areg = (uint16_t)data;
                    if(lua_isnumber(L, 4)) {
                        data = lua_tointeger(L, 4);
                        C->breg = (uint16_t)data;
                    }
                    break;
            }
            lua_pushboolean(L, 1);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}

int ModApiPdp13::l_destroy(lua_State *L) {
    if(lua_islightuserdata (L, 1)) {
        cpu13_t *C = (cpu13_t*)lua_topointer(L, 1);
        if(C != NULL) {
            vm13_destroy(C);
            lua_pushboolean(L, 1);
            return 1;
        }
    }
    lua_pushboolean(L, 0);
    return 1;
}



void ModApiPdp13::Initialize(lua_State *L, int top)
{
    API_FCT(create);
    API_FCT(clear);
    API_FCT(loadaddr);
    API_FCT(deposit);
    API_FCT(examine);
    API_FCT(get_vm);
    API_FCT(set_vm);
    API_FCT(read_mem);
    API_FCT(write_mem);
    API_FCT(get_cpu_reg);
    API_FCT(run);
    API_FCT(get_event);
    API_FCT(event_response);
    API_FCT(destroy);
}
