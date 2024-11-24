function create_gui()
    fig, ax, grid = create_figure()

    create_buttons(fig, grid)

    return fig, ax
end

function create_figure()
    # Figure dimensions
    width = 1500
    height = 800

    fig = Figure(size = (width, height), backgroundcolor = :black)

    # Define a grid layout
    grid = GridLayout(fig[1:2, 1:3], tellheight = true)

    title_axis = Axis(grid[1, 2], width = width*0.5, height = 200, backgroundcolor = :black)
    deregister_interaction!(title_axis, :rectanglezoom)
    deactivate_interaction!(title_axis, :dragpan)
    deactivate_interaction!(title_axis, :scrollzoom)
    deactivate_interaction!(title_axis, :limitreset)
    xlims!(title_axis, (0, 1))
    ylims!(title_axis, (0, 1))
    hidedecorations!(title_axis)
    hidespines!(title_axis)
    date_text = text!(title_axis, position = (0.5, 0.5), date_label[], align = (:center, :top), fontsize = 30, color = :white)
    lift(date_label) do d
        date_text[1] = d
    end

    crash_text = text!(title_axis, position = (0.5, 0.25), crash_label[], align = (:center, :top), fontsize = 20, color = :white)
    lift(crash_label) do cr
        crash_text[1] = cr
    end

    ax = Axis3(grid[2, 2], width = width*0.5, height = 700, aspect = (1, 1, 1), yreversed = true, xreversed = true)
    hidedecorations!(ax)
    hidespines!(ax)

    return fig, ax, grid
end

function create_buttons(fig, grid)
    button_size = (100, 30)

    # Orbit elements
    orbit_elements_box = Axis(grid[2, 1], width = 200, height = 500, backgroundcolor = :black)
    xlims!(orbit_elements_box, (0, 1))
    ylims!(orbit_elements_box, (-3, 1))
    hidedecorations!(orbit_elements_box)
    hidespines!(orbit_elements_box)
    deregister_interaction!(orbit_elements_box, :rectanglezoom)
    deactivate_interaction!(orbit_elements_box, :dragpan)
    deactivate_interaction!(orbit_elements_box, :scrollzoom)
    deactivate_interaction!(orbit_elements_box, :limitreset)

    text!(orbit_elements_box, "Orbit elements", position = Point3f0(0, 1, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "H", position = Point3f0(0, 0.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    h_text = text!(orbit_elements_box, "", position = Point3f0(0.1, 0.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "a", position = Point3f0(0, 0, 0), align = (:left, :top), fontsize = 20, color = :white)
    a_text = text!(orbit_elements_box, "", position = Point3f0(0.1, 0, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "e", position = Point3f0(0, -0.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    e_text = text!(orbit_elements_box, "", position = Point3f0(0.1, -0.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "i", position = Point3f0(0, -1.0, 0), align = (:left, :top), fontsize = 20, color = :white)
    i_text = text!(orbit_elements_box, "", position = Point3f0(0.1, -1.0, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "Ω", position = Point3f0(0, -1.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    Ω_text = text!(orbit_elements_box, "", position = Point3f0(0.1, -1.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "ω", position = Point3f0(0, -2.0, 0), align = (:left, :top), fontsize = 20, color = :white)
    ω_text = text!(orbit_elements_box, "", position = Point3f0(0.1, -2.0, 0), align = (:left, :top), fontsize = 20, color = :white)
    text!(orbit_elements_box, "f", position = Point3f0(0, -2.5, 0), align = (:left, :top), fontsize = 20, color = :white)
    f_text = text!(orbit_elements_box, "", position = Point3f0(0.1, -2.5, 0), align = (:left, :top), fontsize = 20, color = :white)

    lift(altitude_label) do h
        h_text[1] = h
    end

    lift(coes) do c
        a_text[1] = "$(round((c.a / 1e3), digits = 1)) km"
        e_text[1] = "$(round(c.e, digits = 1))"
        i_text[1] = "$(round(c.i, digits = 1))°"
        Ω_text[1] = "$(round(c.Ω, digits = 1))°"
        ω_text[1] = "$(round(c.ω, digits = 1))°"
        f_text[1] = "$(round(c.f,digits = 1))°"
    end

    # Buttons and sliders
    button_box = GridLayout(grid[2, 3])

    start_button = Button(fig, label = "Start", width = button_size[1], height = button_size[2])
    stop_button = Button(fig, label = "Stop", width = button_size[1], height = button_size[2])
    restart_button = Button(fig, label = "Restart", width = button_size[1], height = button_size[2])

    button_box[2, 1] = start_button
    button_box[3, 1] = stop_button
    button_box[4, 1] = restart_button

    # Slider
    slider_grid = GridLayout(button_box[1, 1])
    sl_cd = Slider(slider_grid[2, 1], range = 1.5:0.1:3, startvalue = 2.2)
    slider_label = Label(slider_grid[1, 1], "", fontsize = 20, color = :white, halign = :left)
    lift(sl_cd.value) do value
        slider_label.text = "Drag coefficient: $(round(value, digits=1))"
    end
    # Update the satellite's c_d value when the slider value changes
    on(sl_cd.value) do value
        orbit[].satellite = SATORBIT.Satellite(value, orbit[].satellite.area, orbit[].satellite.mass,)
    end

    connect_buttons(start_button, stop_button, restart_button, sl_cd)
end

function connect_buttons(start_button, stop_button, restart_button, sl_cd)
    on(start_button.clicks) do _
        start_simulation()
    end

    on(stop_button.clicks) do _
        stop_simulation()
    end

    on(restart_button.clicks) do _
        restart_simulation(sl_cd)
    end
end

# Function to stop the simulation
function stop_simulation()
    is_running[] = false
end

# Simulation control functions
function start_simulation()
    is_running[] = true
end

function restart_simulation(sl_cd)
    is_running[] = false
    satellite_position[] = r_0
    date_label[] = Dates.format(start_date, "yyyy-mm-dd HH:MM:SS")
    altitude_label[] = @sprintf("%.2f km", altitude)
    rotate_earth(earth, start_date)
    rotate_ecef_frame(x_ecef, y_ecef, z_ecef, start_date)

    # set slider value to default
    set_close_to!(sl_cd, 2.2)
    satellite = SATORBIT.Satellite(2.2, 1, 1)
    orbit[] = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

    # reset orbit elements
    coes[] = init_orbit

    crash_label[] = ""

end

function plot_earth(ax)
    earth_radius = 6371 * 1e3
    data = load(Makie.assetpath("earth.png"))
    color = Sampler(data)

    sphere = Sphere(Point3f0(0, 0, 0), earth_radius)
    earth = mesh!(ax, sphere, color = color, transparency = false)

    return earth
end

function rotate_earth(earth, date)
    et = SATORBIT.utc2et(date)
    R_eci_ecef = SATORBIT.pxform("J2000", "ITRF93", et)
    theta = atan(R_eci_ecef[1, 1], R_eci_ecef[2, 1]) + π/2
    GLMakie.rotate!(earth, Vec3f0(0, 0, 1), theta)
end

function plot_eci_frame(ax)
    earth_radius = 6371 * 1e3
    x_eci = Point3f0(earth_radius + 1e6, 0, 0)
    y_eci = Point3f0(0, earth_radius + 1e6, 0)
    z_eci = Point3f0(0, 0, earth_radius + 1e6)

    arrows!(ax, [Point3f0(0, 0, 0)], [x_eci], arrowsize = 1e6, color = :red)
    arrows!(ax, [Point3f0(0, 0, 0)], [y_eci], arrowsize = 1e6, color = :green)
    arrows!(ax, [Point3f0(0, 0, 0)], [z_eci], arrowsize = 1e6, color = :blue)
end

function plot_ecef_frame(ax)
    earth_radius = 6371 * 1e3
    x_ecef = Point3f0(earth_radius + 1e6, 0, 0)
    y_ecef = Point3f0(0, earth_radius + 1e6, 0)
    z_ecef = Point3f0(0, 0, earth_radius + 1e6)

    x_ecef_arrow = arrows!(ax, [Point3f0(0, 0, 0)], [x_ecef], arrowsize = 1e6, color = :red)
    y_ecef_arrow = arrows!(ax, [Point3f0(0, 0, 0)], [y_ecef], arrowsize = 1e6, color = :green)
    z_ecef_arrow = arrows!(ax, [Point3f0(0, 0, 0)], [z_ecef], arrowsize = 1e6, color = :blue)

    return x_ecef_arrow, y_ecef_arrow, z_ecef_arrow
end

function rotate_ecef_frame(x_ecef_arrow, y_ecef_arrow, z_ecef_arrow, date)
    et = SATORBIT.utc2et(date)
    R_eci_ecef = SATORBIT.pxform("J2000", "ITRF93", et)
    theta = atan(R_eci_ecef[1, 1], R_eci_ecef[2, 1]) - π/2

    # rotate the ECEF frame
    GLMakie.rotate!(x_ecef_arrow, Vec3f0(0, 0, 1), theta)
    GLMakie.rotate!(y_ecef_arrow, Vec3f0(0, 0, 1), theta)
    GLMakie.rotate!(z_ecef_arrow, Vec3f0(0, 0, 1), theta)
end