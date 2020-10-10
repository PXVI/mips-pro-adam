# mips-pro-adam
------------------------
<br />
This is a MIPS microprocessor hardware design. The design is in no way meant to be a full fledged RTL with some extreme application. This is rather to build my understanding of the processor design and eventually the verification. <br />
I will be using the MIPS ISA, to which extent, I do not know. Primary goal is to actually build a microarchitecture which will serve as a learning reference for myself or anyone who is intereted. The microarchitectures ( one after the other ) which I will be implementing are :<br />
<br />
<b>1. Single Cycle Processor Design</b><br />
<b>2. Multi Cycle Processor Design</b><br />
<b>3. Pipelined Processor Design</b><br />
<br />
<br />
<b>Single Cycle Design :</b><br />
<br />
This is the IP checklist for the time being. Eventually, I will add a few more things as I figure out the proper design flow. As of now, my primary focus is implementing the mandatory instructions and provide proper debug access feature.<br />
<br />

- [ ] Design
  - [X] Instruction Memory
  - [X] Data Memory
  - [ ] MIPS Registers
  - [X] ALU
  - [ ] ISA ( Instruction Sets )
    - [ ] Register Type
      - [ ] ADD
      - [ ] SUB
      - [ ] XOR
      - [ ] OR
      - [ ] NOR
    - [ ] Immideate Type
      - [X] LW
      - [X] LH
      - [X] LHU
      - [X] LB
      - [X] LBU
      - [ ] SB
      - [ ] SH
      - [ ] SW
    - [ ] Jump Type
- [ ] Testbench
  - [ ] Systemverilog based functional model of MIPS32
  - [X] Debug tasks to write and read data into the IP
  - [X] Scoreboarding tasks
  - [X] Scoreboarding displays
  - [ ] Stimulus Randomization
  - [X] Simulation run result displays / infos
- [ ] Test Suite ( Custom )
  - [ ] Basic Instructions Data Path Only Tests
    - [X] Load Instructions
    - [ ] Store Instructions
    - [ ] Register Arithematic Instructions
    - [ ] Immideate Arithematic Instructions
  - [ ] Appication Based Tests
  - [ ] Stress Testing Tests
- [ ] Miscellaneous
  - [X] Makefile
  - [X] Debug Logs
  - [X] External Program File ( .bin )
  - [X] Test dump ( .vcd )
  - [ ] Documentation / Readme
<br />
<br />
<br />

------------------------
<b>Update</b><br /><br />
Upon proper research, I realised that MIPS ISA is not exactly open source. So, spending too much time on this might in the end become unproductive. Which is why, I will just be building a simple verison of the base ISA and re-use it to further implement the multi-cycle and the pipelined versions. Testing will be very simple and will not involve a full fledge UVM testbench as I originally intended. Rather, we will be going with a basic verilog based test bench.<br /><br />
In this light, I plan to start with a RISC-V processor implementation, once my MIPS processor is complete.<br />
<b>Lastly, this code is in no way proprietary, nor does it have any restrictions. Feel free to use this anywhere or however you want :)</b>
