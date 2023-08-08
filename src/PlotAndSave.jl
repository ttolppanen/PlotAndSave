module PlotAndSave

using JLD2
using Gadfly

include("PlotStructs.jl")

export makeplot
export makehistogram
export addtrajectories

function makeplot(path, lines...; xlabel::String = "x", ylabel::String = "y", param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    mkpath(path)
    savefigure(path, plotinfo)
    jldsave(joinpath(path, "data.jld2"); plotinfo)
end

function makehistogram(path, data; xlabel::String = "x", ylabel::String = "y", param...)
    histograminfo = HistogramInfo(data; xlabel, ylabel, param...)
    mkpath(path)
    savefigure(path, histograminfo)
    jldsave(joinpath(path, "data.jld2"); histograminfo)
end

function savefigure(path::String, plotinfo::PlotInfo)
    layers = []
    for lineinfo in values(plotinfo.lines)
        new_layer = layer(x=lineinfo.x, y=lineinfo.y, Geom.line, color = [lineinfo.tag])
        push!(layers, new_layer)
    end
    p = plot(layers..., Guide.title(plotinfo.title), Guide.xlabel(plotinfo.xlabel), Guide.ylabel(plotinfo.ylabel))
    p |> SVG(joinpath(path, "plot.svg"))
end

function savefigure(path::String, histograminfo::HistogramInfo)
    p = plot(x = histograminfo.data, Geom.histogram, Guide.title(histograminfo.title), Guide.xlabel(histograminfo.xlabel), Guide.ylabel(histograminfo.ylabel))
    p |> SVG(joinpath(path, "plot.svg"))
end

function addtrajectories(path_to_prev_data::String, new_trajectories...)
    plotinfo = load(joinpath(path_to_prev_data, "data.jld2"), "plotinfo")
    new_lines = plotinfo.lines
    for traj in new_trajectories
        old_line = plotinfo.lines[traj.tag]
        new_lines[traj.tag] = updateline(old_line, traj)
    end
    makeplot(path_to_prev_data, values(new_lines)...; xlabel = plotinfo.xlabel, ylabel = plotinfo.ylabel, plotinfo.parameters...)
end

function updateline(old_line::LineInfo, new_line::LineInfo)
    total_traj = old_line.traj + new_line.traj
    y = (old_line.traj .* old_line.y .+ new_line.traj .* new_line.y) ./ total_traj
    return LineInfo(new_line.x, y, total_traj, new_line.tag)
end

end # module
