function plot_atmosphere(orbit::OrbitPropagation)

    prop_time = orbit.time_et .- orbit.time_et[1]

    # convert into hours
    prop_time = prop_time ./ 3600

    fig = Figure()
    ax1 = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "Temperature / K")
    ax2 = Axis(fig[1, 2], xlabel = "Time / h", ylabel = "Oxygen Density / m^-3")
    ax3 = Axis(fig[2, 1], xlabel = "Time / h", ylabel = "Relative Velocity / (m/s)")

    temperature = Float64[]
    n_o = Float64[]
    v_rel = Float64[]
    for atm in orbit.atmosphere_data
        push!(temperature, atm.T)
        push!(n_o, atm.n_o)
        push!(v_rel, atm.v_ref)
    end

    lines!(ax1, prop_time, temperature, color = :blue, linewidth = 2)
    lines!(ax2, prop_time, n_o, color = :red, linewidth = 2)
    lines!(ax3, prop_time, v_rel, color = :green, linewidth = 2)

    # add title to the figure
    start_date = orbit.time_utc[1]
    end_date = orbit.time_utc[end]
    Label(fig[0, :], text = "$(start_date) to $(end_date)", fontsize = 24, tellwidth = false)

    fig
end