// Standard Macros
//---------------------------------------------------------------D Flip Flop-------------------------------------------------------------

module dff #(
  parameter FLOP_WIDTH  = 3,
  parameter RESET_VALUE = 'b0
)(
  input wire  clk,
  input wire  reset_b,
  input wire  [FLOP_WIDTH-1 : 0]d,
  
  output reg [FLOP_WIDTH-1 : 0]q
);

  always @(posedge clk or negedge reset_b) begin
    if(~reset_b) begin
      q[FLOP_WIDTH-1 : 0] <= RESET_VALUE;
    end
    else begin
      q[FLOP_WIDTH-1 : 0] <= d[FLOP_WIDTH-1 : 0];
    end
  end

endmodule

//------------------------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------D Flip Flop synch reset------------------------------------------------------------
module dffs #(
  parameter FLOP_WIDTH  = 3,
  parameter RESET_VALUE = 'b0
)(
  input wire  clk,
  input wire  reset_b,
  input wire  [FLOP_WIDTH-1 : 0]d,
  
  output reg [FLOP_WIDTH-1 : 0]q
);

  always @(posedge clk) begin
    if(~reset_b) begin
      q[FLOP_WIDTH-1 : 0] <= RESET_VALUE;
    end
    else begin
      q[FLOP_WIDTH-1 : 0] <= d[FLOP_WIDTH-1 : 0];
    end
  end

endmodule
//------------------------------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------T Flip Flop----------------------------------------------------------
module tff #(
	parameter 													RESET_VALUE = 1'b0
)(
  input wire  clk,
  input wire  reset_b,
  input wire  t,
  input wire  clear,
  
  output reg q
);

  always @(posedge clk or negedge reset_b) begin
    if(~reset_b) begin
      q <= RESET_VALUE;
    end
    else begin
      q <= clear ? 1'b0 : (t ? ~q : q);
    end
  end

endmodule
//-------------------------------------------------------------------------------------------------------------------------------------

//--------------------------------------------------------------- Counter--------------------------------------------------------------
module counter #(
	parameter 													RESET_VALUE = 1'b0,
	parameter														COUNTER_WIDTH = 1
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												clear,
	input wire                         en,
	
	output reg[COUNTER_WIDTH - 1 : 0] count
);


	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			count[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			count[COUNTER_WIDTH-1 : 0] <= clear ? {COUNTER_WIDTH{RESET_VALUE}} : count + en;
		end
	end

endmodule
//----------------------------------------------------------------------------------------

//Mod N counter
module mod_n_counter #(
	parameter RESET_VALUE = 1'b0,
	parameter	COUNTER_WIDTH = 1
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire[COUNTER_WIDTH - 1 : 0] 	n,
	input wire 												clear,
	output reg[COUNTER_WIDTH - 1 : 0] count
);

	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			count[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			count[COUNTER_WIDTH-1 : 0] <= clear | (count + 1'b1 == n) ? {COUNTER_WIDTH{RESET_VALUE}} : count + 1'b1;
		end
	end

endmodule
//---------------------------------------------------------------------------------------------------------------



//8 to 1 MUX
module mux8to1 (
  input wire  in0,
  input wire  in1,
  input wire  in2,
  input wire  in3,
  input wire  in4,
  input wire  in5,
  input wire  in6,
  input wire  in7, 
  input wire [2:0] sel,      
  output reg data_out        
);

  always @(*) begin
    casez (sel)
      3'b000: data_out = in0;
      3'b001: data_out = in1;
      3'b010: data_out = in2;
      3'b011: data_out = in3;
      3'b100: data_out = in4;
      3'b101: data_out = in5;
      3'b110: data_out = in6;
      3'b111: data_out = in7;
      default: data_out = 'bx;
    endcase
  end

endmodule


//---------------------------------------------------------------------------------------------------------------

//Updown Counter
module updown_counter #(
	parameter 													RESET_VALUE = 1'b0,
	parameter														COUNTER_WIDTH = 1
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												clear,
	input wire                         en,
	input wire                         dir,
	
	output reg[COUNTER_WIDTH - 1 : 0] count
);


	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			count[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			count[COUNTER_WIDTH-1 : 0] <= clear ? {COUNTER_WIDTH{RESET_VALUE}} :  (dir  ? count-en : count+en) ;
		end
	end

endmodule

//---------------------------------------------------------------------------------------------------------------




//--------------------------------------------------------------- Counter with load--------------------------------------------------------------
module counter_ld #(
	parameter 													RESET_VALUE = 1'b0,
	parameter														COUNTER_WIDTH = 1
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												clear,
	input wire                         load,
	input wire                         en,
	input wire[COUNTER_WIDTH - 1 : 0] load_data,
	
	output reg[COUNTER_WIDTH - 1 : 0] count
);


	always@(posedge clk or negedge reset_b) begin
		if(~reset_b)begin
			count[COUNTER_WIDTH-1 : 0] <= {COUNTER_WIDTH{RESET_VALUE}};
		end
		else begin
			count[COUNTER_WIDTH-1 : 0] <= clear ? {COUNTER_WIDTH{RESET_VALUE}} : load ? load_data : count - en;
		end
	end

endmodule
//----------------------------------------------------------------------------------------

//-------------------------------Positive Edge Detector--------------------------------------------
  module posedge_detector (
  
  input wire clk,
  input wire reset,
  input wire in,
  
  output wire pos_edge

);

  wire q;
  
  dff #(
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u_psr(  
    .clk     ( clk     ),
    .reset_b ( reset  ),
    .d       ( in  ),
    .q       ( q  )
  );
  
  assign pos_edge = in & ~q;
  
  endmodule
//----------------------------------------------------------------------------------------

//-------------------------------Negative Edge Detector-----------------------------------
 module negedge_detector (
  
  input wire clk,
  input wire reset,
  input wire in,
  
  output wire neg_edge

);

  wire q;
  
  dff #(
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u_psr(  
    .clk     ( clk     ),
    .reset_b ( reset  ),
    .d       ( in  ),
    .q       ( q  )
  );
  
  assign neg_edge = ~in & q;
  
  endmodule
//-------------------------------------------------------------------------------------


//-------------------------------Both Edge Detector-----------------------------------
 module edge_detector (
  
  input wire clk,
  input wire reset_b,
  input wire in,
  
  output wire out

);

  wire q;
  
  dff #(
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u_psr(  
    .clk     ( clk     ),
    .reset_b ( reset_b ),
    .d       ( in      ),
    .q       ( q       )
  );
  
  assign out = in ^ q;
  
  endmodule
//-------------------------------------------------------------------------------------



// serial in, parallel in, serial out parallel out right shift register
// (UNIVERSAL)
module right_shift_register #(
    parameter WIDTH = 8  
)(
    input wire              clk,              
    input wire              reset_b,            
    input wire              shift_en,            
    input wire              serial_in,        
    input wire  [WIDTH-1:0] load_data, 
    input wire              load_en,    
    output reg [WIDTH-1:0] q,
    output wire             serial_out
);

   
    always @(posedge clk or negedge reset_b) begin
        if (~reset_b) begin
            q[WIDTH-1 : 0] <= {WIDTH{1'b0}};  
        end 
        else begin
            q[WIDTH-1 : 0] <= load_en ? load_data[WIDTH-1 : 0] : ( shift_en ? {serial_in, q[WIDTH-1:1]} : q[WIDTH-1:0] ) ;  
        end
    end
    assign serial_out = q[0];
    
endmodule



//Shift Regsiter
module shift_reg #(
	parameter 													RESET_VALUE = 'b0,
	parameter														REG_WIDTH = 8
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												clear,
	input wire                         shift_en,
	input wire                         dir,
	
	output reg[REG_WIDTH - 1 : 0] q
);


	always@(posedge clk or negedge reset_b) begin
	
		if(~reset_b)begin
			q[REG_WIDTH-1 : 0] <= {REG_WIDTH{RESET_VALUE}};
		end
		
		else begin
			q[REG_WIDTH-1 : 0] <= clear ? {REG_WIDTH{RESET_VALUE}} :  (dir  ? q << shift_en : q >> shift_en) ;
		end
	end

endmodule

// shift Register with load
module shift_reg_wload #(
	parameter 													RESET_VALUE = 'b0,
	parameter														REG_WIDTH = 8
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												load,
	input wire                         shift_en,
	input wire                         dir,
	input wire       [REG_WIDTH-1 : 0] data_in,
	
	output reg    [REG_WIDTH - 1 : 0] q
);


	always@(posedge clk or negedge reset_b) begin
	
		if(~reset_b)begin
			q[REG_WIDTH-1 : 0] <= {REG_WIDTH{RESET_VALUE}};
		end
		
		else begin
			q[REG_WIDTH-1 : 0] <= load ? data_in[REG_WIDTH-1 : 0]  :  (dir  ? q << shift_en : q >> shift_en) ;
		end
	end

endmodule

//  Register
module register #(
	parameter 													RESET_VALUE = 'b0,
	parameter														REG_WIDTH = 8
)(
	input wire 												clk,
	input wire 												reset_b,
	input wire 												load_en,
	input wire       [REG_WIDTH-1 : 0] load_data,
	
	output reg    [REG_WIDTH - 1 : 0] q
);


	always@(posedge clk or negedge reset_b) begin
	
		if(~reset_b)begin
			q[REG_WIDTH-1 : 0] <= {REG_WIDTH{RESET_VALUE}};
		end
		
		else begin
			q[REG_WIDTH-1 : 0] <= load_en ? load_data[REG_WIDTH-1:0] : q[REG_WIDTH-1:0]; 
    end
	end

endmodule

// Two Flop Synchronizer----------
module two_flop_sync (

  input wire clk,
  input wire reset_b,
  input wire in,
  
  output reg out
  
);
  
  wire q1;

  dff #(                      
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u1(  
    .clk     ( clk     ),
    .reset_b ( reset_b ),
    .d       ( in      ),
    .q       ( q1      )
  );
   
  dff #(                      
    .FLOP_WIDTH ( 1     ),
    .RESET_VALUE( 1'b0 )
  )u2(  
    .clk     ( clk     ),
    .reset_b ( reset_b ),
    .d       ( q1      ),
    .q       ( out      )
    
  );   


endmodule




module full_adder #(
  parameter N = 4
)(
  input wire [N-1:0]a,
  input wire [N-1:0]b,
  input wire cin,
  
  output wire [N-1:0]sum,
  output wire cout

); 
 wire [N:0] total;
  assign total[N:0] = a[N-1:0] + b[N-1:0] ; 
  
  assign sum[N-1:0] = total[N-1:0];
  assign cout = total[N];
  
endmodule



// Synchronous FIFO

module fifo_sync #( 
     parameter FIFO_DEPTH = 8,
	   parameter DATA_WIDTH = 32,
     parameter FIFO_DEPTH_LOG = 3
	   )(
	     input wire clk, 
       input wire rst_n,
       input wire wr_en, 
       input wire rd_en, 
       input wire clear,
       input wire [DATA_WIDTH-1:0] data_in, 
       output wire [DATA_WIDTH-1:0] data_out, 
       output reg [FIFO_DEPTH_LOG:0] data_count, 
	     output wire empty,
	     output wire full
	    
	   ); 

  
    // Declare a by-dimensional array to store the data
  reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];// depth 8 => [0:7] 32 bit elements
	
	// Wr/Rd pointer have 1 extra bits at MSB
  reg [FIFO_DEPTH_LOG-1:0] write_pointer;//3:0
  reg [FIFO_DEPTH_LOG-1:0] read_pointer;//3:0
  wire fifo_wr_en;
  wire fifo_rd_en;
  
  //write enbale and read enable reg with full and empty 
  assign fifo_wr_en = ~full & wr_en;
  assign fifo_rd_en = ~empty & rd_en;

  //write
    always @(posedge clk or negedge rst_n) begin
      
      if(~rst_n)
		    write_pointer <= 0;
		    
      else  begin
         fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= (fifo_wr_en && ~full) ?  data_in : fifo[write_pointer[FIFO_DEPTH_LOG-1:0]];
	       write_pointer <= clear ? ( write_pointer <= 'b0 ) : ( (fifo_wr_en && ~full) ? ( write_pointer + 1'b1 ) :  write_pointer ) ;
      end
      
    end
  
	//read
	always @(posedge clk or negedge rst_n) begin
      
	    if(~rst_n) begin
		    read_pointer <= 0;
		  end
		  
      else begin
        
	      read_pointer <= clear ? ( write_pointer <= 'b0 ) : ((fifo_rd_en && ~empty) ?  (read_pointer + 1'b1) : read_pointer) ;
      end
      
	end
  
  assign data_out[DATA_WIDTH-1:0] =  fifo[read_pointer[FIFO_DEPTH_LOG-1:0]] ;
	
	
 // Counter to count the number of data is written to the FIFO 
  always @(posedge clk or negedge rst_n) begin
  
        if(~rst_n) begin
		      data_count[FIFO_DEPTH_LOG:0] <= 'b0;
		    end 
		    
        else  begin
        
          if(clear) begin
            data_count[FIFO_DEPTH_LOG:0] <= 'b0;
          end
          
          else begin
            casez({fifo_wr_en,fifo_rd_en})
              2'b00   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0];
              2'b01   : data_count[FIFO_DEPTH_LOG:0] <= empty ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] - 1;
              2'b10   : data_count[FIFO_DEPTH_LOG:0] <= full ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] + 1;
              2'b11   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0]; 
              default : data_count[FIFO_DEPTH_LOG:0] <= 'bx;            
            endcase
          end
        end
  end
  
  
  assign empty             = data_count == 0;
  assign full              = data_count == FIFO_DEPTH;
  
  
endmodule
//--------------------------------------------------------------------------------------------------------------------


// >>>>>>>>>>>>>>>>>>>>> COUNTER WITH ENABLE>>>>>>>>>>>>>>>>>>>>

module counter_en #(
  parameter COUNTER_WIDTH = 16
)(
  input wire                        clk,
  input wire                        reset_b,
  input wire                        counter_clear,
  input wire                        en,
  output reg [COUNTER_WIDTH-1 : 0] count
);

  always @(posedge clk or negedge reset_b) begin
    if (~reset_b) begin
      count[COUNTER_WIDTH -1 : 0] <= 'b0;
    end
    else begin
      count[COUNTER_WIDTH -1 : 0] <= counter_clear ? 'b0 : (en ? (count [COUNTER_WIDTH -1 : 'b0] + 1'b1) : count);
    end
  end

endmodule
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



// Universal shift register

//mode control          opeartion 
//--------------------------------------
//  00                   No Change
//  01                   Shift Right
//  10                   Shift Left
//  11                   Parallel Load

module universal_shift_reg #(
  parameter DATA_WIDTH = 8
)(
  input  wire                      clk, 
  input  wire                      rst, 
  input  wire                [1:0] select,                        // select operation
  input  wire [DATA_WIDTH - 1 : 0] p_din,                         // parallel data in 
  input  wire                      s_left_din,                    // serial left data in
  input  wire                      s_right_din,                   // serial right data in
  output reg [DATA_WIDTH - 1 : 0] p_dout,                        // parallel data out
  output wire                      s_left_dout,                   // serial left data out
  output wire                      s_right_dout                   // serial right data out
);
  always@(posedge clk or negedge rst) begin
    if(~ rst) begin
      p_dout <= 'b0;
    end
    else begin
      casez (select)
        2'b00    : p_dout <= p_dout;                                    // No Chnage
        2'b01    : p_dout <= {s_right_din,p_dout[DATA_WIDTH - 1 : 1]};  // Right Shift
        2'b10    : p_dout <= {p_dout[DATA_WIDTH - 2 : 0], s_left_din};  // Left Shift
        2'b11    : p_dout <= p_din;                                     // Parallel in - Parallel out
        default  : p_dout <= 'bx; 
      endcase
    end
  end
  assign s_left_dout  = p_dout[0];
  assign s_right_dout = p_dout[DATA_WIDTH - 1];
endmodule


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




//.......................mux4to1.............
module mux4to1#(
  parameter LINE_WIDTH = 1
    
)(
  input  wire [1:0]sel,
  input  wire [LINE_WIDTH-1:0] in0,
  input  wire [LINE_WIDTH-1:0] in1,
  input  wire [LINE_WIDTH-1:0] in2,
  input  wire [LINE_WIDTH-1:0] in3,
  
  output reg [LINE_WIDTH-1:0] out
);

  always @(*) begin
    casez(sel)
      2'b00   : out = in0;
      2'b01   : out = in1;
      2'b10   : out = in2;
      2'b11   : out = in3;
      default : out = 'bx; 
    endcase
  end
 
endmodule

  //..>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> fifo without read delay >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

module fifo_syncs #( 
  parameter FIFO_DEPTH = 8,
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH_LOG = 3
  )(
  input wire clk, 
  input wire rst_n,
  input wire wr_en, 
  input wire rd_en, 
  input wire clear,
  input wire [DATA_WIDTH-1:0] data_in, 
  output wire [DATA_WIDTH-1:0] data_out, 
  output reg [FIFO_DEPTH_LOG:0] data_count, 
  output wire empty,
  output wire full
        
       ); 

    
    // Declare a by-dimensional array to store the data
  reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];// depth 8 => [0:7] 32 bit elements
    
    // Wr/Rd pointer have 1 extra bits at MSB
  reg [FIFO_DEPTH_LOG-1:0] write_pointer;//3:0
  reg [FIFO_DEPTH_LOG-1:0] read_pointer;//3:0
  wire fifo_wr_en;
  wire fifo_rd_en;
  
  //write enbale and read enable reg with full and empty 
  assign fifo_wr_en = ~full & wr_en;
  assign fifo_rd_en = ~empty & rd_en;

  //write
    always @(posedge clk or negedge rst_n) begin
      
      if(~rst_n)
            write_pointer <= 0;
            
      else  begin
         fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= (fifo_wr_en && ~full) ?  data_in : fifo[write_pointer[FIFO_DEPTH_LOG-1:0]];
           write_pointer <= clear ? ( write_pointer <= 'b0 ) : ( (fifo_wr_en && ~full) ? ( write_pointer + 1'b1 ) :  write_pointer ) ;
      end
      
    end
  
    //read
    always @(posedge clk or negedge rst_n) begin
      
        if(~rst_n) begin
            read_pointer <= 0;
          end
          
      else begin        
          read_pointer <= clear ? ( write_pointer <= 'b0 ) : ((fifo_rd_en && ~empty) ?  (read_pointer + 1'b1) : read_pointer) ;
      end
      
    end
    
    assign data_out =  fifo[read_pointer[FIFO_DEPTH_LOG-1:0]] ;
    
    
 // Counter to count the number of data is written to the FIFO 
  always @(posedge clk or negedge rst_n) begin
  
        if(~rst_n) begin
              data_count[FIFO_DEPTH_LOG:0] <= 'b0;
            end 
            
        else  begin
        
          if(clear) begin
            data_count[FIFO_DEPTH_LOG:0] <= 'b0;
          end
          
          else begin
            casez({fifo_wr_en,fifo_rd_en})
              2'b00   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0];
              2'b01   : data_count[FIFO_DEPTH_LOG:0] <= empty ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] - 1;
              2'b10   : data_count[FIFO_DEPTH_LOG:0] <= full ? data_count[FIFO_DEPTH_LOG:0] : data_count[FIFO_DEPTH_LOG:0] + 1;
              2'b11   : data_count[FIFO_DEPTH_LOG:0] <= data_count[FIFO_DEPTH_LOG:0]; 
              default : data_count[FIFO_DEPTH_LOG:0] <= 'bx;            
            endcase
          end
        end
  end
   
  assign empty             = data_count == 0;
  assign full              = data_count == FIFO_DEPTH;
  
  
endmodule