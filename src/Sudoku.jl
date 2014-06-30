module Sudoku

export Grid, PartialGrid, grid_values, is_solved, parse_grid, peers, solve, units


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
units = Dict([(s, filter(u -> s in u, unitlist)) for s=squares])
peers = Dict([(s, Set(vcat(map(collect, units[s])...)))
              for s=squares::Array{Int64}])
for (i, p)=peers
    pop!(p, i)
end

# Convert grid to a dict of possible values, {square: digits}, or
# return False if a contradiction is detected.
function parse_grid(grid::Grid)
    # To start, every square can be any digit;
    # then assign values from the grid.
    vals = PartialGrid([(s, digits_) for s=squares])
    for (s,d)=grid
    #for s in 1:81  #TODO not hardcode
        #d = grid[s]
        if d in digits_ && assign!(vals, s, d) == false
            #println(vals, "\n", s, "\n", d)
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
    return Dict(collect(zip(squares, chars)))
end

# Eliminate all the other values (except d) from values[s] and propagate.
# Return values, except return False if a contradiction is detected.
function assign!(vals, s::Int64, d::Char)
    #println(vals[s], " = ", d)
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
function search(vals)
    if vals == false
        return false ## Failed earlier
    end

    poss = {length(v) => k for (k,v)=vals}
    pop!(poss, 1, -1)
    if length(poss) == 0
        return vals  ## Solved!
    end

    ## Chose the unfilled square s with the fewest possibilities
    s = minimum(poss)[2]
    return some([search(assign!(copy(vals), s, d)) for d in vals[s]])
end

# Return some element of seq that is true.
function some(seq)
    for e=seq
        if e != false
            return e
        end
    end
    return false
end

function is_solved(grid::PartialGrid)
    maximum(map(length, values(grid))) == 1
end


end # module
