function output = shinyIf(st, data, context, localContext)
%SHINYIF Summary of this function goes here
%   Detailed explanation goes here
    checkValue = st.lookupValue(data{2}{1}, context, localContext);
    if checkValue
        output = st.evaluate(data{3}, context, localContext);
    elseif ~isnumeric(data{4})
        output = st.evaluate(data{4}, context, localContext);
    else
        output = {''};
    end
end