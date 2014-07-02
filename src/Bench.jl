include("_jump.jl")

using DataFrames
using PyCall
using Sudoku


# iterate function over array, if function returns false report NaN
function map_time(f, arr)
    times = zeros(Float64, length(arr))
    f(arr[1]) # warmup... will this be optimized away?
    for (i,a)=enumerate(arr)
        t1 = time()
        res = try
            f(a)
        catch
            false
        end
        t = time() - t1
        times[i] = res == false ? NaN : t
    end
    times
end

function bench_compare(N::Integer=100)
    # Note: using pre-calculated arrays so generation is not benchmarked
    puzzles = [random_puzzle() for i=1:N]
    solve(puzzles[1])  # warm up
    times = map_time(solve, puzzles)

    # TODO use pycall of norvig.py
    src_dir = splitdir(@__FILE__)[1]
    if !(src_dir in PyVector(pyimport("sys")["path"]))
        unshift!(PyVector(pyimport("sys")["path"]), src_dir)
    end
    @pyimport norvig
    p_times = convert(Array{Float64}, norvig.map_times(puzzles))

    j_puzzles = map(p -> reshape(map(x -> grid_values(p)[x], 1:81), 9, 9), puzzles)
    SolveModel(j_puzzles[1])  # warm up
    #@time for j=j_puzzles SolveModel(j) end
    j_times = map_time(SolveModel, j_puzzles)

    #TODO make this less awful... ffs NaN NA
    arr = hcat(times, j_times, p_times)
    n = any(map(isnan, arr), 2)
    @assert n == all(map(isnan, arr), 2)
    dropped = arr[!collect(n), :]

    df = convert(DataFrame, dropped)
    names!(df, [:Julia, :JuMP, :Python])
    return df
end




# TODO not use my own bespoke describe function
function impl_describe(df::DataFrame)
    function q10(col)
        quantile(col, 0.1)
    end
    function q90(col)
        quantile(col, 0.9)
    end
    fns = [mean, minimum, q10, median, q90, maximum]
    res = DataFrame(impl=[:Julia, :JuMP, :Python])
    for f=fns
        res[symbol(string(f))] = [f(col) for (cname,col)=eachcol(df)]
    end
    res
end


N = (length(ARGS) == 1) ? int(ARGS[1]) : 100
b = bench_compare(N)
s = impl_describe(b)
println(s)

# TODO more desciptive stats from result
# TODO eg plot of sorted times?
