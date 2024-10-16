using SATORBIT
using Dates

spacewaether_data = SATORBIT.spaceweather()

first_day = SATORBIT.DateTime(spacewaether_data[1, 1])
date = SATORBIT.DateTime(2020, 10, 14, 12, 0, 0)

# days since the first day
date_year_month_day = Dates.yearmonthday(date)

# convert to DateTime
date_year_month_day = DateTime(date_year_month_day...)


millisecounds_since_first_day = date_year_month_day - first_day
days_since_first_day = millisecounds_since_first_day.value / (1000 * 60 * 60 * 24)

day = spacewaether_data[Int(days_since_first_day + 1), :]

spaceweather_at_date = SATORBIT.spaceweather_at(date, spacewaether_data)

f107adj_day_value = SATORBIT.f107adj_day(date, spacewaether_data)

f107adj_81avg_value = SATORBIT.f107adj_81avg(date, spacewaether_data)

row_value = SATORBIT.get_rownbr(DateTime(1930, 1, 1, 0, 0, 0))