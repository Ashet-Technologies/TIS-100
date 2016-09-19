# Test Comments and all mnemonics:
NOP
SWP
SAV
ADD NIL
ADD -1
SUB NIL
SUB -1
NEG
JRO NIL
JRO -1
HLT
MOV NIL NIL
MOV -1  NIL
JMP TARGET
JEZ TARGET
JNZ TARGET
JGZ TARGET
JLZ TARGET

# Test Label Name Ambiguity
JMP LEFT
JMP RIGHT
JMP 100 # <- Should invoke an error

# Test Register Names
ADD ACC
ADD NIL
ADD PORT0
ADD PORT1
ADD PORT2
ADD PORT3
ADD PORT4
ADD PORT5
ADD PORT6
ADD PORT7
ADD LEFT
ADD UP
ADD RIGHT
ADD DOWN
ADD INVLD # <- Should invoke an error

MOV NIL NIL # <- Should invoke an error
MOV NIL INVLD # <- Should invoke an error
MOV INVLD NIL # <- Should invoke an error
MOV INVLD INVLD # <- Should invoke an error

# Test optional comma between <SRC> and <DST>
MOV NIL NIL
MOV NIL,NIL
MOV NIL, NIL
MOV NIL ,NIL
MOV NIL , NIL

# Test labels and label referencing
LBL1:
LBL2: NOP
JMP LBL1
LBL3: JMP LBL2