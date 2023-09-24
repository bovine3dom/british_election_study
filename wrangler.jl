#!/bin/julia

# Combine all BES waves into one big DataFrame. Takes a while on a 12 thread CPU. Needs ~60GB of RAM

using StatFiles, DataFrames, Statistics, ThreadsX, CSV, Arrow
surveys = readdir("data/")

# df = DataFrame(load("data/BES2019_W24_v24.0.sav")) # no immig key :(
df = ThreadsX.mapreduce(filename -> begin
        dft = DataFrame(load("./data/"*filename))
        dft.survey .= filename
        @info "done" filename
        dft
end, (l,r) -> vcat(l, r; cols=:union), surveys[1:end-1],init=DataFrame())

Arrow.write("wrangled/bes-w1-w24.arrow", df)

#df.redist[partyname] vs self
immigs = filter(x-> startswith(x, "immig"), names(df))
redists = filter(x-> startswith(x, "redist"), names(df))

parties = filter(x->x!=="Self", intersect(Set(map(x->x[7:end],filter(x-> startswith(x, "redist"), names(df)))), Set(map(x->x[6:end],filter(x-> startswith(x, "immig"), names(df))))))

mymedian(x) = filter(x -> !ismissing(x) && (x<=10), x) |> x -> length(x) == 0 ? missing : median(x)
comb = combine(groupby(df, [:immigSelf, :redistSelf, :survey]), (Symbol(x) => mymedian for x in immigs)..., (Symbol(x) => mymedian for x in redists)...)

# In the UK, more immigration = more left wing wing, more redistribution = more right wing
comb.immigLefty = 10 .- comb.immigSelf

for p in parties
    comb[!, Symbol("immigDist"*p)] = comb.immigSelf .- comb[!, Symbol("immig"*p*"_mymedian")]
    comb[!, Symbol("redistDist"*p)] = comb.redistSelf .- comb[!, Symbol("redist"*p*"_mymedian")]
    comb[!, Symbol("dist"*p)] = sqrt.(comb[!, Symbol("redistDist"*p)].^2 .+ comb[!, Symbol("immigDist"*p)].^2)
end

CSV.write("wrangled/comb.csv",comb)
