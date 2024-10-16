@testset "Coordinate Transformation" begin
    @testset "COES to ECI" begin
        alt_perigee = 409e3
        radius_earth = 6378.137e3
        radius_perigee = radius_earth+ alt_perigee
        alt_apogee = 409e3
        radius_apogee = radius_earth+ alt_apogee

        e = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
        a = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis

        i = 52.0 # Inclination (degrees)
        f = 40.0 # True Anomaly (degrees)
        Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
        ω = 234.0 # Argument of Periapsis (degrees)

        orbit_coes = SATORBIT.COES(a, e, i, Ω, ω, f)
        γ = 6.67430e-11 # m^3 kg^-1 s^-2 (Gravitational constant)
        mass = 5.972e24 # kg (Earth)
        μ = γ * mass # m^3 s^-2 (Standard gravitational parameter)

        r_eci, v_eci = SATORBIT.coes2eci(orbit_coes, μ)

        # Expected values
        r_eci_expected = [3.8764236166295903e6, 1.6040729659445104e6, -5.335308662217337e6]
        v_eci_expected = [-2423.528291504609, 7257.837811991218, 421.24631637197353]

        @test r_eci ≈ r_eci_expected atol=1e-6
        @test v_eci ≈ v_eci_expected atol=1e-6
    end

    @testset "ECI to COES" begin
        r_eci = [3.8764236166295903e6, 1.6040729659445104e6, -5.335308662217337e6]
        v_eci = [-2423.528291504609, 7257.837811991218, 421.24631637197353]
        γ = 6.67430e-11 # m^3 kg^-1 s^-2 (Gravitational constant)
        mass = 5.972e24 # kg (Earth)
        μ = γ * mass # m^3 s^-2 (Standard gravitational parameter)

        a, e, i, Ω, ω, f = SATORBIT.eci2coes(r_eci, v_eci, μ)

        # Expected values
        alt_perigee = 409e3
        radius_earth = 6378.137e3
        radius_perigee = radius_earth+ alt_perigee
        alt_apogee = 409e3
        radius_apogee = radius_earth+ alt_apogee

        e_expected = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
        a_expected = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis
        i_expected = 52.0
        Ω_expected = 106.0
        ω_expected = 234.0
        f_expected = 40.0

        @test a ≈ a_expected rtol=1
        @test e ≈ e_expected rtol=1
        @test i ≈ i_expected atol=1
        @test Ω ≈ Ω_expected atol=1
        @test ω ≈ ω_expected atol=1
        @test f ≈ f_expected atol=1
    end

    # @testset "ECI to ECEF" begin
    #     r_eci = [ 3876345.37008241, 1604040.58734418, -5335200.96772307]
    #     date = SATORBIT.DateTime(2020, 8, 29, 0, 0, 0)
    #     t_0 = SATORBIT.utc2et(date)
    #     r_ecef = SATORBIT.eci2ecef(r_eci, date)

    #     # Expected values
    #     t_0_exp = 651931269.1826664 # Python code
    #     @test t_0 ≈ t_0_exp rtol=1e-3
    #     r_ecef_expected = [2971823.37381705, 2974744.70366705, -5327525.57786816] # Python code
    #     @test r_ecef ≈ r_ecef_expected atol=1e-6
    # end

    # @testset "ECEF to GEO" begin
    #     r_ecef = [2971823.37381705, 2974744.70366705, -5327525.57786816]
    #     latitude, longitude = SATORBIT.ecef2geo(r_ecef)

    #     # Expected values
    #     latitude_expected = -51.71700694342137
    #     longitude_expected = 45.02814730367574

    #     @test latitude ≈ latitude_expected atol=1e-6
    #     @test longitude ≈ longitude_expected atol=1e-6
    # end
end