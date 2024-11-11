function spaceweather_daily_forecast(file_path::String)
    # Load the spaceweather data
    lines = readlines(file_path)

    # Extract the AP forecast data
    ap_forecast_start = findfirst(contains("45-DAY AP FORECAST"), lines) + 1
    ap_forecast_end = findfirst(contains("45-DAY F10.7 CM FLUX FORECAST"), lines) - 1
    ap_forecast_lines = lines[ap_forecast_start:ap_forecast_end]

    # Extract the F10.7 cm flux forecast data
    f107_forecast_start = ap_forecast_end + 2
    f107_forecast_lines = lines[f107_forecast_start:end]

    # Parse the AP forecast data
    ap_data = []
    for line in ap_forecast_lines
        push!(ap_data, split(line))
    end
    ap_data = vcat(ap_data...)

    # Parse the F10.7 cm flux forecast data
    f107_data = []
    for line in f107_forecast_lines
        push!(f107_data, split(line))
    end
    f107_data = vcat(f107_data...)

    # Remove the last elements of the f107 data
    nbr = length(ap_data)
    f107_data = f107_data[1:nbr]

    # Create DataFrames
    ap_dates = ap_data[1:2:end]
    ap_values = parse.(Int64, ap_data[2:2:end])
    ap_df = DataFrame(Date = ap_dates, AP = ap_values)

    f107_dates = f107_data[1:2:end]
    f107_values = parse.(Int64, f107_data[2:2:end])
    f107_df = DataFrame(Date = f107_dates, F107 = f107_values)

    # Convert dates to the desired format
    ap_df.Date = convert_date.(ap_df.Date)
    f107_df.Date = convert_date.(f107_df.Date)

    # Create a DataFrame with the AP and F10.7 cm flux forecast data
    forecast_df = rightjoin(ap_df, f107_df, on = :Date)

    return forecast_df
end

function get_spaceweather_daily_forecast(date::Date)
    row = spaceweather_daily_forecast_data[][spaceweather_daily_forecast_data[].Date .== date, :]
    f107 = row.F107[1]
    ap = row.AP[1]
    return f107, f107, ap
end

function convert_date(date::SubString{String})
    yyyy = 2000 + parse(Int, date[6:7])
    dd = parse(Int, date[1:2])
    mm = month2int(date[3:5])
    date = Date(yyyy, mm, dd)
    return date
end

function month2int(month::SubString{String})
    months = Dict(
        "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
        "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
        "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
    )
    return months[month]
end