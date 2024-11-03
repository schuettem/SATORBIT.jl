@testset "spaceweather" begin
    date = DateTime(2023, 08, 27, 0, 0, 0)

    f107, f107_avg, ap = SATORBIT.get_spaceweather(date)

    @test f107 ≈ 144.5 atol=1e-6
    @test f107_avg ≈ 161.23703703703703 atol=1e-6
    @test ap ≈ 10 atol=1e-6
end