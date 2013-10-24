Shiny Template Documentation
============================


### Table of Contents
1. [Tags](#tags)
2. [Control](#control)


<a name='tags' />
### Tags

The Shiny Template uses display `{{ ... }}` and control `{% ... %}` tags.

Control tags are used for controlling how the template will be evaluated and is used for iterating across sets of data or for "if else" statements.

Display tags are for evaluating the statements within them and displaying the results into the template's output.


<a name='display' />
### Display

Suppose `context('name') = 'Harry';`.
```
I am {{ name }}.
```
should output
```
I am Harry.
```


<a name='control' />
### Control

Suppose `context('people') = {'Harry', 'Ron', 'Hermione'};`.
```
{% for person in people %}
I am {{ person }}.
{% endfor %}
```
should output
```
I am Harry.
I am Ron.
I am Hermione.
```