#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){	
	ofxAccelerometer.setup();
    ofEnableAlphaBlending();
    ofSetVerticalSync(true);
    ofEnableSmoothing();
    ofSetFullscreen(true);
	
    //  Compass & GPS
    //
	coreLocation = new ofxiPhoneCoreLocation();
	hasCompass = coreLocation->startHeading();
	hasGPS = coreLocation->startLocation();
	heading = 0.0;
	
	//If you want a landscape oreintation 
	//iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
	
    
    //  MPI API
    //
    dBase.loadCities("cities.csv");
    dBase.loadYear(2000, "2000.csv");
    dBase.loadYear(2005, "2005.csv");
    dBase.loadYear(2010, "2010.csv");
    
    //  Map
    //
    map.setup(new OpenStreetMapProvider(), (double)ofGetWidth(), (double)ofGetHeight());
	map.setZoom(5);
    
    //  Loads cities positions
    //
    for (int i = 0; i < dBase.getTotalCities(); i++){
        citiesPos.push_back( map.getLocation( dBase.getLatitud(i), dBase.getLongitud(i) ) );
    }
    
    angle   = 0;
    distance = 0;
    apperture = 30;
    
    ofPoint point = map.locationPoint(myLoc);
    areaZone.clear();
    areaZone.addVertex(point);
    areaZone.arc(point, distance, distance, angle-apperture*0.5, angle+apperture*0.5, true,60);
    areaZone.addVertex(point);
    
    graphView.init(10,10,301,142);
    graphView.bEditMode = false;

    TotalPop    = 0.0f;
    TotalBlack  = 0.0f;
    TotalAsian  = 0.0f;
    TotalLatino = 0.0f;
    TotalND     = 0.0f;
    TotalHS     = 0.0f;
    TotalBA     = 0.0f;
    
    closerWellcomeCityIndex = -1;
}

//--------------------------------------------------------------
void testApp::update(){
    //  Update Compass
    //
    myLoc = Location(coreLocation->getLatitude(),coreLocation->getLongitude());
    myPos = map.locationPoint(myLoc);
    
    map.setCenter(myLoc);
    heading = ofLerpDegrees(heading, coreLocation->getTrueHeading(), 0.7);
    angle = heading+90+180;
    float accY = ofxAccelerometer.getForce().y * -1.0f ;
    distance = ofLerp( distance, -(300.0f*ofMap(map.getZoom(),3,10,0.3,1.0,true)) * ((accY>0.0)?accY:0.0f), 0.1);
    
    areaZone.clear();
    areaZone.addVertex(myPos);
    areaZone.arc(myPos, distance, distance, angle-apperture*0.5, angle+apperture*0.5, true,60);
    areaZone.addVertex(myPos);
    
    //  Map
    //
	map.update();
    
    //  DataBase
    //
    int tmpPop = 0;
    int tmpBlack = 0;
    int tmpAsian = 0;
    int tmpLatino = 0;
    
    float tmpPctUnEmpND = 0.0f; // no degree
    float tmpPctUnEmpHS = 0.0f; // highschool
    float tmpPctUnEmpBA = 0.0f; // bachellor
    
    float closerWellcomeCityDist = 1000.f;
    for (int i = 0; i < citiesPos.size(); i++){
        
        //  Update City position
        //  ( this probably it's not need because the person it's not going to be moving so much )
        //
        citiesPos[i] = map.getLocation( dBase.getLatitud(i), dBase.getLongitud(i) );
        
        //  It's in the green zone?
        //
        if (areaZone.inside( citiesPos[i] )){
            
            tmpPop += dBase.getNumVal(MPI_NUM_POPULATION, i);
            
            tmpBlack += dBase.getNumVal(MPI_PCT_ETHNIC_BLACK, i);
            tmpAsian += dBase.getNumVal(MPI_PCT_ETHNIC_ASIAN, i);
            tmpLatino += dBase.getNumVal(MPI_PCT_ETHNIC_LATINO, i);
            
            tmpPctUnEmpND += dBase.getPctVal(MPI_PCT_UNEMPLOY_IMMIGRANTS_NO_DEGREE, i);
            tmpPctUnEmpHS += dBase.getPctVal(MPI_PCT_UNEMPLOY_IMMIGRANTS_HIGHSCHOOL_DEGREE , i);
            tmpPctUnEmpBA += dBase.getPctVal(MPI_PCT_UNEMPLOY_IMMIGRANTS_BA_DEGREE, i);
        }
        
        //  It's this city active recruting?
        //
        if ( dBase.getCityCategory(i) == MPI_CITY_ACTIVE_RECRUITING ){
            //  if so, ask if is the closest one
            //
            float dist = myPos.distance(citiesPos[i]);
            if ( dist <= closerWellcomeCityDist  ){
                closerWellcomeCityIndex = i;
                closerWellcomeCityDist = dist;
            }
        }
    }
    
    TotalPop = ofLerp(TotalPop, tmpPop, 0.1);
    TotalBlack  = ofLerp(TotalBlack, tmpBlack, 0.1);
    TotalAsian  = ofLerp(TotalAsian, tmpAsian, 0.1);
    TotalLatino = ofLerp(TotalLatino, tmpLatino, 0.1);
    
    TotalND     = ofLerp(TotalND, tmpPctUnEmpND, 0.1);
    TotalHS     = ofLerp(TotalHS, tmpPctUnEmpHS, 0.1);
    TotalBA     = ofLerp(TotalBA, tmpPctUnEmpBA, 0.1);
}

//--------------------------------------------------------------
void testApp::draw(){
    map.draw();
    
    ofPushStyle();
    
    //  Draw you position
    //
    ofSetColor(0,200,0);
    ofCircle( myPos, map.getZoom() );
    
    //  Draw arrow to the closes actively recruiting city
    //
    if ( closerWellcomeCityIndex != -1 ){
        ofPushStyle();
        
        ofSetLineWidth(2);
        ofPoint diff = citiesPos[ closerWellcomeCityIndex ] - myPos;
        float angleToCity = atan2(diff.y,diff.x);
        float radioToCity = 30;
        ofPoint arrowHead = myPos + ofPoint(radioToCity*cos(angleToCity),
                                            radioToCity*sin(angleToCity));
        
        ofSetColor(0,0,255, 50+100*abs(sin(ofGetElapsedTimef())));
        ofLine( myPos, arrowHead);
        
        ofPushMatrix();
        ofTranslate(arrowHead);
        ofRotate(ofRadToDeg(angleToCity)+90, 0, 0, 1.0);
        ofFill();
        
        ofBeginShape();
        ofVertex(0, 0);
        ofVertex(5, 10);
        ofVertex(-5, 10);
        ofEndShape();
        
        ofPopMatrix();
        
        ofPopStyle();
    }
    
    //  Draw pointing area zone
    //
    ofSetColor(0,200,0,100);
    ofBeginShape();
    for(int i = 0; i < areaZone.size(); i++){
        ofVertex(areaZone[i]);
    }
    ofEndShape();
    
    //  Draw cities position
    //
    for (int i = 0; i < citiesPos.size(); i++){
        
        if (areaZone.inside( citiesPos[i] )){
            ofSetColor(0,50,0,200);
            ofDrawBitmapString(dBase.getCity(i), citiesPos[i] + ofPoint(10,5));
            ofFill();
        } else {
            ofNoFill();
        }
        
        ofColor cityColor = ofColor(255,0,0);
        
        if ( dBase.getCityCategory(i) == MPI_CITY_ACTIVE_RECRUITING ){
            cityColor = ofColor(255*(1.0-abs(sin(ofGetElapsedTimef()))),0,255*abs(sin(ofGetElapsedTimef())));
        }
        
        ofSetColor(cityColor,100);
        ofCircle(citiesPos[i], map.getZoom() * 2);
        ofSetColor(cityColor,100);
        ofCircle(citiesPos[i], map.getZoom());
        
        ofFill();
        ofSetColor(cityColor,100);
        ofCircle(citiesPos[i], 2);
        
    }
    
    ofPushMatrix();

    float pct       = 0.5;
    float top       = 30;
    
    float PctBlack    = (float)TotalBlack/(float)TotalPop;
    ofRectangle black = graphView;
    black.width = graphView.width*pct;
    black.y = top;
    black.height = graphView.height * PctBlack;
    ofSetColor(0,200,0,200);
    ofRect(black);
    
    
    float PctLatino   = (float)TotalLatino/(float)TotalPop;
    ofRectangle latin = graphView;
    latin.width = graphView.width*pct;
    latin.y = black.y + black.height;
    latin.height = graphView.height * PctLatino;
    ofSetColor(0,150,0,200);
    ofRect(latin);
    
    
    
    float PctAsian    = (float)TotalAsian/(float)TotalPop;
    ofRectangle asian = graphView;
    asian.width = graphView.width*pct;
    asian.y = latin.y + latin.height;
    asian.height = graphView.height * PctAsian;
    ofSetColor(0,100,0,200);
    ofRect(asian);
    
    ofRectangle unEmpND = graphView;
    unEmpND.y = top;
    unEmpND.width = graphView.width*(1.0-pct);
    unEmpND.x += graphView.width*pct;
    unEmpND.height = graphView.height * (TotalND*0.01);
    ofSetColor(0,0,200,200);
    ofRect(unEmpND);
    ofSetColor(255);
    
    ofRectangle unEmpHS = graphView;
    unEmpHS.width = graphView.width*(1.0-pct);
    unEmpHS.x += graphView.width*pct;
    unEmpHS.y = unEmpND.y + unEmpND.height;
    unEmpHS.height = graphView.height * (TotalHS*0.01);
    ofSetColor(0,0,150,200);
    ofRect(unEmpHS);
    
    ofRectangle unEmpBA = graphView;
    unEmpBA.width = graphView.width*(1.0-pct);
    unEmpBA.x += graphView.width*pct;
    unEmpBA.y = unEmpHS.y + unEmpHS.height;
    unEmpBA.height = graphView.height * (TotalBA*0.01);
    ofSetColor(0,0,100,200);
    ofRect(unEmpBA);
    
    ofSetColor(0);
    ofDrawBitmapString("Community", 5, 15 );
    ofDrawBitmapString("Imm. Unemploy.", unEmpND.x+5, 15 );

    ofSetColor(255);
    ofDrawBitmapString(ofToString( (int)(PctBlack*100) )+ "% african a.", black.x+5, black.y+15);
    ofDrawBitmapString(ofToString( (int)(PctLatino*100) )+ "% latin", latin.x+5, latin.y+15);
    ofDrawBitmapString(ofToString( (int)(PctAsian*100) )+ "% asian", asian.x+5, asian.y+15);
    ofDrawBitmapString(ofToString( (int)(TotalND),0 )+ "% no deegre", unEmpND.x+5, unEmpND.y+15);
    ofDrawBitmapString(ofToString( (int)(TotalHS),0 )+ "% highschool", unEmpHS.x+5, unEmpHS.y+15);
    ofDrawBitmapString(ofToString( (int)(TotalBA),0 )+ "% BA", unEmpBA.x+5, unEmpBA.y+15);
    
    ofPopMatrix();
    
    ofPopStyle();
}

//--------------------------------------------------------------
void testApp::exit(){

}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
    map.setZoom(ofMap(touch.y, 0, ofGetHeight(), 3, 10));
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

