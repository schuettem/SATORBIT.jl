"""
    Get the space weather data at a specific date
"""
function get_spaceweather(date::DateTime)
    date = get_year_month_day(date)
    todays_date = today()

    # check if the date is in the future
    if date - todays_date >= Dates.Day(0)
        if date - todays_date >= Dates.Day(45)
            return get_spaceweather_monthly_forecast(date)
        else
            return get_spaceweather_daily_forecast(date)
        end
    else
        return get_spaceweather_historical(date)
    end
end

function get_year_month_day(date::DateTime)
    year_month_day = Dates.yearmonthday(date)
    year_month_day = Dates.Date(year_month_day[1], year_month_day[2], year_month_day[3])
    return year_month_day
end