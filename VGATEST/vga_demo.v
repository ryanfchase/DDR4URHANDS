`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
/////////////////////////////////////////////////////////////////////////////////v/



module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r0, vga_r1, vga_r2, vga_g, vga_b, Sw0, Sw1, btnU, btnD, btnR, btnL,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);

	input ClkPort, Sw0, btnU, btnD, btnR, btnL, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r0, vga_r1, vga_r2, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r0, vga_r1, vga_r2, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////

	/* VGA Range = X:{0, 640}, Y:{0,480}*/

	/*****************************TODO***********************************
  	-Come up with a way of "generating" incoming arrows...
	 -Find out how to expand it from 3 color bits (RGB) to 8 color bits (R0R1R2, G0G1G2, B0B1B2)
	 -write code that sends an arrow (currently box) upwards (i.e.: YPos = YPos - 10)
	 -finish and test TASK that initializes target boxes
	 -FangZhou said FGPA boards come with SOME debouncing...we can save fine tuning for last 
	 -write arrow code to replace boxes
	*****************************\TODO***********************************/

	/* Local Constants*/ 
	localparam COLUMN_1 = 20;
	localparam COLUMN_2 = 50;
	localparam COLUMN_3 = 80;
	localparam COLUMN_4 = 110;

	localparam Y_TARGET = 40;

	/* Registers */ //(NON BLOCKING)//

	wire leftButtonTarget  = (CounterY >= (Y_TARGET-10) && CounterY <= (Y_TARGET+10)&& CounterX >= (COLUMN_1-10) && CounterX <= (COLUMN_1+10));

	wire upButtonTarget;   //    = (CounterY >= (Y_TARGET-10) && CounterY <= (Y_TARGET+10)&& CounterX >= (COLUMN_2-10) && CounterX <= (COLUMN_2+10));
	if (CounterX >= ( (COLUMN_3 - 10) && CounterX <= COLUMN_3)
		upButtonTarget = CounterY >= 10/5*(CounterX - (COLUMN_3 - 5)) + Y_TARGET + 10) && CounterY <= (Y_TARGET + 4);
	if (CounterX >= (COLUMN_3) && CounterX <= (COLUMN_3 + 5)
		upButtonTarget = CounterY >= -(10/5)*(CounterX - COLUMN_3) + Y_TARGET + 4 + 10 && CounterY <= (Y_TARGET+4);
	upButtonTarget = CounterX >= (COLUMN_3 - 5) && CounterX =< (COLUMN_3 + 5);
	wire rightButtonTarget = (CounterY >= (Y_TARGET-10) && CounterY <= (Y_TARGET+10)&& CounterX >= (COLUMN_3-10) && CounterX <= (COLUMN_3+10));
	wire downButtonTarget  = (CounterY >= (Y_TARGET-10) && CounterY <= (Y_TARGET+10)&& CounterX >= (COLUMN_4-10) && CounterX <= (COLUMN_4+10));


	reg [9:0] positionX;//remove
	reg [9:0] positionY;//remove

	/* Temporary Variables */ //(BLOCKING)//
	

	reg [9:0] tempX;//remove
	reg [9:0] tempY;//remove

	/******************* TASKS ***************************/

	
	task setAndDrawTargetBox;
		/* STATUS: Currently only draws squares --> evenutally will be drawn as an arrow */	

		input  [9:0] targetBox; //gets 'X' (position of the Column it is located in)
		output [9:0] color;     //color of the wire (corresponding to the VGA)
		begin

		color = color || 
			((CounterY >= (Y_TARGET  -10) && CounterY <= (Y_TARGET  +10)) &&
			(CounterX >= (targetBox -10) && CounterX <= (targetBox +10)));

		end
	endtask

	/******************** END TASKS ***********************/
	
	always @(posedge DIV_CLK[21])
	begin
	/* VGA Range = X:{0, 640}, Y:{0,480}*/
		
		
		/* INITIALIZE */
		if(reset)
		begin
			tempX = 20;
			tempY = 470;
		end
		
		
		
		
		
		/* UPDATE */
		tempY = tempY - 6;
		
		/* LIMIT BORDERS */
		if(tempY <= 0)
			tempY = 490;
		if(tempY >= 490)
			tempY = 490;
		tempX = 20;
		
		positionX <= tempX;
		positionY <= tempY;
	end


	wire R = // (CounterY>=(positionY-10) && CounterY<=(positionY+10) &&// CounterX[8:5]==7;
			 //  CounterX >= (positionX-10) && CounterX <= (positionX+10)) ;	
	
	wire G = leftButtonTarget | upButtonTarget | rightButtonTarget | downButtonTarget;
	wire B = 0;
	
	always @(posedge clk)
	begin
		vga_r0 <= R & inDisplayArea;
		vga_r1 <= R & inDisplayArea;		
		vga_r2 <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/*-remove-
		if(btnD)
			tempY = tempY+2;
		if(btnU)
			tempY = tempY-2;
		if(btnR)
			tempX = tempX+2;
		if(btnL)
			tempX = tempX-2;
		-end remove-*/
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////


	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == `QI);
	assign LD5 = (state == `QGAME_1);	
	assign LD6 = (state == `QGAME_2);
	assign LD7 = (state == `QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = 4'b1111;//positionY[3:0]; //dunno if i have to change anything here /////////////////////////////////////////////////////////////////////////
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
