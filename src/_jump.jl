using JuMP


# vendorize for now...
function SolveModel(initgrid)
    m = Model()

    @defVar(m, 0 <= x[1:9, 1:9, 1:9] <= 1, Int)

    # Constraint 1 - Each row...
    @addConstraint(m, row[i=1:9,val=1:9], sum(x[i,:,val]) == 1)
    # Constraint 2 - Each column...
    @addConstraint(m, col[j=1:9,val=1:9], sum(x[:,j,val]) == 1)

    # Constraint 3 - Each sub-grid...
    @addConstraint(m, subgrid[i=1:3:7,j=1:3:7,val=1:9], sum(x[i:i+2,j:j+2,val]) == 1)

    # Constraint 4 - Cells...
    @addConstraint(m, cells[i=1:9,j=1:9], sum(x[i,j,:]) == 1)

    # Initial solution
    for row in 1:9
        for col in 1:9
            if initgrid[row,col] != 0
                @addConstraint(m, x[row, col, initgrid[row, col]] == 1)
            end
        end
    end

    # Solve it
    status = JuMP.solve(m)  # edited
    
    # Check solution
    if status == :Infeasible
        return false  # edited
    else
        mipSol = getValue(x)
        sol = zeros(Int,9,9)
        for row in 1:9, col in 1:9, val in 1:9
            if mipSol[row, col, val] >= 0.9
                sol[row, col] = val
            end
        end
        return sol
    end
end
