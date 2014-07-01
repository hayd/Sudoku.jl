# Sudoku.jl

A port of Peter Norvig's *["Solving Every Sudoku Puzzle"](http://norvig.com/sudoku.html)* to [Julia](http://julialang.org/).

[![Build Status](https://travis-ci.org/hayd/Sudoku.jl.svg?branch=master)](https://travis-ci.org/hayd/Sudoku.jl)

*This uses constriant propogation and search, see also [John Myles White's Sudoku with simulated annealing](https://github.com/johnmyleswhite/sudoku.jl) and the [Sudoku solver using JuMP](https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/sudoku.jl).*

Benchmark the performance (against Python and JuMP) by running `Bench.jl`. This solver is (currently) around 20% slower than Python and around 3 times faster than JuMP.
