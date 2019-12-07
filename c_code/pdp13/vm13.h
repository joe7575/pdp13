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

#ifndef vm13_h
#define vm13_h


#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#define IDENT           (0x33314D56)
#define VERSION         (1)
#define VM13_WORD_SIZE  (16)


/*
** VM return values
*/

#define VM13_OK        (0)  // run to the end
#define VM13_DELAY     (1)  // one cycle pause
#define VM13_IN        (2)  // input command
#define VM13_OUT       (3)  // output command
#define VM13_SYS       (4)  // system call
#define VM13_HALT      (5)  // CPU halt
#define VM13_ERROR     (6)  // invalid call

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
    uint16_t l_addr;    // latched addr (I/O, examine)
    uint16_t l_data;    // latched data (I/O, examine)
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
** Determine the size in bytes for the VM
** Size is the memory size 2^'size'
*/
uint32_t vm13_calc_size(uint8_t size);

/*
** Return the size store in the VM
*/
uint32_t vm13_real_size(cpu13_t *C);

/*
** Initialize the allocation VM memory.
*/
bool vm13_init(cpu13_t *C, uint32_t mem_size);

/*
** Clear registers and memory (set to zero)
*/
void vm13_clear(cpu13_t *C);

/*
** Set PC to given memory address
*/
void vm13_loadaddr(cpu13_t *C, uint16_t addr);

/*
** Deposit 'value' to PC address and post-increment PC
** addr/data is available via C->io_addr/C->out_data
*/
void vm13_deposit(cpu13_t *C, uint16_t value);

/*
** Read 'value' from PC address and post-increment PC
** addr/data is available via C->io_addr/C->out_data
*/
void vm13_examine(cpu13_t *C);

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

#endif
