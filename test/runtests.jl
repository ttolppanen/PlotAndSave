using Test, PlotAndSave
using JLD2

@testset "Plot and Save" begin

x1 = rand(10); y1 = rand(10)
x2 = rand(10); y2 = rand(10)
line1 = LineInfo(x1, y1, 9, "1")
line2 = LineInfo(x2, y2, 1, "2")
path = joinpath(@__DIR__, "test_data")
Plot(path, line1, line2; ylabel = "Random Values", dt = 0.2, n = 4, testing = "abcd")

plotinfo = jldopen(joinpath(path, "data.jld2"))["plotinfo"]
@test plotinfo.lines["1"].x == x1
@test plotinfo.lines["2"].x == x2
@test plotinfo.lines["1"].y == y1
@test plotinfo.lines["2"].y == y2
@test plotinfo.lines["1"].traj == 9

end # testset