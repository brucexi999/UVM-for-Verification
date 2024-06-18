// Exit Simulation with UVM_WARNING
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;
    initial begin
        uvm_top.set_report_severity_action(UVM_WARNING, UVM_EXIT | UVM_DISPLAY);
        `uvm_warning("TB_TOP", "WARNING! NUCLEAR MISSILE LAUNCHED!");
        `uvm_warning("TB_TOP", "WARNING! NUCLEAR MISSILE LAUNCHED!");
    end
endmodule