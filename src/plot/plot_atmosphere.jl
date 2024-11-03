function plot_atmosphere(orbit::Orbit)
    CairoMakie.activate!()

    prop_time = orbit.time_et .- orbit.time_et[1]

    # convert into hours
    prop_time = prop_time ./ 3600

    fig = Figure()
    ax1 = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "Temperature / K")
    ax2 = Axis(fig[1, 2], xlabel = "Time / h", ylabel = "Oxygen Density / m^-3")
    ax3 = Axis(fig[2, 1], xlabel = "Time / h", ylabel = "Relative Velocity / (m/s)")
    ax4 = Axis(fig[2, 2], xlabel = "Time / h", ylabel = "Velocity / (m/s)")

    temperature = Float64[]
    n_aox = Float64[]
    v_relative = Float64[] # relative velocity in m/s in the ECI frame to the atmosphere
    v = Float64[] # orbit velocity in m/s in the ECI frame

    # Calculate the atmospheric conditions:
    for i in 1:length(orbit.eci)

        eci = orbit.eci[i]
        time_utc = orbit.time_utc[i]
        r_ecef = eci2ecef(eci.r, time_utc)
        latitude, longitude = ecef2geo(r_ecef)

        f107, f107a, ap = get_spaceweather(time_utc)
        atm = calc_atmosphere(time_utc, norm(eci.r) - orbit.central_body.radius, latitude, longitude , f107a, f107, ap)
        n_o = get_o_density(atm)
        T = get_temperature(atm)
        v_rel = rel_velocity_to_atm(eci.r, eci.v, orbit.central_body, time_utc, latitude, longitude, 0.0, f107a, f107, [0.0, ap])
        push!(temperature, T)
        push!(n_aox, n_o)
        push!(v_relative, v_rel)
        push!(v, norm(eci.v))
    end

    n_aox_mean = mean(n_aox) * ones(length(n_aox))
    temperature_mean = mean(temperature) * ones(length(temperature))
    v_relative_mean = mean(v_relative) * ones(length(v_relative))
    lines!(ax1, prop_time, temperature, color = :blue, linewidth = 2)
    lines!(ax1, prop_time, temperature_mean, color = :blue, linestyle = :dash, linewidth = 2)
    lines!(ax2, prop_time, n_aox, color = :red, linewidth = 2)
    lines!(ax2, prop_time, n_aox_mean, color = :red, linestyle = :dash, linewidth = 2)
    lines!(ax3, prop_time, v_relative, color = :green, linewidth = 2)
    lines!(ax3, prop_time, v_relative_mean, color = :green, linestyle = :dash, linewidth = 2)
    lines!(ax4, prop_time, v, color = :purple, linewidth = 2)

    # add title to the figure
    start_date = orbit.time_utc[1]
    end_date = orbit.time_utc[end]
    Label(fig[0, :], text = "$(start_date) to $(end_date)", fontsize = 24, tellwidth = false)

    fig
end