`timescale 1ns / 1ps
`include "spi_defines.vh"

module spi_tb;

   parameter sclk_per= 24;
   parameter clk_per= 20;
   
   reg 		rst;
   reg 		clk;
   
   //spi signals
   reg 			 sclk;
   wire 		 miso;
   wire 		 mosi;
   wire 		 ss;   
   

   //spi master control
   reg [`SPI_ADDR_W-1:0] m_address;
   reg [`SPI_DATA_W-1:0] m_data_in;
   reg 			 m_sel;
   reg 			 m_read;
   reg 			 m_write;
   wire [`SPI_DATA_W-1:0] m_data_out;
   wire 		  m_interrupt;

   //spi slave control
   reg [`SPI_ADDR_W-1:0] s_address;		
   reg 			  s_sel;
   reg                    s_read;
   reg 			  s_write;			
   wire [`SPI_DATA_W-1:0] s_data_out;
   reg [`SPI_DATA_W-1:0]  s_data_in; 
   wire 		  s_interrupt;		


   // Instantiate the Units Under Test (UUTs)
   spi_master spi_m (
		     .clk		(clk),
		     .rst		(rst),
		     
		     // SPI 
		     .ss		(ss),
		     .mosi		(mosi),
		     .sclk		(sclk),
		     .miso		(miso),
		     
		     // CONTROL
		     .data_in		(m_data_in),
		     .address		(m_address),
		     .data_out		(m_data_out),
		     .interrupt		(m_interrupt),
		     .sel		(m_sel),
		     .read		(m_read),
		     .write		(m_write)
                     );
   
   spi_slave spi_s (
		    .clk		(clk),
		    .rst		(rst),

		    // SPI 
		    .miso		(miso),
		    .sclk		(sclk),
		    .ss			(ss),
		    .mosi		(mosi),
		    
		    // CONTROL
		    .data_out		(s_data_out[`SPI_DATA_W-1:0]),
		    .interrupt		(s_interrupt),
		    .data_in		(s_data_in[`SPI_DATA_W-1:0]),
		    .address		(s_address[`SPI_ADDR_W-1:0]),
		    .sel		(s_sel),
		    .read		(s_read),
		    .write		(s_write)
                    );

 
   // general process  
   initial begin
      $dumpfile("spi_tb.vcd");
      $dumpvars();

      // assert clocks and reset
      rst = 1;
      clk = 1;
      sclk = 1;

      // deassert reset
      #(2*clk_per+1) rst = 0;
      

   end
   

   //
   // MASTER PROCESS
   //

   //cpu read word
   reg [31:0] mreg;
    
   initial begin
      
      m_sel = 0;
      m_read = 0;
      m_write = 0;

      //sync up 
      #(10*sclk_per);
      @(posedge clk) #1;
      

      // POLLING TEST 

      // write word to send
      cpu_mwrite(`SPI_TX, 32'hf0f0f0f0);

      // wait spi master ready
      cpu_mread (`SPI_READY, mreg);
      while(!mreg) 
        cpu_mread (`SPI_READY, mreg);

      $display("Poll test, word 1 sent");

      //write something to sent next and get response     
      cpu_mwrite(`SPI_TX, 32'h0);
      
      // wait spi master ready
      cpu_mread (`SPI_READY, mreg);
      while(!mreg) 
        cpu_mread (`SPI_READY, mreg);

      // read word, compare with expected and clear ready
      cpu_mread (`SPI_RX, mreg);
      if(mreg != 32'hF0F0F0F0) begin
	 $display("Polling test failed");
	 $finish;
      end else
        $display("Poll test, word 1 received");
      


      // INTERRUPT TEST 

      // write word to send next
      cpu_mwrite(`SPI_TX, 32'hABABABAB);

      // enable interrupt
      cpu_mwrite(`SPI_INTRRPT_EN, 32'h1);
      
      // wait interrupt on word sent
      while(~m_interrupt)
	@(posedge clk) #1;

      $display("Interrupt test, word 1 sent");
      
      // disable interrupt
      cpu_mwrite(`SPI_INTRRPT_EN, 32'h0);

      // send someting to get response
      cpu_mwrite(`SPI_TX, 32'h0);

      // enable interrupt
      cpu_mwrite(`SPI_INTRRPT_EN, 32'h1);
      
      // wait interrupt on word sent
      while(~m_interrupt)
	@(posedge clk) #1;

      // disable interrupt
      cpu_mwrite(`SPI_INTRRPT_EN, 32'h0);

      cpu_mread (`SPI_RX, mreg);

      if(mreg != 32'hABABABAB)
        $display("Interrupt test failed: expected 32'hABABABAB, got %x", m_data_out);
      else begin 
        $display("Interrupt test, word 1 received\n\n\n");
        $display("Test Passed!");
      end
      $finish;
      
   end


   //
   // SLAVE PROCESS
   //

   //cpu read word
   reg [31:0]   sreg;
    
   initial begin

      s_sel = 0;
      s_read = 0;
      s_write = 0;

      //
      // POLLING TEST 
      //
      
      // poll SPI_READY address until word received
      cpu_sread (`SPI_READY, sreg);
      while(!sreg) 
        cpu_sread (`SPI_READY, sreg);

      // read word and clear ready
      cpu_sread (`SPI_RX, sreg);
   
      // write word to send it back to master 
      cpu_swrite (`SPI_TX, sreg);

  
      // poll SPI_READY address until word sent
      cpu_sread (`SPI_READY, sreg);
      while(!sreg) 
        cpu_sread (`SPI_READY, sreg);

    
      // read nop word to clear ready
      cpu_sread (`SPI_RX, sreg);



      //
      // INTERRUPT TEST 
      //
      
      // enable interrupt
      cpu_swrite (`SPI_INTRRPT_EN, 1);
 
      // wait for interrupt until data is received
      while(~s_interrupt)
 	@(posedge clk) #1;
     
      // read word and clear interrupt
      cpu_sread (`SPI_RX, sreg);
 
      // write word to send it back to master
      cpu_swrite (`SPI_TX, sreg);
 
 
      // wait for interrupt on word is sent and nop received
      while(~s_interrupt)
  	@(posedge clk) #1;

      // read nop to clear interrupt 
      cpu_sread (`SPI_RX, sreg);

  end

   
   //
   // CLOCKS 
   //
   
   always
     #(sclk_per/2) sclk = ~sclk;
   
   always
     #(clk_per/2) clk = ~clk;

 
   
   // TASKS

   // 1-cycle write
   task cpu_mwrite;
      input [2:0]  cpu_address;
      input [31:0]  cpu_data;

      #1 m_address = cpu_address;
      m_sel = 1;
      m_write = 1;
      m_data_in = cpu_data;
      @ (posedge clk) #1 m_write = 0;
      m_sel = 0;
   endtask

  // 1-cycle write
   task cpu_swrite;
      input [2:0]  cpu_address;
      input [31:0] cpu_data;

      # 1 s_address = cpu_address;
      s_sel = 1;
      s_write = 1;
      s_data_in = cpu_data;
      @ (posedge clk) #1 s_write = 0;
      s_sel = 0;
   endtask


   // 2-cycle read
   task cpu_mread;
      input [2:0]   cpu_address;
      output [31:0] mreadreg;

      #1 m_address = cpu_address;
      m_sel = 1;
      m_read = 1;
      @ (posedge clk) #1 m_read = 1;
      mreadreg = m_data_out;
      @ (posedge clk) #1 m_read = 0;
      m_sel = 0;
   endtask

   task cpu_sread;
      input [2:0]   cpu_address;
      output [31:0] sreadreg;

      # 1 s_address = cpu_address;
      s_sel = 1;
      s_read = 1;
      @ (posedge clk) #1 s_read = 1;
      sreadreg = s_data_out;
      @ (posedge clk) #1 s_read = 0;
      s_sel = 0;
   endtask

endmodule

