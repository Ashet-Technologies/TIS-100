#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

uint8_t rom[256] = {
	0x89,
	0x21,
	0x07,
};

int8_t ACC = 0;
int8_t BAK = 0;
uint8_t IP = 0;

int8_t read_reg(int reg)
{
	if(reg >= 0x8) {
		return (int8_t)(uint8_t)getc(stdin);
	}
	switch(reg)
	{
		case 0x1: return ACC;
		case 0x2: return 0;
		default: exit(1);
	}
}

void write_reg(int reg, int8_t value)
{
	if(reg >= 0x8) {
		putc((uint8_t)value, stdout);
	} else {
		switch(reg)
		{
			case 0x1: ACC = value; break;
			case 0x2: break;
			default: exit(1);
		}
	}
}

void load_rom(char const *file)
{
	FILE *f = fopen(file, "r");
	
	while(!feof(f))
	{
		int len;
		int offset;
		int type;
		int res = fscanf(f, ":%2X%4X%2X", &len, &offset, &type);
		
		uint8_t checksum = len + offset + type;
		for(int i = 0; i < len; i++) {
			int val;
			fscanf(f, "%2X", &val);
			rom[offset + i] = val;
			checksum += val;
		}
		checksum ^= 0xFF;
		checksum += 1;
		
		int check;
		fscanf(f, "%2X\n", &check);
		
		if(check != checksum) {
			fprintf(stderr, 
				"fptr=%d, fscanf=%d len=%d, offset=%d type=%d, checksum: %d, %d\n", 
				ftell(f),
				res,
				len, 
				offset, 
				type, 
				checksum, 
				check);
		}
		
		if(type == 0x01) {
			break;
		}
	}
	
	fclose(f);
}

int main(int argc, char **argv)
{
	if(argc > 1) {
		for(int i = 1; i < argc; i++) {
			load_rom(argv[i]);
		}
	}	
	
	while(true)
	{
		// Fetch:
		uint8_t instr = rom[IP++];
		uint8_t info1 = (instr >> 4);
		instr &= 0x0F;
		
		// Fetch More:
		uint8_t info2;
		if(instr >= 0x08) {
			info2 = rom[IP++];
		}

		// Decode
		switch(instr)
		{
/*| NOP              | 0x00                |                            | Yes     |*/
			case 0x0: break;
/*| SWP              | 0x01                |                            | Yes     | */
			case 0x1: {
				uint8_t tmp = BAK;
				BAK = ACC;;
				ACC = tmp;
				break;
			}
/*| SAV              | 0x02                |                            | Yes     |*/
			case 0x2: {
				BAK = ACC;
				break;
			}
/*| ADD <SRC>        | 0x*S*3              | S = `<SRC>`                | Yes     |*/
			case 0x3: {
				ACC += read_reg(info1);
				break;
			}
/*| SUB <SRC>        | 0x*S*4              | S = `<SRC>`                | Yes     |*/
			case 0x4: {
				ACC -= read_reg(info1);
				break;
			}
/*| NEG              | 0x05                |                            | Yes     |*/
			case 0x5: {
				ACC = -ACC;
				break;
			}
/*| JRO <SRC>        | 0x*S*6              | S = `<SRC>`                | Yes     |*/
			case 0x6: {
				IP += read_reg(info1);
				break;
			}
/*| HLT              | 0x07                |                            | Yes     |*/
			case 0x7: {
				exit(0);
			}
/*| MOV <SRC>, <DST> | 0x*D*8 0x0*S*       | D = `<DST>`, S = `<SRC>`   | Yes     |*/
			case 0x8: {
				write_reg(info1, read_reg(info2));
				break;
			}
/*| MOV <IMM>, <DST> | 0x*D*9 *IMM*        | D = `<DST>`, IMM = `<IMM>` | Yes     |*/
			case 0x9: {
				write_reg(info1, info2);
				break;
			}
/*| ADD <IMM>        | 0x0A *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xA: {
				ACC += read_reg(info2);
				break;
			}
/*| SUB <IMM>        | 0x0B *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xB: {
				ACC += read_reg(info2);
				break;
			}
/*| JMP <DEST>       | 0x0C *DEST*         | DEST = `<DEST>`            | Yes     |*/
/*| JEZ <DEST>       | 0x1C *DEST*         | DEST = `<DEST>`            | Yes     |*/
/*| JNZ <DEST>       | 0x2C *DEST*         | DEST = `<DEST>`            | Yes     |*/
/*| JGZ <DEST>       | 0x3C *DEST*         | DEST = `<DEST>`            | Yes     |*/
/*| JLZ <DEST>       | 0x4C *DEST*         | DEST = `<DEST>`            | Yes     |*/
			case 0xC: {
				switch(info1) {
					case 0x0: {
						IP = info2;
						break;
					}
					case 0x1: {
						if(ACC == 0) IP = info2;
						break;
					}
					case 0x2: {
						if(ACC != 0) IP = info2;
						break;
					}
					case 0x3: {
						if(ACC > 0) IP = info2;
						break;
					}
					case 0x4: {
						if(ACC < 0) IP = info2;
						break;
					}
					default: exit(1);
				}
				break;
			}
/*| JRO <IMM>        | 0x0D *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xD: {
				IP += read_reg(info2);
				break;
			}
			default: exit(1);
		}
	}

	return 0;
}