`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2025 12:31:57 PM
// Design Name: 
// Module Name: apb_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module apb_fsm
(
    input pclk,
    input presetn,
    input psel,
    input penable,
    input pwrite,
    output[31:0] pwdata,
    output[31:0] paddr,
    
    output pready,
    output pslverr,
    
    input [31:0] data_2s,
    output [31:0] data_2m,
    input [31:0] add,
    output wr_en,
    output rd_en,
    input[31:0] prdata
    
    );
    
  wire rd_en;
  wire wr_en;
  parameter   IDLE    = 1'b0,
              ACCESS  = 1'b1;
            
  reg pstate, nstate;
  
  always@(posedge pclk or negedge presetn)begin
    if(~presetn)begin
        pstate <= 1'b0;
    end
    else begin
        pstate <= nstate;
    end
  end
  

  always@(*) begin : NSL
    casez(pstate)
    
      IDLE : begin
        nstate = psel ? ACCESS : IDLE;
      end
      
      ACCESS : begin
        nstate = IDLE;
      end
      
      default : begin
        nstate = 1'bx;
      end
      
    endcase
  end
  
  assign rd_en  = ( pstate == ACCESS ) & ~pwrite  & penable & psel;
  assign wr_en  = ( pstate == ACCESS ) & pwrite   & penable & psel;
  assign pready = 1'b1;
  assign pslverr= 1'b0;
 
 //forward the data and address bus
 assign data_2m = prdata;
 assign pwdata = data_2s;
 assign paddr = add;
  
endmodule
