/*
Design UVM testbench to perform verification of 4:1 Mux. Design code of 4:1 Mux is added in the Instruction tab.

module mux
  (
    input [3:0] a,b,c,d, ////input data port have size of 4-bit
    input [1:0] sel,     ////control port have size of 2-bit
    output reg [3:0] y 
  );
  
  always@(*)
    begin
      case(sel)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        2'b11: y = d;
      endcase
    end
  
  
endmodule
*/

`include "uvm_macros.svh"
import uvm_pkg::*;

interface MyInterface();

    logic [3:0] a, b, c, d, y;
    logic [1:0] sel;

endinterface

class Transaction extends uvm_sequence_item;

    rand bit [3:0] a, b, c, d;
    rand bit [1:0] sel;
    bit [3:0] y;

    `uvm_object_utils_begin(Transaction);
        `uvm_field_int(a, UVM_DEFAULT);
        `uvm_field_int(b, UVM_DEFAULT);
        `uvm_field_int(c, UVM_DEFAULT);
        `uvm_field_int(d, UVM_DEFAULT);
        `uvm_field_int(sel, UVM_DEFAULT);
        `uvm_field_int(y, UVM_DEFAULT);
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
        forever begin
            seq_item_port.get_next_item(trans);
            drive_one_trans();
            seq_item_port.item_done();
        end
    endtask

    task drive_one_trans();
        vif.a <= trans.a;
        vif.b <= trans.b;
        vif.c <= trans.c;
        vif.d <= trans.d;
        vif.sel <= trans.sel;
        #10;
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
        forever begin
            collect_one_trans();
            ap.write(trans);
        end
    endtask

    task collect_one_trans();
        #10;
        trans.a = vif.a;
        trans.b = vif.b;
        trans.c = vif.c;
        trans.d = vif.d;
        trans.sel = vif.sel;
        trans.y = vif.y;
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

    function new(string name = "Model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port = new("port", this);
        ap = new("ap", this);

    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            port.get(trans);
            $cast(new_trans, trans.clone());
            generate_exp();
            ap.write(new_trans);
        end
    endtask

    task generate_exp();
        case(new_trans.sel)
            2'b00: new_trans.y = new_trans.a;
            2'b01: new_trans.y = new_trans.b;
            2'b10: new_trans.y = new_trans.c;
            2'b11: new_trans.y = new_trans.d;
        endcase
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
                exp_queue.push_back(exp_trans);
            end

            forever begin
                act_port.get(act_trans);
                wait(exp_queue.size()>0);
                if (exp_queue.size()>0) begin
                    tmp_trans = exp_queue.pop_front();
                    result = act_trans.compare(tmp_trans);
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

    /*MyInterface if_in();
    MyInterface if_out();

    mux DUT (
        if_in.a,
        if_in.b,
        if_in.c,
        if_in.d,
        if_in.sel,
        if_out.y
    );*/

    MyInterface itfc();
    mux DUT (
        itfc.a,
        itfc.b,
        itfc.c,
        itfc.d,
        itfc.sel,
        itfc.y
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.*", "vif", itfc);
        //uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.agent_input.*", "vif", if_in);
        //uvm_config_db #(virtual MyInterface)::set(null, "uvm_test_top.env.agent_output.*", "vif", if_out);
        run_test("Test");
    end

endmodule
