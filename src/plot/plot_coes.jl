function plot_coes(orbit::Orbit)

    # Transform eci to coes
    a = Float64[]
    e = Float64[]
    i = Float64[]
    Ω = Float64[]
    ω = Float64[]
    f = Float64[]
    for eci in orbit.eci
        a_i, e_i, i_i, Ω_i, ω_i, f_i = eci2coes(eci.r, eci.v, orbit.central_body.μ)
        push!(a, a_i)
        push!(e, e_i)
        push!(i, i_i)
        push!(Ω, Ω_i)
        push!(ω, ω_i)
        push!(f, f_i)
    end

    CairoMakie.activate!()

    prop_time = orbit.time_et .- orbit.time_et[1]

    # convert into hours
    prop_time = prop_time ./ 3600

    fig = Figure()

    ax1 = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "a / m")
    ax2 = Axis(fig[1, 2], xlabel = "Time / h", ylabel = "e")
    ylims!(ax2, 0, 1)

    ax3 = Axis(fig[2, 1], xlabel = "Time / h", ylabel = "i / °")
    ylims!(ax3, 0, 180)

    ax4 = Axis(fig[2, 2], xlabel = "Time / h", ylabel = "Ω / °")
    ylims!(ax4, 0, 360)

    ax5 = Axis(fig[3, 1], xlabel = "Time / h", ylabel = "ω / °")

    ax6 = Axis(fig[3, 2], xlabel = "Time / h", ylabel = "f / °")

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