/*
 * Copyright (c) 2008-2016 Thomas Roell.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimers.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimers in the
 *     documentation and/or other materials provided with the distribution.
 *  3. Neither the name of Thomas Roell, nor the names of its contributors
 *     may be used to endorse or promote products derived from this Software
 *     without specific prior written permission.
 *
 * THE SOFTWARE IS PROVINCED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * WITH THE SOFTWARE.
 */


/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 * 
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __copy_table_start__
 *   __copy_table_end__
 *   __zero_table_start__
 *   __zero_table_end__
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */

MEMORY
{
   FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 0x00040000
   SRAM1 (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00010000
}

ENTRY(Reset_Handler)

SECTIONS
{
   .boot :
   {
       KEEP(*(.boot_isr_vector))
       KEEP(*(.bootcode .bootcode*))
       KEEP(boot_stm32l433.o(.text .text*))
       KEEP(boot_stm32l433.o(.rodata .rodata*))
       KEEP(*(.iap_prefix));
       . = 1024;
   } > FLASH

   .text :
   {
       KEEP(*(.isr_vector));
       . = 460;
       KEEP(*(.iap_info));
       . = 512;

       *(.text .text.* .gnu.linkonce.t.*)

       KEEP(*(.init))
       KEEP(*(.fini))

       /* .ctors */
       *crtbegin.o(.ctors)
       *crtbegin?.o(.ctors)
       *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
       *(SORT(.ctors.*))
       *(.ctors)

       /* .dtors */
       *crtbegin.o(.dtors)
       *crtbegin?.o(.dtors)
       *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
       *(SORT(.dtors.*))
       *(.dtors)

       *(.rodata .rodata.* .gnu.linkonce.r.*)

       KEEP(*(.eh_frame*))

       /* preinit data */
       PROVIDE_HIDDEN (__preinit_array_start = .);
       KEEP(*(.preinit_array))
       PROVIDE_HIDDEN (__preinit_array_end = .);

       /* init data */
       PROVIDE_HIDDEN (__init_array_start = .);
       KEEP(*(SORT(.init_array.*)))
       KEEP(*(.init_array))
       PROVIDE_HIDDEN (__init_array_end = .);

       /* finit data */
       PROVIDE_HIDDEN (__fini_array_start = .);
       KEEP(*(SORT(.fini_array.*)))
       KEEP(*(.fini_array))
       PROVIDE_HIDDEN (__fini_array_end = .);

       . = ALIGN(4);
     __copy_table_start__ = .;
       LONG (LOADADDR(.data))
       LONG (__data_start__)
       LONG (__data_end__ - __data_start__)
       LONG (LOADADDR(.data2))
       LONG (__data2_start__)
       LONG (__data2_end__ - __data2_start__)
       LONG (LOADADDR(.rodata2))
       LONG (__rodata2_start__)
       LONG (__rodata2_end__ - __rodata2_start__)
     __copy_table_end__ = .;
     __zero_table_start__ = .;
       LONG (__bss_start__)
       LONG (__bss_end__ - __bss_start__)
       LONG (__bss2_start__)
       LONG (__bss2_end__ - __bss2_start__)
     __zero_table_end__ = .;
       . = ALIGN(8);
   } > FLASH

   .ARM.extab :
   {
       *(.ARM.extab* .gnu.linkonce.armextab.*)
       . = ALIGN(8);
   } > FLASH

   .ARM.exidx :
   {
       PROVIDE_HIDDEN(__exidx_start = .);
       *(.ARM.exidx* .gnu.linkonce.armexidx.*)
       PROVIDE_HIDDEN(__exidx_end = .);
       . = ALIGN(8);
   } > FLASH

   __etext = . ;

   .data :
   {
     __data_start__ = .;
       *(vtable)
       *(.data .data.* .gnu.linkonce.d.*)
     . = ALIGN(8);
     __data_end__ = .;
   } > SRAM1 AT >FLASH

   .bss (NOLOAD) :
   {
     __bss_start__ = .;
       *(.bss .bss.* .gnu.linkonce.b.*)
       *(COMMON)
       . = ALIGN(8);
     __bss_end__ = .;
   } > SRAM1

   .noinit (NOLOAD) :
   {
       *(.noinit .noinit.*)
       . = ALIGN(8);
   } > SRAM1

   .heap (COPY):
   {
     __end__ = . ;
       PROVIDE(end = .);
       *(.heap*)
       . = ALIGN(8);
     __HeapLimit = .;
   } > SRAM1

   /* .stack_dummy section doesn't contains any symbols. It is only
    * used for linker to calculate size of stack sections, and assign
    * values to stack symbols later */
   .stack_dummy (COPY):
   {
       *(.stack*)
   } > SRAM1

   /* Set stack top to end of RAM, and stack limit move down by
    * size of stack_dummy section */
   __StackTop = ORIGIN(SRAM1) + LENGTH(SRAM1);
   __StackLimit = __StackTop - SIZEOF(.stack_dummy);
   PROVIDE(__stack = __StackTop);
        
   /* Check if data + heap + stack exceeds RAM limit */
   ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")

   .rodata2 :
   {
     __rodata2_start__ = .;
       *(.rodata2 .rodata2.*)
       . = ALIGN(8);
     __rodata2_end__ = .;
       . = ALIGN(1024);
   } > SRAM2 AT >FLASH

   .data2 :
   {
     __data2_start__ = .;
       *(.data2 .data2.*)
       . = ALIGN(8);
     __data2_end__ = .;
   } > SRAM2 AT >FLASH

   .bss2 (NOLOAD) :
   {
     __bss2_start__ = .;
       *(.bss2 .bss2.*)
       . = ALIGN(8);
     __bss2_end__ = .;
   } > SRAM2

   .noinit2 (NOLOAD) :
   {
       *(.noinit2 .noinit2.*)
       . = ALIGN(8);
   } > SRAM2

   .backup :
   {
     __backup_start__ = .;
       *(.backup .backup.*)
       . = ALIGN(8);
     __backup_end__ = .;
   } > SRAM2 AT >FLASH

   __etextbkp = LOADADDR(.backup);

   __FlashBase = ALIGN(LOADADDR(.backup) + SIZEOF(.backup), 1024);
   __FlashLimit = ORIGIN(FLASH) + LENGTH(FLASH);

   /* Stabs debugging sections.  */
   .stab          0 : { *(.stab) }
   .stabstr       0 : { *(.stabstr) }
   .stab.excl     0 : { *(.stab.excl) }
   .stab.exclstr  0 : { *(.stab.exclstr) }
   .stab.index    0 : { *(.stab.index) }
   .stab.indexstr 0 : { *(.stab.indexstr) }
   .comment       0 : { *(.comment) }
   /* DWARF debug sections.
      Symbols in the DWARF debugging sections are relative to the beginning
      of the section so we begin them at 0.  */
   /* DWARF 1 */
   .debug          0 : { *(.debug) }
   .line           0 : { *(.line) }
   /* GNU DWARF 1 extensions */
   .debug_srcinfo  0 : { *(.debug_srcinfo) }
   .debug_sfnames  0 : { *(.debug_sfnames) }
   /* DWARF 1.1 and DWARF 2 */
   .debug_aranges  0 : { *(.debug_aranges) }
   .debug_pubnames 0 : { *(.debug_pubnames) }
   /* DWARF 2 */
   .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
   .debug_abbrev   0 : { *(.debug_abbrev) }
   .debug_line     0 : { *(.debug_line) }
   .debug_frame    0 : { *(.debug_frame) }
   .debug_str      0 : { *(.debug_str) }
   .debug_loc      0 : { *(.debug_loc) }
   .debug_macinfo  0 : { *(.debug_macinfo) }
   /* SGI/MIPS DWARF 2 extensions */
   .debug_weaknames 0 : { *(.debug_weaknames) }
   .debug_funcnames 0 : { *(.debug_funcnames) }
   .debug_typenames 0 : { *(.debug_typenames) }
   .debug_varnames  0 : { *(.debug_varnames) }
   /* DWARF 3 */
   .debug_pubtypes 0 : { *(.debug_pubtypes) }
   .debug_ranges   0 : { *(.debug_ranges) }
   /* DWARF Extension.  */
   .debug_macro    0 : { *(.debug_macro) }
   .ARM.attributes 0 : { KEEP (*(.ARM.attributes)) KEEP (*(.gnu.attributes)) }
   .note.gnu.arm.ident 0 : { KEEP (*(.note.gnu.arm.ident)) }
   /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}
