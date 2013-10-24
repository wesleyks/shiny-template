classdef LocalContext < handle
    %LOCALCONTEXT Summary of this class goes here
    %   Detailed explanation goes here
    
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

