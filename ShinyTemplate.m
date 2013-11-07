classdef ShinyTemplate < handle
    %SHINYTEMPLATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties %(Access = private)
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
            position = -1;
        end
        
        function [matchStart, matchEnd, bisectStart, bisectEnd] = findMatchingTag(this, start, stop, token, bisectToken)
            [allStarts, allEnds] = regexp(this.templateString(start:stop), '{%.*?%}');
            depth = 1;
            for i = 1:length(allStarts)
                if regexp(this.templateString((allStarts(i) + start - 1):(allEnds(i)) + start - 1), strcat('{%\s*', token, '\s*%}'))
                    depth = depth - 1;
                else
                    depth = depth + 1;
                end
                if depth == 0
                    matchStart = allStarts(i) + start - 1;
                    matchEnd = allEnds(i) + start - 1;
                    return;
                end
            end
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
                        if strcmp(controlTokens{1}, 'for')
                            [matchTagStart, matchTagEnd] = this.findMatchingTag(closePos, stop, 'endfor', 0);
                            innerParsed = this.parseString(closePos + 2, matchTagStart - 1);
                            output{length(output) + 1} = {controlTokens{1}, {controlTokens{2:end}}, innerParsed};
                            last = matchTagEnd + 1;
                        elseif strcmp(controlTokens{1}, 'if')
                            [matchTagStart, matchTagEnd, bisectTagStart, bisectTagEnd] = this.findMatchingTag(closePos, stop, 'endif', 'else');
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
            if (localContext == 0)
                exception = MException(strcat('Local variable not found: ', name));
                throw(exception);
            elseif (strcmp(localContext.name, name))
                value = localContext.data;
            else
                value = this.lookupLocal(name, localContext.next);
            end
        end
        
        function value = lookup(this, expression, context, localContext)
            lookupArray = strsplit(expression, '.');
            try 
                value = this.lookupLocal(lookupArray{1}, localContext);
            catch
                value = getfield(context, lookupArray{1});
            end
            
            for i = 2:length(lookupArray)
                value = getfield(value, lookupArray{i});
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

