function spaceweather()
    # Example usage
    file_path = "src/atmosphere/spaceweather.txt"
    # Load the data into a DataFrame
    df = DataFrame(CSV.File(file_path; delim=' ', ignorerepeated=true))
    # Generate row keys in yyyy-mm-dd format
    row_keys = Date[]
    for row in eachrow(df)
        date = Date(row[1], row[2], row[3])
        push!(row_keys, date)
    end

    # Add the row keys to the DataFrame
    df[!, :Date] = row_keys

    # remove the first, secound and third columns
    df = select(df, Not(1:3))

    # Move the Date column to the first position
    select!(df, :Date, Not(:Date))

    return df
end

function get_rownbr(date::DateTime)
    first_day = DateTime(1932, 1, 1, 0, 0, 0)
    date = get_year_month_day(date)
    # days since the first day
    millisecounds_since_first_day = date - first_day
    days_since_first_day = millisecounds_since_first_day.value / (1000 * 60 * 60 * 24)

    row_nbr = Int(days_since_first_day + 1)

    return row_nbr
end

"""
    Get the spaceweather data at a specific date
"""

function spaceweather_at(date::DateTime, df::DataFrame)
    row_nbr = get_rownbr(date)

    # Access the data for a specific date
    row = df[row_nbr, :]
    return row
end

"""
    Solar flux F10.7 at a specific date
"""
function f107adj_day(date::DateTime, df::DataFrame)
    date = get_year_month_day(date)

    row = spaceweather_at(date, df)
    return row["F10.7adj"]
end

"""
    Solar flux F10.7 81 day average at a specific date
"""
function f107adj_81avg(date::DateTime, df::DataFrame)
    date = get_year_month_day(date)

    dates = df[:, 1]

    # get 40 days before and 40 days after the date
    before = date - Dates.Day(40)
    after = date + Dates.Day(40)

    nbr_rows = size(df, 1)
    row_nbr_before = get_rownbr(before)
    row_nbr_after = get_rownbr(after)

    # if the date is before the first date or after the last date, return the data for the date
    if row_nbr_before < 1 || row_nbr_after > nbr_rows
        return f107adj_day(date, df)
    end

    # get the data for the 81 days
    f107adj_days = df[row_nbr_before:row_nbr_after, "F10.7adj"]

    # calculate the average
    f107adj_81avg = mean(f107adj_days)
    return f107adj_81avg
end

"""
    Magnetic index Ap at a specific date
"""
function ap_at(date::DateTime, df::DataFrame)
    date = get_year_month_day(date)

    row = spaceweather_at(date, df)
    return row["Ap"]
end

function get_year_month_day(date::DateTime)
    year_month_day = Dates.yearmonthday(date)
    year_month_day = Dates.DateTime(year_month_day[1], year_month_day[2], year_month_day[3])
    return year_month_day
end