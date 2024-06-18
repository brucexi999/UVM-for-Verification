// Override the UVM_WARNING action to make quit_count equal to the number of times UVM_WARNING executes. 
// Write an SV code to send four random messages to a terminal with potential error severity.
// Simulation must stop as soon as we reach to quit_count of four. Do not use UVM_INFO, UVM_ERROR, UVM_FATAL.
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;
    initial begin
        uvm_top.set_report_severity_action(UVM_WARNING, UVM_COUNT | UVM_DISPLAY);
        uvm_top.set_report_max_quit_count(4);
        for (int i=0; i<10; i++) begin
            `uvm_warning("TB_TOP","WARNING! NUCLEAR MISSILE LAUNCHED!");
        end
    end

endmodule