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

`define alu_add 4'd5
`define alu_sub 4'd6
`define alu_and 4'd3
`define alu_xor 4'd1
`define alu_or  4'd2
`define alu_not 4'd4
`define alu_nor 4'd7

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module mpa_mips_32  #(  parameter   DATA_WIDTH = 32,
                                    INSTR_WIDTH = 32,
                                    ADDRESS_WIDTH = 32,
                                    RESET_PC_ADDRESS = 32'd0,
                                    IM_CAPACITY = 32,
                                    MR_CAPACITY = 32, // Fixed Value
                                    DM_CAPACITY = 32
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

    wire [4:0] instr2mr_a0_addr_gate, instr2mr_a1_addr_gate, instr2mr_a2_addr_gate;
    wire [DATA_WIDTH-1:0] instr_imm2mr_gate;
    wire [4-1:0] mpa_alu_func_sel_gate;
    wire [DATA_WIDTH-1:0] mr_a0_out;
    wire [DATA_WIDTH-1:0] mr_a1_out_gate; // Supports DEBUG Access
    wire [DATA_WIDTH-1:0] alu_a1_in_gate;
    wire [ADDRESS_WIDTH-1:0] dm_addr_in_gate;
    wire [DATA_WIDTH-1:0] dm_data_in_gate;

    // TODO - Exceptions Registers / Handling
    // ++++++++++++++++++++++++++++++++++++++
    reg mips_arith_ex_local;
    wire mips_arith_ex_gate;

    reg [1:0] mips_arith_ex_check_en_local;
    reg instr_mem_we_local;
    reg mips_reg_we_local;
    reg [3:0] instr_imm_value_en_local;
    reg [4-1:0] mpa_alu_func_sel_reg;
    reg [DATA_WIDTH-1:0] alu_a1_in_reg;
    reg [1:0] mr_a1_out_instr_imm_en_local;
    reg load_from_data_addr_local;
    reg data_mem_we_local;
    reg data_mem_re_local;
    reg [ADDRESS_WIDTH-1:0] dm_addr_in_local;
    reg [DATA_WIDTH-1:0] dm_data_in_local;
    reg [1:0] dm_data_wr_byte_strobe_local;
    reg data_mem_or_alu_dout_sel_local;
    wire alu_carry_gen;
    wire alu_borrow_gen;
    wire [1:0] mips_arith_ex_check_en_gate;
    wire [1:0] dm_data_wr_byte_strobe_gate;
    wire data_mem_we_wire;
    wire data_mem_re_wire;
    wire [3:0] instr_imm_value_en_gate;
    reg [4:0] instr2mr_a0_addr_local, instr2mr_a1_addr_local, instr2mr_a2_addr_local;
    reg [DATA_WIDTH-1:0] instr_imm2mr_reg;
    reg [DATA_WIDTH-1:0] debug_access_dout; // DEBUG Access
    reg [1:0] instr_r_i_j_type_local;
    wire [DATA_WIDTH-1:0] alu_data_out;
    wire [DATA_WIDTH-1:0] instr_mem_dout; // Supports DEBUG Access
    wire [DATA_WIDTH-1:0] data_mem_or_alu_dout_gate; // Supports DEBUG Access
    wire [DATA_WIDTH-1:0] data_mem_dout;
    wire data_mem_or_alu_dout_sel_gate; // Selects weather ALU output is considered or the DM output is considered
    wire [1:0] instr_r_i_j_type_gate; // Tell if the instruction is R type or I type or J type : R(0), I(1), J(2)

    reg [ADDRESS_WIDTH-1:0] pc_p; // Special Purpose Register #1
    reg [ADDRESS_WIDTH-1:0] pc_n;

    reg [DATA_WIDTH-1:0] reg_HI_p, reg_HI_n; // Special Purpose Register #2
    reg [DATA_WIDTH-1:0] reg_LO_p, reg_LO_n; // Special Purpose Register #3

    // Debug Access Ports
    // ++++++++++++++++++
    always@( * )
    begin
        case( debug_func )
            1       :   begin // IM
                            debug_access_dout = instr_mem_dout;
                        end
            2       :   begin // DM
                            debug_access_dout = data_mem_dout;
                        end
            3       :   begin // MR
                            debug_access_dout = mr_a1_out_gate;
                        end
            default :   begin // Default
                            debug_access_dout = 'b0;
                        end
        endcase
    end

    assign dout = debug_access_dout;

    always@( * )
    begin
    end

    // Control Logic Signals
    // +++++++++++++++++++++
    wire [ADDRESS_WIDTH-1:0] pc2instr_mem_addr;

    assign mem_debug_clk_gate = ( mem_debug ) ? ( debug_we ) ? CLK : 1'b0 /* Optimize */ : CLK;
    assign instr_mem_we_gate = ( mem_debug ) ? ( debug_func == 2'd1 ) ? debug_we : 1'b0 : instr_mem_we_local; // Debug Supported
    assign mips_reg_we_gate = (  mem_debug ) ? ( debug_func == 2'd3 ) ? debug_we : 1'b0 : mips_reg_we_local; // Debug Supported
    assign data_mem_we_gate = ( mem_debug ) ? ( debug_func == 2'd2 ) ? debug_we : 1'b0 : data_mem_we_local; // Debug Supported 
    assign data_mem_re_gate = ( mem_debug ) ? ( debug_func == 2'd2 ) ? debug_re : 1'b0 : data_mem_re_local; // Debug Supported

    //assign instr2mr_a0_addr_gate = pc2instr_mem_addr[25:21]; // A0
    //assign instr2mr_a1_addr_gate = pc2instr_mem_addr[20:16]; // A1

    always@( * ) // MIPS Register DIN Data Rearranger & Multiplexer // TODO This can be optimized
    begin
        instr_imm2mr_reg = { 32'b0 };

        if( instr_r_i_j_type_gate == 2'd0 ) // Register Type Instruction
        begin
            instr_imm2mr_reg = alu_data_out;
        end
        else if( instr_r_i_j_type_gate == 2'd1 ) // Immediate type Instruction
        begin
            case( instr_imm_value_en_gate )
                1       :   begin
                                instr_imm2mr_reg = { 16'b0, instr_mem_dout[15:0] };
                            end
                2       :   begin // Load byte
                                instr_imm2mr_reg = { 24'b0, data_mem_dout[7:0] };
                            end
                3       :   begin // Load halfword
                                instr_imm2mr_reg = { 16'b0, data_mem_dout[15:0] };
                            end
                4       :   begin // Load word
                                instr_imm2mr_reg = ( data_mem_or_alu_dout_sel_gate ) ? dm_data_in_gate : { data_mem_dout };
                            end
                5       :   begin // Load byte sign ext
                                instr_imm2mr_reg = { {24{data_mem_dout[7]}}, data_mem_dout[7:0] };
                            end
                6       :   begin // Load halfword sign ext
                                instr_imm2mr_reg = { {16{data_mem_dout[15]}}, data_mem_dout[15:0] };
                            end
                7       :   begin // Load upper immideate
                                instr_imm2mr_reg = { instr_mem_dout[15:0] , {16{1'b0}} };
                            end
                default :   begin
                            end
        endcase       
        end
    end
    assign instr_imm2mr_gate = ( mem_debug ) ? din : instr_imm2mr_reg; // Debug Supported
    assign instr_imm_value_en_gate = instr_imm_value_en_local;
    assign data_mem_or_alu_dout_sel_gate = data_mem_or_alu_dout_sel_local;

    always@( * ) // MIPS ALU Second Input Multiplexer
    begin
        alu_a1_in_reg = mr_a1_out_gate;

        if( instr_r_i_j_type_gate == 2'd0 ) // Register Type Instruction
        begin
            alu_a1_in_reg = mr_a1_out_gate;
        end
        else if( instr_r_i_j_type_gate == 2'd1 ) // Immediate type Instruction
        begin
            case( mr_a1_out_instr_imm_en_local )
                1           :   begin
                                    alu_a1_in_reg[15:0] = { instr_mem_dout[15:0] }; // Sign Extended
                                    alu_a1_in_reg[31:16] = {16{ instr_mem_dout[15] }};
                                end
                2           :   begin
                                    alu_a1_in_reg[15:0] = { instr_mem_dout[15:0] }; // Zero Extended
                                    alu_a1_in_reg[31:16] = {16{ 1'b0 }};
                                end
                default     :   begin
                                    alu_a1_in_reg = instr_mem_dout; // Default
                                end
            endcase
        end
    end
    assign alu_a1_in_gate = alu_a1_in_reg;

    assign mpa_alu_func_sel_gate = mpa_alu_func_sel_reg;
    assign pc2instr_mem_addr = ( mem_debug ) ? addr : pc_p; // Debug Access

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
    // 1. [X] SB
    // 2. [X] SH
    // 3. [X] SW
    // 4. [X] SC
    // 

    // Control Logic Decoder
    // +++++++++++++++++++++
    always@( * )
    begin
        // Defaults
        // ++++++++
        instr_mem_we_local = 0;
        mips_reg_we_local = 0;
        instr_imm_value_en_local = 0;
        mr_a1_out_instr_imm_en_local = 0;
        data_mem_we_local = 0;
        data_mem_re_local = 0;
        dm_data_wr_byte_strobe_local = 0; // W Strobe - Default ( 1 : Lower Byte, 2 : Lower Half Word, 3 : Word )
        data_mem_or_alu_dout_sel_local = 0;
        mips_arith_ex_check_en_local = 0;
        instr_r_i_j_type_local = 0; // Default is R type

        case( instr_mem_dout[31:26] )
            // Generic Register Instruction ( Special Opcode )
            // +++++++++++++++++++++++++++++++++++++++++++++++
            6'b00_0000  :   begin
                                case( instr_mem_dout[5:0] )
                                    // ADD ( MIPS I ) // TODO : Will be
                                    // implemented later after the signed part
                                    // has been properly understood and I am
                                    // at a conclusion as to what to do with
                                    // it.
                                    // ++++++++++++++
                                    6'b10_0000  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_add;
                                                        mips_arith_ex_check_en_local = 1;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // ADDU ( MIPS I )
                                    // +++++++++++++++
                                    6'b10_0001  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_add;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // SUB ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0010  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_sub;
                                                        mips_arith_ex_check_en_local = 1;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // SUBU ( MIPS I )
                                    // +++++++++++++++
                                    6'b10_0011  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_sub;
                                                        instr_r_i_j_type_local = 0;
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
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_and;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // OR ( MIPS I )
                                    // +++++++++++++
                                    6'b10_0101  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_or;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // XOR ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0110  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_xor;
                                                        instr_r_i_j_type_local = 0;
                                                    end
                                    // NOR ( MIPS I )
                                    // ++++++++++++++
                                    6'b10_0111  :   begin
                                                        mips_reg_we_local = 1;
                                                        mpa_alu_func_sel_reg = `alu_nor;
                                                        instr_r_i_j_type_local = 0;
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
            // ADDI ( MIPS I ) // Max Postive Sume is (2^31)-1
            // TODO Must generate an overflow for sum if addition 
            // goes above the positive max or below the min negative 
            // val
            // +++++++++++++++
            6'b00_1000  :   begin
                            end
            // ADDIU ( MIPS I ) // Max Positive Sum is (2^32)-1
            // TODO Must implement the overflow for max sum
            // ++++++++++++++++
            6'b00_1001  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                instr_imm_value_en_local = 4;
                                data_mem_or_alu_dout_sel_local = 1;
                                instr_r_i_j_type_local = 1;
                            end
            // ANDI ( MIPS I )
            // +++++++++++++++
            6'b00_1100  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_and;
                                mr_a1_out_instr_imm_en_local = 2;
                                instr_imm_value_en_local = 4;
                                data_mem_or_alu_dout_sel_local = 1;
                                instr_r_i_j_type_local = 1;
                            end
            // ORI ( MIPS I )
            // ++++++++++++++
            6'b00_1101  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_or;
                                mr_a1_out_instr_imm_en_local = 2;
                                instr_imm_value_en_local = 4;
                                data_mem_or_alu_dout_sel_local = 1;
                                instr_r_i_j_type_local = 1;
                            end
            // XORI
            // ++++
            6'b00_1110  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_xor;
                                mr_a1_out_instr_imm_en_local = 2;
                                instr_imm_value_en_local = 4;
                                data_mem_or_alu_dout_sel_local = 1;
                                instr_r_i_j_type_local = 1;
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
                                instr_r_i_j_type_local = 1;
                            end
            // LB [ Load Byte Sign Ext ]
            // +++++++++++++++++++++++++
            6'b10_0000  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 5;
                                instr_r_i_j_type_local = 1;
                            end
            // LHU ( MIPS I ) [ Load Half Word Unsigned ]
            // ++++++++++++++++++++++++++++++++++++++++++
            6'b10_0101  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 3;
                                instr_r_i_j_type_local = 1;
                            end
            // LH [ Load Half Word Sign Ext ]
            // ++++++++++++++++++++++++++++++
            6'b10_0001  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 6;
                                instr_r_i_j_type_local = 1;
                            end
            // LUI ( MIPS I ) [ Load Upper Immediate ]
            // +++++++++++++++++++++++++++++++++++++++
            6'b00_1111  :   begin
                                mips_reg_we_local = 1;
                                instr_imm_value_en_local = 7;
                                instr_r_i_j_type_local = 1;
                            end
            // LW ( MIPS I ) [ Load Word ]
            // +++++++++++++++++++++++++++
            6'b10_0011  :   begin
                                mips_reg_we_local = 1;
                                mpa_alu_func_sel_reg = `alu_add;
                                mr_a1_out_instr_imm_en_local = 1;
                                data_mem_re_local = 1;
                                instr_imm_value_en_local = 4;
                                instr_r_i_j_type_local = 1;
                            end
            // SB ( MIPS I ) [ Store Byte ]
            // ++++++++++++++++++++++++++++
            6'b10_1000  :   begin
                                mpa_alu_func_sel_reg = `alu_add;
                                data_mem_we_local = 1;
                                data_mem_re_local = 1;
                                dm_data_wr_byte_strobe_local = 1;
                                mr_a1_out_instr_imm_en_local = 1;
                                instr_r_i_j_type_local = 1;
                            end
            //// SC ( MIPS II ) [ Store Conditional ] // TODO : In Rev 2.0
            //6'b000000   :   begin
            //                end
            
            // SH ( MIPS I ) [ Store Half Word ]
            // +++++++++++++++++++++++++++++++++
            6'b10_1001  :   begin
                                mpa_alu_func_sel_reg = `alu_add;
                                data_mem_we_local = 1;
                                data_mem_re_local = 1;
                                dm_data_wr_byte_strobe_local = 2;
                                mr_a1_out_instr_imm_en_local = 1;
                                instr_r_i_j_type_local = 1;
                            end
            // SW ( MIPS I ) [ Store Word ]
            // ++++++++++++++++++++++++++++
            6'b10_1011  :   begin
                                mpa_alu_func_sel_reg = `alu_add;
                                data_mem_we_local = 1;
                                data_mem_re_local = 1;
                                dm_data_wr_byte_strobe_local = 3;
                                mr_a1_out_instr_imm_en_local = 1;
                                instr_r_i_j_type_local = 1;
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
            if( mem_debug )
            begin
                pc_p <= RESET_PC_ADDRESS; // TODO Check how a core realises from where to start the program execution. For now just start from 0 by default.
            end
            else
            begin
                pc_p <= pc_n;
            end
        end
    end

    always@( * ) // Program Counter Next Address Selection
    begin
        pc_n = { pc_p + { {28{1'b0}}, 3'd4 } }; // Default Rule
    end

    // MIPS Reg Input Address Mux
    // ++++++++++++++++++++++++++
    always@( * )
    begin
        if( mem_debug )
        begin
            instr2mr_a1_addr_local = addr[4:0];
        end
        else
        begin
            instr2mr_a1_addr_local = instr_mem_dout[20:16]; // rt
        end
        instr2mr_a0_addr_local = instr_mem_dout[25:21]; // rs
        instr2mr_a2_addr_local = ( instr_r_i_j_type_gate == 2'd1 /* I Type Check */ ) ? instr_mem_dout[20:16] : instr_mem_dout[15:11]; // rd in R type and rt in I type
    end

    assign instr2mr_a0_addr_gate = instr2mr_a0_addr_local;
    assign instr2mr_a1_addr_gate = instr2mr_a1_addr_local;
    assign instr2mr_a2_addr_gate = ( mem_debug ) ? addr[4:0] : instr2mr_a2_addr_local;
    assign instr_r_i_j_type_gate = instr_r_i_j_type_local;

    // Instruction Memory Instance
    // +++++++++++++++++++++++++++
    mpa_instr_mem   #(  .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .INSTR_WIDTH( INSTR_WIDTH ),
                        .INSTR_CAPACITY( IM_CAPACITY )
                    )
                    instr_mem_inst
                    (
                        .HW_RSTn( HW_RSTn ),
                        .CLK( mem_debug_clk_gate ),
                        .addr( {pc2instr_mem_addr[31:2], 2'b00} /* Byte Addressable */ ), // PC to Instruction Memory
                        .WE( instr_mem_we_gate ),
                        .data_in( din ), // Instr Mem Debug Data In
                        .data_out( instr_mem_dout ) // Instr Mem Debug Data Out
                    );

    // MIPS MPA Register Memory Instance
    // +++++++++++++++++++++++++++++++++
    mpa_mips_reg    mips_mpa_inst   (
                                        .HW_RSTn( HW_RSTn ),
                                        .CLK( mem_debug_clk_gate ),
                                        .A0( instr2mr_a0_addr_gate ),
                                        .A1( instr2mr_a1_addr_gate ),
                                        .A2( instr2mr_a2_addr_gate ),
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
                .data_out( alu_data_out ),
                .carry_gen( alu_carry_gen ),
                .borrow_gen( alu_borrow_gen )
            );

    // Arithematic Exceptions Generation Logic
    // +++++++++++++++++++++++++++++++++++++++
    always@( * )
    begin
        mips_arith_ex_local = 0;

        if( mips_arith_ex_check_en_local == 2'd1 ) // Addition Overflow Exception
        begin
            if( alu_data_out[DATA_WIDTH-1] != alu_carry_gen )
            begin
                mips_arith_ex_local = 1;
            end
        end
        else if( mips_arith_ex_check_en_local == 2'd2 ) // Subtraction Underflow/Overflow Exception
        begin
            if( alu_data_out[DATA_WIDTH-1] != alu_borrow_gen )
            begin
                mips_arith_ex_local = 1;
            end
        end
    end

    assign mips_arith_ex_check_en_gate = mips_arith_ex_check_en_local;
    assign mips_arith_ex_gate = mips_arith_ex_local;

    // Data Memory Input Mux
    // +++++++++++++++++++++
    always@( * )
    begin
        dm_addr_in_local = alu_data_out;

        case( dm_data_wr_byte_strobe_gate )
            1       :   begin // Byte Strobe
                            dm_data_in_local = { data_mem_dout[31:8],mr_a1_out_gate[7:0] };
                        end
            2       :   begin // Half Word Strobe
                            dm_data_in_local = { data_mem_dout[31:16],mr_a1_out_gate[15:0] };
                        end
            3       :   begin // Word Strobe
                            dm_data_in_local = { mr_a1_out_gate };
                        end
            default :   begin // Data In Takes Input Directly From ALU - Default
                            dm_data_in_local = alu_data_out;
                        end
        endcase
    end

    assign dm_addr_in_gate = ( mem_debug ) ? addr : dm_addr_in_local; // Debug Supported
    assign dm_data_in_gate = ( mem_debug ) ? din : dm_data_in_local; // Debug Supported
    assign dm_data_wr_byte_strobe_gate = dm_data_wr_byte_strobe_local;
    
    // Data Memory Instance
    // ++++++++++++++++++++
    mpa_data_mem    #(  .DATA_WIDTH( DATA_WIDTH ),
                        .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .DATA_CAPACITY( DM_CAPACITY )
                    )
                    mpa_data_mem_inst
                    (   
                        .HW_RSTn( HW_RSTn ),
                        .CLK( mem_debug_clk_gate ),
                        .addr( {dm_addr_in_gate[31:2], 2'b00} /* Byte Addressable */ ), // TODO
                        .data_in( dm_data_in_gate ),
                        .WE( data_mem_we_gate ),
                        .RE( data_mem_re_gate ),
                        .data_out( data_mem_dout ) 
                    );

endmodule
