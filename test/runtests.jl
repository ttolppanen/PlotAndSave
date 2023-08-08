using Test, PlotAndSave
using JLD2

@testset "Plot and Save" begin

line1_traj = 9
line2_traj = 1

    @testset "Saving" begin
        x1 = rand(10); y1 = rand(10)
        x2 = rand(10); y2 = rand(10)
        line1 = LineInfo(x1, y1, line1_traj, "1")
        line2 = LineInfo(x2, y2, line2_traj, "2")
        path = joinpath(@__DIR__, "test_data")
        makeplot(path, line1, line2; ylabel = "Random Values", dt = 0.2, n = 4, testing = "abcd")

        plotinfo = load(joinpath(path, "data.jld2"), "plotinfo")
        @test plotinfo.lines["1"].x == x1
        @test plotinfo.lines["2"].x == x2
        @test plotinfo.lines["1"].y == y1
        @test plotinfo.lines["2"].y == y2
        @test plotinfo.lines["1"].traj == line1_traj
    end

    @testset "Updating Trajectories" begin
        x1 = rand(10); y1 = rand(10)
        x2 = rand(10); y2 = rand(10)
        line1 = LineInfo(x1, y1, line1_traj, "1")
        line2 = LineInfo(x2, y2, line2_traj, "2")
        path = joinpath(@__DIR__, "test_data")
        addtrajectories(path, line1, line2)

        plotinfo = load(joinpath(path, "data.jld2"), "plotinfo")
        @test plotinfo.lines["1"].x == x1
        @test plotinfo.lines["2"].x == x2
        @test plotinfo.lines["1"].traj == line1_traj * 2
        @test plotinfo.lines["2"].traj == line2_traj * 2
    end

    @testset "HistogramInfo" begin
        data = 10 * rand(100)
        path = joinpath(@__DIR__, "test_data_histogram")
        makehistogram(path, data; xlabel = "xlabel", ylabel = "Count", dt = 0.2, n = 4, testing = "abcd")
        
        histograminfo = load(joinpath(path, "data.jld2"), "histograminfo")
        @test all(histograminfo.data .== data)
    end

end # testset