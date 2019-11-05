import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import f1_score
from math import sqrt

#Clasifiers
from sklearn import preprocessing
import xgboost as xgb
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import GridSearchCV


class BuildModels():
    
    LIMPIADOR = CleanData()
    
    def split_and_clean(self, df):
        y = df.semaforo_std.ravel()
        X = df.drop(['cct', 'semaforo_std'], axis=1)

        X_train, X_test, y_train, y_test = train_test_split(X, y, 
                                                        test_size=0.1, 
                                                        random_state=15)
        
        df_train = LIMPIADOR.clean_data(X_train.join(y_train))
        df_test = LIMPIADOR.clean_data(X_test.join(y_test))
        
        y_train = df_train.semaforo_std.ravel()
        y_test = df_test.semaforo_std.ravel()
        
        X_train = df_train.drop(['semaforo_std'], axis=1)
        X_test = df_test.drop(['semaforo_std'], axis=1)
        
        return X_train, X_test, y_train, y_test
    
    def get_models_metrics(self, df):
        models = [
                "LogisticRegression",
                "KNeighbors",
                "RandomForest",
                "ExtraTreesClassifier",
                "XGBClassifier"
                ]

        classifiers = [
           LogisticRegression(n_jobs = -1,solver="saga", random_state = 10) ,
           KNeighborsClassifier(n_jobs = -1),
           RandomForestClassifier(n_jobs = -1, random_state = 10, oob_score = True),
           ExtraTreesClassifier(n_jobs = -1, random_state = 10) ,
           xgb.XGBClassifier()
        ]

        parameters = [
                    {'penalty':['elasticnet','l1','l2'],   #Logit
                     'C' : [0.01, 0.1,0.3,0.5,0.8,1,2],
                     "l1_ratio" : [0.3,0.5,0.8],
                     "max_iter" : [70, 100,200,500]},
                     {'n_neighbors' :[2,5,10,20,30,50] },  #KN
                     {'n_estimators':[50,100,200,400, 500],     #RandomForest
                    'max_depth':[None, 10,50],
                    'min_samples_split':[2,4,8],
                     'max_features':["auto", "log2"]} ,
                    {'n_estimators':[50,100,200, 400,500],      #Extra trees
                    'max_depth':[10,50,None],
                    'min_samples_split':[2,4,8],
                     'max_features':["auto", "log2"]} ,
                    {'learning_rate': [0.2, 0.3, 0.5],     #XGBoost
                    'max_depth': [6, 9, 12],
                    'subsample': [0.8, 1.0],
                    'colsample_bytree': [0.8, 1.0]}   
                     ]

        optimal = {}
        info_modelo = {}
        results = {}


        diferencia = list(range(1,6))

        X_train_org, X_test_org, y_train_org, y_test_org = self.split_and_clean(df)
        
        for model, clf, params in zip(models, classifiers, parameters):
            gscv = GridSearchCV(clf, param_grid=params, 
                                cv=5, verbose=1, n_jobs=-1,  
                                scoring='f1')

            gscv = gscv.fit(X_train_org.astype('float32'), y_train_org)
            score = gscv.best_score_
            optimal[model] = {'clf':gscv.best_estimator_, 'score':score}
            print("{} score: {}".format(model, score))
            reg = gscv.best_estimator_
            print(gscv.refit_time_)
            info_modelo[model] = gscv.refit_time_
            nom_csv = "cv_"+ str(model) +".csv"
            pd.DataFrame(gscv.cv_results_).to_csv(nom_csv)

            results[model] ={}

            for dif in diferencia:
                df_dif = df[df.diferencia ==dif]
                X_train, X_test, y_train, y_test = self.split_and_clean(df_dif)

                reg.fit(X_train, y_train)
                y_pred = reg.predict(X_test)
                f1_value =  f1_score(y_test, y_pred, average='weighted') 

                results[model][dif] =f1_value
                print(model, dif, f1_value)

        print(results)
        return optimal, results,info_modelo

    def clean_dataset(self, df):
        assert isinstance(df, pd.DataFrame), "df needs to be a pd.DataFrame"
        df.dropna(inplace=True)
        print(len(df))
        X = df.drop(['cct'], axis = 1)
        y = df[['cct']]
        indices_to_keep = ~df.isin([np.nan, np.inf, -np.inf]).any(1)

        df_new = X[indices_to_keep].astype(np.float64).join(y[indices_to_keep])
        print(len(df_new))
        return df_new
    
    
    def resultados_por_estado(self, df):
        estados = list(range(1,34))
        diferencia = list(range(1,6))

        lista_vars = []

        resultados = {}
        benchmark = {}
        ganancia = {}


        for dif in diferencia:
            df_dif = df[df.diferencia ==dif]
            resultados[dif]=[]
            benchmark[dif]=[]
            ganancia[dif]=[]
            for edo in estados:
                if edo == 33:
                    df_edo = df_dif
                else:
                    df_edo = df_dif[df_dif.edo ==edo]
                if len(df_edo)>0:
                 
                    X_train, X_test, y_train, y_test = split_and_clean(df_edo)
                   
                    reg_rf = RandomForestClassifier(n_jobs = -1, random_state = 10, oob_score = True, n_estimators = 500) 
                    reg_rf.fit(X_train, y_train)
                    feature_importances = pd.DataFrame(reg_rf.feature_importances_, index = X_train.columns,
                                                      columns=['importance']).sort_values('importance',ascending=False)
                    nuevas_vars = list(feature_importances.index)[:50]
                    union = list(set(lista_vars) | set(nuevas_vars))
                    lista_vars = union

                    y_pred = reg_rf.predict(X_test)

                    f1 = f1_score(y_test, y_pred, average='weighted') 

                    resultados[dif].append(f1)
                    if ((y_test.sum()/len(y_test))>0.5).bool():
                        y_bench = [1]*len(y_test)
                    else:
                        y_bench = [0]*len(y_test)

                    f2 = f1_score(y_test, y_bench, average='weighted') 
                    benchmark[dif].append(f2)

                    margen= f1-f2
                    ganancia[dif].append(margen)
                    print(dif, edo, f1,margen, len(union))
                else:
                    resultados[dif].append("-")
                    benchmark[dif].append("-")
                    ganancia[dif].append("-")

        return ganancia, benchmark, resultados



