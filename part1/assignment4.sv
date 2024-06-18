// Write a TB_TOP Code to send message with ID : CMP1 to console while blocking message with ID : CMP2. 
// Code is mentioned in the Instruction tab. Do not change Component code.
`include "uvm_macros.svh"
import uvm_pkg::*;
 
//////////////////////////////////////////////////
class component extends uvm_component;
  `uvm_component_utils(component)
  
  function new(string path , uvm_component parent);
    super.new(path, parent);
  endfunction
 
  
  task run();
    `uvm_info("CMP1", "Executed CMP1 Code", UVM_DEBUG);
    `uvm_info("CMP2", "Executed CMP2 Code", UVM_DEBUG);
  endtask
  
endclass

module tb;
    component cmp = new("CMP", null);

    initial begin
        cmp.set_report_id_verbosity("CMP1", UVM_DEBUG);
        cmp.run();
    end
endmodule