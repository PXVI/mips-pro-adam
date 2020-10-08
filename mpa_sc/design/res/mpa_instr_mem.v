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

    reg [INSTR_WIDTH-1:0] temp_out;

    integer i = 0;
    integer j = 0;
    integer k = 0;

    always@(  posedge CLK or negedge HW_RSTn)
    begin
        for( i = 0; i < INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS); i = i + 1 )
        begin
            instr_mem_p[i] <= instr_mem_p[i];
        end

        if( !HW_RSTn )
        begin
            for( i = 0; i < INSTR_CAPACITY*( (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS) ); i = i + 1 )
            begin
                instr_mem_p[i] <= 0; // TODO : Decide later what the default values will be/should be
            end
        end
        else
        begin
            for( i = 0; i < INSTR_CAPACITY*( (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS) ); i = i + 1 )
            begin
                instr_mem_p[i] <= instr_mem_n[i];
            end
        end
    end

    always@( * )
    begin
        for( i = 0; i < INSTR_CAPACITY*( (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS) ); i = i + 1 )
        begin
            instr_mem_n[i] = instr_mem_p[i]; // By Default
        end

        if( WE )
        begin
            for( j = 0; j < (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS); j = j + 1 )
            begin
                instr_mem_n[addr%(INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS))+j] = data_in[ADDRESS_ACCESS*( (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS) - 1 - j )+:ADDRESS_ACCESS];
            end
        end
    end

    always@( * )
    begin
        for( k = 0; k < (INSTR_WIDTH/ADDRESS_ACCESS) + (INSTR_WIDTH%ADDRESS_ACCESS); k = k + 1 )
        begin
            temp_out[(ADDRESS_ACCESS*((INSTR_WIDTH/ADDRESS_ACCESS)+(INSTR_WIDTH%ADDRESS_ACCESS)-1-k))+:ADDRESS_ACCESS] = instr_mem_p[addr%(INSTR_CAPACITY*(INSTR_WIDTH/ADDRESS_ACCESS))+k]; // The Mod is added to make sure the actual evaluated address is inside the valid range of addresses
        end
    end

    assign data_out = temp_out;

endmodule
