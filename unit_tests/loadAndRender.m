function result = loadAndRender(context, string)
%LOADANDRENDER loads and renders the template
%   Renders the template, string, using context, a struct.
    st = ShinyTemplate();
    st.loadString(string);
    result = st.render(context);
end