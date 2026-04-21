from flask import Flask, request, jsonify, render_template
import sqlite3
import json
import pandas as pd
from model.finalbackend_project_V2 import rate
from model.airline_homepage import get_homepage
from model.airline_revews import get_review
from model.feature_ratings import get_feature_rating
from model.city_filter import get_endcities, get_stopCities, get_airlines

app = Flask(__name__)

@app.route('/')
@app.route('/home')
def home():

    departureCities = ['London', 'Toronto', 'New York', 'Hong Kong', 'Bangkok',
     'Amsterdam', 'Vancouver', 'Guangzhou', 'Sydney', 'Los Angeles',
     'Manchester', 'Singapore', 'Istanbul', 'Jakarta', 'Kuala Lumpur',
     'Phuket', 'Dubai', 'Chiang Mai', 'Melbourne', 'Brisbane']

    return render_template("home.html", departureCities=departureCities)

@app.route('/airline')
def airline():
    airline = request.args.get('airline', None)
    print("airline", airline)
    #airline = 'ANA All Nippon Airways'

    home_page = get_homepage(airline)
    print("home_page", home_page)

    reviews = get_review(airline)
    print("reviews", reviews)

    ratings = get_feature_rating(airline)
    print("ratings", ratings)

    return render_template("airline.html", airline=airline, al_homepage = home_page, reviews=reviews, ratings=ratings)

rating_strings = {"Don't care":0, "Not important":1, "Somewhat not important":2,
                  "Somewhat important":3, "Important":4, "Very important":5, "":0, None:0}

@app.route('/Recomm', methods = ['GET'])
def Recomm():
    start_city = request.args.get('start_city', None)
    end_city = request.args.get('end_city', None)
    Stops = request.args.get('Stops', None)
    Aircraft = request.args.get('Aircraft', None)
    ServiceRating = rating_strings[request.args.get('ServiceRating', "Don't care")]
    FoodRating = rating_strings[request.args.get('FoodRating', "Don't care")]
    SeatComfortRating = rating_strings[request.args.get('SeatComfortRating', "Don't care")]
    EntertainmentRating = rating_strings[request.args.get('EntertainmentRating', "Don't care")]
    GroundServiceRating = rating_strings[request.args.get('GroundServiceRating', "Don't care")]
    WifiRating = rating_strings[request.args.get('WifiRating', "Don't care")]

    if Stops == "Don't care" or len(Stops.strip()) < 1:
        Stops = 'nan'
    if Aircraft == "Don't care"  or len(Aircraft.strip()) < 1:
        Aircraft = 'nan'

    # EntertainmentRating=5
    # FoodRating=4
    # GroundServiceRating=3
    # SeatComfortRating=2
    # ServiceRating=1
    # WifiRating=0

    #['EntertainmentRating','FoodRating','GroundServiceRating','SeatComfortRating','ServiceRating', 'WifiRating']
    print("Parameters: ", start_city, end_city, [Aircraft, Stops, EntertainmentRating,FoodRating,GroundServiceRating,SeatComfortRating,ServiceRating, WifiRating])

    if len(start_city) and len(end_city):
        airlines, airlines_percentage = rate(start_city=start_city, end_city=end_city,
            lst=[Aircraft, Stops, EntertainmentRating,FoodRating,GroundServiceRating,SeatComfortRating,ServiceRating, WifiRating], route='db/my_database.db')

        #airlines, airlines_percentage = rate(start_city='Bangkok', end_city='Singapore',
        #                                     lst=['Airbus', 'nan', 1, 5, 3, 5, 5, 0], route='db/my_database.db')
        recomm_list = [{'airline': n, 'matchingRate': round(r * 100, 1)} for n, r in zip(airlines.tolist(), airlines_percentage.tolist())]
    else:
        recomm_list = []

    recomm_list = recomm_list[0:3]
    json_string = json.dumps(recomm_list)
    print("returned: ", json_string)

    return json_string


@app.route('/ArrivalCities', methods = ['GET'])
def ArrivalCities():
    start_city = request.args.get('start_city', None)
    print("start_city: ", start_city)

    if (len(start_city.strip()) > 0):
        return get_endcities(start_city)
    return []

@app.route('/StopCities', methods = ['GET'])
def StopCities():
    start_city = request.args.get('start_city', None)
    end_city = request.args.get('end_city', None)
    print("start_city: ", start_city, "end_city: ", end_city)

    if (len(start_city.strip()) > 0) and (len(end_city.strip()) > 0):
        return get_stopCities(start_city, end_city)
    return []

@app.route('/Airlines', methods = ['GET'])
def Airlines():
    airlines = get_airlines()
    return airlines

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
