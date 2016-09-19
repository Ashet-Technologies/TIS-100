# TIS-100
Tesselated Intelligence System 100

## Word Size
8 Bit

## Registers
All registers have word size.

### ACC
Accumulator, used for working.

### BAK
Allows storing a backup value, cannot be accessed directly.
> Is not directly addressable.

### NIL
Always zero, ignores writes.

### IP
Instruction pointer. Stores the next instruction that is executed.
> Is not directly addressable.

## IO Ports
IO ports allow communication with the outer world. There are 8 ports
whereby 4 of them are named.

| Port Name | Mnemonic |
|-----------|----------|
| PORT0     | LEFT     |
| PORT1     | UP       |
| PORT2     | RIGHT    |
| PORT3     | DOWN     |
| PORT4     |          |
| PORT5     |          |
| PORT6     |          |
| PORT7     |          |

## Program Memory
The CPU can address a maximum of 256 instructions which are stored in the program memory.

## Instruction Set

> Notation Hints:
> <SRC> or <DST> means any of ACC, NIL or IO.
> <IMM> means an immediate number from -128 to +127.
> <DEST> means an address between 0 and 255.
> IP is the instruction pointer.

### NOP
Waits one cycle.

### HLT
Halts the machine.

### MOV <SRC>, <DST>
Copies `<SRC>` to `DST`.

	<DST> ← <SRC>;

### MOV <IMM>, <DST>
Copies `<IMM>` to `DST`.

	<DST> ← <IMM>;

### SWP
Swaps `ACC` and `BAK`

	SAV ← ACC, ACC ← SAV;

### SAV
Copies `ACC` to `BAK`

	SAV ← ACC;

### ADD <SRC>
Adds `<SRC>` to `ACC`

	ACC ← ACC + <SRC>;
	
### ADD <IMM>
Adds `<IMM>` to `ACC`

	ACC ← ACC + <IMM>;

### SUB <SRC>
Subtracts `<SRC>` from `ACC`

	ACC ← ACC - <SRC>;

### SUB <IMM>
Subtracts `<IMM>` from `ACC`

	ACC ← ACC - <IMM>;

### NEG
Negates `ACC`:

	ACC ← -(ACC);

### JMP <DEST>
Jumps to the address `<DEST>`.

	IP ← <DEST>;

### JEZ <DEST>
Jumps to the address `<DEST>` if `ACC` is zero.

	if ACC == 0:
		IP ← <DEST>;

### JNZ <DEST>
Jumps to the address `<DEST>` if `ACC` is not zero.

	if ACC != 0:
		IP ← <DEST>;

### JGZ <DEST>
Jumps to the address `<DEST>` if `ACC` is greater than zero.

	if ACC > 0:
		IP ← <DEST>;

### JLZ <DEST>
Jumps to the address `<DEST>` if `ACC` is less than zero.

	if ACC < 0:
		IP ← <DEST>;

### JRO <SRC>
Jumps to the relative address given in `<SRC>`.
> Note that some commands use 2 bytes and some commands only one.

	IP ← IP + <SRC>;
	
### JRO <IMM>
Jumps to the relative address given with `<IMM>`.
> Note that some commands use 2 bytes and some commands only one.

	IP ← IP + <IMM>;

## Instruction Encoding
Each instruction has a size of a mulitple of 8 bit.

The encoding is noted in a list of hexadecimal values where
each emphasised character has a special meaning.

| Instruction      | Encoding            | Hints                      | Tested? |
|------------------|---------------------|----------------------------|---------|
| NOP              | 0x00                |                            | Yes     |
| SWP              | 0x01                |                            | Yes     | 
| SAV              | 0x02                |                            | Yes     |
| ADD <SRC>        | 0x*S*3              | S = `<SRC>`                | Yes     |
| SUB <SRC>        | 0x*S*4              | S = `<SRC>`                | Yes     |
| NEG              | 0x05                |                            | Yes     |
| JRO <SRC>        | 0x*S*6              | S = `<SRC>`                | Yes     |
| HLT              | 0x07                |                            | Yes     |
| MOV <SRC>, <DST> | 0x*D*8 0x0*S*       | D = `<DST>`, S = `<SRC>`   | Yes     |
| MOV <IMM>, <DST> | 0x*D*9 *IMM*        | D = `<DST>`, IMM = `<IMM>` | Yes     |
| ADD <IMM>        | 0x0A *IMM*          | IMM = `<IMM>`              | Yes     |
| SUB <IMM>        | 0x0B *IMM*          | IMM = `<IMM>`              | Yes     |
| JMP <DEST>       | 0x0C *DEST*         | DEST = `<DEST>`            | Yes     |
| JEZ <DEST>       | 0x1C *DEST*         | DEST = `<DEST>`            | Yes     |
| JNZ <DEST>       | 0x2C *DEST*         | DEST = `<DEST>`            | Yes     |
| JGZ <DEST>       | 0x3C *DEST*         | DEST = `<DEST>`            | Yes     |
| JLZ <DEST>       | 0x4C *DEST*         | DEST = `<DEST>`            | Yes     |
| JRO <IMM>        | 0x0D *IMM*          | IMM = `<IMM>`              | Yes     |
|                  | 0x0E *???*          | Reserved for later use.    |
|                  | 0x0F *???*          | Reserved for later use.    |

### <SRC>, <DST> Encoding
A `<SRC>` or `<DST>` target is encoded with a nibble (4 bits).

| Value    | Target       |
|----------|--------------|
| 0x0      | Invalid      |
| 0x1      | ACC          |
| 0x2      | NIL          |
| 0x8..0xF | IO Port 0..7 |

### <IMM> Encoding
An immediate value is encoded with an 8 bit [two's complement](https://en.wikipedia.org/wiki/Two%27s_complement) value.

### <DEST> Encoding
A destination value is encoded by an unsigned 8 bit value.
