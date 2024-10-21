function plot_coes(orbit::OrbitPropagation)
    a = [coes.a for coes in orbit.coes]
    e = [coes.e for coes in orbit.coes]
    i = [coes.i for coes in orbit.coes]
    Ω = [coes.Ω for coes in orbit.coes]
    ω = [coes.ω for coes in orbit.coes]
    f = [coes.f for coes in orbit.coes]

    prop_time = orbit.time_et .- orbit.time_et[1]

    # convert into hours
    prop_time = prop_time ./ 3600

    fig = Figure()

    ax1 = Axis(fig[1, 1], xlabel = "Time [h]", ylabel = "a / m")
    ax2 = Axis(fig[1, 2], xlabel = "Time [h]", ylabel = "e")
    ylims!(ax2, 0, 1)

    ax3 = Axis(fig[2, 1], xlabel = "Time [h]", ylabel = "i / °")
    ylims!(ax3, 0, 180)

    ax4 = Axis(fig[2, 2], xlabel = "Time [h]", ylabel = "Ω / °")
    ylims!(ax4, 0, 360)

    ax5 = Axis(fig[3, 1], xlabel = "Time [h]", ylabel = "ω / °")

    ax6 = Axis(fig[3, 2], xlabel = "Time [h]", ylabel = "f / °")

    lines!(ax1, prop_time, a, color = :blue)
    lines!(ax2, prop_time, e, color = :blue)
    lines!(ax3, prop_time, i, color = :blue)
    lines!(ax4, prop_time, Ω, color = :blue)
    lines!(ax5, prop_time, ω, color = :blue)
    lines!(ax6, prop_time, f, color = :blue)

    # add title to the figure
    start_date = orbit.time_utc[1]
    end_date = orbit.time_utc[end]
    Label(fig[0, :], text = "$(start_date) to $(end_date)", fontsize = 24, tellwidth = false)

    fig

end