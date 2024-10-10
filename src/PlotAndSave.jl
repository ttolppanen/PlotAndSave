module PlotAndSave

using JLD2
using Plots
using OrderedCollections

include("ParameterStruct.jl")
include("PlotStructs.jl")

export makeplot
export savedata
export loaddata
export savefigure
export makehistogram
export addtrajectories
export combineplots
export get_traj

function makeplot(path, lines...; xlabel::String = "x", ylabel::String = "y", copy_code = true, param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    makeplot(path, plotinfo; copy_code)
end

function makeplot(path, plotinfo::PlotInfo; copy_code = true)
    savedata(path, plotinfo; copy_code)
    savefigure(path, plotinfo)
end

function makehistogram(path, data; xlabel::String = "x", ylabel::String = "y", copy_code = true, bins = nothing, param...)
    histograminfo = HistogramInfo(data; xlabel, ylabel, param...)
    mkpath(path)
    savefigure(path, histograminfo; bins)
    if copy_code
        copycode(path)
    end
    jldsave(joinpath(path, "data.jld2"); histograminfo)
end

function savedata(path, lines...; xlabel::String = "x", ylabel::String = "y", copy_code = true, param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    savedata(path, plotinfo; copy_code)
end
function savedata(path, plotinfo::PlotInfo; copy_code = true)
    mkpath(path)
    if copy_code
        copycode(path)
    end
    jldsave(joinpath(path, "data.jld2"); plotinfo)
end

function loaddata(path)
    load(path, "plotinfo")
end

function savefigure(path::String, plotinfo::PlotInfo)
    mkpath(path)
    traj_numbers = [line.traj for line in values(plotinfo.lines)]
    all_same_traj = all(traj_numbers[1] .== traj_numbers)
    title_to_show = plotinfo.title
    if all_same_traj && traj_numbers[1] != 1
        title_to_show *= ", traj = $(traj_numbers[1])"
    end
    p = plot(
        title = title_to_show,
        xlabel = plotinfo.xlabel, 
        ylabel = plotinfo.ylabel, 
        legend = :outertopright, 
        titlefontsize = 9,
        dpi = 300)
    for line in values(plotinfo.lines)
        if !all_same_traj
            plot!(p, line.x, line.y, label = line.tag * ", traj = $(line.traj)")
        else
            plot!(p, line.x, line.y, label = line.tag)
        end
    end
    savefig(p, joinpath(path, "plot.png"))
end

function savefigure(path::String, histograminfo::HistogramInfo; bins = nothing)
    if isa(bins, Nothing)
        p = histogram(histograminfo.data, legend = :outertopright, titlefontsize = 9, dpi = 300)
    else
        p = histogram(histograminfo.data, legend = :outertopright, titlefontsize = 9, dpi = 300; bins)
    end
    title!(p, histograminfo.title)
    xlabel!(p, histograminfo.xlabel)
    ylabel!(p, histograminfo.ylabel)
    savefig(p, joinpath(path, "plot.png"))
end

function addtrajectories(path_to_prev_data::String, new_trajectories...)
    plotinfo = load(joinpath(path_to_prev_data, "data.jld2"), "plotinfo")
    new_lines = plotinfo.lines
    for traj in new_trajectories
        old_line = plotinfo.lines[traj.tag]
        new_lines[traj.tag] = updateline(old_line, traj)
    end
    makeplot(path_to_prev_data, values(new_lines)...; xlabel = plotinfo.xlabel, ylabel = plotinfo.ylabel, copy_code = false, plotinfo.parameters...)
end

function updateline(old_line::LineInfo, new_line::LineInfo)
    total_traj = old_line.traj + new_line.traj
    y = (old_line.traj .* old_line.y .+ new_line.traj .* new_line.y) ./ total_traj
    return LineInfo(new_line.x, y, total_traj, new_line.tag)
end

function combineplots(new_path,path_to_folder1::String, path_to_folder2::String)
    plot1 = load(joinpath(path_to_folder1, "data.jld2"), "plotinfo")
    plot2 = load(joinpath(path_to_folder2, "data.jld2"), "plotinfo")
    combineplots(new_path, plot1, plot2)
end
function combineplots(new_path, plot1::PlotInfo, plot2::PlotInfo)
    makeplot(new_path, values(plot1.lines)..., values(plot2.lines)...; xlabel = plot1.xlabel, ylabel = plot1.ylabel, copy_code = false, plot1.parameters...)
end

function copycode(path)
    path_to_code = Base.source_path()
    save_path = joinpath(path, "code.jl")
    cp(path_to_code, save_path; force = true)
end

function get_traj(path::String)
    plotinfo = load(joinpath(path, "data.jld2"), "plotinfo")
    return get_traj(plotinfo)
end
function get_traj(plotinfo::PlotInfo)
    traj_numbers = [line.traj for line in values(plotinfo.lines)]
    all_same_traj = all(traj_numbers[1] .== traj_numbers)
    if all_same_traj
        return traj_numbers[1]
    else
        return traj_numbers
    end
end

end # module
