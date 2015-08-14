using Sudoku

using Base.Test
import Iterators: chain


@test length(Sudoku.squares) == 81
@test length(Sudoku.unitlist) == 27
@test all([length(Sudoku.units[s]) == 3 for s=Sudoku.squares])
@test all([length(Sudoku.peers[s]) == 20 for s=Sudoku.squares])

u12 = collect(chain(Sudoku.units[12]...))  # this is impl dependent!
#u12_exp = [3,12,21,30,39,48,57,66,75,
#       10,11,12,13,14,15,16,17,18,
#       1,2,3,10,11,12,19,20,21]
u12_exp = [19,20,21,22,23,24,25,26,27,
           2,11,20,29,38,47,56,65,74,
           1,10,19,2,11,20,3,12,21]
@test u12 == u12_exp

p12_exp = Set{Int64}(Int64[1,2,3,10,11,13,14,15,16,17,18,19,20,21,30,39,48,57,66,75])
@test Sudoku.peers[12] == p12_exp

grid1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
grid2 = "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
hard1  = ".....6....59.....82....8....45........3........6..3.54...325..6.................."

vhard1 = "....56......9...5.3.....4..5...9.....7.2.............1.....1.....3..96...9..4...."
vhard2 = "..3...59...2.89...............3926...........4.8..7......9..8......6......9......"

solve(grid1) # warm up
solve_all([grid1, grid2, hard1, vhard1, vhard2], name="test", showif=0.3)

@test string(solve(grid1)) == "483921657967345821251876493548132976729564138136798245372689514814253769695417382"
@test string(solve(grid2)) == "417369825632158947958724316825437169791586432346912758289643571573291684164875293"
@test string(solve(hard1)) == "487536219659412378231798465145269837873154692926873154714325986598641723362987541"
@test string(solve(vhard1)) == "921456873467938152358712496534197268176284935289365741645871329713529684892643517"
@test string(solve(vhard2)) == "713426598642589731985173246157392684326845917498617352264951873531768429879234165"

@test sprint(io -> show(io, solve(grid1))) == """\
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
"""

bad1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010303"
@test solve(bad1).vals == false

function remove_trailing_whitespace(s)
    join(map(rstrip, split(s, '\n')), '\n')
end
@test remove_trailing_whitespace(sprint(io -> show(io, solve(bad1)))) == """\
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
"""

bench()
