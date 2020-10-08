/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_mips_x32
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : The top module of the MPA single cycle 32 bit processor
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

`include "mpa_alu.v"
`include "mpa_data_mem.v"
`include "mpa_instr_mem.v"
`include "mpa_mips_reg.v"

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Defines
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`define alu_add 3'd5
`define alu_sub 3'd6
`define alu_and 3'd3
`define alu_xor 3'd1
`define alu_or  3'd2
`define alu_not 3'd4

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module mpa_mips_32  #(  parameter   DATA_WIDTH = 32,
                                    INSTR_WIDTH = 32,
                                    ADDRESS_WIDTH = 32,
                                    RESET_PC_ADDRESS = 32'd0
                )
                (
                                    input HW_RSTn,
                                    input CLK,

                                    // Debug/Back-Door Pins
                                    // ++++++++++++++++++++
                                    input [DATA_WIDTH-1:0] din,
                                    output [DATA_WIDTH-1:0] dout,
                                    input [ADDRESS_WIDTH-1:0] addr,
                                    input [1:0] debug_func, // ( 1, 2, 3 ) : IM, DM, MR
                                    input debug_we,
                                    input debug_re,
                                    input mem_debug
                );

    wire mem_debug_clk_gate;
    wire instr_mem_we_gate;
    wire data_mem_we_gate, data_mem_re_gate;
    wire mips_reg_we_gate;

    wire [4:0] instr2mr_a0_addr_gate, instr2mr_a1_addr_gate;
    wire [DATA_WIDTH-1:0] instr_imm2mr_gate;
    wire [3-1:0] mpa_alu_func_sel_gate;
    wire [DATA_WIDTH-1:0] mr_a0_out;
    wire [DATA_WIDTH-1:0] mr_a1_out_gate;
    wire [DATA_WIDTH-1:0] alu_a1_in_gate;

    reg mips_reg_we_local;
    reg [2:0] instr_imm_value_en_local;
    reg [3-1:0] mpa_alu_func_sel_reg;
    reg [DATA_WIDTH-1:0] alu_a1_in_reg;
    reg [1:0] mr_a1_out_instr_imm_en_local;
    reg load_from_data_addr_local;
    reg data_mem_we_local;
    reg data_mem_re_local;
    reg [DATA_WIDTH-1:0] instr_imm2mr_reg;
    wire [DATA_WIDTH-1:0] alu_data_out;
    wire [DATA_WIDTH-1:0] data_mem_dout;

    reg [ADDRESS_WIDTH-1:0] pc_p; // Special Purpose Register #1
    reg [ADDRESS_WIDTH-1:0] pc_n;

    reg [DATA_WIDTH-1:0] reg_HI_p, reg_HI_n; // Special Purpose Register #2
    reg [DATA_WIDTH-1:0] reg_LO_p, reg_LO_n; // Special Purpose Register #3

    // Control Logic Signals
    // +++++++++++++++++++++
    wire [ADDRESS_WIDTH-1:0] pc2instr_mem_addr;

    assign instr_mem_we_gate = ( ( debug_func == 2'd1 ) && mem_debug ) ? debug_we : 0;
    assign data_mem_we_gate = ( ( debug_func == 2'd2 ) && mem_debug ) ? debug_we : 0 /* TODO Connect this to the mpa's data mem WE */;
    assign data_mem_re_gate = ( ( debug_func == 2'd2 ) && mem_debug ) ? debug_re : 0 /* TODO Connect this to the mpa's data mem RE */;
    assign mips_reg_we_gate = ( ( debug_func == 2'd3 ) && mem_debug ) ? debug_we : mips_reg_we_local;
    assign mem_debug_clk_gate = ( mem_debug ) ? 1'b0 /* Optimize */ : CLK;

    assign instr2mr_a0_addr_gate = pc2instr_mem_addr[25:21]; // A0
    assign instr2mr_a0_addr_gate = pc2instr_mem_addr[20:16]; // A1

    always@( * ) // MIPS Register DIN Multiplexer
    begin
        instr_imm2mr_reg = { 32'b0 };

        case( instr_imm_value_en_local )
            1       :   begin
                            instr_imm2mr_reg = { 16'b0, pc2instr_mem_addr[15:0] };
                        end
            2       :   begin // Load byte
                            instr_imm2mr_reg = { 24'b0, data_mem_dout[7:0] };
                        end
            3       :   begin // Load halfword
                            instr_imm2mr_reg = { 16'b0, data_mem_dout[15:0] };
                        end
            4       :   begin // Load word
                            instr_imm2mr_reg = { data_mem_dout };
                        end
            default :   begin
                        end
        endcase       
    end
    assign instr_imm2mr_gate = instr_imm2mr_reg;

    always@( * ) // MIPS ALU Second Input Multiplexer
    begin
        alu_a1_in_reg = mr_a1_out_gate;

        case( mr_a1_out_instr_imm_en_local )
            1           :   begin
                                alu_a1_in_reg[15:0] = { pc2instr_mem_addr[15:0] }; // Sign Extended
                                alu_a1_in_reg[31:16] = {16{ pc2instr_mem_addr[15] }};
                            end
            default     :   begin
                                alu_a1_in_reg = pc2instr_mem_addr; // Default
                            end
        endcase
    end
    assign alu_a1_in_gate = alu_a1_in_reg;

    assign mpa_alu_func_sel_gate = mpa_alu_func_sel_reg;
    assign pc2instr_mem_addr = pc_p;

    /* Instructions
     * ------------
     *    31       25   20   15   10      5
     *    ------------------------------------------------
     * R  | opcode | rs | rt | rd | shamt | funct        |
     *    ------------------------------------------------
     *    ------------------------------------------------
     * I  | opcode | rs | rt | immediate                 |
     *    ------------------------------------------------
     *    ------------------------------------------------
     * J  | opcode | address                             |
     *    ------------------------------------------------
     */

    // Intstruction Categories
    // +++++++++++++++++++++++
    //
    // Loads :
    // 1. [X] LBU
    // 2. [X] LHU
    // 3. [X] LUI 
    // 4. [X] LW
    //
    // Stores :
    // 1. [ ] SB
    // 2. [ ] SH
    // 3. [ ] SW
    // 4. [ ] SC
    // 

    // Control Logic Decoder
    // +++++++++++++++++++++
    always@( * )
    begin
        // Defaults
        // ++++++++
        mips_reg_we_local = 0;
        instr_imm_value_en_local = 0;
        mr_a1_out_instr_imm_en_local = 0;
        data_mem_we_local = 0;
        data_mem_re_local = 0;

        case( pc2instr_mem_addr[31:26] )
            // Generic Register Instruction ( Special Opcode )
            // +++++++++++++++++++++++++++++++++++++++++++++++
            6'b00_0000  :   begin
                                case( pc2instr_mem_addr[5:0] )
                                    // ADD ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0000  :   begin
                                                    end
                                    // ADDU ( MIPS I )
                                    // +++++++++++++++
                                    6'b10_0001  :   begin
                                                    end
                                    // SUB ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0010  :   begin
                                                    end
                                    // SUBU ( MIPS I )
                                    // +++++++++++++++
                                    6'b10_0011  :   begin
                                                    end
                                    // SLT ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_1010  :   begin
                                                    end
                                    // SLTU ( MIPS I )
                                    // +++++++++++++++
                                    6'b10_1011  :   begin
                                                    end
                                    // AND ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0100  :   begin
                                                    end
                                    // OR ( MIPS I )
                                    // +++++++++++++
                                    6'b10_0101  :   begin
                                                    end
                                    // XOR ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0110  :   begin
                                                    end
                                    // NOR ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0111  :   begin
                                                    end
                                    // JR ( MIPS I ) [ Jump Register ]
                                    // +++++++++++++++++++++++++++++++
                                    6'b00_1000  :   begin
                                                    end
                                    // SLL ( MIPS I ) [ Shift Left Logical ]
                                    // +++++++++++++++++++++++++++++++++++++
                                    6'b00_0000  :   begin
                                                    end
                                    // SRL ( MIPS I ) [ Shift Right Logical ]
                                    // ++++++++++++++++++++++++++++++++++++++
                                    6'b00_0010  :   begin
                                                    end
                                    // Unsupported Func
                                    // ++++++++++++++++
                                    default     :   begin
                                                    end
                                endcase
                            end
            // ADDI ( MIPS I )
            // +++++++++++++++
            6'b10_0000  :   begin
                            end
            // ADDIU ( MIPS I )
            // ++++++++++++++++
            6'b00_1000  :   begin
                            end
            // ANDI ( MIPS I )
            // +++++++++++++++
            6'b00_1100  :   begin
                            end
            // ORI ( MIPS I )
            // ++++++++++++++
            6'b00_1101  :   begin
                            end
            // SLTI ( MIPS I ) [ Set Less Than Immdediate ]
            // ++++++++++++++++++++++++++++++++++++++++++++
            6'b00_1010  :   begin
                            end
            // SLTIU ( MIPS I ) [ Set Less Than Immediate Unsigned ]
            // +++++++++++++++++++++++++++++++++++++++++++++++++++++
            6'b00_1011  :   begin
                            end
            // BEQ ( MIPS I ) [ Branch On Equal ]
            // ++++++++++++++++++++++++++++++++++
            6'b00_0100  :   begin
                            end
            // BNE ( MIPS I ) [ Branch On Not Equal ]
            // ++++++++++++++++++++++++++++++++++++++
            6'b00_0101  :   begin
                            end
            // LBU ( MIPS I ) [ Load Byte Unsigned ]
            // +++++++++++++++++++++++++++++++++++++
            6'b10_0100  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 2;
                            end
            // LHU ( MIPS I ) [ Load Half Word Unsigned ]
            // ++++++++++++++++++++++++++++++++++++++++++
            6'b10_0101  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 3;
                            end
            // LUI ( MIPS I ) [ Load Upper Immediate ]
            // +++++++++++++++++++++++++++++++++++++++
            6'b00_1111  :   begin
                                mips_reg_we_local = 1;
                                instr_imm_value_en_local = 1;
                            end
            // LW ( MIPS I ) [ Load Word ]
            // +++++++++++++++++++++++++++
            6'b10_0011  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 4;
                            end
            // SB ( MIPS I ) [ Store Byte ]
            // ++++++++++++++++++++++++++++
            6'b10_1000  :   begin
                            end
            //// SC ( MIPS II ) [ Store Conditional ] // TODO : In Rev 2.0
            //6'b000000   :   begin
            //                end
            
            // SH ( MIPS I ) [ Store Half Word ]
            // +++++++++++++++++++++++++++++++++
            6'b10_1001  :   begin
                            end
            // SW ( MIPS I ) [ Store Word ]
            // ++++++++++++++++++++++++++++
            6'b10_1011  :   begin
                            end
            // Unsupported Opcode   
            // ++++++++++++++++++
            default     :   begin
                            end
        endcase
    end

    // Program Counter
    // +++++++++++++++
    always@( posedge mem_debug_clk_gate or negedge HW_RSTn )
    begin
        if( !HW_RSTn )
        begin
            pc_p <= RESET_PC_ADDRESS;
        end
        else
        begin
            pc_p <= pc_n;
        end
    end

    always@( * ) // Program Counter Next Address Selection
    begin
        pc_n = { pc_p + 1'b1 }; // Default Rule
    end

    // Instruction Memory Instance
    // +++++++++++++++++++++++++++
    mpa_instr_mem   #(  .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .INSTR_WIDTH( INSTR_WIDTH )
                    )
                    instr_mem_inst
                    (
                        .HW_RSTn( HW_RSTn ),
                        .CLK( CLK ),
                        .addr( pc2instr_mem_addr ), // PC to Instruction Memory
                        .WE(),
                        .data_in( din ), // Instr Mem Debug Data In
                        .data_out() // Instr Mem Debug Data Out
                    );

    // MIPS MPA Register Memory INstance
    // +++++++++++++++++++++++++++++++++
    mpa_mips_reg    mips_mpa_inst   (
                                        .HW_RSTn( HW_RSTn ),
                                        .CLK( mem_debug_clk_gate ),
                                        .A0( instr2mr_a0_addr_gate ),
                                        .A1( instr2mr_a1_addr_gate ),
                                        .A2( instr2mr_a1_addr_gate ), // Redundant Input Pin : TODO Remove this later
                                        .DIN( instr_imm2mr_gate ),
                                        .WE( mips_reg_we_gate ),
                                        .DOUT0( mr_a0_out ),
                                        .DOUT1( mr_a1_out_gate )
                                    );

    // ALU Moudule Instance
    // ++++++++++++++++++++
    mpa_alu #(  .DATA_WIDTH( DATA_WIDTH )
            )
            mpa_alu_inst
            (
                .func_sel( mpa_alu_func_sel_gate ),
                .data0( mr_a0_out ),
                .data1( alu_a1_in_gate ),
                .data_out( alu_data_out )
            );

    // Data Memory Instance
    // ++++++++++++++++++++
    mpa_data_mem    #(  .DATA_WIDTH( DATA_WIDTH ),
                        .ADDRESS_WIDTH( ADDRESS_WIDTH )
                    )
                    mpa_data_mem_inst
                    (   
                        .HW_RSTn( HW_RSTn ),
                        .CLK( CLK ),
                        .addr( alu_data_out ), // TODO
                        .data_in( alu_data_out ),
                        .WE( data_mem_we_local ),
                        .RE( data_mem_re_local ),
                        .data_out( data_mem_dout ) 
                    );

endmodule
