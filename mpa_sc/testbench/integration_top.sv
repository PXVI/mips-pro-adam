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

    // Parameters
    // ----------
    parameter   DATA_WIDTH = 32,
                ADDRESS_WIDTH = 32,
                IM_CAPACITY = 32, // Byte Addressable
                DM_CAPACITY = 32, // Byte Addressable
                MR_CAPACITY = 32; // Double Word Addressable
    
    // IP Regs and Wires
    // -----------------
    
    reg ip_CLK;
    reg ip_HW_RSTn;
    
    reg [DATA_WIDTH-1:0] ip_din;
    wire [DATA_WIDTH-1:0] ip_dout;
    reg [ADDRESS_WIDTH-1:0] ip_addr;
    reg [1:0] ip_debug_func;
    reg ip_debug_we;
    reg ip_debug_re;
    reg ip_mem_debug;
    
    // Testbench Variables / Registers
    // -------------------------------
    
    bit [DATA_WIDTH-1:0] tb_im_mem [IM_CAPACITY];
    bit [DATA_WIDTH-1:0] tb_dm_mem [DM_CAPACITY];
    bit [DATA_WIDTH-1:0] tb_mr_mem [MR_CAPACITY];
    
    // IP Instantiations
    // -----------------
    
    mpa_mips_32     #(
                        .DATA_WIDTH( DATA_WIDTH ),
                        .INSTR_WIDTH(),
                        .ADDRESS_WIDTH( ADDRESS_WIDTH ),
                        .RESET_PC_ADDRESS(),
                        .IM_CAPACITY( IM_CAPACITY ),
                        .MR_CAPACITY( MR_CAPACITY ),
                        .DM_CAPACITY( DM_CAPACITY )
                    )
                    mips_mpa_dut_inst
                    (
                        .HW_RSTn( ip_HW_RSTn ),
                        .CLK( ip_CLK ),
    
                        .din( ip_din ),
                        .dout( ip_dout ),
                        .addr( ip_addr ),
                        .debug_func( ip_debug_func ),
                        .debug_we( ip_debug_we ),
                        .debug_re( ip_debug_re ),
                        .mem_debug( ip_mem_debug )
                    );
    
    
    initial
    begin
        fork
            begin // Clock
                start_clk();
            end
            begin // Stimulus
                hw_reset( 100 );
                delay( 2 );
    
                //read_mpa_im();
                //read_mpa_dm();
                //read_mpa_mr();
                
                //write_mpa_im();
                //read_mpa_im();
                
                //write_mpa_dm();
                //read_mpa_dm();
                
                //write_mpa_mr();
                //read_mpa_mr();
    
                load_mips_im_code_b();
                write_mpa_im( 1 );
                rand_dm_reg_and_load(,,1);
                write_mpa_dm( 1 );

                read_mpa_im();
                read_mpa_dm();

                run_cpu_instr();

                read_mpa_im();
                read_mpa_mr();
                read_mpa_dm();
                
                end_sim();
            end
        join
    end
    
    initial // End Simulation Condition
    begin
        #100000000;
        $finish;
    end
    
    `ifdef GEN_DUMP
        initial
        begin
            $dumpfile( "mpa_mips_dump.vcd" );
            $dumpvars( 0, integration_top );
        end
    `endif
    
    // Test Subroutines
    // ----------------
    
    task start_clk( integer time_period = 5 );
        integer tp;
        tp = time_period;
        ip_CLK <= 1;
        fork
            forever
            begin
                #(tp) ip_CLK <= ~ip_CLK;
            end
        join
    endtask

    task hw_reset( integer duration = 0 );
        if( duration == 0 )
        begin
            ip_HW_RSTn <= 0;
        end
        else
        begin
            ip_HW_RSTn <= 0;
            fork
                #(duration) ip_HW_RSTn <= 1;
            join
        end
    endtask
    
    task rm_reset();
        ip_HW_RSTn <= 1;
    endtask
    
    task run_cpu_instr( integer instr_count = IM_CAPACITY );
        disable_debug_mode();

        $display( " %8d ## [ SIM_X ][    ] ", $time ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] Simulation Started : The core will run for a total of %0d cycles", $time, instr_count ); 
        $display( " %8d ## [ SIM_X ][    ] -----------------------------------------------------------------------------", $time ); 
        $display( " %8d ## [ SIM_X ][    ] ", $time ); 
        @( negedge ip_CLK );
        repeat( instr_count )
        begin
            @( posedge ip_CLK );
        end
        @( negedge ip_CLK );

        enable_debug_mode();
    endtask
    
    task enable_debug_mode( integer func = 0 );
        ip_mem_debug <= 1;
        ip_debug_we <= 0;
        ip_debug_re <= 0;
        ip_debug_func <= func;
        ip_addr <= 'd0;
        ip_din <= 'd0;
        $display( " %8d ## [ DEBUG ] Debug Mode is enabled", $time );
    endtask
    
    task disable_debug_mode();
        ip_mem_debug <= 0;
        ip_debug_we <= 0;
        ip_debug_re <= 0;
        ip_debug_func <= 2'd0;
        ip_addr <= 'd0;
        ip_din <= 'd0;
        $display( " %8d ## [ DEBUG ] Debug Mode is disabled", $time );
    endtask
    
    task read_mpa_im();
        integer i;
    
        enable_debug_mode( 1 );
    
        // Read the Instruction Memory
        // +++++++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            $display( " %8d ## [ DEBUG ][ IM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
        end
    
        disable_debug_mode();
    endtask
    
    task read_mpa_dm();
        integer i;
    
        enable_debug_mode( 2 );
    
        // Read the Data Register
        // ++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            $display( " %8d ## [ DEBUG ][ DM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
        end
    
        disable_debug_mode();
    endtask
    
    task read_mpa_mr();
        integer i;
    
        enable_debug_mode( 3 );
    
        // Read the MIPS Registers
        // +++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < MR_CAPACITY; i = i + 1 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_re <= 1;
            @( posedge ip_CLK );
            $display( " %8d ## [ DEBUG ][ MR ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) ", $time, ip_addr, ip_dout[31:24], ip_dout[23:16], ip_dout[15:8], ip_dout[7:0], ip_dout );
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_im( int file = 0 );
        integer i;
    
        enable_debug_mode( 1 );
    
        // Write the Instruction Memory
        // ++++++++++++++++++++++++++++

        if( file == 1 )
        begin
            @( posedge ip_CLK );
            for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= tb_im_mem[i/4];
                @( posedge ip_CLK );
                //$display( " %8d ## [ DEBUG ][ IM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
            end
        end
        else
        begin
            @( posedge ip_CLK );
            for( i = 0; i < IM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= $urandom;
                @( posedge ip_CLK );
                $display( " %8d ## [ DEBUG ][ IM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
            end
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_dm( int file = 0 );
        integer i;
    
        enable_debug_mode( 2 );
    
        // Write the Data Memory
        // +++++++++++++++++++++
        if( file == 1 )
        begin
            @( posedge ip_CLK );
            for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= tb_dm_mem[i/4];
                @( posedge ip_CLK );
                //$display( " %8d ## [ DEBUG ][ DM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
            end
        end
        else
        begin
            @( posedge ip_CLK );
            for( i = 0; i < DM_CAPACITY*4; i = i + 4 )
            begin
                @( posedge ip_CLK );
                ip_addr <= i;
                ip_debug_we <= 1;
                ip_din <= $urandom;
                @( posedge ip_CLK );
                $display( " %8d ## [ DEBUG ][ DM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
            end
        end
    
        disable_debug_mode();
    endtask
    
    task write_mpa_mr();
        integer i;
    
        enable_debug_mode( 3 );
    
        // Write the MIPS Registers
        // ++++++++++++++++++++++++
        @( posedge ip_CLK );
        for( i = 0; i < MR_CAPACITY; i = i + 1 )
        begin
            @( posedge ip_CLK );
            ip_addr <= i;
            ip_debug_we <= 1;
            ip_din <= $urandom;
            @( posedge ip_CLK );
            $display( " %8d ## [ DEBUG ][ MR ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Backdoor Loaded Data }", $time, ip_addr, ip_din[31:24], ip_din[23:16], ip_din[15:8], ip_din[7:0], ip_din );
        end
    
        disable_debug_mode();
    endtask
    
    task load_mips_im_code_b( string filename = "mpa_mips_load_im_program.bin" );
        if( filename == "mpa_mips_load_im_program.bin" )
        begin
            $readmemb( filename, tb_im_mem );
        end
        else
        begin
            $readmemb( filename, tb_im_mem );
            for( int i = 0; i < IM_CAPACITY; i++ )
            begin
                $display( "%32b ( %0d )", tb_im_mem[i], tb_im_mem[i] );
            end
        end
    endtask
    
    task load_mips_im_code_h( string filename = "" );
    endtask
    
    task load_mips_dm_code_b( string filename = "mpa_mips_load_dm_data.bin" );
        if( filename == "mpa_mips_load_dm_data.bin" )
        begin
            $readmemb( filename, tb_dm_mem );
        end
        else
        begin
            $readmemb( filename, tb_dm_mem );
            for( int i = 0; i < DM_CAPACITY; i++ )
            begin
                $display( "%32b ( %0d )", tb_dm_mem[i], tb_dm_mem[i] );
            end
        end
    endtask
    
    task load_mips_dm_code_h( string filename = "" );
    endtask
    
    task load_mips_mr_code_b( string filename = "mpa_mips_load_mr.bin" );
        if( filename == "mpa_mips_load_mr.bin" )
        begin
            $readmemb( filename, tb_mr_mem );
        end
        else
        begin
            $readmemb( filename, tb_mr_mem );
            for( int i = 0; i < MR_CAPACITY; i++ )
            begin
                $display( "%32b ( %0d )", tb_mr_mem[i], tb_mr_mem[i] );
            end
        end
    endtask
    
    task load_mips_mr_code_h( string filename = "" );
    endtask

    task rand_dm_reg_and_load( int min = 0, int max = 512, bit show_data = 0 );
        for( int i = 0; i < DM_CAPACITY; i++ )
        begin
            tb_dm_mem[i] = $urandom_range( min, max );
        end

        if( show_data )
        begin
            for( int i = 0; i < DM_CAPACITY; i++ )
            begin
                tb_dm_mem[i] = $urandom_range( min, max );
                $display( " %8d ## [ SIMDE ][ DM ] Addr : %16d, Data : %8b_%8b_%8b_%8b ( %16d ) : { Testbench Local Debug }", $time, i, tb_dm_mem[i][31:24], tb_dm_mem[i][23:16], tb_dm_mem[i][15:8], tb_dm_mem[i][7:0], tb_dm_mem[i] );
            end
        end
    endtask
    
    task delay( integer dl = 0 );
        if( dl == 0 )
        begin
            #1;
        end
        else
        begin
            #(dl);
        end
    endtask
    
    task end_sim();
        $display( "Simulation has been terminated abruptly..." );
        $finish;
    endtask

endmodule
