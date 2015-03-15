This is a port of an old school project from [Google Code](https://code.google.com/p/xslt-sudoku-solver/)

This project aims to explore XSLT 1.0 as a general purpose functional programming language, by providing an implementation of a Sudoku puzzle solver, directly executable in a regular browser.

The initial puzzle configuration is saved in an XML file (see sudoku.xml as an example). The format of the file is defined by the XML Schema, which can be found in sudoku\_schema.xsd. To run the style sheet sudoku.xsl open the sudoku.xml file in a XSLT 1.0 compliant web browser. The browser will compute a solution and render it for you.

The guts of the algorithm can be found in the sudoku.xsl file.

Contact author at: 
ivan.vladimirov.ivanov@gmail.com
