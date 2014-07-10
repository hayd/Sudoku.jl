include("_jump.jl")  # if this fails, paste SolveModel from .julia/JuMP/examples/sudoku.jl

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

function bench_julia(puzzles::Vector{ASCIIString})
    solve(puzzles[1])  # warm up
    map_time(solve, puzzles)
end
function bench_python(puzzles::Vector{ASCIIString})
    src_dir = splitdir(@__FILE__)[1]
    if !(src_dir in PyVector(pyimport("sys")["path"]))
        unshift!(PyVector(pyimport("sys")["path"]), src_dir)
    end
    @pyimport norvig
    convert(Array{Float64}, norvig.map_times(puzzles))
end
function bench_jump(puzzles::Vector{ASCIIString})
    j_puzzles = map(p -> reshape(map(c -> c in "0." ? 0 : parseint(c), collect(p)),
                                 9, 9),
                    puzzles)
    SolveModel(j_puzzles[1])  # warm up
    map_time(SolveModel, j_puzzles)
end

function bench_all(N::Integer)
    # Note: using pre-calculated arrays so generation is not benchmarked
    puzzles = [random_sudoku().init for i=1:N]::Vector{ASCIIString}

    times = bench_julia(puzzles)
    p_times = bench_python(puzzles)
    j_times = bench_jump(puzzles)

    #TODO make this less awful... ffs NaN NA BS
    arr = hcat(times, j_times, p_times)
    ns = any(map(isnan, arr), 2)
    if ns != all(map(isnan, arr), 2)
        # TODO this is just broken
        println("Inconsistent solutions:")
        println(puzzles[ns $ all(map(isnan, arr), 2)])
    end
    dropped = arr[!collect(ns), :]

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
b = bench_all(N)
s = impl_describe(b)
println(s)

# TODO more desciptive stats from result
# TODO eg plot of sorted times?
