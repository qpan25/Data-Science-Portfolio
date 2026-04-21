
def get_feature_rating(airline, route='db/2ndfunction.db'):
    import sqlite3
    import pandas as pd
    conn = sqlite3.connect(route)
    query = 'SELECT * FROM "2ndfunction_table"'
    df = pd.read_sql(query, conn)
    conn.close()

    df = df[(df['Airline'] == airline)]
    df = df[['EntertainmentRating', 'FoodRating', 'GroundServiceRating', 'SeatComfortRating', 'ServiceRating',
               'WifiRating']]
    mdf = df.mean()

    #ratings = mdf.to_dict(orient='records')
    ratings = []
    for k,v in mdf.to_dict().items():
        ratings.append({'name':k[:-6], 'value': round(v,1), 'percent':round(v*100/5.0) })

    return ratings

#test=get_feature_rating('ANA All Nippon Airways',route= '../db/2ndfunction.db')
#print(type(test))
#print(test)