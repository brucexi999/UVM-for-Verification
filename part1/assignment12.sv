/*
module dff
  (
    input clk, rst, din, ////din - data input, rst - active high synchronus
    output reg dout ////dout - data output
  );
  
  always@(posedge clk)
    begin
      if(rst == 1'b1) 
        dout <= 1'b0;
      else
        dout <= din;
    end
  
endmodule
Design UVM TB to perform verification of Data flipflop (D-FF). Design code is mentioned in the instruction tab.
*/

// Driver, Monitor, and Model usually need to be tailored according to the DUT.
`include "uvm_macros.svh"
import uvm_pkg::*;

interface MyInterface(input clk, input rst);

    logic din, dout;

endinterface

class Transaction extends uvm_sequence_item;

    rand bit din;
    bit dout;

    `uvm_object_utils_begin(Transaction);
        `uvm_field_int(din, UVM_DEFAULT);
        `uvm_field_int(dout, UVM_DEFAULT);
    `uvm_object_utils_end;

    function new(string name = "Transaction");
        super.new(name);
    endfunction

endclass

class MySequence extends uvm_sequence #(Transaction);

    `uvm_object_utils(MySequence);
    Transaction trans;

    function new(string name = "MySequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat(20) begin
            `uvm_do(trans);
        end
    endtask

endclass

class Driver extends uvm_driver #(Transaction);

    `uvm_component_utils(Driver);

    Transaction trans;
    virtual MyInterface vif;

    function new(string name = "Driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual MyInterface)::get(this, "", "vif", vif))
            `uvm_error("Driver", "Unable to get the virtual interface.");
        trans = Transaction::type_id::create("trans");
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        vif.din <= 0;
        wait(vif.rst==0);
        forever begin
            seq_item_port.get_next_item(trans);
            @(posedge vif.clk);
            //#1;
            drive_one_trans();
            //`uvm_info("Driver", $sformatf("din driven to DUT = %0d", trans.din), UVM_NONE);
            seq_item_port.item_done();
        end
    endtask

    task drive_one_trans();
        vif.din <= trans.din;
    endtask

endclass

class Monitor extends uvm_monitor;

    `uvm_component_utils(Monitor);

    Transaction trans;
    virtual MyInterface vif;
    uvm_analysis_port #(Transaction) ap;

    function new(string name = "Monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual MyInterface)::get(this, "", "vif", vif))
            `uvm_error("Monitor", "Unable to get the virtual interface.")
        trans = Transaction::type_id::create("trans");
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(vif.rst==0);
        //@(posedge vif.clk); // The delay of the FF.
        forever begin
            @(posedge vif.clk);
            #1;
            collect_one_trans();
            //`uvm_info("Monitor", $sformatf("din = %0d, dout = %0d", vif.din, vif.dout), UVM_NONE);
            ap.write(trans);
        end
    endtask

    task collect_one_trans();
        trans.din = vif.din;
        trans.dout = vif.dout;
    endtask

endclass

class Agent extends uvm_agent;

    `uvm_component_utils(Agent);
    Driver driver;
    Monitor monitor;
    uvm_sequencer #(Transaction) sequencer;
    uvm_analysis_port #(Transaction) ap;

    function new(string name = "Agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            driver = Driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(Transaction)::type_id::create("sequencer", this);
        end
        monitor = Monitor::type_id::create("monitor", this);
        
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        ap = monitor.ap;
    endfunction

endclass

class Model extends uvm_component;
    `uvm_component_utils(Model);
    uvm_blocking_get_port #(Transaction) port;
    uvm_analysis_port #(Transaction) ap;
    Transaction trans, new_trans;
    bit previous_data = 0;

    function new(string name = "Model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port = new("port", this);
        ap = new("ap", this);
        new_trans = Transaction::type_id::create("new_trans");
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            port.get(trans);
            //`uvm_info("Model", $sformatf("din received from input monitor = %0d", trans.din), UVM_NONE);
            //$cast(new_trans, trans.clone());
            generate_exp();
            ap.write(new_trans);
            previous_data = trans.din;
            //`uvm_info("Model", $sformatf("new previous_data = %0d", previous_data), UVM_NONE);
        end
    endtask

    task generate_exp();  // Generate expected output
        new_trans.dout = previous_data;
    endtask

endclass

class Scoreboard extends uvm_scoreboard;
    `uvm_component_utils(Scoreboard);

    uvm_blocking_get_port #(Transaction) exp_port; // Port for expected output from the reference model
    uvm_blocking_get_port #(Transaction) act_port; // Port for actual output from the monitor
    Transaction exp_trans, act_trans, tmp_trans;
    Transaction exp_queue[$];
    bit result;

    function new(string name = "Scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        exp_port = new("exp_port", this);
        act_port = new("act_port", this);
    endfunction

    virtual task run_phase (uvm_phase phase);
        super.run_phase(phase);
        fork
            forever begin
                exp_port.get(exp_trans);
                //`uvm_info("Scoreboard", $sformatf("dout received from model %0d", exp_trans.dout), UVM_NONE);
                exp_queue.push_back(exp_trans);
            end

            forever begin
                act_port.get(act_trans);
                //`uvm_info("Scoreboard", $sformatf("dout received from output monitor %0d", act_trans.dout), UVM_NONE);
                wait(exp_queue.size()>0);
                if (exp_queue.size()>0) begin
                    tmp_trans = exp_queue.pop_front();
                    result = act_trans.dout == tmp_trans.dout;
                    if (result) begin
                        `uvm_info("Scoreboard", "Compare SUCCEEDED", UVM_LOW);
                    end
                    else begin
                        `uvm_error("Scoreboard", "Compare FAILED");
                        $display("Expected transaction:");
                        tmp_trans.print();
                        $display("Actual transaction:");
                        act_trans.print();
                    end
                end
                else begin
                    `uvm_error("Scoreboard", "Received from DUT, while Expected Queue is empty");
                    $display("Unexpected transaction:");
                    act_trans.print();
                end
            $display("---------------------------------------------------------------------------------------------------------------------------------");
            end
        join

    endtask

endclass

class Environment extends uvm_env;

    `uvm_component_utils(Environment);
    uvm_tlm_analysis_fifo #(Transaction) agt_mdl_fifo;
    uvm_tlm_analysis_fifo #(Transaction) mdl_scb_fifo;
    uvm_tlm_analysis_fifo #(Transaction) agt_scb_fifo;
    Agent agent_output, agent_input;
    Scoreboard scoreboard;
    Model model;

    function new(string name = "Environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent_output = Agent::type_id::create("agent_output", this);
        agent_input = Agent::type_id::create("agent_input", this);
        agent_output.is_active = UVM_PASSIVE;
        agent_input.is_active = UVM_ACTIVE;

        model = Model::type_id::create("model", this);
        scoreboard = Scoreboard::type_id::create("scoreboard", this);

        agt_mdl_fifo = new("agt_mdl_fifo", this);
        mdl_scb_fifo = new("mdl_scb_fifo", this);
        agt_scb_fifo = new("agt_scb_fifo", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //agent.monitor.ap.connect(scoreboard.imp);
        // agent_input and model
        agent_input.ap.connect(agt_mdl_fifo.analysis_export);
        model.port.connect(agt_mdl_fifo.blocking_get_export);
        // model and scoreboard
        model.ap.connect(mdl_scb_fifo.analysis_export);
        scoreboard.exp_port.connect(mdl_scb_fifo.blocking_get_export);
        // agent_output and scoreboard
        agent_output.ap.connect(agt_scb_fifo.analysis_export);
        scoreboard.act_port.connect(agt_scb_fifo.blocking_get_export);
    endfunction

endclass

class Test extends uvm_test;

    `uvm_component_utils(Test);

    Environment env;
    MySequence mySequence;

    function new(string name = "Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = Environment::type_id::create("env", this);
        mySequence = MySequence::type_id::create("mySequence", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        mySequence.start(env.agent_input.sequencer);
        //#200;
        phase.drop_objection(this);
    endtask

endclass

module TB;
    logic clk, rst;

    MyInterface if_in(clk, rst);
    MyInterface if_out(clk, rst);

    dff DUT (
        clk,
        rst,
        if_in.din,
        if_out.dout
    );

    initial begin
        clk <= 0;
        rst <= 1;
    end

    initial begin
        #100;
        rst <= 0;
    end

    always #5 clk <= ~clk;

    /*MyInterface itfc();
    dff DUT (
        itfc.clk,
        itfc.rst,
        itfc.din,
        itfc.dout
    );

    initial begin
        itfc.clk <= 0;
        itfc.rst <= 1;
    end

    initial begin
        #100;
        itfc.rst <= 0;
    end

    always #5 itfc.clk <= ~itfc.clk;*/

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        //uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.*", "vif", itfc);
        uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.agent_input.*", "vif", if_in);
        uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.agent_output.*", "vif", if_out);
        run_test("Test");
    end

endmodule