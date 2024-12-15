# c3docgen

program to generate documents from c3 source files.

will search for all .c3 files and create documents from sources.
by default, it will generate separate .md files for each module.
modules separate by multiple files will be concatenated into a single file.

there are limitations to using multiple files. if you have modules in the
project folder that have the same name, only 1 file will be generated for that module
which will likely be the first one encountered in the scan.

c3docgen mono will generate a single file with all the modules. this is the only way to
ensure all contidional modules and modules that have the same name will be scanned for
documentation.

documentation consists of using <* *> pairs. the opening pair must be aligned with the
beginning of a line, or they are ignored and treated like normal text.

functions and macros that are not documented will still be added to the output document.

to add documents to a top level file (a module), there should be only one per module.

```
<*
	my module
*>
module my_module;
```

```the output generated will be an .md file. markdown files ignore new lines that
appear before the '@' character. use a tab to make sure the new lines are inserted.
```