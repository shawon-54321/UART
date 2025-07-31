`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2025 02:19:48 PM
// Design Name: 
// Module Name: push_in_reg_bank
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


module push_in_reg_bank(
  input wire pclk,
  input wire presetn,
  input wire wr_en,
  input wire rd_en,
  input wire [31:0] pwdata,
  input wire [31:0] paddr,
  input wire push0,
  input wire push1,
  input wire push2,
  input wire push3,
  
  output wire [31:0] prdata
  );
  
  reg push_reg0;
  reg push_reg1;
  reg push_reg2;
  reg push_reg3;
  
    always@(posedge pclk or negedge presetn)begin
    if(~presetn)begin
        push_reg0 <= 1'b0;
        push_reg1 <= 1'b0;
        push_reg2 <= 1'b0;
        push_reg3 <= 1'b0;
    end
    else begin
        push_reg0 <= pwdata[0] | push0;
        push_reg1 <= pwdata[7] | push1;
        push_reg2 <= pwdata[15] | push2;
        push_reg3 <= pwdata[31] | push3;
    end
  end
  
  reg[31:0] rd_data;
    always @(*) begin
    casez (paddr[31:0])
      32'hA0010000  : rd_data[31:0] = {31'b0, push_reg0};
      32'hA0010004  : rd_data[31:0] = {24'b0, push_reg1, 7'b0};
      32'hA0010008  : rd_data[31:0] = {16'b0, push_reg2, 15'b0};
      32'hA001000C  : rd_data[31:0] = {push_reg3, 31'b0};

      default    : rd_data[31:0] = 32'bx;
    endcase
  end
  
  assign prdata = rd_en ? rd_data : 32'b0;
  
endmodule
