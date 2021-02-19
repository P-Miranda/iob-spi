`timescale 1ns / 1 ps

module spi_tb;
	
	parameter clk_per = 20;
	parameter sclk_per = 40;

	reg rst;
	reg clk;

	reg miso;
	wire mosi;
	wire ss;
	reg sclk;
	
	reg [31:0] data_in;
	wire [31:0] data_out;
	reg [31:0] address;
	reg [7:0] command;
	reg [2:0] commtype;
	reg [6:0] nmiso_bits;
	reg [3:0] dummy_cycles;
    reg [9:0] frame_struct;
	reg validflag; //check later
	wire validflag_out; //check
	wire tready;
	reg tofrom_fl;

	integer i;
	reg [31:0]	mem;

	//Controller signals
	
	// UUT Instantiation
	spi_master_fl 
	#(.CPOL(1), .CPHA(1))
	spi_m (
			.clk		(clk),
			.rst		(rst),

			//SPI
			.ss			(ss),
			.mosi_dq0		(mosi),
			.sclk		(sclk),
			.miso_dq1		(miso),
			
			//Controller
			.data_in	(data_in),
			.data_out	(data_out),
			.address	(address),
			.command	(command),
			.commtype	(commtype),
			.ndata_bits	(nmiso_bits),
            .frame_struct (frame_struct),
			.dummy_cycles (dummy_cycles),
			.validflag	(validflag),
			.validflag_out	(validflag_out),
			.tready		(tready)
			);
			

	//Process
	initial begin
		$dumpfile("spi_fl_tb.vcd");
		$dumpvars();
		//$dumpvars(0,spi_tb.spi_m.r_spistr2send[0]);
		//$dumpvars(0,spi_tb.spi_m.r_spistr2send[1]);
		
		//Clks and reset
		rst = 1;
		clk = 1;
		//sclk = 1;

		//Deassert rst
		#(4*clk_per+1) rst = 0;

	end

	//Master Process
	initial begin
		#100
		data_in=32'h5A000000;
		command=8'h5A;
		address=24'h555555;
		commtype = 3'b100;
		nmiso_bits = 7'd8;
        frame_struct = 10'h000;
		dummy_cycles = 4'd0;
		mem	= 32'hA0A0A0A3;

		#50
		validflag=1'b1;
		#20
		validflag=1'b0;
		#370// Drive miso
		for(i=15;i>=0;i=i-1) begin
			#40;
			//miso <= mem[i];
		end
	    //#3000	
        
        wait(tready);
        #120
        //New command
        data_in=8'h5A;
		command=8'hA3;
		address=24'h555555;
		commtype = 3'b010;
        frame_struct = 10'h004;
		nmiso_bits = 7'd8;
		dummy_cycles = 4'd0;
		mem	= 32'hA0A0A0A3;
		#50
		validflag=1'b1;
		#20
		validflag=1'b0;
		//#370// Drive miso

		#3000 
        wait(tready);
        #100 $finish;
	end

	//CLK driving
	always
		#(clk_per/2) clk=~clk;
	
	//always
		//#(clk_per/4) sclk=~sclk;
endmodule
