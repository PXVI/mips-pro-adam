/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_data_mem
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : This is the data memory from/on which the data LOADs and STOREs
 *                will happen. This particular memory is actually an external
 *                component which uses a data handling/management digital block 
 *                that brings in data from the nearst memory location in the memory
 *                heirarchy. For now, this block will be an internal part of
 *                the design itself ( Not Advised though! ).
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

// Notes :
// +++++++
// 1. This memory model is byte addressable only.
//

module mpa_data_mem #(  parameter   DATA_CAPACITY = 128,
                                    DATA_WIDTH = 32,
                                    ADDRESS_WIDTH = 32,
                                    GRANULARITY = 8 // Byte Addressable
                    )
                    (   
                                    input HW_RSTn,
                                    input CLK,

                                    input [ADDRESS_WIDTH-1:0] addr,
                                    input [DATA_WIDTH-1:0] data_in,
                                    input WE, // Write Enable
                                    input RE, // Read Enable

                                    output [DATA_WIDTH-1:0] data_out
                    );

    reg [GRANULARITY-1:0] mem_p [(DATA_CAPACITY*(DATA_WIDTH/GRANULARITY))-1:0]; // 128*4 Locations ( Each is byte addressable )
    reg [GRANULARITY-1:0] mem_n [(DATA_CAPACITY*(DATA_WIDTH/GRANULARITY))-1:0]; // Same as above

    integer i = 0, j = 0;
    genvar k;

    always@( posedge CLK or negedge HW_RSTn )
    begin
        for( i = 0; i < (DATA_CAPACITY*(DATA_WIDTH/GRANULARITY)); i = i + 1 )
        begin
            mem_p[i] <= mem_n[i];
        end

        if( !HW_RSTn )
        begin
            // Do Nothing : For now
        end
        else
        begin
            mem_p <= mem_n;
        end
    end

    always@( * )
    begin
        for( i = 0; i < (DATA_CAPACITY*(DATA_WIDTH/GRANULARITY)); i = i + 1 )
        begin
            mem_n[i] = mem_p[i]; // By default
        end

        if( WE )
        begin
            for( j = 0; j < (DATA_WIDTH/GRANULARITY) + (DATA_WIDTH%GRANULARITY); j = j + 1 )
            begin
                mem_n[(addr+j)%(DATA_CAPACITY*(DATA_WIDTH/GRANULARITY))] = data_in[GRANULARITY*( (DATA_WIDTH/GRANULARITY) + (DATA_WIDTH%GRANULARITY) - 1 - j )+:GRANULARITY]; // 0 : data_in[31:24], 1 : data_in[23:26], 2 : data_in[15:8], 3 : data_in[7:0]
            end
        end
    end

    generate
        for( k = 0; k < (DATA_WIDTH/GRANULARITY) + (DATA_WIDTH%GRANULARITY); k = k + 1 )
        begin
            assign data_out[GRANULARITY*(((DATA_WIDTH/GRANULARITY)+(DATA_WIDTH%GRANULARITY)-1)-k)+:GRANULARITY] = ( RE ) ? mem_p[(addr+k)%(DATA_CAPACITY*(DATA_WIDTH/GRANULARITY))] : 8'b0;
        end
    endgenerate

endmodule
