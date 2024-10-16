function plot_ground_track(orbit::OrbitPropagation)
    latitude = Float64[]
    longitude = Float64[]
    for geo in orbit.geo
        push!(latitude, geo.latitude)
        push!(longitude, geo.longitude)
    end

    fig = Figure()
    ax = Axis(fig[1, 1], xlabel = "Longitude", ylabel = "Latitude")
    scatter!(ax, longitude, latitude,  color = :blue)
    scatter!(ax, longitude[1], latitude[1], color = :red)
    scatter!(ax, longitude[end], latitude[end], color = :green)

    # Add the Earth coastlines to the plot
    header = ["longitude", "latitude"]
    coastlines = CSV.read("coastlines/coastlines_earth.csv", DataFrame, header = header)

    scatter!(ax, coastlines[:, "longitude"], coastlines[:, "latitude"], color = :black, markersize = 0.5)

    # Customize the ticks
    xlims!(ax, -180, 180)
    ax.xticks = (-180:30:180, ["-180", "-150", "-120", "-90", "-60", "-30", "0", "30", "60", "90", "120", "150", "180"])

    ylims!(ax, -90, 90)
    ax.yticks = (-90:15:90, ["-90", "-75", "-60", "-45", "-30", "-15", "0", "15", "30", "45", "60", "75", "90"])

    fig
end
