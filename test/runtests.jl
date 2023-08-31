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
        makeplot(path, line1, line2; ylabel = "Random Values", dt = 0.2, n = 4, testing = "abcd", copy_code = false)

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
        makehistogram(path, data; xlabel = "xlabel", ylabel = "Count", dt = 0.2, n = 4, testing = "abcd", copy_code = false)
        
        histograminfo = load(joinpath(path, "data.jld2"), "histograminfo")
        @test all(histograminfo.data .== data)
    end

    @testset "Combining Plots" begin
        x1 = rand(10); y1 = rand(10)
        x2 = rand(10); y2 = 2 * rand(10)
        line1 = LineInfo(x1, y1, line1_traj, "1")
        line2 = LineInfo(x2, y2, line2_traj, "2")
        path1 = joinpath(@__DIR__, "combine_plots_test", "combine_test_data1")
        path2 = joinpath(@__DIR__, "combine_plots_test", "combine_test_data2")
        makeplot(path1, line1; ylabel = "Random Values", dt = 0.1, n = 1, testing = "abcd1", copy_code = false)
        makeplot(path2, line2; ylabel = "Random Values 2", dt = 0.2, n = 2, testing = "abcd2", copy_code = false)
        new_path = joinpath(@__DIR__, "combine_plots_test", "combined_data")
        combineplots(new_path, path1, path2)

        plotinfo = load(joinpath(new_path, "data.jld2"), "plotinfo")
        @test plotinfo.lines["1"].x == x1
        @test plotinfo.lines["2"].x == x2
        @test plotinfo.lines["1"].y == y1
        @test plotinfo.lines["2"].y == y2
        @test plotinfo.lines["1"].traj == line1_traj
    end

    function random_plot(traj, index)
        lines = []
        for i in eachindex(traj)
            push!(lines, LineInfo(rand(10), rand(10), traj[i], "$i"))
        end
        path = joinpath(@__DIR__, "test_data", "traj_adding$index")
        makeplot(path, lines...; ylabel = "Random Values", dt = 0.2, n = 4, testing = "abcd", copy_code = false)
    end

    function random_add_plot(traj, index)
        lines = []
        for i in eachindex(traj)
            push!(lines, LineInfo(rand(10), rand(10), traj[i], "$i"))
        end
        path = joinpath(@__DIR__, "test_data", "traj_adding$index")
        addtrajectories(path, lines...)
    end

    @testset "Traj To Title" begin
        random_plot([1, 1, 1, 1], 1)
        random_plot([1, 2, 3, 4], 2)
        random_plot([5, 5, 5, 5], 3)
        random_plot([5], 4)
        random_plot([1, 1, 1, 1], 5)
        random_add_plot([1, 1, 1, 1], 5)
        random_plot([1, 1, 1, 1], 6)
        random_add_plot([1, 3, 1, 4], 6)
    end

end # testset