Shiny Template Documentation
============================


### Table of Contents
1. [Tags](#tags)
2. [Display](#display)
3. [Control](#control)
4. [Extending Shiny Template](#extend)


<a name='tags' />
### Tags

Shiny Template uses display `{{ ... }}` and control `{% ... %}` tags.

Control tags are used for controlling how the template will be evaluated and is used for iterating across sets of data or for "if else" statements.

Display tags are for evaluating the statements within them and displaying the results into the template's output.


<a name='display' />
### Display

```
context = struct('name', 'Harry');
st.loadString('I am {{ name }}.');
st.render(context)

ans = 

I am Harry.
```


You can access elements in vectors:
```
context = struct('names', {'Harry', 'Ron'});
st.loadString('{{ names{1} }}');
st.render(context)

ans =

Harry
```


You can have nested structs or class properties:
```
person = struct('firstname', 'Harry', 'lastname', 'Potter');
context = struct('person', person);
st.loadString('{{ person.lastname }}');
st.render(context)

ans = 

Potter
```

<a name='control' />
### Control

You can iterate:
```
context = struct('coolnumbers', [42, 2, 1, 0]);
st.loadString('{% for number in coolnumbers %}{{ number }} {% endfor %}');
st.render(context)

ans =

42 2 1 0 
```


You can have conditional statements:
```
context = struct('foo', false);
st.loadString('{% if foo %}bar{% else %}baz{% endif %}');
st.render(context)

ans = 

baz
```


The else branch is optional:
```
context = struct('foo', true);
st.loadString('{% if foo %}bar{% endif %}');
st.render(context)

ans = 

bar
```

<a name='extend' />
### Extending Shiny Template

You can extend Shiny Template with your own control keywords. Just edit the parserSymbold and evaluateSymbols properties in ShinyTemplate.m to include your own keywords.


####Example - adding the "foo" keyword

Let the parser know about foo:
```
parserSymbols = struct('foo',  struct('branches', 1),...
```


Assuming that the function, "shinyFoo", has been implemented and is in the "lib" folder. Let the renderer/eval know how to handle "foo":
```
evaluateSymbols = struct('for',  @shinyFoo,...
```