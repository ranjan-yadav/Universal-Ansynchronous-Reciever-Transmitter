`timescale 1ns / 1ps

module UART_CODE(
    input iclk,
	 input tx_data_valid,
	 input [31:0] tx_byte,
	 output tx_active,
	 output reg tx_serial,
	 output tx_done,
	
    output rx_data_valid,
	 output reg [31:0] rx_byte
    );
	 
reg rx_serial; //ip to rx board 

parameter CLKS_PER_BIT=86;	 
//defining state machines
parameter TX_IDLE=4'b0000,
			 TX_START_BIT=4'b0001,
			 TX_DATA_BITS=4'b0010,
			 TX_STOP_BIT=4'b0011,
			 TX_CLEAN=4'b0100;
			 
//defining states machine 
parameter RX_IDLE=4'b1000,
			 RX_START_BIT=4'b1001,
			 RX_DATA_BITS=4'b1010,
			 RX_STOP_BIT=4'b1011,
			 RX_CLEAN=4'b1100;


reg [3:0] tx_state_machine =0;
reg [7:0] tx_clk_cnt=0;
reg [4:0] tx_bit_index=0;
reg [31:0] tx_data=0;
reg tx_done1 =0;
reg tx_active1=0;

always @(posedge iclk)
	begin
	
	case(tx_state_machine)
	TX_IDLE: begin
			tx_serial<=1'b1;
			rx_serial<=tx_serial;
			tx_done1<=0;
			tx_clk_cnt<=0;
			tx_bit_index<=0;
			
			if(tx_data_valid==1'b1)
			begin
				tx_active1<=1'b1;
				tx_data<=tx_byte;
				tx_state_machine<=TX_START_BIT;
				end
			else
				tx_state_machine<=TX_IDLE;
			end
	//send out start bit as zero
	
	TX_START_BIT: begin
			tx_serial<=1'b0;
			rx_serial<=tx_serial;
			
			//wait for 1 clk_per_bit
			if(tx_clk_cnt < CLKS_PER_BIT-1)
				begin
				tx_clk_cnt<=tx_clk_cnt+1;
				tx_state_machine<=TX_START_BIT;
				end
			else
				begin
				tx_clk_cnt<=0;
				tx_state_machine<=TX_DATA_BITS;
				end
			 end
			
	 TX_DATA_BITS : begin
					tx_serial<=tx_data[tx_bit_index];
					rx_serial<=tx_serial;
					
				if(tx_clk_cnt< CLKS_PER_BIT-1)
				 begin
					tx_clk_cnt<=tx_clk_cnt+1;
					tx_state_machine<=TX_DATA_BITS;
				 end
				else
					begin
						tx_clk_cnt<=0;
						
					if(tx_bit_index<31)
						begin
						tx_bit_index<=tx_bit_index+1;
						tx_state_machine<=TX_DATA_BITS;
						end
					else
						begin
							tx_bit_index<=0;
							tx_state_machine<=TX_STOP_BIT;
						end
				end
		 end
		 
		TX_STOP_BIT: begin
				tx_serial<=1'b1;
				
				//wait for 1 clksperbit to finish stop bit
				if(tx_clk_cnt<CLKS_PER_BIT-1)
					begin
					tx_clk_cnt<=tx_clk_cnt+1;
					tx_state_machine<=TX_STOP_BIT;
					end
				else
					begin
					tx_done1<=1'b1;
					tx_clk_cnt<=0;
					tx_state_machine<=TX_CLEAN;
					end
				end
				
			TX_CLEAN: begin
						tx_done1<=1'b1;
						tx_state_machine<=TX_IDLE;
					 end
			
			default: tx_state_machine<= TX_IDLE;
		endcase
	end
	assign tx_active=tx_active1;
	assign tx_done=tx_done1;

//////////rx/////////////////
reg rx_data=1'b1;
reg rx_data_R=1'b1;

reg [7:0] clk_cnt=0;
reg [4:0] bit_index =0;
reg [31:0] rx_byte1 =0;
reg  rx_dv=0;
reg [3:0] state_machine =0;

always @(posedge iclk)
	begin
		rx_data<=rx_serial;
		rx_data_R<=rx_data;
	end
	
always @(posedge iclk)
	begin
		 case(state_machine)
		 
		 RX_IDLE: begin
				 rx_dv <=1'b0;
				 clk_cnt<=0;
				 bit_index<=0;
				 
				 if(rx_data==1'b0)
						state_machine<=RX_START_BIT; ///moving to RX_START bit if 0 is detected
				 else
						state_machine<=RX_IDLE;
				 end
     
	   RX_START_BIT: begin
		           if(clk_cnt==(CLKS_PER_BIT)/2)
							begin
								if(rx_data==1'b0)
									begin 
										clk_cnt<=0;
										state_machine<=RX_DATA_BITS;
									end
								else
										state_machine<=RX_IDLE;
							end
		           else
					      begin
								clk_cnt<=clk_cnt +1;
								state_machine<= RX_START_BIT;
							end
					  end

     RX_DATA_BITS: begin
					  if(clk_cnt<CLKS_PER_BIT-1)
						begin
							clk_cnt<=clk_cnt+1;
							state_machine<=RX_DATA_BITS;
						end
					  else
							begin
							 clk_cnt<=0;
							 rx_byte1[bit_index]<=rx_data;
							 
							 if(bit_index<31) //checked
								begin
									bit_index<=bit_index+1;
									state_machine<=RX_DATA_BITS;
								end
								
							 else
								begin
									bit_index<=0;
									state_machine<=RX_STOP_BIT;
								end
						    end
                  end

		RX_STOP_BIT: begin
						if(clk_cnt<CLKS_PER_BIT-1)
							begin
								clk_cnt<=clk_cnt+1;
								state_machine<=RX_STOP_BIT;
							end
						 else
							 begin
							   rx_dv<=1'b1;
								clk_cnt<=0;
								state_machine<=RX_CLEAN;
							  end
					 end
					 
		RX_CLEAN: begin
					state_machine<=RX_IDLE;
					rx_dv<=1'b0;
				 end
		default: state_machine<=RX_IDLE;
	 
		endcase
end
 assign rx_data_valid=rx_dv;
 always @(negedge tx_done)
  begin
  rx_byte<=rx_byte1;
  end
endmodule
