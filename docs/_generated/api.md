<!-- AUTOGENERATED. See 'doc/build.jl' for source. -->
Sudoku.jl provides the following methods for solving and displaying
sudoku puzzles:

## Constructing sudoku puzzles

### sudoku

Create a `SudokuPuzzle` from a string, for example:

```
julia> sudoku("003020600900305001001806400008102900700000008006708200002609500800203009005010300")
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

```
1  sudoku(init::AbstractString)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L35)*.

### from_file

Parse a file into a list of strings, separated by sep.

```
1  from_file(filename)
2  from_file(filename, sep)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L282) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L282)*.

### show

Display puzzles as a 2-D grid.

```
1  show(io::IO, grid::Sudoku.SudokuPartial)
2  show(io::IO, p::Sudoku.SudokuPuzzle)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L223) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L245)*.



## Solving puzzles

### propagate

Convert grid to a `SudokuPartial` of possible values, `vals` is a `BitArray{2}` remove values already seen in a shared unit

Returns `false` if a contradiction is detected.

```
1  propagate(grid::Sudoku.SudokuPuzzle)
2  propagate(grid::AbstractString)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L75) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L82)*.

### solve

Solve a sudoku puzzle.

```
1  solve(p::Sudoku.SudokuPuzzle)
2  solve(init::AbstractString)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L157) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L164)*.

### solve_all

Attempt to solve a sequence of grids. Report results.

Display the puzzles that take longer than `showif` seconds to solve, see `time_solve`.

```
1  solve_all(grids)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L316)*.

### is_solved

Returns `true` if the grid is completely filled in.

```
1  is_solved(grid::Sudoku.SudokuPartial)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L194)*.



## Creating random puzzles and testing performance

### random_sudoku

Make a random puzzle with N or more assignments. Restart on contradictions.

Note the resulting puzzle is not guaranteed to be solvable, but empirically about 99.8% of them are solvable. Some have multiple solutions.

```
1  random_sudoku()
2  random_sudoku(N::Integer)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L204) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L204)*.

### time_solve

Time how long it takes to solve `grid`.

If it takes longer than `showif` seconds to solve, print `grid` and whether or not it has been solved.

This is useful for finding "difficult" random puzzles.

```
1  time_solve(grid, showif)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L295)*.

### bench

Benchmarking: Solve some some example puzzles:

  * easy (from easy.txt)
  * hard (from top95.txt)
  * hardest (from hardest.txt)
  * 100 random puzzles.

```
1  bench()
2  bench(N::Integer)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L337) [2](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L349)*.



## Internal

Internally the following functions do the searching and propogation:

### search!

Using depth-first search and propogation, try all possible values.

```
1  search!(vals::BitArray{2})
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L169)*.

### eliminate!

Eliminate `d` from `vals[:, s]`; propagate when values or places <= 2. Returns `false` if a contradiction is detected.

```
1  eliminate!(vals::BitArray{2}, s::Int64, d::Int64)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L122)*.

### assign!

Eliminate all the other values (except d) from `vals[:, s]` and propagate.

Returns values, or `false` if a contradiction is detected.

```
1  assign!(vals::BitArray{2}, s::Int64, d::Int64)
```
*Source: [1](https://github.com/hayd/Sudoku.jl/tree/4a25779219c3f5701d2a8feffdb38b52faaacbdb/src/Sudoku.jl#L108)*.


