function create_gui()
    fig, ax = create_figure()

    create_buttons(fig)

    return fig, ax
end

function create_figure()
    # Figure dimensions
    width = 800
    height = 800

    fig = Figure(size = (width, height), backgroundcolor = :black)

    supertitle = Label(fig[0, 1], "", fontsize = 30, color = :white)
    lift(date_label) do d
        supertitle.text = d
    end

    subtitle = Label(fig[1, 1], "", fontsize = 20, color = :white)
    lift(altitude_label) do a
        subtitle.text = a
    end

    ax = Axis3(fig[2, 1], width = 600, height = 600, aspect = (1, 1, 1), yreversed = true, xreversed = true)
    hidedecorations!(ax)

    return fig, ax
end

function create_buttons(fig)
    button_size = (100, 30)

    button_box = GridLayout(fig[2, 2])

    start_button = Button(fig, label = "Start", width = button_size[1], height = button_size[2])
    stop_button = Button(fig, label = "Stop", width = button_size[1], height = button_size[2])

    button_box[1, 1] = start_button
    button_box[2, 1] = stop_button

    connect_buttons(start_button, stop_button)
end

function connect_buttons(start_button, stop_button)
    on(start_button.clicks) do _
        start_simulation()
    end

    on(stop_button.clicks) do _
        stop_simulation()
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