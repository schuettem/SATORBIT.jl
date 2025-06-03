function plot_atmosphere(orbit::Orbit)
    CairoMakie.activate!()

    prop_time = orbit.time_et .- orbit.time_et[1]

    # convert into hours
    prop_time = prop_time ./ 3600

    fig = Figure()
    ax1 = Axis(fig[1, 1], xlabel = L"t \, / \, \mathrm{h}", ylabel = L"T \, / \, \mathrm{K}")
    ax2 = Axis(fig[1, 2], xlabel = L"t \, / \, \mathrm{h}", ylabel = L"n_{\mathrm{O}} \, / \, \mathrm{m^{-3}}")
    ax3 = Axis(fig[2, 1], xlabel = L"t \, / \, \mathrm{h}", ylabel = L"u_{rel} \, / \, \mathrm{(m/s)}")
    ax4 = Axis(fig[2, 2], xlabel = L"t \, / \, \mathrm{h}", ylabel = L"\dot{n}_{\mathrm{O}} \, / \, \mathrm{(m^2 s)^{-1}}")
    ax5 = Axis(fig[3, 1], xlabel = L"t \, / \, \mathrm{h}", ylabel = L"\theta \, / \, ^{°}")

    temperature = Float64[]
    n_aox = Float64[]
    v_relative = Float64[] # relative velocity in m/s in the ECI frame to the atmosphere
    nbr_flux_densities = Float64[]
    polar_angles = Float64[]
    polar_angles_2 = Float64[]

    # Calculate the atmospheric conditions:
    for i in 1:length(orbit.eci)

        eci = orbit.eci[i]
        time_utc = orbit.time_utc[i]

        atm = get_atmosphere_data(eci.r, time_utc, orbit.central_body)

        n_o = atm.o_density
        T = atm.temperature
        v_atm = atm.velocity
        v_orbit = eci.v
        v_rel = norm(v_orbit - v_atm)
        push!(temperature, T)
        push!(n_aox, n_o)
        push!(v_relative, v_rel)

        # Calculate the number flux density
        v_orbit_tnw = eci2tnw(eci.r, v_orbit, v_orbit)
        v_atm_tnw = eci2tnw(eci.r, v_orbit, v_atm)
        v_tnw = v_orbit_tnw - v_atm_tnw
        nbr_flux_density = calc_nbr_flux_density(n_o, v_tnw[1], T)
        push!(nbr_flux_densities, nbr_flux_density)

        # polar angle
        theta = atand(v_tnw[3], v_tnw[1])
        push!(polar_angles, theta)
    end

    # n_aox_mean = mean(n_aox) * ones(length(n_aox))
    # temperature_mean = mean(temperature) * ones(length(temperature))
    # v_relative_mean = mean(v_relative) * ones(length(v_relative))
    lines!(ax1, prop_time, temperature, color = :blue, linewidth = 2)
    # lines!(ax1, prop_time, temperature_mean, color = :blue, linestyle = :dash, linewidth = 2)
    lines!(ax2, prop_time, n_aox, color = :red, linewidth = 2)
    # lines!(ax2, prop_time, n_aox_mean, color = :red, linestyle = :dash, linewidth = 2)
    lines!(ax3, prop_time, v_relative, color = :green, linewidth = 2)
    # lines!(ax3, prop_time, v_relative_mean, color = :green, linestyle = :dash, linewidth = 2)
    lines!(ax4, prop_time, nbr_flux_densities, color = :purple, linewidth = 2)

    lines!(ax5, prop_time, polar_angles, color = :orange, linewidth = 2)
    ylims!(ax5, -5, 5)

    # add title to the figure
    start_date = orbit.time_utc[1]
    end_date = orbit.time_utc[end]
    Label(fig[0, :], text = "$(start_date) to $(end_date)", fontsize = 24, tellwidth = false)

    display(fig)
end