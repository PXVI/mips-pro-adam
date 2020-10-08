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

module integration_top;

// IP Regs and Wires
// -----------------

reg ip_CLK;
reg ip_RSTn;

// Testbench Variables / Registers
// -------------------------------


// IP Instantiations
// -----------------

mpa_mips_32 mips_mpa_dut_inst   (
                                    .CLK( ip_CLK )
                                );


initial
begin
end

`ifdef GEN_DUMP
    initial
    begin
        $dumpfile( "dump.vcd" );
        $dumpvars( 0, integration_top );
    end
`endif

endmodule
