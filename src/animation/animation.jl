function run_animation()
    GLMakie.activate!()

    # Satellite Parameters
    c_d = 2.2 # Drag Coefficient
    area = 1.0 # Cross-sectional area (m^2)
    mass = 1.0 # Mass (kg)

    satellite = SATORBIT.Satellite(c_d, area, mass)

    # Orbit Parameters
    central_body = SATORBIT.Earth()

    alt_perigee = 300e3
    radius_perigee = central_body.radius + alt_perigee
    alt_apogee = 400e3
    radius_apogee = central_body.radius + alt_apogee

    e = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
    a = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis

    i = 52.0 # Inclination (degrees)
    f = 40.0 # True Anomaly (degrees)
    Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
    ω = 234.0 # Argument of Periapsis (degrees)

    init_coes = SATORBIT.COES(a, e, i, Ω, ω, f)

    start_date = SATORBIT.DateTime(2020, 5, 10, 12, 0, 0)

    J2 = false
    aero = true
    disturbances = SATORBIT.Pertubations(J2, aero)

    # inital eci position
    r_0, v_0 = SATORBIT.coes2eci(init_coes, central_body.μ)
    r_0_mag = norm(r_0)

    orbit = SATORBIT.Orbit(satellite, central_body, init_coes, start_date)

    gui_data = GUIData(orbit)

    # Fig:
    fig, ax = create_gui(gui_data)

    # Earth:
    plotted_earth = plot_earth(ax)
    gui_data.plotted_earth = plotted_earth
    rotate_earth(plotted_earth, start_date)

    # plot ECI frame
    plot_eci_frame(ax)

    # plot ECEF frame
    x_ecef, y_ecef, z_ecef = plot_ecef_frame(ax)
    gui_data.ecef_frame = (x_ecef, y_ecef, z_ecef)
    rotate_ecef_frame(x_ecef, y_ecef, z_ecef, start_date)

    display(fig)

    while isopen(fig.scene)
        if gui_data.is_running[]
            orbit_part = 1 / 200
            for i in 1:200
                if !gui_data.is_running[]
                    break
                end

                SATORBIT.simulate_orbit!(gui_data.orbit[], disturbances, orbit_part, 2)

                r = gui_data.orbit[].eci[end].r
                v = gui_data.orbit[].eci[end].v

                gui_data.satellite_position[] = r

                altitude = round((norm(r) - gui_data.orbit[].central_body.radius) / 1e3 , digits=2)
                gui_data.altitude_label[] = "$(round(altitude, digits=2)) km"
                gui_data.date_label[] = Dates.format(gui_data.orbit[].time_utc[end], "yyyy-mm-dd HH:MM:SS")

                a, e, i, Ω, ω, f = SATORBIT.eci2coes(r, v, central_body.μ)
                gui_data.coes[] = SATORBIT.COES(a, e, i, Ω, ω, f)

                if altitude < 100 # stop the simulation if the satellite is below 100 km
                    gui_data.is_running[] = false
                    gui_data.crash_label[] = "Altitude below 100 km Simulation stopped"
                end

                # Rotate the Earth
                rotate_earth(plotted_earth, gui_data.orbit[].time_utc[end])
                rotate_ecef_frame(x_ecef, y_ecef, z_ecef, gui_data.orbit[].time_utc[end])

                sleep(1/120) # for visibility of the animation (120 fps)
            end
        end
        sleep(1/120)
    end
end
