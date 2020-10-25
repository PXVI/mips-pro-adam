# mips-pro-adam
------------------------
### Single Cycle Design
------------------------
<br />
This is the MIPS32 single cycle hardware design. The objective of this design is to provide a base skeletal processor core model which implements the basic MIPS32 ISA. A lot of more advance features have not been covered/implemented in this version, bacause frankly the SV based testbench was getting more complex and spending more time fine tuning it seemed tedious. So, this verison will be completed will all the basic features intact. The design and testbench features have been listed below :

<br />
<br />

<b>Project Features :</b><br />

This is the IP checklist for the time being. Eventually, I will add a few more things as I figure out the proper design flow. As of now, my primary focus is implementing the mandatory instructions and provide proper debug access feature.<br />
<br />

- [X] Design
  - [X] Instruction Memory
  - [X] Data Memory
  - [X] MIPS Registers
  - [X] ALU
  - [X] ISA ( Instruction Sets )
    - [X] Register Type
      - [X] **ADDU** [ ArithExep Untested ]
      - [X] **ADD** [ ArithExep Untested ]
      - [X] **SUBU** [ ArithExep Untested ]
      - [X] **SUB** [ ArithExep Untested ]
      - [X] **XOR**
      - [X] **OR**
      - [X] **NOR**
      - [X] **SLL**
      - [X] **SRL**
      - [X] **SLT**
      - [X] **SLTU**
    - [X] Immideate Type
      - [X] **LW**
      - [X] **LH**
      - [X] **LHU**
      - [X] **LB**
      - [X] **LBU**
      - [X] **SB**
      - [X] **SH**
      - [X] **SW**
      - [X] **ADDI** [ ArithExep Untested ]
      - [X] **ADDIU** [ ArithExep Untested ]
      - [X] **ANDI** [ ArithExep Untested ]
      - [X] **ORI**
      - [X] **XORI**
      - [X] **SLTI**
      - [X] **SLTUI**
    - [X] Jump / Branch Type
      - [X] **BEQ** 
      - [X] **BNE**
      - [X] **JR** [ AddrErrorExep Untested ]
    - [ ] ~~Exceptions~~
      - [ ] ~~Arithematic Exception Flag~~
- [X] Testbench
  - [X] Systemverilog based functional model of MIPS32
  - [X] Debug tasks to write and read data into the IP
  - [X] Scoreboarding tasks
  - [X] Scoreboarding displays
  - [ ] ~~Stimulus Randomization~~
  - [X] Simulation run result displays / infos
- [X] Test Suite ( Custom )
  - [X] Basic Instructions Data Path Only Tests
    - [X] Load Instructions
    - [X] Store Instructions
    - [X] Register Arithematic Instructions
    - [X] Immideate Arithematic Instructions
    - [X] Branch Instructions
  - [ ] ~~Appication Based Tests~~
  - [ ] ~~Stress Testing Tests~~
- [X] Miscellaneous
  - [X] Makefile
  - [X] Makefile Documentation ( User Manual )
  - [X] Regression commands and regression lists
  - [X] Multi-Core Regression Scripts
  - [X] Debug Logs
  - [X] External Program File ( .bin )
  - [X] Test dump ( .vcd )
  - [X] Documentation / Readme
<br />
<br />

**Note :** The features which have been struck or have a strikethrough, means they have been pushed forward into the next verison, ie Multi Cycle/Pipelined. So, you will more or less find those features in the future versions. But make a nate that, they will not be implemented in this verison.

<br />
