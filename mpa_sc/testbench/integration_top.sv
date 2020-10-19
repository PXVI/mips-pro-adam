/* -----------------------------------------------------------------------------------
 * Module Name  : integration_top
 * Date Created : 20:35:18 IST, 06 October, 2020 [ Tuesday ]
 *
 * Author       : pxvi
 * Description  : Top level integration block for the IP and the Testbench
 * -----------------------------------------------------------------------------------

   MIT License

   Copyright (c) 2020 k-sva

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the Software), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

 * ----------------------------------------------------------------------------------- */

// --------------------------------------------
// Include the design files here.
// --------------------------------------------

`include "mpa_mips.v"

// --------------------------------------------
// Defines
// --------------------------------------------

`define tdebug( x ) \
    if( tdebug_en ) \
    begin \
        $display( " %8d ## [ TERML_DEBUG ] %s", $time, x ); \
    end

`define unimpl \
    impl_missing = 1;

// --------------------------------------------

module integration_top;

    // Parameters
    // ----------
    parameter   DATA_WIDTH = 32,
                ADDRESS_WIDTH = 32,
                IM_CAPACITY = 32, // Byte Addressable
                DM_CAPACITY = 32, // Byte Addressable
                MR_CAPACITY = 32; // Double Word Addressable
    
    // IP Regs and Wires
    // -----------------
    
    reg ip_CLK;
    reg ip_HW_RSTn;
    
    reg [DATA_WIDTH-1:0] ip_din;
    wire [DATA_WIDTH-1:0] ip_dout;
    reg [ADDRESS_WIDTH-1:0] ip_addr;
    reg [1:0] ip_debug_func;
    reg ip_debug_we;
    reg ip_debug_re;
    reg ip_mem_debug;
    
    // Testbench Variables / Registers
    // -------------------------------
    
    bit tdebug_en, sb_enable;
    bit error_rcvd, impl_missing;

    bit [DATA_WIDTH-1:0] tb_im_mem [IM_CAPACITY];
    bit [DATA_WIDTH-1:0] tb_dm_mem [DM_CAPACITY];
    bit [DATA_WIDTH-1:0] tb_mr_mem [MR_CAPACITY];
    string load_im_filename;
    string load_dm_filename;
    string load_mr_filename;

    bit [DATA_WIDTH-1:0] sb_im_mem [IM_CAPACITY]; // Will be used with the functional model of the MIPS core
    bit [DATA_WIDTH-1:0] sb_dm_mem [DM_CAPACITY]; // Will be used with the functional model of the MIPS core
    bit [DATA_WIDTH-1:0] sb_mr_mem [MR_CAPACITY]; // Will be used with the functional model of the MIPS core

    bit [31:0] mips_model_pc;
    
    // IP Instantiations
    // -----------------
    
    mpa_mips_32     #(
                        .DATA_WIDTH( DATA_WIDTH ),
                        .INSTR_WIDTH(),
                        .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .RESET_PC_ADDRESS(),
                        .IM_CAPACITY( IM_CAPACITY ),
                        .MR_CAPACITY( MR_CAPACITY ),
                        .DM_CAPACITY( DM_CAPACITY )
                    )
                    mips_mpa_dut_inst
                    (
                        .HW_RSTn( ip_HW_RSTn ),
                        .CLK( ip_CLK ),
    
                        .din( ip_din ),
                        .dout( ip_dout ),
                        .addr( ip_addr ),
                        .debug_func( ip_debug_func ),
                        .debug_we( ip_debug_we ),
                        .debug_re( ip_debug_re ),
                        .mem_debug( ip_mem_debug )
                    );
    
    initial
    begin
        $display( " %8d ## ------------------------------------------------------------------------- ", $time );
        $display( " %8d ## [ SETUP ] Pre Simulation Configuration ", $time );
        $display( " %8d ## ------------------------------------------------------------------------- ", $time );
        if( $value$plusargs( "IM_FILE=%s", load_im_filename ) )
        begin
            $display( " %8d ## [ SETUP ] %s ", $time, $sformatf( "IM File Loaded : %s", load_im_filename ) );
        end
        if( $value$plusargs( "DM_FILE=%s", load_dm_filename ) )
        begin
            $display( " %8d ## [ SETUP ] %s ", $time, $sformatf( "DM File Loaded : %s", load_dm_filename ) );
        end
        if( $value$plusargs( "MR_FILE=%s", load_mr_filename ) )
        begin
            $display( " %8d ## [ SETUP ] %s ", $time, $sformatf( "MR File Loaded : %s", load_mr_filename ) );
        end
        $display( " %8d ## ------------------------------------------------------------------------- ", $time );
        if( $test$plusargs( "SBENABLE" ) )
        begin
            sb_enable = 1;
            $display( " %8d ## [ SETUP ] %s ", $time, $sformatf( "BFM Scoreboarding Enabled" ) );
            $display( " %8d ## ------------------------------------------------------------------------- ", $time );
        end
        if( $test$plusargs( "TDEBUG" ) )
        begin
            tdebug_en = 1;
            $display( " %8d ## [ SETUP ] %s ", $time, $sformatf( "Terminal Debug Enabled" ) );
            $display( " %8d ## ------------------------------------------------------------------------- ", $time );
        end
    end
    
    initial
    begin
        fork
            begin // Clock
                start_clk();
            end
            begin // Stimulus
                hw_reset( 100 );
    
                load_mips_im_code_b( load_im_filename );
                write_mpa_im( 1 );
                rand_dm_reg_and_load(0,0,1);
                write_mpa_dm( 1 );

                read_mpa_im( , sb_enable);
                read_mpa_dm( , sb_enable);

                run_cpu_instr();

                read_mpa_im( 1, sb_enable);
                read_mpa_mr( 1, sb_enable);
                read_mpa_dm( 1, sb_enable);
                eval_sb_values();
                
                end_sim();
            end
        join
    end
    
    initial // End Simulation Condition
    begin
        #100000000;
        end_sim(1);
    end
    
    `ifdef GEN_DUMP
        initial
        begin
            $dumpfile( "mpa_mips_dump.vcd" );
            $dumpvars( 0, integration_top );
        end
    `endif
    
    // Test Subroutines
    // ----------------
    
    task reset_mips_model_pc();
        mips_model_pc = 1;
    endtask

    task run_mips_model( int num_instr = 0 );
        if( !num_instr )
        begin
            // Do Nothing
        end
        else
        begin
            for( int i = 0; i < num_instr; i++ )
            begin
                bit [31:0] temp_pc;
                bit [4:0] rs,rt,rd;
                bit [15:0] imm;
                bit [25:0] addr;
                bit [4:0] shamt;
                bit arith_ex;

                rs = sb_im_mem[mips_model_pc/4][25:21];
                rt = sb_im_mem[mips_model_pc/4][20:16];
                rd = sb_im_mem[mips_model_pc/4][15:11];
                imm = sb_im_mem[mips_model_pc/4][15:0];
                addr = sb_im_mem[mips_model_pc/4][25:0];
                shamt = sb_im_mem[mips_model_pc/4][10:6];

                temp_pc = mips_model_pc;

                // Execute the instruction based on the SB Memory registers
                // ( These are BFM Local Registers )
                // --------------------------------------------------------
                
                if( sb_im_mem[mips_model_pc/4][31:26] == 6'b00_0000 ) // Special
                begin
                    case( sb_im_mem[mips_model_pc/4][5:0] ) // Function
                        // ADD ( MIPS I ) // add 0 0 0 will be used as a NOP
                        // TODO : For now this will be implemented just like
                        // the ADDU. More work needs to be done in this
                        // section.
                        // ++++++++++++++
                        6'b10_0000  :   begin // Signed Addition : TODO There's a possibility of an overflow when the posivite sums cross the (2^31)-1 boundary. It'll be treated as an negative number.
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            { arith_ex, sb_mr_mem[rd] } = sb_mr_mem[rs] + sb_mr_mem[rt];
                                            if( arith_ex != sb_mr_mem[rd] ) // Will happen if carry is 1 but the MSB of sum is 0 ( This is becasue the carry and MSB must be the same to comply with the signed addition concept )
                                            begin
                                                `tdebug( $sformatf( "ADD Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b ) { Add Overflow Exception }", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                            end
                                            else
                                            begin
                                                `tdebug( $sformatf( "ADD Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                            end
                                        end
                        // ADDU ( MIPS I ) // addu 0 0 0 will be used as a UNOP ( same as NOP )
                        // +++++++++++++++
                        6'b10_0001  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rs] + sb_mr_mem[rt];
                                            `tdebug( $sformatf( "ADDU Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // SUB ( MIPS I )
                        // ++++++++++++++
                        6'b10_0010  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            { arith_ex, sb_mr_mem[rd] } = sb_mr_mem[rs] - sb_mr_mem[rt];
                                            if( arith_ex != sb_mr_mem[rd] ) // Will happen if carry is 1 but the MSB of sum is 0 ( This is becasue the carry and MSB must be the same to comply with the signed addition concept )
                                            begin
                                                `tdebug( $sformatf( "ADD Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b ) { Add Overflow Exception }", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                            end
                                            else
                                            begin
                                                `tdebug( $sformatf( "ADD Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                            end
                                        end
                        // SUBU ( MIPS I )
                        // +++++++++++++++
                        6'b10_0011  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rs] - sb_mr_mem[rt];
                                            `tdebug( $sformatf( "SUB Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // SLT ( MIPS I )
                        // ++++++++++++++
                        6'b10_1010  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = ( sb_mr_mem[rs] < sb_mr_mem[rt] ) ? 32'd1 : 32'd0;
                                            `tdebug( $sformatf( "SLT Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // SLTU ( MIPS I )
                        // +++++++++++++++
                        6'b10_1011  :   begin
                                        end
                        // AND ( MIPS I )
                        // ++++++++++++++
                        6'b10_0100  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rs] & sb_mr_mem[rt];
                                            `tdebug( $sformatf( "AND Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // OR ( MIPS I )
                        // +++++++++++++
                        6'b10_0101  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rs] | sb_mr_mem[rt];
                                            `tdebug( $sformatf( "OR Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // XOR ( MIPS I )
                        // ++++++++++++++
                        6'b10_0110  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rs] ^ sb_mr_mem[rt];
                                            `tdebug( $sformatf( "XOR Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // NOR ( MIPS I )
                        // ++++++++++++++
                        6'b10_0111  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = ~( sb_mr_mem[rs] | sb_mr_mem[rt] );
                                            `tdebug( $sformatf( "NOR Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // JR ( MIPS I ) [ Jump Register ]
                        // +++++++++++++++++++++++++++++++
                        6'b00_1000  :   begin
                                            `unimpl
                                        end
                        // SLL ( MIPS I ) [ Shift Left Logical ]
                        // +++++++++++++++++++++++++++++++++++++
                        6'b00_0000  :   begin
                                            //bit [31:0] temp_addr, temp_by4_addr;

                                            //sb_mr_mem[rd] = sb_mr_mem[rt] << shamt;
                                            //`tdebug( $sformatf( "SLL Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        // SRL ( MIPS I ) [ Shift Right Logical ]
                        // ++++++++++++++++++++++++++++++++++++++
                        6'b00_0010  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rd] = sb_mr_mem[rt] >> shamt;
                                            `tdebug( $sformatf( "SRL Instruction : RT ( %0d ), RS ( %0d ), RD ( %0d ), MR[rt] ( %0d ), MR[rs] ( %0d ), MR[rd] ( %0d ), Instr ( %6b_%5b_%5b_%5b_%5b_%6b )", rt, rs, rd, sb_mr_mem[rt], sb_mr_mem[rs], sb_mr_mem[rd], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:11], sb_im_mem[mips_model_pc/4][10:6], sb_im_mem[mips_model_pc/4][5:0] ) )
                                        end
                        default     :   begin
                                            // Do nothing
                                            `tdebug( $sformatf( "Special Default" ) )
                                        end
                    endcase
                end
                else // Others
                begin
                    case( sb_im_mem[mips_model_pc/4][31:26] )
                        // ADDI ( MIPS I )
                        // +++++++++++++++
                        6'b00_1000  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = sb_mr_mem[rs] + { {16{imm[15]}}, imm };
                                            `tdebug( $sformatf( "ADDI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // ADDIU ( MIPS I )
                        // ++++++++++++++++
                        6'b00_1001  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = sb_mr_mem[rs] + { {16{1'b0}}, imm };
                                            `tdebug( $sformatf( "ADDIU Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // ANDI ( MIPS I )
                        // +++++++++++++++
                        6'b00_1100  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = sb_mr_mem[rs] & { {16{imm[1'b0]}}, imm };
                                            `tdebug( $sformatf( "ANDI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // ORI ( MIPS I )
                        // ++++++++++++++
                        6'b00_1101  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = sb_mr_mem[rs] | { {16{imm[1'b0]}}, imm };
                                            `tdebug( $sformatf( "ORI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // XORI ( MIPS ? )
                        // +++++++++++++++
                        6'b00_1110  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = sb_mr_mem[rs] ^ { {16{imm[1'b0]}}, imm };
                                            `tdebug( $sformatf( "XORI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // SLTI ( MIPS I ) [ Set Less Than Immdediate ]
                        // ++++++++++++++++++++++++++++++++++++++++++++
                        6'b00_1010  :   begin // TODO Treat both the numbers as signed
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = ( sb_mr_mem[rs] < { {16{imm[15]}}, imm } ) ? 32'd1 : 32'd0;
                                            `tdebug( $sformatf( "SLTI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // SLTIU ( MIPS I ) [ Set Less Than Immediate Unsigned ]
                        // +++++++++++++++++++++++++++++++++++++++++++++++++++++
                        6'b00_1011  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = ( sb_mr_mem[rs] < { {16{imm[1'b0 /* This is a neccessary modification */]}}, imm } ) ? 32'd1 : 32'd0;
                                            `tdebug( $sformatf( "SLTI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem (  NA  ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // BEQ ( MIPS I ) [ Branch On Equal ]
                        // ++++++++++++++++++++++++++++++++++
                        6'b00_0100  :   begin
                                            `unimpl
                                        end
                        // BNE ( MIPS I ) [ Branch On Not Equal ]
                        // ++++++++++++++++++++++++++++++++++++++
                        6'b00_0101  :   begin
                                            `unimpl
                                        end
                        // LBU ( MIPS I ) [ Load Byte Unsigned ]
                        // +++++++++++++++++++++++++++++++++++++
                        6'b10_0100  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({imm+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_mr_mem[rt] = {{24{1'b0}},sb_dm_mem[temp_by4_addr][7:0]};
                                            `tdebug( $sformatf( "LBU Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // LB [ Load Byte Sign Ext ]
                        // +++++++++++++++++++++++++
                        6'b10_0000  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({imm+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_mr_mem[rt] = {{24{sb_dm_mem[temp_by4_addr][7]}},sb_dm_mem[temp_by4_addr][7:0]}; // Sign Extended
                                            `tdebug( $sformatf( "LB Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // LHU ( MIPS I ) [ Load Half Word Unsigned ]
                        // ++++++++++++++++++++++++++++++++++++++++++
                        6'b10_0101  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({imm+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_mr_mem[rt] = {{16{1'b0}},sb_dm_mem[temp_by4_addr][15:0]};
                                            `tdebug( $sformatf( "LHU Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // LH [ Load Half Word Sign Ext ]
                        // ++++++++++++++++++++++++++++++
                        6'b10_0001  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({imm+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_mr_mem[rt] = {{16{sb_dm_mem[temp_by4_addr][15]}},sb_dm_mem[temp_by4_addr][15:0]}; // Sign Extended
                                            `tdebug( $sformatf( "LH Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // LUI ( MIPS I ) [ Load Upper Immediate ]
                        // +++++++++++++++++++++++++++++++++++++++
                        6'b00_1111  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;

                                            sb_mr_mem[rt] = ({imm,{16{1'b0}}});
                                            `tdebug( $sformatf( "LUI Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr (  NA  ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // LW ( MIPS I ) [ Load Word ]
                        // +++++++++++++++++++++++++++
                        6'b10_0011  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({imm+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_mr_mem[rt] = sb_dm_mem[temp_by4_addr];
                                            `tdebug( $sformatf( "LW Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // SB ( MIPS I ) [ Store Byte ]
                        // ++++++++++++++++++++++++++++
                        6'b10_1000  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({{{16{imm[15]}},imm}+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_dm_mem[temp_by4_addr][7:0] = sb_mr_mem[rt][7:0];
                                            `tdebug( $sformatf( "SB Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // SH ( MIPS I ) [ Store Half Word ]
                        // +++++++++++++++++++++++++++++++++
                        6'b10_1001  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({{{16{imm[15]}},imm}+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_dm_mem[temp_by4_addr][15:0] = sb_mr_mem[rt][15:0];
                                            `tdebug( $sformatf( "SH Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        // SW ( MIPS I ) [ Store Word ]
                        // ++++++++++++++++++++++++++++
                        6'b10_1011  :   begin
                                            bit [31:0] temp_addr, temp_by4_addr;
                                            temp_addr = ({{{16{imm[15]}},imm}+sb_mr_mem[rs]});
                                            temp_by4_addr = temp_addr/4;

                                            sb_dm_mem[temp_by4_addr] = sb_mr_mem[rt];
                                            `tdebug( $sformatf( "SW Instruction : RT ( %0d ), RS ( %0d ), IMM = %0d, Addr ( %0d ), Mem ( %0d ), Instr ( %6b_%5b_%5b_%16b )", rt, rs, imm, temp_addr, sb_dm_mem[temp_addr], sb_im_mem[mips_model_pc/4][31:26], sb_im_mem[mips_model_pc/4][25:21], sb_im_mem[mips_model_pc/4][20:16], sb_im_mem[mips_model_pc/4][15:0] ) )
                                        end
                        default     :   begin
                                            // Do Nothing
                                            `tdebug( $sformatf( "Non Special Default" ) )
                                        end
                    endcase
                end

                // Fixed Register Values
                // ---------------------
                sb_mr_mem[0] = 32'd0;

                // PC Updation
                // -----------
                //`tdebug( $sformatf( "Old PC : %0d", temp_pc ) )
                if( mips_model_pc == temp_pc )
                begin
                    mips_model_pc = ( temp_pc + 4 );
                end
                else
                begin
                    mips_model_pc = ( mips_model_pc );
                end
                //`tdebug( $sformatf( "New PC : %0d", mips_model_pc ) )
            end
        end
    endtask

    task eval_sb_values( int mode = 0 );
        $display( " %8d ## [ DEBUG ][    ] ", $time ); 
        for( int i = 0; i < IM_CAPACITY*4; i = i + 4 )
        begin
            if( sb_enable )
            begin
                if( tb_im_mem[i/4] != sb_im_mem[i/4] )
                begin
                    $display( " %8d ## [ CHECK ][ IM ] Addr : %8d, IM_Data : %8b_%8b_%8b_%8b ( %10d ) [X] SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_im_mem[i/4][31:24], tb_im_mem[i/4][23:16], tb_im_mem[i/4][15:8], tb_im_mem[i/4][7:0], tb_im_mem[i/4], sb_im_mem[i/4][31:24], sb_im_mem[i/4][23:16], sb_im_mem[i/4][15:8], sb_im_mem[i/4][7:0], sb_im_mem[i/4] );
                    error_rcvd = 1;
                end
                else
                begin
                    $display( " %8d ## [ CHECK ][ IM ] Addr : %8d, IM_Data : %8b_%8b_%8b_%8b ( %10d )  -  SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_im_mem[i/4][31:24], tb_im_mem[i/4][23:16], tb_im_mem[i/4][15:8], tb_im_mem[i/4][7:0], tb_im_mem[i/4], sb_im_mem[i/4][31:24], sb_im_mem[i/4][23:16], sb_im_mem[i/4][15:8], sb_im_mem[i/4][7:0], sb_im_mem[i/4] );
                end
            end
            else
            begin
                $display( " %8d ## [ SB_DB ][ IM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, i, sb_im_mem[i/4][31:24], sb_im_mem[i/4][23:16], sb_im_mem[i/4][15:8], sb_im_mem[i/4][7:0], sb_im_mem[i/4] );
            end
        end
        $display( " %8d ## [ DEBUG ][    ] ", $time ); 
        for( int i = 0; i < MR_CAPACITY; i = i + 1 )
        begin
            if( sb_enable )
            begin
                if( tb_mr_mem[i] != sb_mr_mem[i] )
                begin
                    $display( " %8d ## [ CHECK ][ MR ] Addr : %8d, MR_Data : %8b_%8b_%8b_%8b ( %10d ) [X] SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_mr_mem[i][31:24], tb_mr_mem[i][23:16], tb_mr_mem[i][15:8], tb_mr_mem[i][7:0], tb_mr_mem[i], sb_mr_mem[i][31:24], sb_mr_mem[i][23:16], sb_mr_mem[i][15:8], sb_mr_mem[i][7:0], sb_mr_mem[i] );
                    error_rcvd = 1;
                end
                else
                begin
                    $display( " %8d ## [ CHECK ][ MR ] Addr : %8d, MR_Data : %8b_%8b_%8b_%8b ( %10d )  -  SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_mr_mem[i][31:24], tb_mr_mem[i][23:16], tb_mr_mem[i][15:8], tb_mr_mem[i][7:0], tb_mr_mem[i], sb_mr_mem[i][31:24], sb_mr_mem[i][23:16], sb_mr_mem[i][15:8], sb_mr_mem[i][7:0], sb_mr_mem[i] );
                end
            end
            else
            begin
                $display( " %8d ## [ SB_DB ][ MR ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, i, sb_mr_mem[i][31:24], sb_mr_mem[i][23:16], sb_mr_mem[i][15:8], sb_mr_mem[i][7:0], sb_mr_mem[i] );
            end
        end
        $display( " %8d ## [ DEBUG ][    ] ", $time ); 
        for( int i = 0; i < DM_CAPACITY*4; i = i + 4 )
        begin
            if( sb_enable )
            begin
                if( tb_dm_mem[i/4] != sb_dm_mem[i/4] )
                begin
                    $display( " %8d ## [ CHECK ][ DM ] Addr : %8d, DM_Data : %8b_%8b_%8b_%8b ( %10d ) [X] SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_dm_mem[i/4][31:24], tb_dm_mem[i/4][23:16], tb_dm_mem[i/4][15:8], tb_dm_mem[i/4][7:0], tb_dm_mem[i/4], sb_dm_mem[i/4][31:24], sb_dm_mem[i/4][23:16], sb_dm_mem[i/4][15:8], sb_dm_mem[i/4][7:0], sb_dm_mem[i/4] );
                    error_rcvd = 1;
                end
                else
                begin
                    $display( " %8d ## [ CHECK ][ DM ] Addr : %8d, DM_Data : %8b_%8b_%8b_%8b ( %10d )  -  SB_Data : %8b_%8b_%8b_%8b ( %10d )", $time, i, tb_dm_mem[i/4][31:24], tb_dm_mem[i/4][23:16], tb_dm_mem[i/4][15:8], tb_dm_mem[i/4][7:0], tb_dm_mem[i/4], sb_dm_mem[i/4][31:24], sb_dm_mem[i/4][23:16], sb_dm_mem[i/4][15:8], sb_dm_mem[i/4][7:0], sb_dm_mem[i/4] );
                end
            end
            else
            begin
                $display( " %8d ## [ SB_DB ][ DM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, i, sb_dm_mem[i/4][31:24], sb_dm_mem[i/4][23:16], sb_dm_mem[i/4][15:8], sb_dm_mem[i/4][7:0], sb_dm_mem[i/4] );
            end
        end
        $display( " %8d ## [ DEBUG ][    ] ", $time ); 
    endtask

    task start_clk( integer time_period = 5 );
        integer tp;
        tp = time_period;
        ip_CLK <= 1;
        fork
            forever
            begin
                #(tp) ip_CLK <= ~ip_CLK;
            end
        join
    endtask

    task hw_reset( integer duration = 0 );
        if( duration == 0 )
        begin
            ip_HW_RSTn <= 0;
        end
        else
        begin
            ip_HW_RSTn <= 0;
            fork
                #(duration) ip_HW_RSTn <= 1;
            join
        end
    endtask
    
    task rm_reset();
        ip_HW_RSTn <= 1;
    endtask
    
    task run_cpu_instr( integer instr_count = IM_CAPACITY );
        disable_debug_mode();

        $display( " %8d ## [ SIM_X ][    ] ", $time ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] Simulation : The core will run for a total of %0d cycles", $time, instr_count ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] ", $time ); 
        @( negedge ip_CLK );
        repeat( instr_count )
        begin
            @( posedge ip_CLK );
            run_mips_model( 1 );
        end
        @( negedge ip_CLK );
        $display( " %8d ## [ SIM_X ][    ] ", $time ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] Simulation : Core Simulation Complete", $time ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] ", $time ); 

        enable_debug_mode();
    endtask
    
    task enable_debug_mode( integer func = 0 );
        ip_mem_debug <= 1;
        ip_debug_we <= 0;
        ip_debug_re <= 0;
        ip_debug_func <= func;
        ip_addr <= 'd0;
        ip_din <= 'd0;
        $display( " %8d ## [ DEBUG ] Debug Mode is enabled", $time );
    endtask
    
    task disable_debug_mode();
        ip_mem_debug <= 0;
        ip_debug_we <= 0;
        ip_debug_re <= 0;
        ip_debug_func <= 2'd0;
        ip_addr <= 'd0;
        ip_din <= 'd0;
        $display( " %8d ## [ DEBUG ] Debug Mode is disabled", $time );
    endtask
    
    task read_mpa_im( bit load_tb_mem = 0, bit dis_disp = 1 );
        integer i;
    
        enable_debug_mode( 1 );
    
        // Read the Instruction Memory
        // +++++++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            if( !dis_disp )
            begin
                $display( " %8d ## [ DEBUG ][ IM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
            end
            if( load_tb_mem )
            begin
                tb_im_mem[i/4] = ip_dout;
            end
        end
    
        disable_debug_mode();
    endtask
    
    task read_mpa_dm( bit load_tb_mem = 0, bit dis_disp = 1 );
        integer i;
    
        enable_debug_mode( 2 );
    
        // Read the Data Register
        // ++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            if( !dis_disp )
            begin
                $display( " %8d ## [ DEBUG ][ DM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
            end
            if( load_tb_mem )
            begin
                tb_dm_mem[i/4] = ip_dout;
            end
        end
    
        disable_debug_mode();
    endtask
    
    task read_mpa_mr( bit load_tb_mem = 0, bit dis_disp = 1 );
        integer i;
    
        enable_debug_mode( 3 );
    
        // Read the MIPS Registers
        // +++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < MR_CAPACITY; i = i + 1 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            if( !dis_disp )
            begin
                $display( " %8d ## [ DEBUG ][ MR ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
            end
            if( load_tb_mem )
            begin
                tb_mr_mem[i] = ip_dout;
            end
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_im( int file = 0 );
        integer i;
    
        enable_debug_mode( 1 );
    
        // Write the Instruction Memory
        // ++++++++++++++++++++++++++++

        if( file == 1 )
        begin
            @( posedge ip_CLK );
            for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= tb_im_mem[i/4];
                @( posedge ip_CLK );
                //$display( " %8d ## [ DEBUG ][ IM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
                sb_im_mem[i/4] = ip_din;
            end
        end
        else
        begin
            @( posedge ip_CLK );
            for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= $urandom;
                @( posedge ip_CLK );
                $display( " %8d ## [ DEBUG ][ IM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
                sb_im_mem[i/4] = ip_din;
            end
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_dm( int file = 0 );
        integer i;
    
        enable_debug_mode( 2 );
    
        // Write the Data Memory
        // +++++++++++++++++++++
        if( file == 1 )
        begin
            @( posedge ip_CLK );
            for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= tb_dm_mem[i/4];
                @( posedge ip_CLK );
                //$display( " %8d ## [ DEBUG ][ DM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
                sb_dm_mem[i/4] = ip_din;
            end
        end
        else
        begin
            @( posedge ip_CLK );
            for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= $urandom;
                @( posedge ip_CLK );
                $display( " %8d ## [ DEBUG ][ DM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
                sb_dm_mem[i/4] = ip_din;
            end
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_mr();
        integer i;
    
        enable_debug_mode( 3 );
    
        // Write the MIPS Registers
        // ++++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < MR_CAPACITY; i = i + 1 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_we <= 1;
            ip_din <= $urandom;
            @( posedge ip_CLK );
            $display( " %8d ## [ DEBUG ][ MR ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
            sb_dm_mem[i/4] = ip_din;
        end
    
        disable_debug_mode();
    endtask
    
    task load_mips_im_code_b( string filename = "mpa_mips_load_im_program.bin" );
        if( filename != "" )
        begin
            $readmemb( filename, tb_im_mem );
        end
        else
        begin
            //$readmemb( filename, tb_im_mem );
            //for( int i = 0; i < IM_CAPACITY; i++ )
            //begin
            //    tb_im_mem[i]
            //    $display( "%32b ( %0d )", tb_im_mem[i], tb_im_mem[i] );
            //end
        end
    endtask
    
    task load_mips_im_code_h( string filename = "" );
    endtask
    
    task load_mips_dm_code_b( string filename = "mpa_mips_load_dm_data.bin" );
        if( filename == "mpa_mips_load_dm_data.bin" )
        begin
            $readmemb( filename, tb_dm_mem );
        end
        else
        begin
            $readmemb( filename, tb_dm_mem );
            for( int i = 0; i < DM_CAPACITY; i++ )
            begin
                $display( "%32b ( %0d )", tb_dm_mem[i], tb_dm_mem[i] );
            end
        end
    endtask
    
    task load_mips_dm_code_h( string filename = "" );
    endtask
    
    task load_mips_mr_code_b( string filename = "mpa_mips_load_mr.bin" );
        if( filename == "mpa_mips_load_mr.bin" )
        begin
            $readmemb( filename, tb_mr_mem );
        end
        else
        begin
            $readmemb( filename, tb_mr_mem );
            for( int i = 0; i < MR_CAPACITY; i++ )
            begin
                $display( "%32b ( %0d )", tb_mr_mem[i], tb_mr_mem[i] );
            end
        end
    endtask
    
    task load_mips_mr_code_h( string filename = "" );
    endtask

    task rand_dm_reg_and_load( int min = 0, int max = 512, bit show_data = 0 );
        for( int i = 0; i < DM_CAPACITY; i++ )
        begin
            tb_dm_mem[i] = $urandom_range( min, max );
        end

        if( !min && !max )
        begin
            for( int i = 0; i < DM_CAPACITY; i++ )
            begin
                tb_dm_mem[i] = $urandom;
            end
        end

        if( show_data )
        begin
            for( int i = 0; i < DM_CAPACITY; i++ )
            begin
                $display( " %8d ## [ SIMDE ][ DM ] Addr : %8d, Data : %8b_%8b_%8b_%8b ( %10d ) : { Testbench Local Debug }", $time, i*4, tb_dm_mem[i][31:24], tb_dm_mem[i][23:16], tb_dm_mem[i][15:8], tb_dm_mem[i][7:0], tb_dm_mem[i] );
            end
        end
    endtask
    
    task delay( integer dl = 0 );
        if( dl == 0 )
        begin
            #1;
        end
        else
        begin
            #(dl);
        end
    endtask
    
    task end_sim( bit forced_kill = 0 );
        $display( " %8d ## [       ][    ] %s", 0, $sformatf( "Simulation has been terminated..." ) );
        if( forced_kill )
        begin
            $display( " %8d ## [       ][    ]", 0 );
            $display( " %8d ## [       ][    ]", 0 );
            $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777  77777777777777777777777777777777777777777777 7777", 0 );
            $display( " %8d ## [       ][    ] 7777777777    7777777777777777777777777777777777777    77777", 0 );
            $display( " %8d ## [       ][    ] 77777777777     7777777777777777777777777777777      7777777", 0 );
            $display( " %8d ## [       ][    ] 77777777 777                  777777777            777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777  77777           7777777777777       7777777777777", 0 );
            $display( " %8d ## [       ][    ] 7777777777   77777777777777777777777777777777777777777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777777                                   7777777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777777777777777777777777777777  777  777  777777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777777777777777777777777777777  777  777  777777777777", 0 );
            $display( " %8d ## [       ][    ] 77    7      7      77    77      77  777  777  777777777777", 0 );
            $display( " %8d ## [       ][    ] 77  777  77  7  77  7  77  7  77  77  7777 777  777777777777", 0 );
            $display( " %8d ## [       ][    ] 77    7    777    777  77  7    77777    7777  7777777777777", 0 );
            $display( " %8d ## [       ][    ] 77  777  77  7  77  7  77  7  77  77777    7  77777777777777", 0 );
            $display( " %8d ## [       ][    ] 77    7  77  7  77  77    77  77  7777777    777777777777777", 0 );
            $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
            $display( " %8d ## [       ][    ]", 0 );
            $display( " %8d ## [       ][    ][ RESULT ] Error_Run : Simulation Timeout Has Occured! FATAL", 0 );
            $display( " %8d ## [       ][    ]", 0 );

            $finish;
        end
        if( sb_enable )
        begin
            if( error_rcvd )
            begin
                $display( " %8d ## [       ][    ]", 0 );
                $display( " %8d ## [       ][    ]", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777  77777777777777777777777777777777777777777777 7777", 0 );
                $display( " %8d ## [       ][    ] 7777777777    7777777777777777777777777777777777777    77777", 0 );
                $display( " %8d ## [       ][    ] 77777777777     7777777777777777777777777777777      7777777", 0 );
                $display( " %8d ## [       ][    ] 77777777 777                  777777777            777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777  77777           7777777777777       7777777777777", 0 );
                $display( " %8d ## [       ][    ] 7777777777   77777777777777777777777777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777                                   7777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777  777  777  777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777  777  777  777777777777", 0 );
                $display( " %8d ## [       ][    ] 77    7      7      77    77      77  777  777  777777777777", 0 );
                $display( " %8d ## [       ][    ] 77  777  77  7  77  7  77  7  77  77  7777 777  777777777777", 0 );
                $display( " %8d ## [       ][    ] 77    7    777    777  77  7    77777    7777  7777777777777", 0 );
                $display( " %8d ## [       ][    ] 77  777  77  7  77  7  77  7  77  77777    7  77777777777777", 0 );
                $display( " %8d ## [       ][    ] 77    7  77  7  77  77    77  77  7777777    777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ]", 0 );
                $display( " %8d ## [       ][    ][ RESULT ] Error_Run : The loaded program does not match the expected behaviour of the SV functional model", 0 );
                $display( " %8d ## [       ][    ]", 0 );
            end
            else
            begin
                $display( " %8d ## [       ][    ]", 0 );
                $display( " %8d ## [       ][    ]", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 7777777777777777777777777777777777        777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777        7777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 77777777777777777777777777777777        77777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 7777777777777777777777777777777        777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777        7        7777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 7777777777777777777777      7        77777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 77777777777777777777777    7        777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777  7        7777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 7777777777777777777777777         77777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777    77     7     7     7777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777 777 7 777 7  7777  7777777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777    77     777  7777  77777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777 77777 777 7     7     7777777777777777777", 0 );
                $display( " %8d ## [       ][    ] 777777777777777777777777777777777777777777777777777777777777", 0 );
            $display( " %8d ## [       ][    ]", 0 );
            $display( " %8d ## [       ][    ][ RESULT ] Clean_Run : The loaded program has executed and does match the expected behaviour of the SV functional model", 0 );
            $display( " %8d ## [       ][    ]", 0 );
            end
        end
        if( impl_missing )
        begin
            $display( " %8d ## [       ][    ][ RESULT ] Warning   : An unimplemented instruction was run during the testing", 0 );
        end
        $display( " %8d ## [       ][    ]", 0 );
        $finish;
    endtask

endmodule
