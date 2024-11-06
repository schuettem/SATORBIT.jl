using SATORBIT
using Dates
using Test

@testset "SATORBIT.jl" begin
    include("test_coordinate_transformation.jl")
    include("test_spaceweather.jl")
    include("test_atmosphere.jl")
end