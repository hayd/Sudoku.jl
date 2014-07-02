module Sudoku

export GridInit, GridPartial,
       grid_values, parse_grid,
       peers, units,
       is_solved, solve, solve_all,
       random_puzzle,
       bench


import Iterators: chain, imap


typealias GridInit Dict{Int64,Int64}
typealias GridPartial Dict{Int64,BitArray{1}}


# globals
const squares = reshape(1:81, 9, 9)
const rows = [squares[i, :] for i in 1:9]
const cols = [squares[:, i] for i in 1:9]
const subs = [squares[3*i-2:3*i, 3*j-2:3*j] for i=1:3, j=1:3]
const unitlist = collect(chain(rows, cols, subs))

# exported globals
const units = [s::Int64 => filter(u -> s in u, unitlist) for s=squares]
const peers = [s::Int64 => Set(vcat(map(collect, units[s])...))::Set{Int64}
               for s=squares]
for (i, p)=peers
    pop!(p, i)
end

# Convert grid to a dict of possible values, {square: digits}, or
# return False if a contradiction is detected.
function parse_grid(grid::GridInit)
    # To start, every square can be any digit;
    # then assign values from the grid.
    vals = [s::Int64 => trues(9)::BitArray{1}
            for s=Sudoku.squares]::GridPartial
    for (s,d)=grid
        if d != 0 && assign!(vals, s, d) == false
            return false ## (Fail if we can't assign d to square s.)
            # TODO: remove type instability
        end
    end
    return vals
end
function parse_grid(grid::String)
    parse_grid(grid_values(grid)::GridInit)
end

# Convert grid into a dict of {square: char} with '0' or '.' for empties.
function grid_values(grid::String)
    chars = filter(c -> c in ".0123456789", grid)
    chars = replace(chars, ".", "0")
    # TODO do this in one pass?
    @assert length(chars) == 81
    return [s::Int64 => parseint(c)::Int64
            for (s,c)=zip(squares, chars)]::GridInit
end

# Eliminate all the other values (except d) from values[s] and propagate.
# Return values, except return False if a contradiction is detected.
function assign!(vals, s::Int64, d::Int64)
    other_vals = copy(vals[s])
    other_vals[d] = false

    # for d2=findin(other_vals, true)
    #     eliminate!(vals, s, d2) == false && return false
    # end
    # return vals

    # TODO why doesn't this work??
    # for d2=other_vals
    #     if eliminate!(vals, s, d2) == false
    #         return false
    #     end
    # end
    # return vals


    if all([eliminate!(vals, s, d2) != false for d2=findin(other_vals, true)])
        return vals
    else
        return false
        # TODO: remove type instability
    end
end

# Eliminate d from values[s]; propagate when values or places <= 2.
# Return values, except return False if a contradiction is detected.
function eliminate!(vals, s::Int64, d::Int64)
    if !(vals[s][d])
        return vals ## Already eliminated
    end
    vals[s][d] = false
    ## (1) If a square s is reduced to one value d2, then eliminate d2 from the peers.
    left = sum(vals[s])
    if left == 0
        return false ## Contradiction: removed last value
    elseif left == 1
        d2 = findfirst(vals[s])
        for s2=peers[s]
            eliminate!(vals, s2, d2) == false && return false
        end
    end
    ## (2) If a unit u is reduced to only one place for a value d, then put it there.
    for u=units[s]
        dplaces = filter(s -> vals[s][d], u)
        L = length(dplaces)
        if L == 0
            return false ## Contradiction: no place for this value
        elseif L == 1
            # d can only be in one place in unit; assign it there
            assign!(vals, dplaces[1], d) == false  && return false
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
function Base.show(vals::GridPartial)
    # TODO don't override show for Dict{Int64, String}

    function to_digits(ba::BitArray{1})
        join(findin(ba, true), "")
    end

    width = 1 + maximum([sum(vals[s]) for s=squares])
    line = join(repeat(["-" ^ (width*3)], outer=[3]), "+")
    for (i,row)=enumerate(rows)
        println(join([center(to_digits(vals[s]), width) * (j in [3, 6] ? "|" : "")
                      for (j,s)=enumerate(row)],
                     ""))
        if i in [3, 6]
            println(line)
        end
    end
    println()
end

function solve(grid::GridPartial)
    search(grid)
end
function solve(grid::String)
    g = parse_grid(grid)
    g != false && solve(g)
end

# Using depth-first search and propagation, try all possible values."
function search(vals::GridPartial)
    poss = [sum(v)::Int64 => k::Int64 for (k,v)=vals]
    pop!(poss, 1, -1)
    if length(poss) == 0
        return vals  ## Solved!
    end

    # TODO replace this dict impl with something like the following
    # s, minL = 0, 99  # > 9, at most 9 digits
    # for (k,v)=vals
    #     L = length(v)
    #     if 1 < L < minL
    #         s, minL = k, L
    #     end
    # end
    # if s == 0
    #     return vals  ## Solved!
    # end

    ## Chose the unfilled square s with the fewest possibilities
    s = minimum(poss)[2]
    for d=findin(vals[s], true)
        v = search(assign!(deepcopy(vals), s, d))
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

function is_solved(grid::GridPartial)
    all(imap(x -> sum(x) == 1, values(grid)))
end

function time_solve(grid, showif)
    t0 = time()
    val = solve(grid)
    t = time() - t0
    if false && t > showif  # TODO put back
        println("$(round(t, 2)) seconds:")
        println(grid)
        val == false ? println("No solutions") : show(val)
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
        t_mean = round(sum(times)/N, 3)
        t_hz = round(N/sum(times), 3)
        t_max = round(maximum(times), 3)
        println("Solved $(sum(results)) of $N $name puzzles (avg $(t_mean)s ($(t_hz)Hz), max $(t_max)s).")
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
    vals = [s => trues(9) for s=squares]::GridPartial
    for s=shuffle(collect(squares))
        assign!(vals, s, findin(vals[s], true)[rand(1:end)]) == false  && break
        ds = filter((s, v) -> sum(v) == 1, vals)
        if length(ds) >= N && length(values(ds)) >= 8
            return join([sum(vals[s])==1 ? string(findfirst(vals[s])) : "." for s=squares], "")
        end
    end
    return random_puzzle(N) ## Give up and make a new puzzle
end

grid1 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"

function bench()
    examples = joinpath(splitdir(dirname(@__FILE__()))[1], "examples")

    solve(grid1)  #warm up

    solve_all(from_file(joinpath(examples, "easy50.txt"), "========"), name="easy")
    solve_all(from_file(joinpath(examples, "top95.txt")), name="hard", showif=0.4)
    solve_all(from_file(joinpath(examples, "hardest.txt")), name="hardest")
    bench(100, showif=1.0);
end
function bench(N::Integer; showif=0.03)
    solve_all([random_puzzle() for i=1:N], name="random", showif=showif);
end

end # module
