using SATORBIT
using Dates
using DataFrames
using PyCall
using DelimitedFiles
using CSV

year = 2020
month = 8
day = 29
hour = 0
minute = 0
second = 0
date_time = DateTime(year, month, day, hour, minute, second)

altitude = 350 # km
latitude = -52 # degrees
longitude = 25.2 # degrees
f107 = 150
f107a = 150
ap = 4

atmosphere_data = SATORBIT.nrlmsise00.msise_flat(date_time, altitude, latitude, longitude, f107, f107a, ap)
