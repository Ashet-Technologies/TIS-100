#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

const char *registerName[16] = {
	"INVALID",
	"ACC",
	"NIL",
	"???",
	"???",
	"???",
	"???",
	"???",
	"LEFT",
	"UP",
	"RIGHT",
	"DOWN",
	"PORT4",
	"PORT5",
	"PORT6",
	"PORT7",
};

// #define DEBUG(args...) fprintf(stderr, args)
#define DEBUG(args...)

uint8_t rom[256] = {
	0x07,
};

int8_t ACC = 0;
int8_t BAK = 0;
uint8_t IP = 0;

int8_t read_reg(int reg)
{
	if(reg >= 0x8) {
		int val = getc(stdin);
		if(val == EOF) exit(0);
		
		return (int8_t)(uint8_t)val;
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
				DEBUG("SWP\n");
				uint8_t tmp = BAK;
				BAK = ACC;;
				ACC = tmp;
				break;
			}
/*| SAV              | 0x02                |                            | Yes     |*/
			case 0x2: {
				DEBUG("SAV\n");
				BAK = ACC;
				break;
			}
/*| ADD <SRC>        | 0x*S*3              | S = `<SRC>`                | Yes     |*/
			case 0x3: {
				DEBUG("ADD %s\n", registerName[info1]);
				ACC += read_reg(info1);
				break;
			}
/*| SUB <SRC>        | 0x*S*4              | S = `<SRC>`                | Yes     |*/
			case 0x4: {
				DEBUG("SUB %s\n", registerName[info1]);
				ACC -= read_reg(info1);
				break;
			}
/*| NEG              | 0x05                |                            | Yes     |*/
			case 0x5: {
				DEBUG("NEG\n");
				ACC = -ACC;
				break;
			}
/*| JRO <SRC>        | 0x*S*6              | S = `<SRC>`                | Yes     |*/
			case 0x6: {
				DEBUG("JRO %s\n", registerName[info1]);
				IP += read_reg(info1);
				break;
			}
/*| HLT              | 0x07                |                            | Yes     |*/
			case 0x7: {
				DEBUG("HTL\n");
				exit(0);
			}
/*| MOV <SRC>, <DST> | 0x*D*8 0x0*S*       | D = `<DST>`, S = `<SRC>`   | Yes     |*/
			case 0x8: {
				DEBUG("MOV %s %s\n", registerName[info2], registerName[info1]);
				write_reg(info1, read_reg(info2));
				break;
			}
/*| MOV <IMM>, <DST> | 0x*D*9 *IMM*        | D = `<DST>`, IMM = `<IMM>` | Yes     |*/
			case 0x9: {
				DEBUG("MOV %d %s\n", info2, registerName[info1]);
				write_reg(info1, info2);
				break;
			}
/*| ADD <IMM>        | 0x0A *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xA: {
				DEBUG("ADD %d\n\n", (int8_t)info2);
				ACC += (int8_t)info2;
				break;
			}
/*| SUB <IMM>        | 0x0B *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xB: {
				DEBUG("SUB %d\n", (int8_t)info2);
				ACC -= (int8_t)info2;
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
						DEBUG("JMP %d\n", info2);
						IP = info2;
						break;
					}
					case 0x1: {
						DEBUG("JEZ %d\n", info2);
						if(ACC == 0) IP = info2;
						break;
					}
					case 0x2: {
						DEBUG("JNZ %d\n", info2);
						if(ACC != 0) IP = info2;
						break;
					}
					case 0x3: {
						DEBUG("JGZ %d\n", info2);
						if(ACC > 0) IP = info2;
						break;
					}
					case 0x4: {
						DEBUG("JLZ %d\n", info2);
						if(ACC < 0) IP = info2;
						break;
					}
					default: exit(1);
				}
				break;
			}
/*| JRO <IMM>        | 0x0D *IMM*          | IMM = `<IMM>`              | Yes     |*/
			case 0xD: {
				DEBUG("JRO %d\n", (int8_t)info2);
				IP += read_reg(info2);
				break;
			}
			default: exit(1);
		}
		
		// fprintf(stderr, "%d (%d)\n", ACC, BAK);
	}

	return 0;
}