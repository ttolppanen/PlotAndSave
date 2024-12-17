module PlotAndSave

using JLD2
using Plots
using OrderedCollections

include("ParameterStruct.jl")
include("PlotStructs.jl")
include("FolderLocking.jl")

export makeplot
export savedata
export loaddata
export savefigure
export makehistogram
export addtrajectories
export combineplots
export get_traj
export x_ticks

const PaS_DATA_FILE_NAME = "data.jld2"
const PaS_PLOT_FILE_NAME = "plot.png"

function makeplot(path, lines...; xlabel::String = "x", ylabel::String = "y", copy_code = true, add_traj = false, param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    makeplot(path, plotinfo; copy_code, add_traj)
end

function makeplot(path, plotinfo::PlotInfo; copy_code = true, add_traj = false)
    if add_traj && isfile(joinpath(path, PaS_DATA_FILE_NAME))
        addtrajectories(path, collect(values(plotinfo.lines))...)
    else
        savedata(path, plotinfo; copy_code)
        savefigure(path, plotinfo)
    end
end

function makehistogram(path, data; xlabel::String = "x", ylabel::String = "y", copy_code = true, bins = nothing, param...)
    histograminfo = HistogramInfo(data; xlabel, ylabel, param...)
    mkpath(path)
    savefigure(path, histograminfo; bins)
    if copy_code
        copycode(path)
    end
    jldsave(joinpath(path, PaS_DATA_FILE_NAME); histograminfo)
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
    wait_and_lock_folder(path)
    jldsave(joinpath(path, PaS_DATA_FILE_NAME); plotinfo)
    remove_lock(path)
end

function loaddata(path)
    wait_and_lock_folder(dirname(path))
    data = load(path, "plotinfo")
    remove_lock(dirname(path))
    return data
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
    wait_and_lock_folder(path)
    savefig(p, joinpath(path, PaS_PLOT_FILE_NAME))
    remove_lock(path)
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
    wait_and_lock_folder(path)
    savefig(p, joinpath(path, PaS_PLOT_FILE_NAME))
    remove_lock(path)
end

function addtrajectories(path_to_prev_data::String, new_trajectories...)
    wait_and_lock_folder(path_to_prev_data)
    plotinfo = load(joinpath(path_to_prev_data, PaS_DATA_FILE_NAME), "plotinfo")
    new_lines = plotinfo.lines
    for traj in new_trajectories
        old_line = plotinfo.lines[traj.tag]
        new_lines[traj.tag] = updateline(old_line, traj)
    end
    remove_lock(path_to_prev_data)
    makeplot(path_to_prev_data, values(new_lines)...; xlabel = plotinfo.xlabel, ylabel = plotinfo.ylabel, copy_code = false, plotinfo.parameters...)
end

function updateline(old_line::LineInfo, new_line::LineInfo)
    total_traj = old_line.traj + new_line.traj
    y = (old_line.traj .* old_line.y .+ new_line.traj .* new_line.y) ./ total_traj
    return LineInfo(new_line.x, y, total_traj, new_line.tag)
end

function combineplots(new_path, path_to_folder1::String, path_to_folder2::String)
    wait_and_lock_folder(path_to_folder1)
    wait_and_lock_folder(path_to_folder2)
    plot1 = load(joinpath(path_to_folder1, PaS_DATA_FILE_NAME), "plotinfo")
    plot2 = load(joinpath(path_to_folder2, PaS_DATA_FILE_NAME), "plotinfo")
    remove_lock(path_to_folder1)
    remove_lock(path_to_folder2)
    combineplots(new_path, plot1, plot2)
end
function combineplots(new_path, plot1::PlotInfo, plot2::PlotInfo)
    makeplot(new_path, values(plot1.lines)..., values(plot2.lines)...; xlabel = plot1.xlabel, ylabel = plot1.ylabel, copy_code = false, plot1.parameters...)
end

function copycode(path)
    path_to_code = Base.source_path()
    save_path = joinpath(path, "code.jl")
    wait_and_lock_folder(dirname(path_to_code))
    wait_and_lock_folder(path)
    cp(path_to_code, save_path; force = true)
    remove_lock(path)
    remove_lock(dirname(path_to_code))
end

function get_traj(path::String)
    wait_and_lock_folder(path)
    plotinfo = load(joinpath(path, PaS_DATA_FILE_NAME), "plotinfo")
    remove_lock(path)
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

function x_ticks(start, stop, n_ticks, specific_points...)
    # sp = specific_points[1] for example
    # sp[1] = start
    # sp[2] = end
    # sp[3] = tick factor e.g. 2 means that there will be 2 times more ticks in this specific_points
    out = []
    default_step = (stop - start) / (n_ticks - 1)
    current_step = start
    push!(out, current_step)
    flag = false # if we added point in specific point
    while current_step < stop
        for sp in specific_points
            if sp[1] <= current_step && current_step < sp[2]
                current_step += default_step / sp[3]
                if current_step > sp[2]
                    current_step = sp[2]
                end
                push!(out, current_step)
                flag = true
                break
            end
        end
        if flag
            flag = false
            continue
        end
        current_step += default_step
        push!(out, current_step)
    end
    return out
end

end # module
