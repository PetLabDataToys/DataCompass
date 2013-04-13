#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

//  Thanks to Tom Carden, for ModestMaps code ( http://modestmaps.com/index.html )
//  https://github.com/RandomEtc/modestmaps-of
//
#include "Map.h"
#include "OpenStreetMapProvider.h"

//  Our happy dataBase
//
#include "MpiData.h"

#include "DragRect.h"

class testApp : public ofxiPhoneApp{
public:
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    //  Compass and GPS
    //
    ofxiPhoneCoreLocation * coreLocation;
    float   heading;
    bool    hasCompass;
    bool    hasGPS;
    
    //  Map
    //
    Map         map;
    vector <ofPoint> citiesPos;
    Location    myLoc;
    ofPoint     myPos;
    
    float       angle;
    float       apperture;
    float       distance;
    ofPolyline  areaZone;
    
    //  MPI API
    //
    MpiData     dBase;
    DragRect    graphView;
    
    float       TotalND;
    float       TotalHS;
    float       TotalBA;
    
    int         TotalPop;
    int         TotalBlack;
    int         TotalAsian;
    int         TotalLatino;
    
    int         closerWellcomeCityIndex;
};


