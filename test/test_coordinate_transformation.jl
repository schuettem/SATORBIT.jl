@testset "Coordinate Transformation" begin
    @testset "COES <-> ECI" begin
        alt_perigee = 409e3
        radius_earth = 6378.137e3
        radius_perigee = radius_earth+ alt_perigee
        alt_apogee = 409e3
        radius_apogee = radius_earth+ alt_apogee

        e_original = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
        a_original = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis

        i_original = 52.0 # Inclination (degrees)
        f_original = 40.0 # True Anomaly (degrees)
        Ω_original = 106.0 # Right Ascension of the Ascending Node (degrees)
        ω_original = 234.0 # Argument of Periapsis (degrees)

        orbit_coes = SATORBIT.COES(a_original, e_original, i_original, Ω_original, ω_original, f_original)
        planet = SATORBIT.Earth()
        μ = planet.μ # m^3 s^-2 (Standard gravitational parameter)

        r_eci, v_eci = SATORBIT.coes2eci(orbit_coes, μ)

        # Expected values
        r_eci_expected = [3.8764236166295903e6, 1.6040729659445104e6, -5.335308662217337e6]
        v_eci_expected = [-2423.528291504609, 7257.837811991218, 421.24631637197353]

        @test r_eci ≈ r_eci_expected atol=1e-6
        @test v_eci ≈ v_eci_expected atol=1e-6

        # Convert back to COES
        a, e, i, Ω, ω, f = SATORBIT.eci2coes(r_eci_expected, v_eci_expected, μ)

        @test a_original ≈ a atol=1 # Semi-major axis
        @test e_original ≈ e atol=1 # Eccentricity
        @test i_original ≈ i atol=1 # Inclination
        @test Ω_original ≈ Ω atol=1 # Right Ascension of the Ascending Node
        @test ω_original ≈ ω atol=1 # Argument of Periapsis
        @test f_original ≈ f atol=1 # True Anomaly
    end
end