//
//  AppConfiguration.swift
//  INIAD IoT
//
//  Created by Kentaro on 2019/05/21.
//  Copyright © 2019 Kentaro. All rights reserved.
//

import Foundation
import SwiftyJSON

class AppConfiguration{
    private var rawDict:JSON!
    private var vocabDict:JSON!
    
    init(){
        let path = Bundle.main.path(forResource: "env", ofType: "json")
        if let path = path{
            do{
                let jsonStr = try String(contentsOfFile: path)
                
                let json = JSON(parseJSON: jsonStr)
                print(json)
                
                rawDict = json
                #if INIADIoT
                vocabDict = rawDict["production"]["vocabularies"]
                #else
                vocabDict = rawDict["development"]["vocabularies"]
                #endif
                
            } catch {
                assert(false,"Could not find or Failed parse Env JSON File")
            }
        }else{
            assert(false,"Could not find Env JSON File")
        }
        
        
    }
    
    func getValue(key:String) -> String?{
        #if RELEASE
            return rawDict["production"][key].string
        #else
            return rawDict["development"][key].string
        #endif
    }
    
    func setValue(key:String,value:String){
        
    }
    
    func vocabulary(key:String) -> String?{
        return vocabDict[key].string
    }
    
    func getRoomCategory() -> [String]{
        var js_array:[JSON]!
        #if RELEASE
        //return rawDict["production"][key].string
        js_array = rawDict["production"]["room_order"].array
        #else
        //return rawDict["development"][key].string
        js_array = rawDict["development"]["room_order"].array
        #endif
        
        var room_array = [String]()
        for i in js_array{
            if let value = i.string{
                room_array.append(value)
            }
        }
        
        return room_array
    }
    
    func getRooms() -> JSON{
        
        #if RELEASE
        return rawDict["production"]["rooms"]
        #else
        return rawDict["development"]["rooms"]
        #endif
    }
}
