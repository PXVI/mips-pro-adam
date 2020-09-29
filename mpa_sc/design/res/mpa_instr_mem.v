/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_instr_mem
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : The MIPS processor's instruction memory space. The program
 *                sequence which is to be run, will be loaded into this memory
 *                using either an additional mechanism or a simple backdoor
 *                loading. ( For the current model, we will use a backdoor
 *                instruction loading )
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

module mpa_instr_mem #( parameter   INSTR_CAPACITY = 64,
                                    ADDRESS_WIDTH = 32,
                                    INSTR_WIDTH = 32 ,
                                    ADDRESS_ACCESS = 8 // Addressability ( Byte Addressable )
                        )
                        (  
                                    input HW_RSTn,
                                    input CLK,

                                    input [ADDRESS_WIDTH-1:0] addr,
                                    input WE,
                                    input [INSTR_WIDTH-1:0] data_in,

                                    output [INSTR_WIDTH-1:0] data_out
                        );

    reg [ADDRESS_ACCESS-1:0] instr_mem_p [INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS)]; // 64*4 memory locations, ie still 64 full instructions
    reg [ADDRESS_ACCESS-1:0] instr_mem_n [INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS)]; // Same as above

    integer i = 0;

    always@(  posedge CLK or negedge HW_RSTn)
    begin
        for( i = 0; i < INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS); i = i + 1 )
        begin
            instr_mem_p[i] <= instr_mem_p[i];
        end

        if( !HW_RSTn )
        begin
            for( i = 0; i < INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS); i = i + 1 )
            begin
                instr_mem_p[i] <= 32'd0; // TODO : Decide later what the default values will be/should be
            end
        end
        else
        begin
            for( i = 0; i < INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS); i = i + 1 )
            begin
                instr_mem_p[i] <= instr_mem_n[i];
            end
        end
    end

    always@( * )
    begin
        if( WE )
        begin
            instr_mem_n[addr%(INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS)] <= data_in;
        end
    end

    assign data_out = instr_mem_p[addr%(INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS)]; // The Mod is added to make sure the actual evaluated address is inside the valid range of addresses

endmodule
