module Sudoku

export Grid, PartialGrid, grid_values, bench, is_solved, parse_grid, peers, random_puzzle, solve, solve_all, units


import Iterators: chain, imap


typealias Grid Dict{Int64,Char}
typealias PartialGrid Dict{Int64,String}


# globals
digits_ = "123456789"

squares = reshape(1:81, 9, 9)
rows = [squares[i, :] for i in 1:9]
cols = [squares[:, i] for i in 1:9]
subs = [squares[3*i-2:3*i, 3*j-2:3*j] for i=1:3, j=1:3]
unitlist = collect(chain(rows, cols, subs))

# exported globals
units = {s => filter(u -> s in u, unitlist) for s=squares}
peers = Dict{Int64, Set{Int64}}({s => Set(vcat(map(collect, units[s])...))
                                 for s=squares})
for (i, p)=peers
    pop!(p, i)
end

# Convert grid to a dict of possible values, {square: digits}, or
# return False if a contradiction is detected.
function parse_grid(grid::Grid)
    # To start, every square can be any digit;
    # then assign values from the grid.
    vals = PartialGrid({s => digits_ for s=squares})
    for (s,d)=grid
        if d in digits_ && assign!(vals, s, d) == false
            return false ## (Fail if we can't assign d to square s.)
            # TODO: remove type instability
        end
    end
    return vals
end
function parse_grid(grid::String)
    parse_grid(grid_values(grid))
end

# Convert grid into a dict of {square: char} with '0' or '.' for empties.
function grid_values(grid::String)
    chars = filter(c -> c in digits_ * "0.", grid)
    @assert length(chars) == 81
    return Grid({s => c for (s,c)=zip(squares, chars)})
end

# Eliminate all the other values (except d) from values[s] and propagate.
# Return values, except return False if a contradiction is detected.
function assign!(vals, s::Int64, d::Char)
    other_vals = replace(vals[s], d, "")
    if all([eliminate!(vals, s, d2) != false for d2=other_vals])
        return vals
    else
        return false
        # TODO: remove type instability
    end
end

# Eliminate d from values[s]; propagate when values or places <= 2.
# Return values, except return False if a contradiction is detected.
function eliminate!(vals, s::Int64, d::Char)
    if !(d in vals[s])
        return vals ## Already eliminated
    end
    vals[s] = replace(vals[s], d, "")
    ## (1) If a square s is reduced to one value d2, then eliminate d2 from the peers.
    if length(vals[s]) == 0
        return false ## Contradiction: removed last value
    elseif length(vals[s]) == 1
        d2 = vals[s][1]
        if !all([eliminate!(vals, s2, d2) != false for s2=peers[s]])
            return false
        end
    end
    ## (2) If a unit u is reduced to only one place for a value d, then put it there.
    for u in units[s]
        dplaces = filter(s -> d in vals[s], u)
        if length(dplaces) == 0
            return false ## Contradiction: no place for this value
        elseif length(dplaces) == 1
        # d can only be in one place in unit; assign it there
            if assign!(vals, dplaces[1], d) == false
                return false
            end
        end
    end
    return vals
end

# pad string with spaces so it's centered on size width
function center(text, width)
    pad = width - length(text)
    @assert pad >= 0
    rpad = div(pad, 2)
    lpad = pad - rpad
    " " ^ lpad * text * " " ^ rpad
end

# Display these values as a 2-D grid.
function Base.show(vals::PartialGrid)
    # TODO don't override show for Dict{Int64, String}
    width = 1 + maximum([length(vals[s]) for s=squares])
    line = join(repeat(["-" ^ (width*3)], outer=[3]), "+")
    for (i,row)=enumerate(rows)
        println(join([center(vals[s], width) * (j in [3, 6] ? "|" : "")
                        for (j,s)=enumerate(row)],
                     ""))
        if i in [3, 6]
            println(line)
        end
    end
    println()
end

function solve(grid::PartialGrid)
    search(grid)
end
function solve(grid::String)
    solve(parse_grid(grid))
end

# Using depth-first search and propagation, try all possible values."
function search(vals::PartialGrid)
    poss = {length(v) => k for (k,v)=vals}
    pop!(poss, 1, -1)
    if length(poss) == 0
        return vals  ## Solved!
    end

    ## Chose the unfilled square s with the fewest possibilities
    s = minimum(poss)[2]
    for d=vals[s]
        v = search(assign!(copy(vals), s, d))
        if v != false
            return v
        end
    end
    return false
end
function search(vals::Bool)
    @assert vals == false
    return false
end

function is_solved(grid::PartialGrid)
    maximum(map(length, values(grid))) == 1
end

#import time, random

function time_solve(grid, showif)
    t0 = time()
    val = solve(grid)
    t = time() - t0
    if t > showif
        println("$(round(t, 2)) seconds:")
        println(grid)
        show(val)
    end
    solved = val != false && is_solved(val)
    t, solved
end

# Attempt to solve a sequence of grids. Report results.
# When showif is a number of seconds, display puzzles that take longer.
# When showif is None, don't display any puzzles.
function solve_all(grids; name="", showif=0.2)
    ts = map(x -> time_solve(x, showif), grids)
    times, results = zip(filter(x -> x[2] != false, ts)...)
    #times, results = zip([time_solve(grid, showif) for grid=grids]...)
    N = length(grids)
    if N > 1
        t_mean = round(sum(times)/N, 2)
        t_hz = round(N/sum(times), 2)
        t_max = round(maximum(times), 2)
        println("Solved $(sum(results)) of $N $name puzzles (avg $t_mean secs ($t_hz Hz), max $t_max secs).")
    end
end

# Parse a file into a list of strings, separated by sep.
function from_file(filename, sep='\n')
    open(filename) do f
        return split(strip(readall(f)), sep)
    end
end

# Make a random puzzle with N or more assignments. Restart on contradictions.
# Note the resulting puzzle is not guaranteed to be solvable, but empirically
# about 99.8% of them are solvable. Some have multiple solutions.
function random_puzzle(N::Integer=17)
    vals = PartialGrid({s => digits_ for s=squares})
    for s=shuffle(collect(squares))
        if assign!(vals, s, vals[s][rand(1:end)]) == false
            break
        end
        ds = filter((s, v) -> length(v) == 1, vals)
        if length(ds) >= N && length(values(ds)) >= 8
            return join([length(vals[s])==1 ? vals[s] : "." for s=squares], "")
        end
    end
    return random_puzzle(N) ## Give up and make a new puzzle
end

function bench()
    examples = joinpath(splitdir(dirname(@__FILE__()))[1], "examples")
    solve_all(from_file(joinpath(examples, "easy50.txt"), "========"), name="easy")
    solve_all(from_file(joinpath(examples, "top95.txt")), name="hard")
    solve_all(from_file(joinpath(examples, "hardest.txt")), name="hardest")
    bench(100);
end
function bench(N::Integer=100)
    solve_all([random_puzzle() for i=1:N], name="random", showif=0.03);
end

end # module
