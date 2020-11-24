# mips-pro-adam
------------------------
<br />
This is a MIPS microprocessor hardware design reposiroty. The design is in no way meant to be a full fledged RTL with some extreme application. This is rather to build my understanding of the processor design and eventually the verification. <br />
I will be using the MIPS ISA, to which extent, I do not know. Primary goal is to actually build a microarchitecture which will serve as a learning reference for myself or anyone who is intereted. The microarchitectures ( one after the other ) which I will be implementing are :<br />
<br />
<b>1. Single Cycle Processor Design
</b><br />
<b>2. Multi Cycle Processor Design [ SCRATCHED ]
</b><br />
<b>3. Pipelined Processor Design [ SCRATCHED ]
</b><br />
<br />

------------------------
<br />
<b>Single Cycle Design Features :</b><br />
<br />
This is the IP checklist for the time being. Eventually, I will add a few more things as I figure out the proper design flow. As of now, my primary focus is implementing the mandatory instructions and provide proper debug access feature.<br />
<br />

- Design Features
  - Supports Configurable Debug Access ( this is used to load and read the core's registers )
  - Supports Configurable Instruction Memory
  - Supports Configurable Data Memory
  - Supports Basic MIPS Registers Set
  - Supports Independent ALU ( supports interchangablility with a different variant if needed )
  - Supports Base ISA ( Instruction Sets )
    - **Supported Register Type Instructions : 11**
    - **Supported Immideate Type Instructions : 15**
    - **Supported Branch Instruction : 3**
    - **Supported ALU Operations : 13**
- Supports an custom SystemVerilog Testbench
  - Supports all MIP32 instructions & registers mentioned above, in it's own SystemSerilog based functional model
  - Supports pre defined debug tasks to load and read the core's registers
  - Supports scoreboarding
  - Supports descriptive error and infos
  - Supports simulation summary prints
- **Supports ISA specific test suite : ~30 directed programs/tests**
  - Basic Load Programs Provided
  - Basic Store Programs Provided
  - Basic Register Arithematic Programs Provided
  - Basic Immideate Instruction Programs Provided
  - Basic Branch Instruction Programs Provided
- Additonal Miscellaneous Testbench & Reposiroty Feaures
  - Custom Makefile provided
  - Makefile User Guide Is Provided
  - Supports Basic Regression Commands & Regression Lists
  - Supports Multi Core Simulations/Regressions
  - Supports Test Specific Debug Log
  - External Program, Data, Register File Loading is supported
  - DUMP generation is supported
  - Basic Core Documenation is provided ( it's the README.md file indside the  core's directory )
<br />
<br />
<br />

------------------------
<b>Update</b><br /><br />
Upon proper research, I realised that MIPS ISA is not exactly open source. So, spending too much time on this might in the end become unproductive. Which is why, I will just be building a simple verison of the base ISA and re-use it to further implement the multi-cycle and the pipelined versions. Testing will be very simple and will not involve a full fledge UVM testbench as I originally intended. Rather, we will be going with a basic verilog based test bench.<br /><br />
In this light, I plan to start with a RISC-V processor implementation, once my MIPS processor is complete.<br />
<b>Lastly, this code is in no way proprietary, nor does it have any restrictions. Feel free to use this anywhere or however you want :)</b>

