export LineInfo
export PlotInfo

struct LineInfo
    x::AbstractArray
    y::AbstractArray
    traj::Integer
    tag::String
end

struct PlotInfo
    lines::Dict{String, LineInfo}
    parameters::Dict{Symbol, Any}
    xlabel::String
    ylabel::String
    title::String
    function PlotInfo(lines...; xlabel::String = "x", ylabel::String = "y", param...)
        lines_dict = Dict{String, LineInfo}()
        for line in lines
            lines_dict[line.tag] = line
        end
        title = parameters_to_title(; param...)
        param_dict = Dict(param...)
        return new(lines_dict, param_dict, xlabel, ylabel, title)
    end
end

function parameters_to_title(; param...)
    out = ""
    newlinesadded = 0
    for key in keys(param)
        value = param[key]
        stringToAdd = "$key = $value,"
        if length(out * stringToAdd) > 50 * (newlinesadded + 1)
            out *= "\n"
            newlinesadded += 1;
        end
        out *= stringToAdd * " "
    end
    return out[1:end-2]
end