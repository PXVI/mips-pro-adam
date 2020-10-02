/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_mips
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : The top module of the MPA single cycle processor
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

module mpa_mips #(  parameter   DATA_WIDTH = 32,
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
                                input [1:0] debug_func, // ( 1, 2 ) : IM, DM
                                input debug_we,
                                input debug_re,
                                input mem_debug
                );

    wire mem_debug_clk_gate;
    wire instr_mem_we_gate;
    wire data_mem_we_gate, data_mem_re_gate;

    reg [31:0] pc_p;
    wire [31:0] pc_n;

    assign instr_mem_we_gate = ( ( debug_func == 2'd1 ) && mem_debug ) ? debug_we : 0;
    assign data_mem_we_gate = ( ( debug_func == 2'd2 ) && mem_debug ) ? debug_we : 0 /* TODO Connect this to the mpa's data mem WE */;
    assign data_mem_re_gate = ( ( debug_func == 2'd2 ) && mem_debug ) ? debug_re : 0 /* TODO Connect this to the mpa's data mem RE */;
    assign mem_debug_clk_gate = ( mem_debug ) ? 1'b0 /* Optimize */ : CLK;

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

    generate
        assign pc_n = { pc_p + 1'b1 }; // TODO Change this when Branch instruction are implemented | Use case conditional assignment
    endgenerate

    // Instruction Memory Instance
    // +++++++++++++++++++++++++++
    mpa_instr_mem   #(  .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .INSTR_WIDTH( INSTR_WIDTH )
                    )
                    instr_mem_inst
                    (
                        .HW_RSTn( HW_RSTn ),
                        .CLK( CLK ),
                        .addr(),
                        .WE(),
                        .data_in(),
                        .data_out()
                    );

    // MIPS MPA Register Memory INstance
    // +++++++++++++++++++++++++++++++++
    mpa_mips_reg    mips_mpa_inst   (
                                        .HW_RSTn( HW_RSTn ),
                                        .CLK( mem_debug_clk_gate ),
                                        .A0(),
                                        .A1(),
                                        .A2(),
                                        .DIN(),
                                        .WE(),
                                        .DOUT0(),
                                        .DOUT1()
                                    );

    // ALU Moudule Instance
    // ++++++++++++++++++++
    mpa_alu #(  .DATA_WIDTH( DATA_WIDTH )
            )
            mpa_alu_inst
            (
                .func_sel(),
                .data0(),
                .data1(),
                .data_out()
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
                        .addr(),
                        .data_in(),
                        .WE(),
                        .RE(),
                        .data_out()
                    );

endmodule
