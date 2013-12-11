% test basic lookup
c.name = 'John';
c.food = 'kimchi';
s = 'My name is {{name}} and I like {{food}}.';
assert(strcmp(loadAndRender(c, s), 'My name is John and I like kimchi.'));

% test iteration
c.foods = {'kimchi', 'banana', 'oreos'};
s = '{% for food in foods %}food {% endfor %}';
assert(strcmp(loadAndRender(c, s), 'food food food '));

% test iteration and lookup
c.foods = {'kimchi', 'banana', 'oreos'};
c.name = 'John';
s = '{% for food in foods %}{{name}} {% endfor %}';
assert(strcmp(loadAndRender(c, s), 'John John John '));

c.foods = {'kimchi', 'banana', 'oreos'};
s = '{% for food in foods %}{{food}} {% endfor %}';
assert(strcmp(loadAndRender(c, s), 'kimchi banana oreos '));

% test if
c.a = 1;
s = '{% if a %}hi{% endif %}';
assert(strcmp(loadAndRender(c, s), 'hi'));

c.a = 0;
s = '{% if a %}hi{% endif %}';
assert(strcmp(loadAndRender(c, s), ''));

c.a = 1;
s = '{% if a %}hi{% else %}ha{% endif %}';
assert(strcmp(loadAndRender(c, s), 'hi'));

c.a = 0;
s = '{% if a %}hi{% else %}ha{% endif %}';
assert(strcmp(loadAndRender(c, s), 'ha'));

% test accessing arrays
c.a = {'a', 'b'};
s = '{{ a{1} }}';
assert(strcmp(loadAndRender(c, s), 'a'));

c.a = [1, 2, 3];
s = '{{ a(2) }}';
assert(strcmp(loadAndRender(c, s), '2'));

c.a.b = {'a', 'b'};
s = '{{ a.b{2} }}';
assert(strcmp(loadAndRender(c, s), 'b'));

% test tag expected exception
try
    s = '{{ a.b';
    loadAndRender(c, s);
    assert(false); % failed to throw exception
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:ParseError'));
    assert(strcmp(err.message, 'Tag expected, found: {{ a.b'));
end

% test closing tag not found exception
try
    c.a = 1;
    s = '{% if a %}';
    loadAndRender(c, s);
    assert(false); % failed to throw exception
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:ParseError'));
    assert(strcmp(err.message, 'Closing tag for {% if a %} not found, expected: {% endif %}'));
end

% test variable not defined exception
try
    s = '{{ banana }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"banana" is not defined. In {{ banana }}'));
end

try
    c.a = 2;
    s = '{{ a.banana }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"banana" is not defined. In {{ a.banana }}'));
end

% test variable not cell array exeption
try 
    c.a = 1;
    s = '{{ a{1} }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"a" is not a cell array. In {{ a{1} }}'));
end

try 
    c.a.b = 1;
    s = '{{ a.b{1} }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"b" is not a cell array. In {{ a.b{1} }}'));
end

try
    c.a = {'a', 'b'};
    s = '{% for x in a %}{{ x{1} }}{% endfor %}';
    loadAndRender(c, s)
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"x" is not a cell array. In {{ x{1} }}'));
end

% test variable not vector exception
try 
    c.a = [1 2; 3 4];
    s = '{{ a(1) }}';
    loadAndRender(c, s)
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"a" is not a vector. In {{ a(1) }}'));
end

try 
    c.a.b = [1 2; 3 4];
    s = '{{ a.b(1) }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, '"b" is not a vector. In {{ a.b(1) }}'));
end

% test index exceeds dimensions exception
try
    c.a = [1,2,3];
    s = '{{ a(4) }}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:RenderError'));
    assert(strcmp(err.message, 'Index exceeds dimensions. In {{ a(4) }}'));
end

% test symbol not recognized exception
try
    c.a = [1,2,3];
    s = '{% fir x in a %}{% endfir %}';
    loadAndRender(c, s);
    assert(false);
catch err
    assert(strcmp(err.identifier, 'ShinyTemplate:ParseError'));
    assert(strcmp(err.message, 'Symbol not recognized, fir'));
end