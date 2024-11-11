function spaceweather_monthly_forecast(file_path::String)
    headers = ["Year", "Month", "F107_95", "F107_50", "F107_5", "Ap_95", "Ap_50", "Ap_5"]
    df = DataFrame(CSV.File(file_path; delim=' ', ignorerepeated=true, header=headers, skipto=8))

    # Convert the first column to Int (Year)
    df[!, :Year] = round.(Int, df.Year)

    # Define a dictionary to map month names to numbers
    month_map = Dict(
        "JAN" => 1, "FEB" => 2, "MAR" => 3, "APR" => 4,
        "MAY" => 5, "JUN" => 6, "JUL" => 7, "AUG" => 8,
        "SEP" => 9, "OCT" => 10, "NOV" => 11, "DEC" => 12
    )

    # Convert the second column from string to Int (Month)
    df[!, :Month] = [month_map[m] for m in df.Month]

    # Combine the Year and Month columns into a single Date column
    df[!, :Date] = Date.(df.Year, df.Month, 1)

    # Convert the Date column to the format yyyy-mm
    df[!, :Date] = Dates.format.(df.Date, "yyyy-mm")

    # Drop the original Year and Month columns
    select!(df, Not([:Year, :Month]))

    # Move the Date column to the first position
    df = df[:, [:Date, :F107_95, :F107_50, :F107_5, :Ap_95, :Ap_50, :Ap_5]]

    return df
end

function get_spaceweather_monthly_forecast(date::Date)
    date_str = Dates.format(date, "yyyy-mm")

    # get the spaceweather data for the current month
    df_current_month = spaceweather_monthly_forecast_data[][df.Date .== date_str, :]

    f107_50 = df_current_month.F107_50[1]
    ap_50 = df_current_month.Ap_50[1]
    return f107_50, f107_50, ap_50
end
