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

#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#define IDENT           (0x33314D56)
#define VERSION         (1)
#define VM13_WORD_SIZE  (16)


/*
** VM return values
*/

#define VM13_ERROR     (-1) // invalid call
#define VM13_OK        (0)  // run to completion
#define VM13_DELAY     (1)  // one cycle pause
#define VM13_IN        (2)  // input command
#define VM13_OUT       (3)  // output command
#define VM13_HALT      (4)  // debugging halt
#define VM13_SYS       (5)  // system call

typedef struct {
    uint32_t ident;     // VM identifier
    uint16_t version;   // VM version
    uint16_t areg;      // A accu register
    uint16_t breg;      // B accu register
    uint16_t creg;      // C accu register
    uint16_t dreg;      // D accu register
    uint16_t xreg;      // X index register
    uint16_t yreg;      // Y index register
    uint16_t pcnt;      // program counter
    uint16_t sptr;      // stack pointer
    uint16_t io_addr;       // for IN/OUT command
    uint16_t out_data;      // for OUT command
    uint16_t mem_mask;
    uint32_t mem_size;
    uint16_t *p_in_dest;    // for IN command
    uint16_t memory[1];     // program/data memory (16 bit)
}cpu13_t;

/*
** printf
*/
void vm13_disassemble(cpu13_t *C, uint8_t opcode, uint8_t addr_mode1, uint8_t addr_mode2);

/*
** Create the CM with the memory size 2^'size'
*/
cpu13_t *vm13_create(uint8_t size);

/*
** Clear memory (set to zero)
*/
void vm13_clear(cpu13_t *C);

/*
** Set PC to given memory address
*/
void vm13_loadaddr(cpu13_t *C, uint16_t addr);

/*
** Deposit 'value' into address loaded and/or examined
*/
void vm13_deposit(cpu13_t *C, uint16_t value);

/*
** Examine address loaded
*/
uint16_t vm13_examine(cpu13_t *C);

/*
** Retrieve the VM size for malloc purposes
*/
uint32_t vm13_get_vm_size(cpu13_t *C);

/*
** Read complete VM inclusive RAM for storage purposes.
** Number of read bytes is returned.
*/
uint32_t vm13_get_vm(cpu13_t *C, uint32_t size_buffer, uint8_t *p_buffer);

/*
** Write (restore) the VM with then given binary string.
** Number of written bytes is returned.
*/
uint32_t vm13_set_vm(cpu13_t *C, uint32_t size_buffer, uint8_t *p_buffer);

/*
** Read memory block for debugging purposes / external drives
*/
uint32_t vm13_read_mem(cpu13_t *C, uint16_t addr, uint16_t num, uint16_t *p_buffer);

/*
** Write memory block from external drives / storage mediums
*/
uint32_t vm13_write_mem(cpu13_t *C, uint16_t addr, uint16_t num, uint16_t *p_buffer);

/*
** Run the VM with the given number of machine cycles.
** The number of executed cycles is stored in 'ran'
** The reason for the abort is returned.
*/
int vm13_run(cpu13_t *C, uint32_t num_cycles, uint32_t *run);

/*
** Free the allocated VM memory
*/
void vm13_destroy(cpu13_t *C);

