module Sudoku

export SudokuPuzzle, sudoku,
       peers, units,
       is_solved, solve, solve_all,
       random_sudoku,
       bench


import Iterators: chain, imap

# init is the string representation to solve
type SudokuPuzzle
    init::ASCIIString

    SudokuPuzzle(init::String) = new(_clean(init))
end
sudoku(init::String) = SudokuPuzzle(init)
# vals represents the possible entries (from 1 to 9 in 81 squares)
# when initiatializing we propagate these values (across units)
# if vals is false, this means there was a contradition (no solutions).
typealias MaybeVals Union(BitArray{2}, Bool)
type SudokuPartial
    vals::MaybeVals
    puzzle::SudokuPuzzle

    SudokuPartial(vals::MaybeVals, puzzle::SudokuPuzzle) = new(vals, puzzle)
    SudokuPartial(puzzle::SudokuPuzzle) = propagate(puzzle)
    SudokuPartial(puzzle::String) = propagate(SudokuPuzzle(puzzle))
end


# globals
const squares = reshape(1:81, 9, 9).'
const rows = [squares[i, :] for i in 1:9]
const cols = [squares[:, i] for i in 1:9]
const subs = [squares[3*i-2:3*i, 3*j-2:3*j] for i=1:3, j=1:3]
const unitlist = collect(chain(rows, cols, subs))

# exported globals
const units = [filter(u -> s in u, unitlist) for s=squares]
const peers = [Set(vcat(map(collect, units[s])...))::Set{Int64} for s=squares]
for (i, p)=enumerate(peers)
    pop!(p, i)
end

# Convert grid to a SudokuPartial of possible values, vals is a BitArray{2}
# remove values already seen in a shared unit
# return False if a contradiction is detected.
function propagate(grid::SudokuPuzzle)
    vals = trues(9, 81)::MaybeVals
    if !propagate!(grid, vals)
        vals = false::MaybeVals
    end
    SudokuPartial(vals::MaybeVals, grid)
end
function propagate(grid::String)
    propagate(SudokuPuzzle(grid))
end
function propagate!(grid::SudokuPuzzle, vals::BitArray{2})
    # To start, every square can be any digit;
    # then assign values from the grid.
    for (s,d)=enumerate(grid.init)
        d = d in "0." ? 0 : parseint(d)
        d != 0 && !assign!(vals, s, d) && return false ## (Fail if we can't assign d to square s.)
    end
    return true
end
# Strip out all but meaningful chars
function _clean(grid::String)
    chars = filter(c -> c in ".0123456789", grid)
    @assert length(chars) == 81
    chars
end


# Eliminate all the other values (except d) from vals[:, s] and propagate.
# Return values, except return False if a contradiction is detected.
function assign!(vals::BitArray{2}, s::Int64, d::Int64)
    other_vals = copy(vals[:, s])
    other_vals[d] = false

    for d2=findin(other_vals, true)
        !eliminate!(vals, s, d2) && return false
    end
    true
end

# Eliminate d from vals[:, s]; propagate when values or places <= 2.
# return false if a contradiction is detected.
function eliminate!(vals::BitArray{2}, s::Int64, d::Int64)
    if !vals[d, s]
        return true ## Already eliminated
    end
    vals[d, s] = false

    ## (1) If a square s is reduced to one value d2, then eliminate d2 from the peers.
    left = sum(vals[:, s])
    if left == 0
        return false ## Contradiction: removed last value
    elseif left == 1
        d2 = findfirst(vals[:, s])
        for s2=peers[s]
            !eliminate!(vals, s2, d2) && return false
        end
    end

    ## (2) If a unit u is reduced to only one place for a value d, then put it there.
    for u=units[s]
        dplaces = filter(s -> vals[d, s], u)
        L = length(dplaces)
        if L == 0
            return false ## Contradiction: no place for this value
        elseif L == 1
            # d can only be in one place in unit; assign it there
            !assign!(vals, dplaces[1], d) && return false
        end
    end
    return true
end

# solve a sudoku puzzle
function solve!(g::SudokuPartial)
    search!(g.vals)
    g
end
function solve(p::SudokuPuzzle)
    g = propagate(p)
    g.vals != false && solve!(g)
    g
end
function solve(init::String)
    solve(SudokuPuzzle(init))
end

# Using depth-first search and propogation, try all possible values.
function search!(vals::BitArray{2})
    s = 0  # Choose the unfilled square s with the fewest possibilities
    min_l = 99
    all_one = true
    for i in 1:81
        l = sum(vals[:, i])
        all_one &= l == 1
        if l <= min_l && l != 1
            min_l = l
            s = i
        end
    end
    all_one && return true  ## Solved

    for d=findin(vals[:, s], true)
        v = copy(vals)
        if assign!(v, s, d) && search!(v)
            vals[:] = v
            return true
        end
    end
    return false
end

function is_solved(grid::SudokuPartial)
    grid.vals != false && all(sum(grid.vals, 1) .== 1)
end


# Make a random puzzle with N or more assignments. Restart on contradictions.
# Note the resulting puzzle is not guaranteed to be solvable, but empirically
# about 99.8% of them are solvable. Some have multiple solutions.
function random_sudoku(N::Integer=17)
    vals = trues(9, 81)
    digits = [1:9]
    for s=shuffle(collect(squares))
        assign!(vals, s, digits[rand(1:end)]) == false  && break
        ds = sum(sum(vals, 1) .== 1)
        # TODO this is different to norvig...
        if ds >= N && ds >= 8
            init = join([sum(vals[:, s])==1 ? string(findfirst(vals[:, s])) : "." for s=squares], "")::ASCIIString
            return SudokuPuzzle(init)
        end
    end
    return random_sudoku(N) ## Give up and make a new puzzle
end
function Base.rand(::Type{SudokuPuzzle}, N::Integer=17)
    random_sudoku()
end

# Display puzzles as a 2-D grid.
function Base.show(io::IO, grid::SudokuPartial)
    if grid.vals == false
        print(grid.puzzle)
        println("Has no solutions.")
        return nothing
    end

    function to_digits(ba::BitArray{1})
        join(findin(ba, true), "")
    end

    width = 1 + maximum([sum(grid.vals[:, s]) for s=squares])
    line = join(repeat(["-" ^ (width*3)], outer=[3]), "+")
    for (i,row)=enumerate(rows)
        println(join([center(to_digits(grid.vals[:, s]), width) * (j in [3, 6] ? "|" : "")
                      for (j,s)=enumerate(row)],
                     ""))
        if i in [3, 6]
            println(line)
        end
    end
end
function Base.show(io::IO, p::SudokuPuzzle)
    line = join(repeat(["-" ^ 5], outer=[3]), "+")
    for (s,c)=enumerate(p.init)
        c = c in ".0" ? ' ': c
        print("$c" * (rem(s, 9) in [3, 6] ? "|" : " "))
        rem(s, 9) == 0 && println()
        s in [27, 54] && println(line)
    end
end
function Base.string(p::SudokuPuzzle)
    p.init
end
function Base.string(p::SudokuPartial)
    if is_solved(p)
        join([findfirst(p.vals[:, s]) for s=1:81], "")
    else
        string(p.puzzle)
    end
end

# pad string with spaces so it's centered on size width
function center(text, width)
    pad = width - length(text)
    @assert pad >= 0
    rpad = div(pad, 2)
    lpad = pad - rpad
    " " ^ lpad * text * " " ^ rpad
end


# Parse a file into a list of strings, separated by sep.
function from_file(filename, sep='\n')
    open(filename) do f
        return split(strip(readall(f)), sep)
    end
end

function time_solve(grid, showif)
    t0 = time()
    val = solve(grid)
    t = time() - t0
    if t > showif
        println("$(round(t, 2)) seconds:")
        println(grid)
        val == false ? println("No solutions.") : show(val)
    end
    solved = val != false && is_solved(val)
    t, solved
end

# Attempt to solve a sequence of grids. Report results.
# When showif is a number of seconds, display puzzles that take longer.
function solve_all(grids; name="", showif=0.1)
    ts = map(x -> time_solve(x, showif), grids)
    times, results = zip(filter(x -> x[2] != false, ts)...)
    N = length(grids)
    if N > 1
        t_mean = round(sum(times)/N, 3)
        t_hz = round(N/sum(times), 3)
        t_max = round(maximum(times), 3)
        println("Solved $(sum(results)) of $N $name puzzles (avg $(t_mean)s ($(t_hz)Hz), max $(t_max)s).")
    end
end

grid1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"

# Benchmarking
function bench()
    examples = joinpath(splitdir(dirname(@__FILE__()))[1], "examples")

    solve(grid1)  #warm up

    solve_all(from_file(joinpath(examples, "easy50.txt"), "========"), name="easy")
    solve_all(from_file(joinpath(examples, "top95.txt")), name="hard")
    solve_all(from_file(joinpath(examples, "hardest.txt")), name="hardest")
    bench(100, showif=1.0);
end
function bench(N::Integer; showif=0.03)
    solve_all([random_sudoku().init for i=1:N], name="random", showif=showif);
end

end # module
