/*
Design an environment consisting of a single producer class "PROD" and three subscribers viz., iz. "SUB1", "SUB2", and "SUB3". 
Add logic such that the producer broadcasts the name of the coder and all the subscribers are able to receive the string data sent by the producer. 
If Zen is writing the logic, then the producer should broadcast the string "ZEN" and all the subscribers must receive "ZEN".
*/

`include "uvm_macros.svh"
import uvm_pkg::*;

class PROD extends uvm_component;

    `uvm_component_utils(PROD);
    uvm_analysis_port #(string) port;

    string my_name = "Bruce";
    
    function new(string path = "PROD", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port = new("port", this);
    endfunction

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        port.write(my_name);
        phase.drop_objection(this);
    endtask

endclass

class SUB extends uvm_component;

    `uvm_component_utils(SUB);
    uvm_analysis_imp #(string, SUB) imp;

    function new(string path = "SUB", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    virtual function void write(string my_name);
        `uvm_info("SUB", $sformatf("%s", my_name), UVM_NONE);
    endfunction

endclass

class Environment extends uvm_env;

    `uvm_component_utils(Environment);
    PROD producer;
    SUB subscriber1, subscriber2, subscriber3;

    function new(string path = "Environment", uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        producer = PROD::type_id::create("producer", this);
        subscriber1 = SUB::type_id::create("subscriber1", this);
        subscriber2 = SUB::type_id::create("subscriber2", this);
        subscriber3 = SUB::type_id::create("subscriber3", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        producer.port.connect(subscriber1.imp);
        producer.port.connect(subscriber2.imp);
        producer.port.connect(subscriber3.imp);
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
