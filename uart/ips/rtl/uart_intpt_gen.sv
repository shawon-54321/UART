module uart_intpt_gen(
		input logic       thre,
    input logic       etbei,
    input logic       pe,
    input logic       elsi,
    input logic       fe,
    input logic       bi, 
    input logic       dr,
    input logic       erbi,
    input logic       below_level, 

    output logic uart_intpt

);
    
  logic thre_int;
  logic rx_line_st_int;
  logic dr_int;

  assign thre_int       = thre & etbei;
  assign rx_line_st_int = (pe|fe|bi)& elsi;
  assign dr_int         = dr & erbi & ~below_level;

   assign uart_intpt = thre_int | rx_line_st_int | dr_int ;

endmodule