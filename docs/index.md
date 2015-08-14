# Sudoku.jl

A port of Peter Norvig's *["Solving Every Sudoku Puzzle"](http://norvig.com/sudoku.html)* to [Julia](http://julialang.org/).

You can create a `SudokuPuzzle` from a string input, using the `sudoku` method.

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
```
Sometimes a puzzle can be solved simply by propogating the values (no
searching required):

```jl
julia> propogate(s)
 4 9 2| 5 7 1| 3 8 6
 8 6 5| 4 2 3| 7 1 9
 3 7 1| 8 9 6| 2 4 5
------+------+------
 9 3 8| 1 5 7| 6 2 4
 2 4 7| 3 6 9| 8 5 1
 1 5 6| 2 4 8| 9 3 7
------+------+------
 6 8 4| 9 1 2| 5 7 3
 5 2 9| 7 3 4| 1 6 8
 7 1 3| 6 8 5| 4 9 2
```

However, often this is not sufficient to solve the Sudoku, and we need to try
out (search) different possible values and see whether they get a contradiction
or a solution:

```jl
julia> hard1  = ".....6....59.....82....8....45........3........6..3.54...325..6..................";
julia> p = propogate(hard1)
  13478    13467      2    |   1789     1789     1789  |  14789   13456789 13456789
   1378      5       1367  |    4      12789    12789  |   1789   1236789  1236789 
   1478      9       147   |    5        3        6    |   1478    12478    12478  
---------------------------+---------------------------+---------------------------
  124579    1247    14579  |  126789  12456789  12789  |    3      146789   146789 
  134579    1347    134579 |  16789   1456789    1789  |    2      146789   146789 
    6       1247      8    |   1279    12479      3    |    5       1479     1479  
---------------------------+---------------------------+---------------------------
 1234579   123467  1345679 | 1236789   126789   12789  |  14789   12345789 12345789
  123479   123467   134679 | 1236789   126789     5    |  14789   1234789  1234789 
  123579     8      13579  |  12379     1279      4    |    6      123579   123579 

julia> solve(p)
 4 6 2| 1 8 9| 7 5 3
 8 5 3| 4 7 2| 1 9 6
 7 9 1| 5 3 6| 4 8 2
------+------+------
 5 4 7| 2 1 8| 3 6 9
 3 1 9| 6 5 7| 2 4 8
 6 2 8| 9 4 3| 5 1 7
------+------+------
 2 3 4| 8 6 1| 9 7 5
 1 7 6| 3 9 5| 8 2 4
 9 8 5| 7 2 4| 6 3 1
```
Solve a list of Sudokus using `solve_all`.

## Note on implementation

Initially used a dictionary of strings (like Norvig), but now uses a BitArray
to track the partial grid. This has the benefit of being easily extended to
arbitrary sized puzzles.

*Solving is done uses constriant propogation and search, see also [John Myles White's
Sudoku with simulated annealing](https://github.com/johnmyleswhite/sudoku.jl)
and the [Sudoku solver using JuMP](https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/sudoku.jl).*

Benchmark the performance against Python and Jump using `Bench.jl`, this is
around twice as fast as Python and ten times the speed of JuMP. Please try it
yourself!
