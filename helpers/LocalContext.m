classdef LocalContext < handle
    %LOCALCONTEXT Container class for holding local variables
    %   LocalContext is a linked list implementation where name is the name
    %   of the variable, data is the value, and next is the next
    %   LocalContext.
    
    properties
        name;
        data;
        next;
    end
    
    methods
        function this = LocalContext(name, data)
            this.name = name;
            this.data = data;
            this.next = 0;
        end
    end
    
end

