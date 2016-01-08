#Code Pull
This vim plugin allows you to pull code from the web into your own code, without ever leaving the editor
##Setup
This plugin is pathogen compatible. If you do not have pathogen, simply clone this project in your system's ```~/.vim``` directory.
After installing, the plugin should load whenever vim is launched.
##Usage
To use this plugin, open vim, position your cursor on the line above where you want to put the code. Then enter command mode and type 
<pre>:Pull <i>search terms</i></pre>
where *search terms* is a description of the function you want to pull. You do not need to include the language name, as the plugin infers this from the file type of the file you are editing.
###Example
Open vim with a python file, say *rev.py*. Once in the editor, type ```:Pull reverse string```. The plugin will run for a few seconds, and then insert a method that reverses a string below the cursor position.
##Contributing
Any and all help or improvements on this project is very much welcome. You should start by taking a look at [current issues](https://github.com/kasandell/Code-Pull/issues), and seeing what you can fix/improve there.
###Current Contribution Ideas
•Port to [Atom text editor](https://atom.io)


•Use [searchcode's](https://searchcode.com/api/) api to correctly map more filetypes(```echo &filetype```) to their id number as assigned by searchcode


•Help me create a psuedo-style language to allow for easy prototyping of functions, that you can pass to the plugin, and have the function built in your code in your preferred language.
