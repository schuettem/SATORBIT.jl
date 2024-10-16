struct Pertubations
    J2::Bool
    aero::Bool
    moon_gravity::Bool
    sun_gravity::Bool
    solar_pressure::Bool
    relativity::Bool

    function Pertubations(J2, aero)
        new(J2, aero, false, false, false, false)
    end
end