`timescale 1ns/10ps

module LBP ( 
	input clk,
	input reset,
	
	output     [13:0] gray_addr,
	output reg        gray_req,
	input  		      gray_ready,
	input      [7:0]  gray_data,
	
	output reg 		  lbp_valid,
	output reg [13:0] lbp_addr,
	output reg [7:0]  lbp_data,
	output reg 		  finish
);
	localparam frame_width = 3;
	
	integer i;
	
	reg [7:0] gray_temp [0:8];
	
	reg [7:0] valid_pixel;
	reg [7:0] valid_value [7:0];
	
	reg [6:0] gray_x;
	reg [6:0] gray_y;
	reg [6:0] gray_xb;
	reg [6:0] gray_xb_temp;
	
	assign gray_addr = {gray_x+gray_xb, gray_y};
	
	reg gray_done;
	reg gray_valid;
	
	reg [1:0] shift_con;
	
	always@(posedge clk, posedge reset)begin
		if(reset)begin
			gray_req  <= 0;
			gray_done <= 0;
			gray_x    <= 0;
			gray_y    <= 0;
			gray_xb   <= 0;
		end else begin
			if(gray_ready & ~gray_done)gray_req <= 1; else gray_req <= 0;
			if(gray_xb==7'd125 && gray_x==7'd1 && gray_y==7'd127)gray_done <= 1;
			if(gray_req)begin
				if(gray_x==2)begin
					gray_x <= 0; 
					gray_y <= gray_y + 1;
					if(gray_y==127)gray_xb <= gray_xb + 1;
				end else begin
					gray_x <= gray_x + 1;
				end
			end
		end
	end
	
	// 
	always@(posedge clk, posedge reset)begin
		if(reset)begin
			for(i=0;i<9;i=i+1)gray_temp[i] <= 0;
			shift_con <= 0;
		end else begin
			if(gray_req)begin
				if(shift_con==2)shift_con <= 0; else shift_con <= shift_con + 1;
				if(shift_con==0)gray_temp[2] <= gray_data;
				if(shift_con==1)gray_temp[5] <= gray_data;
				if(shift_con==2)gray_temp[8] <= gray_data;
				if(shift_con==0)begin
					gray_temp[1] <= gray_temp[2];
					gray_temp[4] <= gray_temp[5];
					gray_temp[7] <= gray_temp[8];
					gray_temp[0] <= gray_temp[1];
					gray_temp[3] <= gray_temp[4];
					gray_temp[6] <= gray_temp[7];
				end
			end
		end
	end

	always@(*)begin
		for(i=0;i<4;i=i+1)if(gray_temp[i] >= gray_temp[4])valid_pixel[i] = 1; else valid_pixel[i] = 0; 
		for(i=5;i<9;i=i+1)if(gray_temp[i] >= gray_temp[4])valid_pixel[i-1] = 1; else valid_pixel[i-1] = 0; 
		for(i=0;i<8;i=i+1)if(valid_pixel[i])valid_value[i] = 8'd1 << i; else valid_value[i] = 0;
	end
	
	always@(posedge clk, posedge reset)begin
		if(reset)begin
			lbp_data <= 0;
		end else begin
			lbp_data <= valid_value[0] + valid_value[1] + valid_value[2] + valid_value[3] + valid_value[4] + valid_value[5] + valid_value[6] + valid_value[7];
		end
	end
	
	// outpute phase
	always@(posedge clk, posedge reset)begin
		if(reset)begin
			lbp_valid <= 0;
			lbp_addr  <= 14'd129;
			
			gray_xb_temp <= 0;
		end else begin
			if(lbp_valid)begin
				if(lbp_addr[6:0]==7'd126)begin
					lbp_addr[13:7] <= lbp_addr[13:7] + 1;
					lbp_addr[6:0]  <= 1;
				end	else begin
					lbp_addr[6:0] <= lbp_addr[6:0] + 1;
				end
			end
			if(gray_x==0 && gray_y>=3 || gray_xb_temp!=gray_xb)lbp_valid <= 1; else lbp_valid <= 0;
			if(gray_xb_temp!=gray_xb)gray_xb_temp <= gray_xb;
		end
	end
	
	// check finish or not using lbp_addr
	always@(posedge clk, posedge reset)begin
		if(reset)begin
			finish <= 0;
		end else begin
			if(lbp_addr[13:7]==7'd127 && lbp_addr[6:0]==7'd1)finish <= 1;
		end
	end

endmodule
