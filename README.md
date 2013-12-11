Shiny Template
==============

A Matlab Template Engine

### About

Shiny Template is an extensible template engine written in Matlab, for Matlab. Read DOCS.md to learn about everything you can do.

Much of the syntax of Shiny Template was taken from Jinja

### Set Up

Copy the files into a folder in your project. In Matlab, right click the folder and choose `Add to Path` > `Selected Folders and Subfolders`

### Use

First create an instance of the Shiny Template class:
```
st = ShinyTemplate();
```


Next load a template:
```
t = 'Hello {{ audience }}.';
st.loadString(t);
```


Create the context:
```
c = struct('audience', 'world');
```


Render the template:
```
st.render(c)

ans = 

Hello world.
```