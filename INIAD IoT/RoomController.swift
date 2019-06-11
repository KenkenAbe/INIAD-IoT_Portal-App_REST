//
//  RoomController.swift
//  INIAD IoT
//
//  Created by Kentaro on 2019/05/23.
//  Copyright © 2019 Kentaro. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess

class RoomController:UIViewController{
    var room_num = "2416"
    var room_subname = "部室8"
    
    var config = AppConfiguration()
    var api_url = ""
    var keyStore:Keychain!
    
    var light_devices = [light]()
    var doorlock_devices = [doorlock]()
    var aircon_devices = [aircon]()
    
    @IBOutlet weak var room_num_text: UILabel!
    @IBOutlet weak var room_subname_text: UILabel!
    
    
    var current_rect:CGFloat = 0.0
    
    @IBOutlet weak var device_area: UIScrollView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.device_area.removeFromSuperview()
        self.room_num_text.text = self.room_num
        self.room_subname_text.text = self.room_subname
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.init_content()
    }
    
    func init_content(){
        if let url = config.getValue(key: "iniad_api_url"){
            self.api_url = url
        }
        
        if let keychain_identifier = config.getValue(key: "keychain_identifier"){
            self.keyStore = Keychain.init(service: keychain_identifier)
        }
        
        let iniad_api_authkey = self.keyStore["iniad_api_authkey"]!
        var api_req_header = HTTPHeaders()
        api_req_header["Authorization"] = "Basic \(iniad_api_authkey)"
        
        //電気錠のイニシャライズ
        let doorlock_queue = DispatchQueue(label: "doorlock")
        
        doorlock_queue.sync {
            let doorlock_list_url = URL(string:"\(self.api_url)/api/v1/doorlocks/\(self.room_num)")!
            var is_doorlock_initialized = false
            Alamofire.request(doorlock_list_url, method: .get, headers: api_req_header).responseJSON{response in
                if let value = response.result.value{
                    if response.response?.statusCode != 200{
                        is_doorlock_initialized = true
                    }else{
                        let doorlocks_list = JSON.init(value)
                        var item_num = 1
                        for doorlock_url in doorlocks_list{
                            Thread.sleep(forTimeInterval: 0.3)
                            ////print(doorlock_url.1.string!)
                            let new_rect = CGRect(x: 0.0, y: self.current_rect, width: self.view.frame.width, height: 110.0)
                            let device = doorlock.init(frame: new_rect, room_num: self.room_num, api_url: doorlock_url.1.string!, api_key: iniad_api_authkey)
                            device.item_num = String(describing: item_num)
                            device.restorationIdentifier = "\(self.room_num)_doorlocks_\(String(describing:item_num))"
                            self.doorlock_devices.append(device)
                            item_num += 1
                            self.current_rect += 110.0
                            self.device_area.contentSize.height += 110.0
                        }
                        
                        for device in self.doorlock_devices{
                            self.device_area.addSubview(device)
                        }
                        
                        is_doorlock_initialized = true
                    }
                }else{
                    is_doorlock_initialized = true
                }
            }
        }
        
        /*let await_doorlock_init = RunLoop.current
         while is_doorlock_initialized == false && await_doorlock_init.run(mode: .default, before: Date.init(timeIntervalSinceNow: 0.1)){
         NSLog("電気錠のイニシャライズ中・・・")
         }*/
        
        Thread.sleep(forTimeInterval: 1.0)
        
        //照明のイニシャライズ
        let light_queue = DispatchQueue.init(label: "light")
        
        light_queue.sync {
            let light_list_url = URL(string:"\(self.api_url)/api/v1/lights/\(self.room_num)")!
            var is_light_initialized = false
            Alamofire.request(light_list_url, method: .get, headers: api_req_header).responseJSON{response in
                if let value = response.result.value{
                    if response.response?.statusCode != 200{
                        is_light_initialized = true
                    }else{
                        let lights_list = JSON.init(value)
                        var item_num = 1
                        for light_url in lights_list{
                            Thread.sleep(forTimeInterval: 0.3)
                            let new_rect = CGRect(x: 0.0, y: self.current_rect, width: self.view.frame.width, height: 110.0)
                            let device = light.init(frame: new_rect, room_num: self.room_num, api_url: light_url.1.string!, api_key: iniad_api_authkey)
                            device.item_num = String(describing: item_num)
                            device.restorationIdentifier = "\(self.room_num)_light_\(String(describing:item_num))"
                            self.light_devices.append(device)
                            item_num += 1
                            self.current_rect += 110.0
                            self.device_area.contentSize.height += 110.0
                        }
                        
                        for device in self.light_devices{
                            self.device_area.addSubview(device)
                        }
                        
                        is_light_initialized = true
                    }
                }else{
                    is_light_initialized = true
                }
            }
    }
        
        /*let await_light_init = RunLoop.current
         while is_light_initialized == false && await_light_init.run(mode: .default, before: Date.init(timeIntervalSinceNow: 0.1)){
         NSLog("照明のイニシャライズ中・・・")
         }*/
        
        Thread.sleep(forTimeInterval: 1.0)
        
        //空調のイニシャライズ
        let aircon_queue = DispatchQueue.init(label: "aircon")
        aircon_queue.sync {
            let aircon_list_url = URL(string: "\(self.api_url)/api/v1/aircons/\(self.room_num)")!
            var is_aircon_initialized = false
            Alamofire.request(aircon_list_url,method:.get,headers:api_req_header).responseJSON{ response in
                guard let status_code = response.response?.statusCode else{
                    is_aircon_initialized = true
                    return
                }
                
                if status_code != 200{
                    return
                }
                
                if let value = response.result.value{
                    let aircons_list = JSON(value)
                    var item_num = 1
                    for aircon_url in aircons_list{
                        Thread.sleep(forTimeInterval: 0.3)
                        let new_rect = CGRect(x: 0.0, y: self.current_rect, width: self.view.frame.width, height: 330.0)
                        let device = aircon.init(frame: new_rect, room_num: self.room_num, api_url: aircon_url.1.string!, api_key: iniad_api_authkey)
                        device.item_num = String(describing: item_num)
                        device.restorationIdentifier = "\(self.room_num)_aircon_\(String(describing:item_num))"
                        self.aircon_devices.append(device)
                        
                        item_num += 1
                        self.current_rect += 330.0
                        self.device_area.contentSize.height += 330.0
                    }
                    
                    for device in self.aircon_devices{
                        self.device_area.addSubview(device)
                    }
                    
                    is_aircon_initialized = true
                }
            }
        }
        
        /*let await_aircon_init = RunLoop.current
         while is_aircon_initialized == false && await_aircon_init.run(mode: .default, before: Date.init(timeIntervalSinceNow: 0.1)){
         NSLog("空調のイニシャライズ中・・・")
         }*/
        Thread.sleep(forTimeInterval: 1.0)
        
        //センサーのイニシャライズ
        let sensor_queue = DispatchQueue.init(label: "sensor")
        sensor_queue.sync {
            let url = "\(self.api_url)/api/v1/sensors/\(self.room_num)"
            Alamofire.request(url, method: .get, headers: api_req_header).responseJSON{ response in
                guard let status_code = response.response?.statusCode else{
                    return
                }
                
                if status_code != 200{
                    return
                }
                
                let new_rect = CGRect(x: 0.0, y: self.current_rect, width: self.view.frame.width, height: 200.0)
                let device = sensor.init(frame: new_rect, room_num: self.room_num, api_url: url, api_key: iniad_api_authkey, init_data: JSON(response.result.value!))
                self.device_area.addSubview(device)
                self.device_area.contentSize.height += 200.0
            }
        }
    }
    
    
    @IBAction func renew_button(_ sender: Any) {
        let alert = UIAlertController(title: "更新中", message: "しばらくお待ち下さい", preferredStyle: .alert)
        
        self.present(alert, animated: true, completion: {
            //print(self.device_area.subviews)
            for device_view in self.device_area.subviews{
                //print(device_view)
                
                if let device = device_view as? doorlock{
                    device.renew_status(response: nil)
                    Thread.sleep(forTimeInterval: 0.5)
                }else if let device = device_view as? light{
                    device.renew_status(response: nil)
                    Thread.sleep(forTimeInterval: 0.5)
                }else if let device = device_view as? aircon{
                    device.renew_status(response: nil)
                    Thread.sleep(forTimeInterval: 0.5)
                }else if let device = device_view as? sensor{
                    device.renew_status(response: nil)
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
            
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
