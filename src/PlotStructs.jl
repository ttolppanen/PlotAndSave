# using OrderedCollections

export LineInfo
export PlotInfo
export HistogramInfo

struct LineInfo
    x::AbstractArray
    y::AbstractArray
    traj::Integer
    tag::String
end

struct PlotInfo
    lines::OrderedDict{String, LineInfo}
    parameters::Dict{Symbol, Any}
    xlabel::String
    ylabel::String
    title::String
    function PlotInfo(lines...; xlabel::String = "x", ylabel::String = "y", param...)
        lines_dict = OrderedDict{String, LineInfo}()
        for line in lines
            lines_dict[line.tag] = line
        end
        title = parameters_to_title(; param...)
        param_dict = Dict(param...)
        return new(lines_dict, param_dict, xlabel, ylabel, title)
    end
end

struct HistogramInfo
    data::Array{<:Number}
    parameters::Dict{Symbol, Any}
    xlabel::String
    ylabel::String
    title::String
    function HistogramInfo(data::Array{<:Number}; xlabel::String = "x", ylabel::String = "y", param...)
        title = parameters_to_title(; param...)
        param_dict = Dict(param...)
        return new(data, param_dict, xlabel, ylabel, title)
    end
end

function parameters_to_title(; param...)
    out = ""
    newlinesadded = 0
    for key in keys(param)
        value = param[key]
        if isa(value, ValueInfo)
            stringToAdd = "$key = $(value.str_val),"
        else
            stringToAdd = "$key = $value,"
        end
        if length(out * stringToAdd) > 50 * (newlinesadded + 1)
            out *= "\n"
            newlinesadded += 1;
        end
        out *= stringToAdd * " "
    end
    return out[1:end-2]
end