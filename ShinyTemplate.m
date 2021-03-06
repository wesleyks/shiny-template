classdef ShinyTemplate < handle
    %SHINYTEMPLATE is an extensible template engine!
    %   ShinyTemplate LOADS in either a string or a text file written in
    %   the template language and, given some additional data RENDERS it
    %   into a string
    
    properties (Constant)
        %This is where you can customize ShinyTemplate by extending its
        %capabilities.
        parserSymbols = struct( 'for',  struct('branches', 1),...
                                'if',   struct('branches', 2, 'bisect', 'else'));
        evaluateSymbols = struct(   'for',  @shinyFor,...
                                    'if',   @shinyIf);
    end
    
    properties (Access = private)
        templateString;
        parseData;
    end
    
    methods (Access = private)
        function position = findClose(this, start, stop, substring)
            %FINDCLOSE attempts to find the close of a tag, so }} or %}
            %   Inputs:
            %       start - the position in the string to start searching at
            %       stop - the postion in the string to stop searching at
            %       substring - the substring to match
            %   Outputs:
            %       position - the position of the substring that's found
            i = start;
            subLength = length(substring);
            while i < stop
                if strncmp(this.templateString(i:(i + subLength - 1)), substring, subLength) == 1
                    position = i;
                    return;
                end
                i = i + 1;
            end
            exception = MException('ShinyTemplate:ParseError', 'Tag expected, found: %s', this.templateString(start:stop));
            throw(exception);
        end
        
        function [matchStart, matchEnd, bisectStart, bisectEnd] = findMatchingTag(this, start, stop, token, bisectToken, initTag)
            %FINDMATCHINGTAG attempts to find a tag's closing tag. for
            %example, {% endif %} for the {% if... tag. 
            %   Inputs:
            %       start - position to start the search
            %       stop - position to stop the search
            %       token - the token that signals the clsoe, aka symbol, or keyword
            %       bisectToken - the token that splits it into two
            %       branches (like "else"). The second branch is treated as
            %       optional, so if it isn't found, then bisectStart and
            %       bisectEnd will not be set
            %       initTag - the text of the tag that we are trying to
            %       close
            %   Outputs:
            %       matchStart - start position of the matching tag
            %       matchEnd - end position of the ending tag
            %       bisectStart - start of the bisecting tag, if found
            %       bisectEnd - end of the bisecting tag, if found
            [allStarts, allEnds] = regexp(this.templateString(start:stop), '{%.*?%}');
            depth = 1;
            for i = 1:length(allStarts)
                if regexp(this.templateString((allStarts(i) + start - 1):(allEnds(i)) + start - 1), strcat('{%\s*', token, '\s*%}'))
                    depth = depth - 1;
                elseif ~isnumeric(bisectToken) && regexp(this.templateString((allStarts(i) + start - 1):(allEnds(i)) + start - 1), strcat('{%\s*', bisectToken, '\s*%}'))
                    depth = depth - 1;
                    if depth > 0
                        depth = depth + 1;
                    end
                else
                    depth = depth + 1;
                end
                if (depth == 0) && ~isnumeric(bisectToken) && ~isempty(regexp(this.templateString((allStarts(i) + start - 1):(allEnds(i)) + start - 1), strcat('{%\s*', bisectToken, '\s*%}'), 'once'))
                    bisectStart = allStarts(i) + start - 1;
                    bisectEnd = allEnds(i) + start - 1;
                    [subMatchStart, subMatchEnd] = this.findMatchingTag(bisectEnd + 1, stop, token, 0);
                    matchStart = subMatchStart;
                    matchEnd = subMatchEnd;
                    return;
                elseif depth == 0
                    bisectStart = -1;
                    bisectEnd = -1;
                    matchStart = allStarts(i) + start - 1;
                    matchEnd = allEnds(i) + start - 1;
                    return;
                end
            end
            exception = MException('ShinyTemplate:ParseError', 'Closing tag for %s not found, expected: {%% %s %%}',initTag ,token);
            throw(exception);
        end
        
        function output = parseString(this, start, stop)
            %PARSESTRING parses the template string (this.templateString) 
            %from start to stop
            %   Inputs: 
            %       start - where to start parsing
            %       stop - where to stop parsing
            %   Outputs:
            %       output - parsed data used in eval
            output = {};
            i = start;
            last = start;
            while i < stop
                switch this.templateString(i:(i + 1))
                    case '{{'
                        closePos = this.findClose(i, stop, '}}');
                        expression = strtrim(this.templateString((i + 2):(closePos - 1)));
                        if (i - 1 >= start)
                            output{length(output) + 1} = {'text', this.templateString(last:(i - 1))};
                        end
                        output{length(output) + 1} = {'display', expression};
                        last = closePos + 2;
                        i = last - 1;
                    case '{%'
                        closePos = this.findClose(i, stop, '%}');
                        controlTokens = strsplit(strtrim(this.templateString((i + 2):(closePos - 1))));
                        if (i - 1 >= start)
                            output{length(output) + 1} = {'text', this.templateString(last:(i - 1))};
                        end
                        if isfield(this.parserSymbols, controlTokens{1})
                            if this.parserSymbols.(controlTokens{1}).branches == 1
                                [matchTagStart, matchTagEnd] = this.findMatchingTag(closePos, stop, ['end' controlTokens{1}], 0, this.templateString(i:(closePos + 1)));
                                innerParsed = this.parseString(closePos + 2, matchTagStart - 1);
                                output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed};
                                last = matchTagEnd + 1;
                            else
                                bisector = this.parserSymbols.(controlTokens{1}).bisect;
                                [matchTagStart, matchTagEnd, bisectTagStart, bisectTagEnd] = this.findMatchingTag(closePos, stop, ['end' controlTokens{1}], bisector, this.templateString(i:(closePos + 1)));
                                if (bisectTagStart > 0)
                                    innerParsed1 = this.parseString(closePos + 2, bisectTagStart - 1);
                                    innerParsed2 = this.parseString(bisectTagEnd + 1, matchTagStart - 1);
                                    output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed1, innerParsed2};
                                    last = matchTagEnd + 1;
                                else
                                    innerParsed = this.parseString(closePos + 2, matchTagStart - 1);
                                    output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed, 0};
                                    last = matchTagEnd + 1;
                                end
                            end
                        else
                            exception = MException('ShinyTemplate:ParseError','Symbol not recognized, %s', controlTokens{1});
                            throw(exception);
                        end
                        i = last - 1;
                end
                i = i + 1;
            end
            if (last <= stop)
                output{length(output) + 1} = {'text', this.templateString(last:i)};
            end
        end
        
        function value = lookupLocal(this, name, localContext)
            %LOOKUPLOCAL looks up the value of the named variable
            %   Inputs:
            %       name - a string, the name of the variable
            %       localContext - the local context
            %   Outputs:
            %       value - the value of the variable
            if (localContext == 0)
                exception = MException(strcat('Local variable not found: ', name));
                throw(exception);
            elseif (strcmp(localContext.name, name))
                value = localContext.data;
            else
                value = this.lookupLocal(name, localContext.next);
            end
        end
        
        function value = hasIndex(~, string)
            %HASINDEX checks if an expression has an index access
            %   Inputs:
            %       string - the expression
            %   Output:
            %       value - a boolean
            value = regexp(string, '^.*[(|{]\d+[)|}]$', 'once');
        end
        
        function [variable, index, type] = isolateIndex(this, string)
            %ISOLATEINDEX parses the index access
            %   Inputs:
            %       string - the expression to parse
            %   Outputs:
            %       variable - the name of the variable to access
            %       index - the index to access
            %       type - "(" or "{" accessor
            [start, stop] = regexp(string, '[{|(]\d+[}|)]', 'once');
            variable = string(1:(start - 1));
            index = str2double(string((start + 1):(stop - 1)));
            switch string(start)
                case '('
                    type = 'paren';
                case '{'
                    type = 'brace';
            end
            
        end 
        
        function value = accessIndex(this, inputVal, type, index, variable, expression)  
            %ACCESSINDEX accesses the input vector at the index
            %   Inputs:
            %       inputVal - the vector to use
            %       type - the type of array access 'paren' or 'brace'
            %       index - the index
            %       variable - the name of the variable we are attempting
            %       to access
            %       expression - the entire expression that the variable
            %       appears in
            %   Outputs:
            %       value - the value
            if ~isvector(inputVal)
                exception = MException('ShinyTemplate:RenderError', '"%s" is not a vector. In {{ %s }}', variable, expression);
                throw(exception);
            end
            if index > length(inputVal)
                exception = MException('ShinyTemplate:RenderError', 'Index exceeds dimensions. In {{ %s }}', expression);
                throw(exception);
            end
            switch type
                case 'paren'
                    value = inputVal(index);
                case 'brace'
                    if ~iscell(inputVal)
                        exception = MException('ShinyTemplate:RenderError', '"%s" is not a cell array. In {{ %s }}', variable, expression);
                        throw(exception);
                    end
                    value = inputVal{index};
            end
        end
        
        function value = lookup(this, expression, context, localContext)
            %LOOKUP looksup the value of the expression
            %   lookup first checks in localContext, then context
            %   Inputs:
            %       expression - the expression to look up
            %       context - a struct
            %       localContext - the local context
            %   Outputs:
            %       value - the value of the expression
            lookupArray = strsplit(expression, '.');
            hasIndex = this.hasIndex(lookupArray{1});
            if hasIndex
                [variable, index, type] = this.isolateIndex(lookupArray{1});
            end
            
            try 
                if hasIndex
                    value = this.lookupLocal(variable, localContext);
                    value = this.accessIndex(value, type, index, variable, expression);
                else
                    value = this.lookupLocal(lookupArray{1}, localContext);
                end
            catch err
                if strcmp(err.identifier, 'ShinyTemplate:RenderError')
                    throw(err);
                end
                if hasIndex
                    if ~isfield(context, variable)
                        exception = MException('ShinyTemplate:RenderError', '"%s" is not defined. In {{ %s }}', variable, expression);
                        throw(exception);
                    end
                    value = getfield(context, variable);
                    value = this.accessIndex(value, type, index, variable, expression);
                else
                    if ~isfield(context, lookupArray{1})
                        exception = MException('ShinyTemplate:RenderError', '"%s" is not defined. In {{ %s }}', lookupArray{1}, expression);
                        throw(exception);
                    end
                    value = getfield(context, lookupArray{1});
                end
            end
            
            for i = 2:length(lookupArray)
                hasIndex = this.hasIndex(lookupArray{i});
                if hasIndex
                    [variable, index, type] = this.isolateIndex(lookupArray{i});
                    if (~isfield(value, variable))
                        exception = MException('ShinyTemplate:RenderError', '"%s" is not defined. In {{ %s }}', variable, expression);
                        throw(exception);
                    end
                    value = getfield(value, variable);
                    value = this.accessIndex(value, type, index, variable, expression);
                else
                    if (~isfield(value, lookupArray{i}))
                        exception = MException('ShinyTemplate:RenderError', '"%s" is not defined. In {{ %s }}', lookupArray{i}, expression);
                        throw(exception);
                    end
                    value = getfield(value, lookupArray{i});
                end
            end
        end
        
        function output = eval(this, data, context, localContext)
            %EVAL takes parsed template data and returns a cell array
            %of strings
            %   Inputs:
            %       data - the parsed template string
            %       context - a struct whos properties are variables to be
            %       used
            %       localContext - the local context
            %   Outputs:
            %       output - a cell array of strings
            output = {};
            for i = 1:length(data)
                switch data{i}{1}
                    case 'text'
                        output{length(output) + 1} = data{i}{2};
                    case 'display'
                        value = this.lookup(data{i}{2}, context, localContext);
                        
                        if ~ischar(value)
                            value = strtrim(evalc('disp(value);'));
                        end
                        
                        output{length(output) + 1} = value;
                    otherwise
                        if isfield(this.evaluateSymbols, data{i}{1})
                            output = [output this.evaluateSymbols.(data{i}{1})(this, data{i}, context, localContext)];
                        else
                            exception = MException('ShinyTemplate:Render', 'Not implementation for %s', data{i}{1})
                            throw(exception);
                        end
                end
            end
        end
    end
    
    methods
        function loadString(this, string)
            %LOADSTRING parses the template string.
            this.templateString = string;
            this.parseData = this.parseString(1, length(this.templateString));
        end
        
        function loadFile(this, filename)
            %LOADFILE reads and parses the template file
            fid = fopen(filename);
    
            contents = '';

            tline = fgets(fid);
            while ischar(tline)
                contents = [contents tline];
                tline = fgets(fid);
            end
            fclose(fid);
            this.loadString(contents);
        end
        
        function output = render(this, context)
            %RENDER renders a template using the input context
            % Context is a struct whos properties are variables to be used
            % in the template
            outCells = this.eval(this.parseData, context, 0);
            output = strjoin(outCells, '');
        end
        
        function output = evaluate(this, data, context, localContext)
            %EVALUATE takes parsed template data and returns a cell array
            %of strings
            
            output = this.eval(data, context, localContext);
        end
        
        function val = lookupValue(this, expression, context, localContext)
            %LOOKUPVALUE takes an expression and finds the value of it
            % It first searches the localContext before checking context.
            % The expression can be chained property accessors or array
            % accessors
            val = this.lookup(expression, context, localContext);
        end
    end
    
end

