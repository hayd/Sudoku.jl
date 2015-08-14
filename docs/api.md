Sudoku.jl provides the following methods for solving and displaying
sudoku puzzles:

## Constructing sudoku puzzles

{{
    sudoku
    from_file
    show
}}

## Solving puzzles

{{
    propagate
    solve
    solve_all
    is_solved
}}

## Creating random puzzles and testing performance

{{
    random_sudoku
    time_solve
    bench
}}

## Internal

Internally the following functions do the searching and propogation:

{{
    Sudoku.search!
    Sudoku.eliminate!
    Sudoku.assign!
}}

