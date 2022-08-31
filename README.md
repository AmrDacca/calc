# calc

This project was implemented during the coursework  Computer Organization And Programming in of which we were asked to implement a simple calculator 
given an expression with the  + - / *  () operators and calculates the result and prints it

The expression is defined recursively as:
1.(num)

as the the num can be a positive or negative number

2.(num OP num)

the OP is on one the given operators '+' '/' '-' '*'
3.(EXP)

recursively as the definition 1

4.(EXP OP EXP)


The numbers supported to 64bit numbers


# How To Run

as hw2_sol.asm -o hw2_sol.o


gcc -no-pie calc.c hw2_sol.o -o calc


./calc


and enter the expression after running.
