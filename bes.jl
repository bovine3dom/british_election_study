#!/bin/julia
using DataFrames, NaturalSort, CSV, Plots
plotlyjs()

comb = CSV.read("wrangled/comb.csv", DataFrame)

# @gif doesn't like us catching errors so do a wet dry run first
ok = []
for s in sort!(unique(comb.survey), lt=natural)
    try
        # exclude people who couldn't classify themselves
        nonines = comb[(comb.survey .== s) .& (comb.immigSelf .!== 9999.0) .& (comb.redistSelf .!== 9999.0), :]
        # savefig(contour(nonines.redistSelf, nonines.immigLefty, nonines.distCon; xlabel="Economic left/right", ylabel="Social liberal/conservative", title=s), s*"Con.png")
        savefig(contour(nonines.redistSelf, nonines.immigLefty, nonines.distCon; xlabel="Economic left/right", ylabel="Social liberal/conservative", title=s), "temp.png")
        push!(ok, s)
    catch(e)
        @warn e
    end
end

for p in ["Lab", "Con"]
    anim = @animate for s in ok
        nonines = comb[(comb.survey .== s) .& (comb.immigSelf .!== 9999.0) .& (comb.redistSelf .!== 9999.0), :]
        # contour(nonines.redistSelf, nonines.immigLefty, nonines.distCon .< 2; fill = true, levels = 1, xlabel="Economic left/right", ylabel="Social liberal/conservative", title=s)
        contour(nonines.redistSelf, nonines.immigLefty, nonines[!, Symbol("dist" * p)]; xlabel="Economic left/right", ylabel="Social liberal/conservative", title=p*" "*s, legend=:none, clabels=true, cbar=false)
    end
    gif(anim, "pics/"*p*".gif", fps=1)
end
