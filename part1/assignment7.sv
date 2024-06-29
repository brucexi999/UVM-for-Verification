/*
1) Create a class "my_object" by extending the UVM_OBJECT class. Add three logic datatype datamembers "a", "b", and "c" with sizes of 2, 4, and 8 respectively.

2) Create two objects of my_object class in TB Top. Generate random data for data members of one of the object and then copy the data to other object by using clone method.

3) Compare both objects and send the status of comparison to Console using Standard UVM reporting macro. Add User defined implementation for the copy method.
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

class my_new_object extends my_object;
    `uvm_object_utils(my_new_object);

    function new(string path = "my_new_object");
        super.new(path);
    endfunction

    virtual function void do_copy (uvm_object rhs);
        my_new_object temp;
        $cast(temp, rhs);
        super.do_copy(rhs);

        this.a = temp.a;
        this.b = temp.b;
        this.c = temp.c;
    endfunction

endclass

module tb;
    my_object obj1, obj2;
    my_new_object obj3, obj4;
    int status = 0;

    initial begin
        obj1 = my_object::type_id::create("obj1");
        obj1.randomize();
        $cast(obj2, obj1.clone());

        status = obj1.compare(obj2);
        `uvm_info("tb", $sformatf("Compare results = %0d", status), UVM_LOW);

        obj3 = my_new_object::type_id::create("obj3");
        obj4 = my_new_object::type_id::create("obj4");
        obj3.randomize();
        
        obj4.copy(obj3);

        status = obj3.compare(obj4);
        `uvm_info("tb", $sformatf("Compare results = %0d", status), UVM_LOW);
    end
endmodule