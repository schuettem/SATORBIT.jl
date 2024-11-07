@testset "Atmosphere" begin
    f107 = 120
    f107a = 120
    ap = 5
    date_time = DateTime(2023, 10, 20, 0, 0, 0) # 10 / 20 / 2023 12:00:00 AM
    lat = 55.0
    lon = 45.0

    # alt 300 km:
    alt = 300.0 * 1e3
    atm = SATORBIT.get_nrlmsise00_data(date_time, alt, lat, lon, f107, f107a, ap)

    n_o = SATORBIT.get_o_density(atm)
    T = SATORBIT.get_temperature(atm)
    ρ = SATORBIT.get_total_mass_density(atm)

    @test n_o ≈ 5.07e14 atol=1e12 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test T ≈ 848.0 atol=0.1 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test ρ ≈ 1.70e-11 atol=1e-13 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/

    # alt 200 km:
    alt = 200.0 * 1e3
    atm = SATORBIT.get_nrlmsise00_data(date_time, alt, lat, lon, f107, f107a, ap)

    n_o = SATORBIT.get_o_density(atm)
    T = SATORBIT.get_temperature(atm)
    ρ = SATORBIT.get_total_mass_density(atm)

    @test n_o ≈ 4.35e15 atol=1e13 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test T ≈ 802.8 atol=0.1 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test ρ ≈ 2.59e-10 atol=1e-12 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/

    # alt 400 km:
    alt = 400.0 * 1e3
    atm = SATORBIT.get_nrlmsise00_data(date_time, alt, lat, lon, f107, f107a, ap)

    n_o = SATORBIT.get_o_density(atm)
    T = SATORBIT.get_temperature(atm)
    ρ = SATORBIT.get_total_mass_density(atm)

    @test n_o ≈ 6.86e13 atol=1e12 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test T ≈ 850.7 atol=0.1 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
    @test ρ ≈ 1.98e-12 atol=1e-14 # reference value from NRLMSISE-00 https://kauai.ccmc.gsfc.nasa.gov/instantrun/nrlmsis/
end