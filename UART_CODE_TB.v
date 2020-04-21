module UART_CODE_TB();
parameter CLKS_PER_BIT=86;
parameter BIT_PERIOD=8600; // 1/baudrate (in ns)
parameter CLK_PERIOD=100;
	// Inputs
	reg iclk=0;
	reg tx_data_valid=0;
	reg [31:0] tx_byte=0;

	// Outputs
	wire tx_active;
	wire tx_serial;
	wire tx_done;
	wire rx_data_valid;
	wire [31:0] rx_byte;

	// Instantiate the Unit Under Test (UUT)
	UART_CODE uut (
		.iclk(iclk), 
		.tx_data_valid(tx_data_valid), 
		.tx_byte(tx_byte), 
		.tx_active(tx_active), 
		.tx_serial(tx_serial), 
		.tx_done(tx_done), 
		.rx_data_valid(rx_data_valid), 
		.rx_byte(rx_byte)
	);

always #(CLK_PERIOD/2) iclk<=!iclk;

//main testing
initial
 begin
	@(posedge iclk);
   @(posedge iclk); //uart_transmitter
		tx_data_valid<=1'b1;
		tx_byte<=32'b00001111001111001100001111110000;
	@(posedge iclk);
	    tx_data_valid<=1'b0;
	@(posedge tx_done);
	
	 tx_data_valid<=1'b0;
	
	@(posedge iclk);
   @(posedge iclk); //uart_transmitter
		tx_data_valid<=1'b1;
		tx_byte<=32'hFFFFFFFF;
	@(posedge iclk);
	    tx_data_valid<=1'b0;
	@(posedge tx_done);
	 end
endmodule

