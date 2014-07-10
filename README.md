# Sudoku.jl

A port of Peter Norvig's *["Solving Every Sudoku Puzzle"](http://norvig.com/sudoku.html)* to [Julia](http://julialang.org/) (using constraint propagation and search).

[![Build Status](https://travis-ci.org/hayd/Sudoku.jl.svg?branch=master)](https://travis-ci.org/hayd/Sudoku.jl)

```jl
julia> using Sudoku
julia> grid1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300";
julia> s = sudoku(grid1)
    3|  2  |6
9    |3   5|    1
    1|8   6|4
-----+-----+-----
    8|1   2|9
7    |     |    8
    6|7   8|2
-----+-----+-----
    2|6   9|5
8    |2   3|    9
    5|  1  |3

julia> solve(s)
 4 8 3| 9 2 1| 6 5 7
 9 6 7| 3 4 5| 8 2 1
 2 5 1| 8 7 6| 4 9 3
------+------+------
 5 4 8| 1 3 2| 9 7 6
 7 2 9| 5 6 4| 1 3 8
 1 3 6| 7 9 8| 2 4 5
------+------+------
 3 7 2| 6 8 9| 5 1 4
 8 1 4| 2 5 3| 7 6 9
 6 9 5| 4 1 7| 3 8 2
```
Here `solve` works by first propagating the values, and then searching the
cells with the fewest possible values and see whether they get a contradiction
or a solution (see Norvig's post for more details). Check whether it has been
solved using `is_solved`.

```jl
julia> hard1  = ".....6....59.....82....8....45........3........6..3.54...325..6..................";
julia> h = sudoku(hard1);
julia> Sudoku.propagate(h)
  13478     1378     1478  |  124579   134579     6    | 1234579   123479   123579
  13467      5        9    |   1247     1347     1247  |  123467   123467     8
    2       1367     147   |  14579    134579     8    | 1345679   134679   13579  
---------------------------+---------------------------+---------------------------
   1789      4        5    |  126789   16789     1279  | 1236789  1236789   12379  
   1789    12789      3    | 12456789 1456789   12479  |  126789   126789    1279  
   1789    12789      6    |  12789     1789      3    |  12789      5        4
---------------------------+---------------------------+---------------------------
  14789     1789     1478  |    3        2        5    |  14789    14789      6
 13456789 1236789   12478  |  146789   146789    1479  | 12345789 1234789   123579
 13456789 1236789   12478  |  146789   146789    1479  | 12345789 1234789   123579

julia> solve(h)
 4 8 7| 5 3 6| 2 1 9
 6 5 9| 4 1 2| 3 7 8
 2 3 1| 7 9 8| 4 6 5
------+------+------
 1 4 5| 2 6 9| 8 3 7
 8 7 3| 1 5 4| 6 9 2
 9 2 6| 8 7 3| 1 5 4
------+------+------
 7 1 4| 3 2 5| 9 8 6
 5 9 8| 6 4 1| 7 2 3
 3 6 2| 9 8 7| 5 4 1

julia> is_solved(ans)
true

julia> bad1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010303";
julia> b = sudoku(bad1);
julia> solve(b)
    3|  2  |6
9    |3   5|    1
    1|8   6|4
-----+-----+-----
    8|1   2|9
7    |     |    8
    6|7   8|2
-----+-----+-----
    2|6   9|5
8    |2   3|    9
    5|  1  |3   3
Has no solutions.

julia> is_solved(ans)
false
```

Note that Norvig's python implementation used a dictionary of strings as the
implementation. The first revision here did the same, but we now use a single
BitArray of size (9, 81) to track the grid as it is filled in.

*This uses , see also [John Myles White's Sudoku with simulated annealing](https://github.com/johnmyleswhite/sudoku.jl) and the [Sudoku solver using JuMP](https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/sudoku.jl).*

Benchmark the performance against Python and Jump using `Bench.jl`, this is around twice as fast as Python and ten times the speed of JuMP.
