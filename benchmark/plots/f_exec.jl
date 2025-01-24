# == Function Execution Time ==
@load "bench.jld2"

colors = Makie.wong_colors()

data = result["f_exec"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = mean.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of incoming photons",
    ylabel="function execution time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

scatter!(ax, [(1:l)...], data)

save(joinpath(plotpath, "f_exec_compton.pdf"), f)

data = copy(result["f_exec"])
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data_x = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
for i in eachindex(data)
    data[i] = data[i] ./ data_x[i]
end
data = median.(data)

ax2 = Axis(
    f[1, 1];
    yaxisposition=:right,
    yminorgridvisible=false,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    ylabel="execution time average per node",
    limits=(nothing, _find_y_lims(data)),
    yticks=(yticks1, yticks2),
)
hidespines!(ax2)
hidexdecorations!(ax2)
linkxaxes!(ax, ax2)

barplot!(ax2, [(1:l)...], data; color=colors[2], alpha=0.3)

save(joinpath(plotpath, "f_exec_compton_per_line.pdf"), f)
