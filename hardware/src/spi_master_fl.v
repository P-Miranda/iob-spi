`timescale 1ns / 1ps
`include "iob_lib.vh"
`define SPI_DATA_W 32 
`define SPI_COM_W 8
`define SPI_CTYP_W 3
`define SPI_ADDR_W 32
`define SPI_DATA_MINW 8

module spi_master_fl
#(
	parameter	CLKS_PER_HALF_SCLK=2
	)
(
	
	//CONTROLLER INTERFACE
	input		clk,
	input 		rst,

	//CONTROLLER FROM CPU
	input [`SPI_DATA_W-1:0]				data_in,
	output reg [`SPI_DATA_W-1:0]		data_out,
	input [`SPI_ADDR_W-1:0]				address,
	input [`SPI_COM_W-1:0]				command,
	input 								validflag,
	input [`SPI_CTYP_W-1:0]				commtype,
	input [6:0]							nmiso_bits,	
	output reg							validflag_out,
	output reg							tready,

	//SPI INTERFACE
	//output	  	sclk,
	output reg		sclk,
	//output reg	ss,
	output		ss,
	output reg	mosi,
	input		miso,
	output		wp_n,
	output		hold_n
);

	//Register TX data, address, command
	reg [`SPI_DATA_W-1:0]	r_datain;
	reg [`SPI_ADDR_W-1:0]	r_address;
	reg [`SPI_COM_W-1:0]	r_command;

	//Extra reg for mode controlling
	reg	[2:0]	r_commandtype;
	reg			r_4byteaddr_on = 1'b0;
	reg [7:0]	r_counterstop;
	reg [6:0]	r_misoctrstop;

	//MOSI controller signals
	reg [7:0]	r_mosicounter;
	//wire [63:0]	str2send;//Parameterize
	reg [71:0]	r_str2sendbuild;

	//MISO controller signals
	reg [6:0]				r_misocounter;
	reg [`SPI_DATA_W-1:0]	r_misodata;
	reg	[6:0]				r_nmisobits;
	
	//Synchronization signals
	reg	 r_expct_answer = 1'b0;	
	reg  r_inputread = 1'b0;

	reg	 r_validedge = 1'b0;
	reg [1:0] r_validoutHold = 2'b10;

	//SCLK generation signals
	//reg [5:0] sclk_period = 6'd0;
	//wire [5:0] sclk_halfperiod;
	reg			r_setup_start;
	reg			r_counters_done;
	reg			r_build_done;
	reg			r_transfers_done;
	reg			r_mosifinish;
	reg			r_misofinish;
	reg			r_setup_rst;
	reg			r_sending_done; 

	reg			wp_n_int;
	reg			hold_n_int;
	
	reg [8:0]	r_sclk_edges_counter;

	reg 		sclk_ne;
	reg			sclk_pe;
	reg			r_sclk_out_en;
	reg									sclk_int;
	reg [$clog2(CLKS_PER_HALF_SCLK*2)-1:0]			clk_counter;

	reg [8:0]							r_sclk_edges;
	reg			r_transfer_start;
	
	//assign sclk_halfperiod = {1'b0, sclk_period[5:1]};

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			sclk_ne <= 1'b0;
			sclk_pe <= 1'b0;
			sclk_int <= 1'b0;
			clk_counter <= 0; 
			r_sclk_edges_counter <= 9'h0;
			r_transfers_done <= 1'b0;
		end else begin
			if (r_transfer_start) begin
					if(r_sclk_edges_counter > 0) begin
						if (clk_counter == CLKS_PER_HALF_SCLK-1) begin
							sclk_ne <= 1'b1;
							sclk_pe <= 1'b0;
							r_sclk_edges_counter <= r_sclk_edges_counter - 1'b1;
							if (r_sclk_out_en) sclk_int <= 1'b0;
							clk_counter <= clk_counter + 1'b1;
						end else if (clk_counter == CLKS_PER_HALF_SCLK*2-1) begin
							sclk_ne <= 1'b0;
							sclk_pe <= 1'b1;
							r_sclk_edges_counter <= r_sclk_edges_counter - 1'b1;
							if (r_sclk_out_en) sclk_int <= 1'b1;
							clk_counter <= clk_counter + 1'b1;
						end else begin
							sclk_ne <= 1'b0;
							sclk_pe <= 1'b0;
							clk_counter <= clk_counter + 1'b1;
						end
					end else begin
						r_transfers_done <= 1'b1;
						sclk_pe <= 1'b0;
						sclk_ne <= 1'b0;
					end
			end else begin
				sclk_int <= 1'b1; //Initial sclk polarity
				sclk_ne <= 1'b0;
				sclk_pe <= 1'b0;
				clk_counter <= 0; 
				r_transfers_done <= 1'b0;
				r_sclk_edges_counter <= r_sclk_edges;
			end
		end
	end
	// Assign output
	//assign sclk = sclk_int;
	always @(posedge rst, posedge clk) begin
		if (rst) sclk <= 1'b1; //default
		else sclk <= sclk_int;
	end

	//Drive wp_n and hold_n
	always @(posedge rst, posedge clk) begin
		if (rst) begin
			wp_n_int <= 1'b1;
			hold_n_int <= 1'b1;
		end else begin
			wp_n_int <= 1'b1;
			hold_n_int <= 1'b1;
		end
	end
	assign wp_n = wp_n_int;
	assign hold_n = hold_n_int;
	
	//Receive data to transfer from upperlevel controller
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			r_datain <= `SPI_DATA_W'b0;
			r_address <= `SPI_ADDR_W'b0;
			r_command <= `SPI_COM_W'b0;
			r_commandtype <= `SPI_CTYP_W'b111;
			r_inputread <= 1'b0;
			r_nmisobits <= 7'd32;
		end else begin
			if (r_validedge) begin
				r_datain <= data_in;
				r_address <= address;
				r_command <= command;
				r_commandtype <= commtype;
				r_nmisobits <= nmiso_bits;
				r_inputread <= 1'b1;
			end
			else if (~validflag) begin
				r_inputread <= 1'b0;
			end//TODO reset r_nmisobits for idle states (default)
		end
	end

	// Register inputs
	always @(posedge rst, posedge clk) begin
		if (rst) begin
			r_validedge <= 1'b0;
		end
		else begin
			if (validflag && (~r_inputread) && (~r_validedge)) begin
				r_validedge <= 1'b1;
			end else begin
				r_validedge <= 1'b0;
			end
		end
	end

	//Build r_str2sendbuild
	always @(posedge rst, posedge clk) begin
		if (rst) begin
			r_str2sendbuild <= 72'h0;
			r_build_done <= 1'b0;
		end else begin
			r_build_done <= 1'b0;
			if (r_setup_start) begin
					r_build_done <= 1'b1;
					if (~r_4byteaddr_on) begin
						r_str2sendbuild <= (r_commandtype == 3'b011) ? {r_command, data_in, {32{1'b0}}}: {r_command, r_address[23:0], r_datain, {8{1'b0}}};
					end else begin
						r_str2sendbuild <= (r_commandtype == 3'b011) ? {r_command, data_in, {32{1'b0}}}: {r_command, r_address, r_datain};
					end
			end
		end
	end

		
	//Drive mosi
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			mosi <= 1'b0;
			r_mosicounter <= 8'd71;
			r_mosifinish <= 1'b0;
			r_sending_done <= 1'b0;
		end else begin
			//if(r_transfer_start) begin end
			if (sclk_ne && r_sclk_out_en && (~r_mosifinish)) begin
				mosi <= r_str2sendbuild[r_mosicounter];
				r_mosicounter <= r_mosicounter - 1'b1;
				if(r_mosicounter == r_counterstop) begin
					r_mosicounter <= 8'd71;
					r_sending_done <= 1'b1;
				end
			end
			if (r_sending_done && sclk_pe) begin
				r_mosifinish <= 1'b1;
			end
			if (r_setup_rst) begin
				r_mosifinish <= 1'b0;
				r_sending_done <= 1'b0;
			end
		end
	end
	
	//Drive miso
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			r_misodata <= 32'd0;
			r_misocounter <= 7'd31;
			r_misofinish <= 1'b0;
		end else begin
			if(sclk_pe && r_sclk_out_en && (r_mosifinish)) begin
				r_misodata[r_misocounter] <= miso;
				r_misocounter <= r_misocounter - 1'b1;
				if (r_misocounter == r_misoctrstop) begin
					r_misocounter <= 7'd31; 
					r_misofinish <= 1'b1;
				end
			end
			if (r_setup_rst) begin
				r_misofinish <= 1'b0;
			end
		end
	end

	
	//Drive validflag_out to make as pulse
	always @(posedge rst, negedge sclk) begin
		if(rst) begin
			validflag_out <= 1'b0;
		end else if (r_misofinish) begin
			validflag_out <= 1'b1;
		end else if (r_validoutHold == 2'b00) begin
			validflag_out <= 1'b0;
		end	
	end
	
	//Drive validflag_out to make as pulse
	//Synchro it to which clk?
	always @(posedge rst, negedge sclk) begin//allow more clks for polling? yes it's needed, but exactly how many?
		if (rst) begin 
			r_validoutHold <= 2'b10;
		end else begin
			if (validflag_out == 1'b1) begin	
				r_validoutHold <= r_validoutHold - 1'b1;
				if (r_validoutHold == 2'b00) begin
					r_validoutHold <= 2'b10;
				end
			end
		end
	end
	
	//MUX
	//Master State Machine
	always @(posedge rst, posedge clk) begin
		if (rst) begin
			r_expct_answer <= 1'b0;
			r_counterstop <= 8'd64;
			r_misoctrstop <= 7'd0;
			r_sclk_edges <= 0;
			r_counters_done <= 1'b0;
		end else begin
			r_counters_done <= 1'b0;
			if (r_setup_start) begin
					r_counters_done <= 1'b1;
					case(r_commandtype)
						3'b000:	begin//Only command
								r_counterstop <= 8'd64;
								r_expct_answer <= 1'b0;
								r_sclk_edges <= {8'd8, 1'b0};
							end
						3'b001: begin//command + answer
								r_counterstop <= 8'd64;
								r_expct_answer <= 1'b1;
								r_misoctrstop <= 7'd32 - r_nmisobits;
								r_sclk_edges <= {8'd8 + r_nmisobits, 1'b0};
							end
						3'b010: begin//command + address + answer
								r_counterstop <= (~r_4byteaddr_on) ? 8'd40: 8'd32;
								r_expct_answer <= 1'b1;
								r_misoctrstop <= 7'd32 - r_nmisobits;
								r_sclk_edges <= (~r_4byteaddr_on)?{8'd8+r_nmisobits+8'd24, 1'b0}:{8'd8+r_nmisobits+8'd32};
							end
						3'b011:	begin//command + data_in
								r_counterstop <= 8'd32;
								r_expct_answer <= 1'b0;
								r_sclk_edges <= {8'd40,1'b0};
							end
						3'b100: begin//command + address + data_in
								r_counterstop <= (~r_4byteaddr_on) ? 8'd8: 8'd0;
								r_expct_answer <= 1'b0;
								r_sclk_edges <= (~r_4byteaddr_on)?{8'd64,1'b0}:{8'd72,1'b0};
							end
						3'b101: begin//command+address
								r_counterstop <= (~r_4byteaddr_on) ? 8'd40: 8'd32;
								r_expct_answer <= 1'b0;
								r_sclk_edges <= (~r_4byteaddr_on)?{8'd32,1'b0}:{8'd40,1'b0};
							end
					default:	begin
								r_counterstop <= 8'd32;
								r_expct_answer <= 1'b0;//TODO other control signals default
								r_sclk_edges <= {8'd8, 1'b0};
							end
					endcase
			end
		end
	end
	
	//Assert ss
	assign ss = r_ss_n;
	
	//Master State Machine
	reg [2:0]		r_currstate;
	localparam IDLE = 3'h0;
	localparam SETUP = 3'h1;
	localparam TRANSFER = 3'h2;
	reg	r_ss_n;
	always @(posedge rst, posedge clk) begin
		if (rst) begin
			r_currstate <= IDLE;
			r_sclk_out_en <= 1'b0;
			r_ss_n <= 1'b1;
			r_transfer_start <= 1'b0;
			r_setup_start <= 1'b0;
			r_setup_rst <= 1'b0;
			tready <= 1'b1;
			data_out <= 0;
		end else begin
			
			case(r_currstate)

				IDLE:
				begin
					//default
					tready <= 1'b1;
					r_sclk_out_en <= 1'b0;
					r_ss_n <= 1'b1;
					r_transfer_start <= 1'b0;
					if(r_validedge) begin
						r_setup_rst <= 1'b1;
						r_setup_start <= 1'b1;
						data_out <= 0;
						tready <= 1'b0;
						r_currstate <= SETUP;
					end
				end

				SETUP:
				begin
					r_setup_rst <= 1'b0;
					r_transfer_start <= 1'b0;
					r_setup_start <= 1'b0;
					tready <= 1'b0;
					if(r_build_done && r_counters_done) begin
						r_transfer_start <= 1'b1;
						r_ss_n <= 1'b0;
						//r_sclk_out_en <= 1'b1;
						r_currstate <= TRANSFER;
					end
				end

				TRANSFER:
				begin
					r_ss_n <= 1'b0;
					r_sclk_out_en <= 1'b1;
					tready <= 1'b0;
					if(r_transfers_done) begin
						r_ss_n <= 1'b1;
						r_sclk_out_en <= 1'b0;
						data_out <= r_misodata;
						r_currstate <= IDLE;
					end
				end

				default:
				begin
					r_sclk_out_en <= 1'b0;
					r_ss_n <= 1'b1;
					tready <= 1'b1;
					data_out <= 0;
					r_currstate <= IDLE;
				end
			endcase
		end
	end
endmodule
