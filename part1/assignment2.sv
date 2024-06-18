// Write a code to change the verbosity of the entire verification environment to UVM_DEBUG. 
// To demonstrate successful configuration, print the value of the verbosity level on the console.
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;

    initial begin
        uvm_top.set_report_verbosity_level(UVM_DEBUG);
        $display("Verbosity level = %0d", uvm_top.get_report_verbosity_level);
    end

endmodule