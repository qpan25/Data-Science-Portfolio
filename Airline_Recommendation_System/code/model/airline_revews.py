#looking for review
def get_review(airline, route='db/reviews.db'):
    import sqlite3
    import pandas as pd
    conn = sqlite3.connect(route)
    query = 'SELECT * FROM "reviews"'
    df = pd.read_sql(query, conn)
    conn.close()

    df = df[(df['Airline'] == airline)][:5]
    df.reset_index(drop=True, inplace=True)

    reviews = df.to_dict()['CustomerReview']
    #reviews = df[['index', 'CustomerReview']].to_dict(orient='records')

    return reviews

#test = get_review('ANA All Nippon Airways', route='../db/reviews.db')
#print(test)
