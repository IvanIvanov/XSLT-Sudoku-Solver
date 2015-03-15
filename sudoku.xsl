<?xml version="1.0" encoding="UTF-8" ?>

<!--
Copyright (c) 2010 Ivan Vladimirov Ivanov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE

-->

<!-- 
This stylesheet implements a Sudoku solver. When applied to a XML file representing a Sudoku position
(defined by the XML schema: sudoku_schema.xsd) its first step is to serialize the position into a flat string representation.
After this preliminary work it sets up three additional data-structures for use in the computation:
    
    - digits-in-row:  allows to answer questions of the form "Is a given digit already present in a given row?";
    - digits-in-col:  allows to answer questions of the form "Is a given digit already present in a given column?";
    - digits-in-square:  allows to answer questions of the form "Is a given digit already present in a given "big" 3 by 3 square?".

Relying on these data-structures a backtracking search is performed. The search proceeds by consecutively
examining the squares of the board in row major order. When an unfilled square is reached (represented by 0)
an attempt is made to fill it in with a digit from 1 to 9 not already present in the given row, column, or "big" 3 by 3
square. Once a digit is placed all data-structures are updated and the algorithm moves to the next square backtracking
as necessary.

When the solution is found a "user friendly"  HTML representation of it is generated.

The stylesheet complies with the specification of XSLT 1.0 in order to be executable directly by browsers supporting
this standard.
-->  

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" indent="yes"/>
          
    <xsl:template match="/">
        <!-- Convert XML Sudoku representation into a flat string. -->
        <xsl:variable name="board">
            <xsl:for-each select="/sudoku/row">
                <xsl:value-of select="self::node()"/>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- 
                   Construct an equivalent of a two-dimensional table that can be indexed as (digit, row) pairs mapping
                   to a 0 or 1 depending on whether the given digit is contained in the given row. The table is represented
                   as a string. For example the character at position (9 * digit + row + 1) in the string corresponds to the table entry
                   idexed as (digit, row). Digits are under indices from 1 to 9 inclusive, rows are in the range from 0 to 8
                   inclusive, and adding 1 is necessary to compensate for the fact that strings in XPath are indexed starting
                   from 1. 
                   -->
        <xsl:variable name="digits-in-row">
            <xsl:call-template name="init-digits-in-row">
                <xsl:with-param name="board" select="$board"/>
                <xsl:with-param name="row" select="0"/>
                <xsl:with-param name="col" select="0"/>
                <xsl:with-param name="digits-in-row" select="'000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- 
                   Construct an equivalent of a two-dimensional table that can be indexed as (digit, col) pairs mapping
                   to a 0 or 1 depending on whether the given digit is contained in the given column. The table is represented
                   as a string. For example the character at position (9 * digit + col + 1) in the string corresponds to the table entry
                   idexed as (digit, col). Digits are under indices from 1 to 9 inclusive, columns are in the range from 0 to 8
                   inclusive, and adding 1 is necessary to compensate for the fact that strings in XPath are indexed starting
                   from 1. 
                   -->
        <xsl:variable name="digits-in-col">
            <xsl:call-template name="init-digits-in-col">
                <xsl:with-param name="board" select="$board"/>
                <xsl:with-param name="row" select="0"/>
                <xsl:with-param name="col" select="0"/>
                <xsl:with-param name="digits-in-col" select="'000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- 
                   Construct an equivalent of a three-dimensional table that can be indexed as (digit, row-big, col-big)  tuples mapping
                   to a 0 or 1 depending on whether the given digit is contained in the "big" 3 by 3 square defined by row-big and col-big. 
                   "Big"squares are determined by (row-big, col-big) pairs, where the rows and columns are numbered from 0 to 2
                   inclusive. The table is represented as a string. For example the character at position (9 * digit + 3 * row-big + col-big + 1) 
                   in the string corresponds to the table entry idexed as (digit, row-big, col-big). Digits are under indices from 1 to 9 inclusive, 
                   the "big" rows and columns are in the range from 0 to 2 inclusive, and adding 1 is necessary to compensate for the fact 
                   that strings in XPath are indexed starting from 1. 
                   -->
        <xsl:variable name="digits-in-square">
            <xsl:call-template name="init-digits-in-square">
                <xsl:with-param name="board" select="$board"/>
                <xsl:with-param name="row" select="0"/>
                <xsl:with-param name="col" select="0"/>
                <xsl:with-param name="digits-in-square" select="'000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- The solution of the puzzle is stored in a variable as a string representing the completed board or 0 if there is no solution. -->
        <xsl:variable name="result">
            <xsl:call-template name="search">
                <xsl:with-param name="board" select="$board"/>
                <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                <xsl:with-param name="row" select="0"/>
                <xsl:with-param name="col" select="0"/>
                <xsl:with-param name="digit" select="1"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Assuming that there is a solution a nice "user-friendly" html representation of it is generated --> 
        <xsl:call-template name="format-output">
            <xsl:with-param name="board" select="$board"/>
            <xsl:with-param name="result" select="$result"/>
        </xsl:call-template>
        
    </xsl:template>
    
    <!-- A Sudoku board is traversed in row-major order and along the way the digits-in-row data-structure is constructed. -->
    <xsl:template name="init-digits-in-row">
        <xsl:param name="board"/>
        <xsl:param name="row"/>
        <xsl:param name="col"/>
        <xsl:param name="digits-in-row"/>
        
        <xsl:choose>
            <xsl:when test="$col = 9">
                <xsl:call-template name="init-digits-in-row">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row + 1"/>
                    <xsl:with-param name="col" select="0"/>
                    <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$row = 9">
                <xsl:value-of select="$digits-in-row"/>
            </xsl:when>
            
            <xsl:when test="substring($board, 9 * $row + $col + 1, 1) = '0'">
                <xsl:call-template name="init-digits-in-row">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:variable name="digit">
                    <xsl:value-of select="number(substring($board, 9 * $row + $col + 1, 1))"/>
                </xsl:variable>
                <xsl:call-template name="init-digits-in-row">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digits-in-row" select="concat(substring($digits-in-row, 1, 9 * $digit + $row), '1', substring($digits-in-row, 9 * $digit + $row + 2))"/>
                </xsl:call-template>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:template>
    
    <!-- A Sudoku board is traversed in row-major order and along the way the digits-in-col data-structure is constructed. -->
    <xsl:template name="init-digits-in-col">
        <xsl:param name="board"/>
        <xsl:param name="row"/>
        <xsl:param name="col"/>
        <xsl:param name="digits-in-col"/>
        
        <xsl:choose>
            <xsl:when test="$col = 9">
                <xsl:call-template name="init-digits-in-col">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row + 1"/>
                    <xsl:with-param name="col" select="0"/>
                    <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$row = 9">
                <xsl:value-of select="$digits-in-col"/>
            </xsl:when>
            
            <xsl:when test="substring($board, 9 * $row + $col + 1, 1) = '0'">
                <xsl:call-template name="init-digits-in-col">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:variable name="digit">
                    <xsl:value-of select="number(substring($board, 9 * $row + $col + 1, 1))"/>
                </xsl:variable>
                <xsl:call-template name="init-digits-in-col">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digits-in-col" select="concat(substring($digits-in-col, 1, 9 * $digit + $col), '1', substring($digits-in-col, 9 * $digit + $col + 2))"/>
                </xsl:call-template>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:template>
    
    <!-- A Sudoku board is traversed in row-major order and along the way the digits-in-square data-structure is constructed. -->
    <xsl:template name="init-digits-in-square">
        <xsl:param name="board"/>
        <xsl:param name="row"/>
        <xsl:param name="col"/>
        <xsl:param name="digits-in-square"/>
        
        <xsl:choose>
            <xsl:when test="$col = 9">
                <xsl:call-template name="init-digits-in-square">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row + 1"/>
                    <xsl:with-param name="col" select="0"/>
                    <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$row = 9">
                <xsl:value-of select="$digits-in-square"/>
            </xsl:when>
            
            <xsl:when test="substring($board, 9 * $row + $col + 1, 1) = '0'">
                <xsl:call-template name="init-digits-in-square">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:variable name="digit">
                    <xsl:value-of select="number(substring($board, 9 * $row + $col + 1, 1))"/>
                </xsl:variable>
                <xsl:call-template name="init-digits-in-square">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <!-- 
                                               The (row-big, col-big) pair that determines a "big" square can be computed from the coordinates of a small square
                                               using the formula: ((floor(row div 3), floor(col div 3))). The application of the floor function is necessary because
                                               the XPath div operator performs floating-point division.                                 
                                                -->
                    <xsl:with-param name="digits-in-square" select="concat(substring($digits-in-square, 1, 9 * $digit + 3 * floor($row div 3) + floor($col div 3)), '1', substring($digits-in-square, 9 * $digit + 3 * floor($row div 3) + floor($col div 3) + 2))"/>
                </xsl:call-template>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:template>
    
    <!-- 
         The search proceeds by consecutively examining the squares of the board in row-major order. When an unfilled square is 
         reached (represented by 0) an attempt is made to fill it in with a digit from 1 to 9 not already present in the given row, column, 
         or "big" square. Once a digit is placed all data-structures (board, digits-in-row, digits-in-col, digits-in-square) are updated and the 
         algorithm moves to the next square backtracking as necessary.
         -->
    <xsl:template name="search">
        <xsl:param name="board"/>
        <xsl:param name="digits-in-row"/>
        <xsl:param name="digits-in-col"/>
        <xsl:param name="digits-in-square"/>
        <xsl:param name="row"/>
        <xsl:param name="col"/>
        <xsl:param name="digit"/>
        
        <xsl:choose>
            <xsl:when test="$col = 9">
                <xsl:call-template name="search">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                    <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                    <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                    <xsl:with-param name="row" select="$row + 1"/>
                    <xsl:with-param name="col" select="0"/>
                    <xsl:with-param name="digit" select="1"/>
                </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$row = 9">
                <xsl:value-of select="$board"/>
            </xsl:when>
            
            <xsl:when test="$digit = 10">
                <xsl:value-of select="0"/>
            </xsl:when>
            
            <xsl:when test="substring($board, 9 * $row + $col + 1, 1) = '0'">
                <xsl:choose>
                    <!-- 
                                               Can the current digit be placed in the current square without violating the rules? 
                                               
                                               The coordinates row-big and col-big of the current "big" square are computed from the coordinates
                                               of the current "small" square using the formula: ((floor(row div 3), floor(col div 3))). The application 
                                               of the floor function is necessary because the XPath div operator performs floating-point division.  
                                               -->
                    <xsl:when test="substring($digits-in-row, 9 * $digit + $row + 1, 1) = '0' and
                                    substring($digits-in-col, 9 * $digit + $col + 1, 1) = '0' and
                                    substring($digits-in-square, 9 * $digit + 3 * floor($row div 3) + floor($col div 3) + 1, 1) = '0'">
                                    
                        <xsl:variable name="result">
                            <xsl:call-template name="search">
                                <xsl:with-param name="board" select="concat(substring($board, 1, 9 * $row + $col), string($digit), substring($board, 9 * $row + $col + 2))"/>
                                <xsl:with-param name="digits-in-row" select="concat(substring($digits-in-row, 1, 9 * $digit + $row), '1', substring($digits-in-row, 9 * $digit + $row + 2))"/>
                                <xsl:with-param name="digits-in-col" select="concat(substring($digits-in-col, 1, 9 * $digit + $col), '1', substring($digits-in-col, 9 * $digit + $col + 2))"/>
                                <xsl:with-param name="digits-in-square" select="concat(substring($digits-in-square, 1, 9 * $digit + 3 * floor($row div 3) + floor($col div 3)), '1', substring($digits-in-square, 9 * $digit + 3 * floor($row div 3) + floor($col div 3) + 2))"/>
                                <xsl:with-param name="row" select="$row"/>
                                <xsl:with-param name="col" select="$col + 1"/>
                                <xsl:with-param name="digit" select="1"/>
                            </xsl:call-template>     
                        </xsl:variable>
                        
                        <xsl:choose>
                            <xsl:when test="not($result = 0)">
                                <xsl:value-of select="$result"/>
                            </xsl:when>   
                            
                            <xsl:otherwise>
                                <xsl:call-template name="search">
                                    <xsl:with-param name="board" select="$board"/>
                                    <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                                    <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                                    <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                                    <xsl:with-param name="row" select="$row"/>
                                    <xsl:with-param name="col" select="$col"/>
                                    <xsl:with-param name="digit" select="$digit + 1"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:call-template name="search">
                            <xsl:with-param name="board" select="$board"/>
                            <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                            <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                            <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="col" select="$col"/>
                            <xsl:with-param name="digit" select="$digit + 1"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:call-template name="search">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="digits-in-row" select="$digits-in-row"/>
                    <xsl:with-param name="digits-in-col" select="$digits-in-col"/>
                    <xsl:with-param name="digits-in-square" select="$digits-in-square"/>
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="col" select="$col + 1"/>
                    <xsl:with-param name="digit" select="1"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- 
         A board is transformed into an outer HTML 3 by 3 table. Each entry of that table is itself a 3 by 3 inner table that contains the
         individual digits. 
         -->
    <xsl:template name="display-sudoku">
        <xsl:param name="board"/>
        
            <table class="outer_table">
                <tr>
                <td><table class="inner_table_dark">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 1, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 2, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 3, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 10, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 11, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 12, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 19, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 20, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 21, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_light">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 4, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 5, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 6, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 13, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 14, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 15, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 22, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 23, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 24, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_dark">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 7, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 8, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 9, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 16, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 17, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 18, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 25, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 26, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 27, 1)"/></div></td>
                    </tr>
                </table></td>
                </tr>
                <tr>
                <td><table class="inner_table_light">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 28, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 29, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 30, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 37, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 38, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 39, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 46, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 47, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 48, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_dark">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 31, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 32, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 33, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 40, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 41, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 42, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 49, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 50, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 51, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_light">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 34, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 35, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 36, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 43, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 44, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 45, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 52, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 53, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 54, 1)"/></div></td>
                    </tr>
                </table></td>
                </tr>
                <tr>
                <td><table class="inner_table_dark">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 55, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 56, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 57, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 64, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 65, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 66, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 73, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 74, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 75, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_light">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 58, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 59, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 60, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 67, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 68, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 69, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 76, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 77, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 78, 1)"/></div></td>
                    </tr>
                </table></td>
                <td><table class="inner_table_dark">
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 61, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 62, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 63, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 70, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 71, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 72, 1)"/></div></td>
                    </tr>
                    <tr>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 79, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 80, 1)"/></div></td>
                    <td><div class="unit_square"><xsl:value-of select="substring($board, 81, 1)"/></div></td>
                    </tr>
                </table></td>
                </tr>
            </table>
    </xsl:template>
    
    <!-- Genarates a "user-friendly" HTML web page that shows both the initial configuration of the puzzle and its solution.--> 
    <xsl:template name="format-output">
        <xsl:param name="board"/>
        <xsl:param name="result"/>
        
        <html>
            <head>
                <title>XSLT 1.0 Sudoku Solver</title>
                <link rel="stylesheet" href="sudoku_style.css" type="text/css"/>
            </head>
            
            <body>
                <div id="page">
                    <div id="header">XSLT 1.0 Sudoku Solver</div>
                    
                        <table id="content_table">
                            <tr>
                            <th style="padding-right: 60px;">Puzzle</th>
                            <th style="padding-left: 60px;">Solution</th></tr>
                            <tr>
                            <td style="padding-right: 60px;">
                            <xsl:call-template name="display-sudoku">
                                <xsl:with-param name="board" select="$board"/>
                            </xsl:call-template>
                            </td>
                            <td style="padding-left: 60px;">
                            <xsl:call-template name="display-sudoku">
                                <xsl:with-param name="board" select="$result"/>
                            </xsl:call-template>
                            </td>
                            </tr>
                        </table>
                    
                    <div id="footer">
                      <hr/>
                      <em>Copyright (c) 2010 Ivan Vladimirov Ivanov</em>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>
    
</xsl:stylesheet>
