# TIS-50
Tesselated Intelligence System 50

## Word Size
8 Bit

## Registers
All registers have word size.

### ACC
Accumulator, used for working.

### BAK
Allows storing a backup value, cannot be accessed directly.

### NIL
Always zero, ignores writes.

### IO
A write to this register writes a word to the port.
A read from this register reads a word from the port.

### IP
Instruction pointer. Stores the next instruction that is executed.

## Instruction Set

> Notation Hints:
> <SRC> or <DST> means any of ACC, NIL or IO.
> <IMM> means an immediate number from -128 to +127.
> <DEST> means an address between 0 and 255.
> IP is the instruction pointer.

### NOP
Waits one cycle.

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

	IP ← IP + <SRC>;
	
### JRO <IMM>
Jumps to the relative address given with `<IMM>`.

	IP ← IP + <IMM>;

## Instruction Encoding
Each instruction has a size of a mulitple of 8 bit.

The encoding is noted in a list of hexadecimal values where
each emphasised character has a special meaning.

| Instruction      | Encoding            | Hints                  |
|------------------|---------------------|------------------------|
| NOP              | 0x00                |                        |
| MOV <SRC>, <DST> | 0x01 0x*DS*         | D = <DST>, S = <SRC>   |
| MOV <IMM>, <DST> | 0x*D*1 *IMM*        | D = <DST>, IMM = <IMM> |
| SWP              | 0x02                |                        |
| SAV              | 0x03                |                        |
| ADD <SRC>        | 0x*S*4              | S = <SRC>              |
| ADD <IMM>        | 0x05 *IMM*          | IMM = <IMM>            |
| SUB <SRC>        | 0x*S*5              | S = <SRC>              |
| SUB <IMM>        | 0x06 *IMM*          | IMM = <IMM>            |
| NEG              | 0x07                |                        |
| JMP <DEST>       | 0x08 *DEST*         | DEST = <DEST>          |
| JEZ <DEST>       | 0x18 *DEST*         | DEST = <DEST>          |
| JNZ <DEST>       | 0x28 *DEST*         | DEST = <DEST>          |
| JGZ <DEST>       | 0x38 *DEST*         | DEST = <DEST>          |
| JLZ <DEST>       | 0x48 *DEST*         | DEST = <DEST>          |
| JRO <SRC>        | 0x*S*9              | S = <SRC>              |
| JRO <IMM>        | 0x09 *IMM*          | IMM = <IMM>            |

### <SRC>, <DST> Encoding
A `<SRC>` or `<DST>` target is encoded with a nibble (4 bits).

| Value | Target  |
|-------|---------|
| 0x0   | Invalid |
| 0x1   | ACC     |
| 0x2   | NIL     |
| 0x3   | IO      |

### <IMM> Encoding
An immediate value is encoded with an 8 bit [two's complement](https://en.wikipedia.org/wiki/Two%27s_complement) value.

### <DEST> Encoding
A destination value is encoded by an unsigned 8 bit value.