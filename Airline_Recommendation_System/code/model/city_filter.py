#filter arrival cities and stop cities by departure city
# coding: utf-8

import sqlite3
import pandas as pd

def get_endcities(start_city, route='db/my_database.db'):
    conn = sqlite3.connect(route)
    #query = 'SELECT distinct start_city, end_city, Stops FROM your_table_name'
    query = "SELECT distinct end_city FROM your_table_name where start_city='" + start_city + "' and TRIM(end_city) <> '' "
    df = pd.read_sql(query, conn)
    conn.close()

    return df.to_json(orient="records")

def get_stopCities(start_city, end_city, route='db/my_database.db'):
    conn = sqlite3.connect(route)
    #query = 'SELECT distinct start_city, end_city, Stops FROM your_table_name'
    query = "SELECT distinct Stops FROM your_table_name where start_city='" + start_city + "' and end_city='" + end_city + "' and TRIM(Stops) <> '' "
    df = pd.read_sql(query, conn)
    conn.close()

    return df.to_json(orient="records")

def get_airlines(route='db/my_database.db'):
    conn = sqlite3.connect(route)
    #query = 'SELECT distinct start_city, end_city, Stops FROM your_table_name'
    query = "SELECT distinct Airline FROM your_table_name where TRIM(Airline) <> '' "
    df = pd.read_sql(query, conn)
    conn.close()

    return df.to_json(orient="records")

'''
airlines = get_airlines( route='../db/my_database.db')
print("##airlines:")
print(airlines)

cities = get_endcities(start_city='London', route='../db/my_database.db')
print("##end cities:")
print(cities)
cities = get_stopCities(start_city='London', end_city='Dubai', route='../db/my_database.db')
print('##stops:')
print(cities)
'''
