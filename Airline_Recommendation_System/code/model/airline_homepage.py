# looking for homepage
def get_homepage(airline, route='db/airline_sites.db'):
    import sqlite3
    import pandas as pd
    conn = sqlite3.connect(route)
    query = 'SELECT * FROM "airline_sites"'
    df = pd.read_sql(query, conn)
    conn.close()

    df = df[(df['airline'] == airline)]

    if len(df) > 0 :
        return df.iloc[0]['homepage']
    else:
        return str("https://www.google.com/travel/flights")

'''
test = get_homepage('ANA All Nippon Airways', route= '../db/airline_sites.db')
print(type(test), test)
test = get_homepage('ANA Nippon Airways', route= '../db/airline_sites.db')
print(type(test), test)
'''