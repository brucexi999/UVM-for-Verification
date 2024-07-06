/*
Send transaction data from COMPA to COMPB with the help of TLM PUT PORT to PUT IMP . 
Transaction class code is added in Instruction tab. Use UVM core print method to print the values of data members of transaction class.
*/
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
 
    bit [3:0] a = 12;
    bit [4:0] b = 24;
    int c = 256;
    
    function new(string inst = "transaction");
        super.new(inst);
    endfunction
    
    `uvm_object_utils_begin(transaction)
        `uvm_field_int(a, UVM_DEFAULT | UVM_DEC);
        `uvm_field_int(b, UVM_DEFAULT | UVM_DEC);
        `uvm_field_int(c, UVM_DEFAULT | UVM_DEC); 
    `uvm_object_utils_end
  
endclass

class COMPA extends uvm_component;

    `uvm_component_utils(COMPA);
    uvm_blocking_put_port #(transaction) send;
    transaction trans;

    function new(string path = "COMPA", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        send = new("send", this);
    endfunction

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        trans = new();
        trans.print();
        send.put(trans);
        phase.drop_objection(this);
    endtask

endclass

class COMPB extends uvm_component;

    `uvm_component_utils(COMPB);
    uvm_blocking_put_imp #(transaction, COMPB) imp;

    function new(string path = "COMPB", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    virtual function void put(transaction trans);
        `uvm_info("COMPB", "Transaction received", UVM_NONE);
        trans.print();
    endfunction

endclass

class Environment extends uvm_env;
    
    `uvm_component_utils(Environment);
    COMPA a;
    COMPB b;

    function new(string path = "Environment", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a = COMPA::type_id::create("a", this);
        b = COMPB::type_id::create("b", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a.send.connect(b.imp);
    endfunction

endclass

class Test extends uvm_test;

    `uvm_component_utils(Test);
    Environment env;

    function new(string path = "Test", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = Environment::type_id::create("env", this);
    endfunction

endclass

module tb;

    initial begin
        run_test("Test");
    end
    
endmodule

