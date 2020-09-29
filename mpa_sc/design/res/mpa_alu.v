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
                                FUNCTION_SEL_WIDTH = 3
                )
                (
                                input [FUNCTION_SEL_WIDTH-1:0] func_sel,
                                input [DATA_WIDTH-1:0] data0,
                                input [DATA_WIDTH-1:0] data1,

                                output [DATA_WIDTH-1:0] data_out
                );

endmodule
