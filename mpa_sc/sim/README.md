# mips-pro-adam
------------------------

<b>Makefile User Guide :</b><br />
------------------------
<br />

### Primary Steps

1. Source the .install file with "<b>source .install</b>"<br />
2. Use the Makefile commands. For starters, you can try the "<b>make all</b>" command
<br />

### Basic Make Commands

| Intention | Example |
| --------- | ------- |
| Running simple .bin program | ``` make all SB=1 IMFILE=<.bin path> ``` |
| Running a simple regression with multiple .bin programs | ``` make regress REGRESS_LIST=<.bin programs file list path> ``` |
| Running a multi core regression | ``` make regress MC=1 REGRESS_LIST=<.bin programs file list path> ``` |
| Clean/Remove the simulation files from the current directory | ``` make clean ``` |
| Link the RTL design | ``` make lint ``` |

<br />

**Note :** By default all the make switches have a default value set in case they are not provided explicitly <br />

<br />

### Make Switches Guide

| Switch Name | Default Value | Descritption |
| ----------- | ------------- | ------------ |
| TB_FILENAME | ``` ./../testbench/integration_top.sv ``` | ``` Path to the testbench's top file ``` |
| IP_FILENAME | ``` ./../design/res/mpa_mips.v ``` | ``` Path to the top design file ``` |
| COMPILE_FILELIST | ``` ./compile_filelist/compile_filelist.list ``` | ``` Pathe to the file which lists all the incdirs, defines and other included files ``` |
| REGRESS_LIST | ``` ./mpa_mips_programs.rlist ``` | ``` Path to the default regress list if one is not provided ``` |
| TOP_NAME | ``` integration_top ``` | ``` Pass the top name of the integration top where the IP and Testbench have been connected``` |
| DUMP | ``` 0 ``` | ``` Creates a .vcd dump file ``` |
| LINT | ``` 0 ``` | ``` Lints the RTL top and it's submodules``` |
| TDEBUG | ``` 0 ``` | ``` Provides terminal debug prints based on the MIPS SV functional model``` |
| SEED | ``` NA ``` | ``` Provide a custom seed value for the simulation ``` |
| RANDOM_REGRESS_SEED | ``` 0 ``` | ``` If enabled, ie 1, then the regression generates a new seed for itself in ever run ``` |
| MC | ``` 0 ``` | ``` If enabled, ie 1, the regression is run on mluti cores ( provided that you support multiple node liscenses for your simulator ) ``` |
| CORES | ``` 1 ``` | ``` Provide the regression script with the number of core you parallely want to fire the regression test on ``` |
| IMFILE | ``` NA ``` | ``` The Instructions File : You can upload a custom program file using this switch. You must pass the path to the .bin file ``` |
| MRFILE | ``` NA ``` | ``` The MIPS Register File : You can upload custom pre configured MR register values before the actual program is run for a more directed testing scenario ``` |
| DMFILE | ``` NA ``` | ``` The Data Memory File : You can upload a custom file to pre configure the Data Memory of the core before the simulation ``` |

<br />
There are more switches if you go thorugh the Makefile. For the sake of simplicity, the above mentiond ones are all that are needed to run a simulation/regression.
