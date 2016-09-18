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
| ADD <SRC>        | 0x*S*3              | S = `<SRC>`                |
| SUB <SRC>        | 0x*S*4              | S = `<SRC>`                |
| NEG              | 0x05                |                            | Yes     |
| JRO <SRC>        | 0x*S*6              | S = `<SRC>`                |
| HLT              | 0x07                |                            | Yes     |
| MOV <SRC>, <DST> | 0x*D*8 0x0*S*       | D = `<DST>`, S = `<SRC>`   |
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

## CPU Pseudo Code
This part documents the state machine the CPU is executing in pseudocode.

	declare var info1:4, instr:4, info2:8;
	
	# Fetch
	(info1, instr) ← read_byte(IP++);
	
	# Fetch extra if required
	if instr[7] then # if MSB is set
		info2 ← read_byte(IP++);
	else
		info2 ← 0;
	end
	
	switch instr
		case 0x0:
			# NOP
		case 0x1: 
			ACC ← SAV, SAV ← ACC;
		case 0x2:
			SAV ← ACC;
		case 0x3:
			ACC ← ACC + reg(info1);
		case 0x4:
			ACC ← ACC - reg(info1);
		case 0x5:
			ACC ← -ACC;
		case 0x6:
			IP ← IP + reg(info1) - 1;
		case 0x7:
			# NOP
		case 0x8:
			reg(info2[4..7]) ← reg(info2[0..3]);
		case 0x9:
			reg(info1) ← info2;
		case 0xA:
			ACC ← ACC + info2
		case 0xB:
			ACC ← ACC - info2
		CASE 0xC:
			if condition(info1) then
				IP ← info2
			end
		case 0xD:
			IP ← IP + info2 - 1;
		case 0xE:
			# NOP
		case 0xF:
			# NOP
	end