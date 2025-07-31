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


module led_out_reg_bank(
  input wire pclk,
  input wire presetn,
  input wire wr_en,
  input wire rd_en,
  input wire [31:0] pwdata,
  input wire [31:0] paddr,
  
  output wire led0,
  output wire led1,
  output wire led2,
  output wire led3,
  
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
        push_reg0 <= wr_en & (paddr == 32'hA0000000) ? pwdata[0] : push_reg0;
        push_reg1 <= wr_en & (paddr == 32'hA0000004) ? pwdata[7] : push_reg1;
        push_reg2 <= wr_en & (paddr == 32'hA0000008) ? pwdata[15] : push_reg2;
        push_reg3 <= wr_en & (paddr == 32'hA000000C) ? pwdata[31] : push_reg3;
    end
  end
  
  reg[31:0] rd_data;
    always @(*) begin
    casez (paddr[31:0])
      32'hA0000000  : rd_data[31:0] = {push_reg0, 31'b0};
      32'hA0000004  : rd_data[31:0] = {16'b0, push_reg1, 15'b0};
      32'hA0000008  : rd_data[31:0] = {24'b0, push_reg2, 7'b0};
      32'hA000000C  : rd_data[31:0] = {31'b0, push_reg3};

      default    : rd_data[31:0] = 32'bx;
    endcase
  end
  
  assign prdata = rd_en ? rd_data : 32'b0;
  assign led0 = push_reg0;
  assign led1 = push_reg1;
  assign led2 = push_reg2;
  assign led3 = push_reg3;
  
endmodule
