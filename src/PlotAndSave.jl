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
export merge_lines
export get_traj
export x_ticks
export get_param
export reduce_data!
export reduce_data

const PaS_DATA_FILE_NAME = "data.jld2"
const PaS_PLOTINFO_NAME = "plotinfo"
const PaS_PLOT_FILE_NAME = "plot.png"

function makeplot(path, lines...; xlabel::String = "x", ylabel::String = "y", copy_code = true, add_traj = false, cut_data = false, param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    makeplot(path, plotinfo; copy_code, add_traj, cut_data)
end

function makeplot(path, plotinfo::PlotInfo; copy_code = true, add_traj = false, cut_data = false)
    if cut_data
        plotinfo = reduce_data(plotinfo)
    end
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

function loaddata(path, data_name = PaS_DATA_FILE_NAME, plotinfo_name = PaS_PLOTINFO_NAME)::PlotInfo
    wait_and_lock_folder(path)
    data = load(joinpath(path, data_name), plotinfo_name)
    remove_lock(path)
    return data::PlotInfo
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
    plotinfo = load(joinpath(path_to_prev_data, PaS_DATA_FILE_NAME), PaS_PLOTINFO_NAME)
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
    plot1 = load(joinpath(path_to_folder1, PaS_DATA_FILE_NAME), PaS_PLOTINFO_NAME)
    plot2 = load(joinpath(path_to_folder2, PaS_DATA_FILE_NAME), PaS_PLOTINFO_NAME)
    remove_lock(path_to_folder1)
    remove_lock(path_to_folder2)
    combineplots(new_path, plot1, plot2)
end
function combineplots(new_path, plot1::PlotInfo, plot2::PlotInfo)
    makeplot(new_path, values(plot1.lines)..., values(plot2.lines)...; xlabel = plot1.xlabel, ylabel = plot1.ylabel, copy_code = false, plot1.parameters...)
end

function merge_lines(new_path, path_1, path_2)
    plotinfo_1 = loaddata(path_1)
    plotinfo_2 = loaddata(path_2)
    new_plotinfo = merge_lines(plotinfo_1, plotinfo_2)
    makeplot(new_path, new_plotinfo)
end
function merge_lines(plotinfo_1::PlotInfo, plotinfo_2::PlotInfo)
    new_lines = []
    for line in values(plotinfo_2.lines)
        push!(new_lines, merge_lines(plotinfo_1.lines[line.tag], line))
    end
    return PlotInfo(new_lines...; plotinfo_1.xlabel, plotinfo_1.ylabel, plotinfo_1.parameters...)
end    
function merge_lines(line_1::LineInfo, line_2::LineInfo)
    if line_1.tag != line_2.tag
        error("Tags do not match: line_1.tag = $(line_1.tag), line_2.tag = $(line_2.tag)")
    end
    if line_1.traj != line_2.traj
        error("Trajectories do not match: line_1.traj = $(line_1.traj), line_2.traj = $(line_2.traj)")
    end
    diff_val_i = findall(x -> !(x in line_1.x), line_2.x)
    temp_line_2 = LineInfo(line_2.x[diff_val_i], line_2.y[diff_val_i], line_2.traj, line_2.tag)
    merged_x = vcat(line_1.x, temp_line_2.x)
    merged_y = vcat(line_1.y, temp_line_2.y)
    sorted_i = sortperm(merged_x)
    return LineInfo(merged_x[sorted_i], merged_y[sorted_i], line_1.traj, line_1.tag)
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
    plotinfo = load(joinpath(path, PaS_DATA_FILE_NAME), PaS_PLOTINFO_NAME)
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

function get_param(path, param_key, data_name = PaS_DATA_FILE_NAME, plotinfo_name = PaS_PLOTINFO_NAME; print_param = true)
    plotinfo = loaddata(path, data_name, plotinfo_name)
    param = plotinfo.parameters[param_key]
    if isa(param, Number)
        param_number = param
    else
        param_number = parse(Float64, match(r"\d+(\.\d+)?", param).match) # From chatGPT, somehow takes the numbers from strings like "123.2MHz" -> 123.2
    end
    if print_param
        println("Parameter key | Parameter | Out")
        println("$(string(param_key)) | $param | $param_number")
    end
    return param_number
end

function reduce_data!(path, data_name = PaS_DATA_FILE_NAME, plotinfo_name = PaS_PLOTINFO_NAME; kwargs...)
    data = loaddata(path, data_name, plotinfo_name)
    new_plotinfo = reduce_data(data; kwargs...)
    savedata(path, new_plotinfo; copy_code = false)
end
function reduce_data(plotinfo::PlotInfo; ticks = 999)
    new_lines = []
    for line in values(plotinfo.lines)
        if length(line.x) <= ticks
            continue
        end
        new_ticks = []
        l = length(line.x) / (ticks - 1)
        for i in 1:ticks
            j = clamp(round(Int, (i - 1) * l), 1, length(line.x))
            push!(new_ticks, j)
        end
        push!(new_lines, LineInfo(line.x[new_ticks], line.y[new_ticks], line.traj, line.tag))
    end
    return PlotInfo(new_lines...; xlabel = plotinfo.xlabel, ylabel = plotinfo.ylabel, plotinfo.parameters...)
end

end # module
