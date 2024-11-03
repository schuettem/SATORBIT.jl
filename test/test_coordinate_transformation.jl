@testset "Coordinate Transformation" begin
    @testset "COES <-> ECI 1" begin
        # Define the orbital elements
        a_original = 6671e3  # Semi-major axis in meters (6371 km + 300 km)
        e_original = 0.1  # Eccentricity
        i_original = 45.0  # Inclination
        Ω_original = 60.0  # Right Ascension of Ascending Node
        ω_original = 90.0  # Argument of Periapsis
        f_original = 0.0 # True Anomaly at periapsis

        orbit_coes = SATORBIT.COES(a_original, e_original, i_original, Ω_original, ω_original, f_original)
        planet = SATORBIT.Earth()
        μ = planet.μ # m^3 s^-2 (Standard gravitational parameter)

        r_eci, v_eci = SATORBIT.coes2eci(orbit_coes, μ)

        # Expected values
        r_eci_expected = [-3.6766228666739804e6, 2.1226992017829567e6, 4.245398403565912e6]
        v_eci_expected = [-4272.798211988147, -7400.703593652923, 3.700055488743322e-13]

        @test r_eci ≈ r_eci_expected atol=1e-6
        @test v_eci ≈ v_eci_expected atol=1e-6

        # Convert back to COES
        a, e, i, Ω, ω, f = SATORBIT.eci2coes(r_eci_expected, v_eci_expected, μ)
        println("a: $a, e: $e, i: $i, Ω: $Ω, ω: $ω, f: $f")
        @test a_original ≈ a atol=1 # Semi-major axis
        @test e_original ≈ e atol=1 # Eccentricity
        @test i_original ≈ i atol=1 # Inclination
        @test Ω_original ≈ Ω atol=1 # Right Ascension of the Ascending Node
        @test ω_original ≈ ω atol=1 # Argument of Periapsis
        @test f_original ≈ f atol=1 # True Anomaly
    end

    @testset "COES <-> ECI 2" begin
        # Define the orbital elements
        a_original = 6671e3  # Semi-major axis in meters (6371 km + 300 km)
        e_original = 0.1  # Eccentricity
        i_original = 45.0  # Inclination
        Ω_original = 60.0  # Right Ascension of Ascending Node
        ω_original = 90.0  # Argument of Periapsis
        f_original = 45.0 # True Anomaly at periapsis

        orbit_coes = SATORBIT.COES(a_original, e_original, i_original, Ω_original, ω_original, f_original)
        planet = SATORBIT.Earth()
        μ = planet.μ # m^3 s^-2 (Standard gravitational parameter)

        r_eci, v_eci = SATORBIT.coes2eci(orbit_coes, μ)

        # Expected values
        r_eci_expected = [-4.851647307813013e6, -2.235162777629611e6, 3.0840684299536427e6]
        v_eci_expected = [228.86125935370228, -7372.324692711816, -3884.3620108983127]

        @test r_eci ≈ r_eci_expected atol=1e-6
        @test v_eci ≈ v_eci_expected atol=1e-6

        # Convert back to COES
        a, e, i, Ω, ω, f = SATORBIT.eci2coes(r_eci_expected, v_eci_expected, μ)
        println("a: $a, e: $e, i: $i, Ω: $Ω, ω: $ω, f: $f")
        @test a_original ≈ a atol=1 # Semi-major axis
        @test e_original ≈ e atol=1 # Eccentricity
        @test i_original ≈ i atol=1 # Inclination
        @test Ω_original ≈ Ω atol=1 # Right Ascension of the Ascending Node
        @test ω_original ≈ ω atol=1 # Argument of Periapsis
        @test f_original ≈ f atol=1 # True Anomaly
    end
end