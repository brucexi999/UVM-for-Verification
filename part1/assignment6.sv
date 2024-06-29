/*
Create a class "my_object" by extending the UVM_OBJECT class. Add three logic datatype datamembers "a", "b", and "c" with sizes of 2, 4, and 8 respectively. 
Generate a random value for all the data members and send the values of the variables to the console by using the print method.
*/
`include "uvm_macros.svh"
import uvm_pkg::*;

class my_object extends uvm_object;

    function new(string path = "my_object");
        super.new(path);
    endfunction

    rand logic [1:0] a;
    rand logic [3:0] b;
    rand logic [7:0] c;

    `uvm_object_utils_begin(my_object);
    `uvm_field_int(a, UVM_DEFAULT);
    `uvm_field_int(b, UVM_DEFAULT);
    `uvm_field_int(c, UVM_DEFAULT);
    `uvm_object_utils_end

endclass

module tb;
    my_object obj;

    initial begin
        obj = my_object::type_id::create("obj");
        obj.randomize();
        obj.print();
    end

endmodule