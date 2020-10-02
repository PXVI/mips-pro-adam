/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_mips_reg
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : The 32xDWORD MIPS regestier as specified in the ISA
 *                The bus width specified is by default 32 bit. ( This is the
 *                reason this module is not parameterized )
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

module mpa_mips_reg (   
                        input HW_RSTn,
                        input CLK,

                        input [4:0] A0, // Read access port address 1
                        input [4:0] A1, // Read access port address 2
                        input [4:0] A2, // Write access port address 1
                        input [31:0] DIN,
                        input WE,

                        output [31:0] DOUT0,
                        output [31:0] DOUT1
                    );

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Name         Number      Use
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // $zero        0           The constant value of 0
    // $at          1           Assembler Temporary
    // $v0-$v1      2-3         Values for func results and expr evaluation
    // $a0-$a3      4-7         Arguments
    // $t0-$t7      8-15        Temporaries
    // $s0-$s7      16-23       Saved Temporaries
    // $t8-$t9      24-25       Temporaries
    // $k0-$k1      26-27       Reserved for OS kernel
    // $gp          28          Global Pointer
    // $sp          29          Stack Pointer
    // $fp          30          Frame Pointer
    // $ra          31          Return Address
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    reg [31:0] mem_p [32];
    reg [31:0] mem_n [32];

    integer i = 0;

    always@( posedge CLK or negedge HW_RSTn )
    begin
        for( i = 0; i < 32; i = i + 1 )
        begin
            if( i == 0 )
            begin
                mem_p[i] <= 32'd0; // Fixed
            end
            else
            begin
                mem_p[i] <= mem_p[i];
            end
        end

        if( !HW_RSTn )
        begin
            // TODO : For now the default values, ie 0s will be loaded in all registers
            for( i = 1; i < 32; i = i + 1 )
            begin
                mem_p[i] <= 32'd0;
            end
        end
        else
        begin
            for( i = 1; i < 32; i = i + 1 )
            begin
                mem_p[i] <= mem_n[i];
            end
        end
    end

    always@( * )
    begin
        if( WE )
        begin
            mem_n[A2] = DIN; // TODO : There is an exception that must be raised if mem[0] is being written ( I think )
        end
    end

    assign DOUT0 = mem_p[A0];
    assign DOUT1 = mem_p[A1];

endmodule
