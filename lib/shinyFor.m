function output = shinyFor(st, data, context, localContext)
%SHINYFOR Summary of this function goes here
%   Detailed explanation goes here
    output = {};
    localName = data{2}{1};
    iterable = st.lookupValue(data{2}{3}, context, localContext);
    for j = 1:length(iterable)
        if (iscell(iterable))
            localData = iterable{j};
        else
            localData = iterable(j);
        end
        newLocalContext = LocalContext(localName, localData);
        newLocalContext.next = localContext;
        output = [output, st.evaluate(data{3}, context, newLocalContext)];
    end
end

