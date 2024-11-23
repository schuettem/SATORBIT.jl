function plot_ground_track(orbit::Orbit, proj::String)

    # Transform eci to lat and lon
    latitude = Float64[]
    longitude = Float64[]
    for (i, eci) in enumerate(orbit.eci)
        r_ecef = eci2ecef(eci.r, orbit.time_utc[i])
        lat, lon = ecef2geo(r_ecef)
        push!(latitude, lat)
        push!(longitude, lon)
    end

    CairoMakie.activate!()

    fig = Figure(size=(800,800))
    ga = GeoAxis(fig[1,1], title = "Ground Track", source="+proj=latlong", dest=proj)
    lines!(ga, GeoMakie.coastlines())

    scatter!(ga, longitude, latitude,  color = :blue)
    scatter!(ga, longitude[1], latitude[1], color = :red)
    scatter!(ga, longitude[end], latitude[end], color = :green)

    display(fig)
end
