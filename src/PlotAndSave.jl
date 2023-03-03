module PlotAndSave

using JLD2
using Gadfly

include("PlotStructs.jl")

export Plot

function Plot(path, lines...; xlabel::String = "x", ylabel::String = "y", param...)
    plotinfo = PlotInfo(lines...; xlabel, ylabel, param...)
    mkpath(path)
    SavePlot(path, plotinfo)
    jldsave(joinpath(path, "data.jld2"); plotinfo)
end

function SavePlot(path::String, plotinfo::PlotInfo)
    layers = []
    for lineinfo in values(plotinfo.lines)
        new_layer = layer(x=lineinfo.x, y=lineinfo.y, Geom.line, color = [lineinfo.tag])
        push!(layers, new_layer)
    end
    p = plot(layers..., Guide.title(plotinfo.title), Guide.xlabel(plotinfo.xlabel), Guide.ylabel(plotinfo.ylabel))
    p |> SVG(joinpath(path, "plot.svg"))
end

end # module
