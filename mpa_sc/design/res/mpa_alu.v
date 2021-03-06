/* -----------------------------------------------------------------------------------
 * Module Name  : mpa_alu
 * Date Created : 22:22:48 IST, 28 September, 2020 [ Monday ]
 *
 * Author       : pxvi
 * Description  : This is a simple ALU module.
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

// Notes :-
// ++++++++
// 1. Supports Unsigned ADD, SUB
// 2. Supports bit-wise XOR, OR, AND, NOT
//

module mpa_alu  #(  parameter   DATA_WIDTH = 32,
                                FUNCTION_SEL_WIDTH = 4
                )
                (
                                input [FUNCTION_SEL_WIDTH-1:0] func_sel,
                                input [DATA_WIDTH-1:0] data0,
                                input [DATA_WIDTH-1:0] data1,

                                output [DATA_WIDTH-1:0] data_out,
                                output carry_gen,
                                output borrow_gen
                );

    parameter SHIFT_WIDTH = $clog2( DATA_WIDTH );

    genvar i;
    reg [DATA_WIDTH-1:0] temp_out;
    reg carry_out_local;
    reg borrow_out_local;
    reg [SHIFT_WIDTH-1:0] shift_val;
    integer j;
    reg less_than_found;

    // Case Selection
    // ++++++++++++++
    // 0   - reserved ( 0 out )
    // 1   - bitwise XOR
    // 2   - bitwise OR
    // 3   - bitwise AND
    // 4   - bitwise NOT
    // 5   - Unsigned/Signed ADD
    // 6   - Unsigned/Signed SUB
    // 7   - bitwise NOR
    // 8   - Shift Left Logical
    // 9   - Shift Right Logical
    // 10  - Signed set less than
    // 11  - Unsigned set less than
    // 12  - Equal To
    // 13  - Not Equal To
    // ++++++++++++++++++++++++++++

    always@( * )
    begin
        case( func_sel )
            1           :   temp_out = data0 ^ data1;
            2           :   temp_out = data0 | data1;
            3           :   temp_out = data0 & data1;
            4           :   temp_out = ~data0;
            5           :   {carry_out_local,temp_out} = data0 + data1;
            6           :   {borrow_out_local,temp_out} = ~{ data0[DATA_WIDTH-1], data0 } + { data1[DATA_WIDTH-1], data1 } + 1'b1; // TODO Add a borrow/underflow bit somewhere | This needs to be cross checked
            7           :   temp_out = ~{data0 | data1};
            8           :   begin
                                temp_out = data1;
                                for( shift_val = 0; shift_val < data0[SHIFT_WIDTH-1:0]; shift_val = shift_val + 1'b1 )
                                begin
                                    temp_out = { temp_out[DATA_WIDTH-2:0], 1'b0 };
                                end
                            end
            9           :   begin
                                temp_out = data1;
                                for( shift_val = 0; shift_val < data0[SHIFT_WIDTH-1:0]; shift_val = shift_val + 1'b1 )
                                begin
                                    temp_out = { 1'b0, temp_out[DATA_WIDTH-1:1] };
                                end
                            end
            10          :   begin
                                less_than_found = 1'b0;
                                temp_out = 32'd0;
                                if( data0[DATA_WIDTH-1] != data1[DATA_WIDTH-1] )
                                begin
                                    temp_out = ( data0[DATA_WIDTH-1] == 1'b1 ) ? 32'd1 : 32'd0;
                                end
                                else
                                begin
                                    temp_out = 32'd0;

                                    for( j = DATA_WIDTH-2; j >= 0 && ( less_than_found != 1'b1 ); j = j - 1 )
                                    begin
                                        if( ( data0[j] != data1[j] ) & ( data0[j] == 1'b0 ) )
                                        begin
                                            temp_out = 32'd1;
                                            less_than_found = 1'b1;
                                        end
                                        if( ( data0[j] != data1[j] ) & ( data0[j] != 1'b0 ) )
                                        begin
                                            temp_out = 32'd0;
                                            less_than_found = 1'b1;
                                        end
                                    end
                                end
                            end
            11          :   begin
                                less_than_found = 1'b1;
                                temp_out = 32'd0;

                                for( j = DATA_WIDTH-1; j >= 0 && ( less_than_found != 1'b1 ); j = j - 1 )
                                begin
                                    if( ( data0[j] != data1[j] ) & ( data0[j] == 1'b0 ) )
                                    begin
                                        temp_out = 32'd1;
                                        less_than_found = 1'b1;
                                    end
                                    if( ( data0[j] != data1[j] ) & ( data0[j] != 1'b0 ) )
                                    begin
                                        temp_out = 32'd0;
                                        less_than_found = 1'b1;
                                    end
                                end
                            end
            12          :   begin
                                temp_out = ( data0 == data1 ) ? 32'd1 : 32'd0;
                            end
            13          :   begin
                                temp_out = ( data0 != data1 ) ? 32'd1 : 32'd0;
                            end
            default     :   temp_out = 0;
        endcase
    end

    assign data_out = temp_out;
    assign carry_gen = carry_out_local;
    assign borrow_gen = borrow_out_local;

endmodule
