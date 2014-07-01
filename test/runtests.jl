using Sudoku

using Base.Test
import Iterators: chain


@test length(Sudoku.squares) == 81
@test length(Sudoku.unitlist) == 27
@test all([length(units[s]) == 3 for s=Sudoku.squares])
@test all([length(peers[s]) == 20 for s=Sudoku.squares])

u12 = collect(chain(units[12]...))  # this is impl dependent!
u12_exp = [3,12,21,30,39,48,57,66,75,
       10,11,12,13,14,15,16,17,18,
       1,2,3,10,11,12,19,20,21]
@test u12 == u12_exp

p12_exp = Set{Int64}({1,2,3,10,11,13,14,15,16,17,18,19,20,21,30,39,48,57,66,75})
@test peers[12] == p12_exp

grid1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
grid2 = "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
hard1  = ".....6....59.....82....8....45........3........6..3.54...325..6.................."

vhard1 = "....56......9...5.3.....4..5...9.....7.2.............1.....1.....3..96...9..4...."
vhard2 = "..3...59...2.89...............3926...........4.8..7......9..8......6......9......"

solve(grid1) # warm up
solve_all([grid1, grid2, hard1, vhard1, vhard2], name="test", showif=0.3)

bench()
