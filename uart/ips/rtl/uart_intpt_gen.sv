module uart_intpt_gen(
		input logic       thre,
    input logic       etbei,
    input logic       pe,
    input logic       elsi,
    input logic       fe,
    input logic       dr,
    input logic       erbi,

    output logic uart_intpt

);

   assign uart_intpt = (thre & etbei) | (pe & elsi) | (fe & elsi) | (dr & erbi);

endmodule