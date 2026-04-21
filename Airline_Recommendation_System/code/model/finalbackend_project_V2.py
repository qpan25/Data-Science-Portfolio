#!/usr/bin/env python
# coding: utf-8


# 列‘Aircraft’ 已经清洁过，只会有的value是： 'nan','Boeing','Airbus','McDonnell Douglas',
# 'Embraer','Bombardier Aerospace','De Havilland Canada' 等制造飞机的公司名字，不是具体的737， 777 这种


# lst 是根据用户前段点选之后输入的变量，其格式是一个python list: eg. ['Boeing','New York',5,4,3,2,1,0]
# Aircraft='Boeing', 
# Stops='New York',
# EntertainmentRating=0
# FoodRating=1
# GroundServiceRating=2
# SeatComfortRating=3
# ServiceRating=4
# WifiRating=5


# 导包
import sqlite3
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score


def rate(start_city, end_city, lst, route='my_database.db'):

    #导入'toy_dataset.csv' as df
    conn = sqlite3.connect(route)
    query = 'SELECT * FROM your_table_name'
    df = pd.read_sql(query, conn)
    conn.close()
    
    
    df = df[(df['start_city'] == start_city) & (df['end_city'] == end_city)]
    df = df[['Aircraft','Airline','EntertainmentRating','FoodRating','GroundServiceRating','SeatComfortRating','ServiceRating',
                  'WifiRating','Stops']]
    
    # Convert NaN values to string 'nan'
    df['Aircraft'].fillna('nan', inplace=True)
    df['Stops'].fillna('nan', inplace=True)
    
    # numeric 的列添加mean值 into NaN 的部分
    for i in ['EntertainmentRating','FoodRating','GroundServiceRating','SeatComfortRating','ServiceRating',
                  'WifiRating']:
        mean_value = df[i].mean()
        df[i].fillna(mean_value, inplace=True)
        
    #One-hot-encoding
    X = df.drop('Airline', axis=1) 
    y = df['Airline']  
    
    categorical_columns = ['Aircraft', 'Stops'] 
    encoder = OneHotEncoder(sparse=False, handle_unknown='ignore')
    
    
    X_encoded = encoder.fit_transform(X[categorical_columns]) #X_encoded是纯np array
    
    #merge X_encoded 和原始的numeric features
    X_encoded_df = pd.DataFrame(X_encoded)

    df_reset = df.reset_index(drop=True)
    merged_df = pd.concat([X_encoded_df, df_reset[['EntertainmentRating','FoodRating','GroundServiceRating',
                                                        'SeatComfortRating','ServiceRating','WifiRating']]], axis=1)
    #所有列的名字都变成string
    merged_df.columns = merged_df.columns.astype(str)

    #build 随机森林 OOB 
    oob_accuracy=[]
    for tree_number in range(1,70):
        clf_forest = RandomForestClassifier(n_estimators=tree_number,random_state=78,oob_score=True).fit(merged_df, y)
        oob=clf_forest.oob_score_
        oob_accuracy.append(oob)
        
    max_index = np.argmax(oob_accuracy)
    best_num_tree = list(range(1,70))[max_index] # 随机森林最佳参数
    
    #train model with 最佳参数，使用全部data
    clf_forest = RandomForestClassifier(n_estimators=best_num_tree,random_state=78).fit(merged_df, y)
    
    
    #转化用户输入为一个row=1的df_input
    # One-hot encode categorical variables ('Aircraft' and 'Stops')
    
    user_encoded = encoder.transform(pd.DataFrame([lst[:2]],columns=['Aircraft', 'Stops']))

    user_encoded_df = pd.DataFrame(user_encoded, columns=[f'{i}' for i in range(user_encoded.shape[1])])
    
    user_input2_df = pd.DataFrame(np.array([lst[2:]]), columns=['EntertainmentRating','FoodRating','GroundServiceRating','SeatComfortRating','ServiceRating','WifiRating'])
    new_data_df = pd.concat([user_encoded_df, user_input2_df], axis=1) 
    new_data_df.columns = new_data_df.columns.astype(str)
    
    
    #输出最优top 5 Airlines
    class_labels = clf_forest.classes_
    probabilities=clf_forest.predict_proba(new_data_df)
    #输出Airlines的percentage 匹配度，对应输出的Airline名字
    sorted_indices1 = np.argsort(probabilities[0])[::-1]
    sorted_probabilities = probabilities[0][sorted_indices1]
    
    
    sorted_indices = probabilities.argsort()[0][::-1]#倒叙排列
    
    if len(y.unique())>=5:      
        # Get the top 5 class labels
        top_5_labels = class_labels[sorted_indices[:5]]
        return top_5_labels,sorted_probabilities[:5]
    else:
        return class_labels[sorted_indices],sorted_probabilities #全部Airline 少于5的情况



# 测试：
#airlines, airlines_percentage=rate(start_city='Bangkok', end_city='Singapore', lst=['Airbus','nan',1,5,3,5,5,0], route='../db/my_database.db')
#print(type(airlines), airlines.tolist())
#print(airlines_percentage.tolist())




