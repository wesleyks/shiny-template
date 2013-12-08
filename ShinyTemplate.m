classdef ShinyTemplate < handle
    %SHINYTEMPLATE Summary of this class goes here
    %   Detailed explanation goes here
    
    % exceptions to throw, not
    % a vector or array
    
    properties (Constant)
        parserSymbols = struct( 'for',  struct('branches', 1),...
                                'if',   struct('branches', 2, 'bisect', 'else'));
    end
    
    properties (Access = private)
        templateString;
        parseData;
    end
    
    methods (Access = private)
        function position = findClose(this, start, stop, substring)
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
                        end
%                         if strcmp(controlTokens{1}, 'for')
%                             [matchTagStart, matchTagEnd] = this.findMatchingTag(closePos, stop, 'endfor', 0, this.templateString(i:(closePos + 1)));
%                             innerParsed = this.parseString(closePos + 2, matchTagStart - 1);
%                             output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed};
%                             last = matchTagEnd + 1;
%                         elseif strcmp(controlTokens{1}, 'if')
%                             [matchTagStart, matchTagEnd, bisectTagStart, bisectTagEnd] = this.findMatchingTag(closePos, stop, 'endif', 'else', this.templateString(i:(closePos + 1)));
%                             if (bisectTagStart > 0)
%                                 innerParsed1 = this.parseString(closePos + 2, bisectTagStart - 1);
%                                 innerParsed2 = this.parseString(bisectTagEnd + 1, matchTagStart - 1);
%                                 output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed1, innerParsed2};
%                                 last = matchTagEnd + 1;
%                             else
%                                 innerParsed = this.parseString(closePos + 2, matchTagStart - 1);
%                                 output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed, 0};
%                                 last = matchTagEnd + 1;
%                             end
%                         end
                        i = last - 1;
                end
                i = i + 1;
            end
            if (last <= stop)
                output{length(output) + 1} = {'text', this.templateString(last:i)};
            end
        end
        
        function value = lookupLocal(this, name, localContext)
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
            value = regexp(string, '^.*[(|{]\d+[)|}]$', 'once');
        end
        
        function [variable, index, type] = isolateIndex(this, string)
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
                    case 'for'
                        localName = data{i}{2}{1};
                        iterable = this.lookup(data{i}{2}{3}, context, localContext);
                        for j = 1:length(iterable)
                            if (iscell(iterable))
                                localData = iterable{j};
                            else
                                localData = iterable(j);
                            end
                            newLocalContext = LocalContext(localName, localData);
                            newLocalContext.next = localContext;
                            output = [output, this.eval(data{i}{3}, context, newLocalContext)];
                        end
                    case 'if'
                        checkValue = this.lookup(data{i}{2}{1}, context, localContext);
                        if checkValue
                            output = [output, this.eval(data{i}{3}, context, localContext)];
                        elseif ~isnumeric(data{i}{4})
                            output = [output, this.eval(data{i}{4}, context, localContext)];
                        end
                end
            end
        end
    end
    
    methods
        function loadString(this, string)
            this.templateString = string;
            this.parseData = this.parseString(1, length(this.templateString));
        end
        
        function output = render(this, context)
            outCells = this.eval(this.parseData, context, 0);
            output = strjoin(outCells, '');
        end
    end
    
end

