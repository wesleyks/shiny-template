clearvars;
st = ShinyTemplate();
c.name = 'John';
c.food = 'kimchi';
s = 'My name is {{name}} and I like {{food}}.';
st.loadString(s);
assert(strcmp(st.render(c), 'My name is John and I like kimchi.'));

clearvars;
st = ShinyTemplate();
c.foods = {'kimchi', 'banana', 'oreos'};
s = '{% for food in foods %}food {% endfor %}';
st.loadString(s);
assert(strcmp(st.render(c), 'food food food '));

clearvars;
st = ShinyTemplate();
c.foods = {'kimchi', 'banana', 'oreos'};
c.name = 'John';
s = '{% for food in foods %}{{name}} {% endfor %}';
st.loadString(s);
assert(strcmp(st.render(c), 'John John John '));

clearvars;
st = ShinyTemplate();
c.foods = {'kimchi', 'banana', 'oreos'};
s = '{% for food in foods %}{{food}} {% endfor %}';
st.loadString(s);
assert(strcmp(st.render(c), 'kimchi banana oreos '));