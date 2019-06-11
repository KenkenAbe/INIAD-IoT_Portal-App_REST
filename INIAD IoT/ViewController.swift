//
//  ViewController.swift
//  INIAD IoT
//
//  Created by Kentaro on 2019/05/21.
//  Copyright © 2019 Kentaro. All rights reserved.
//

import UIKit
import Alamofire
import KeychainAccess
import SwiftyJSON

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var config = AppConfiguration()
    var keyStore:Keychain!
    var iniad_api_authkey = ""
    var room_categories = [String]()
    var rooms = [String:[[String]]]()

    @IBOutlet weak var room_table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let room_categories = config.getRoomCategory()
        self.room_categories = room_categories
        
        var j_rooms = config.getRooms()
        //print(rooms)
        for category in room_categories{
            self.rooms[category] = [[String]]()
            for room in j_rooms[category]{
                var dict = room.1.dictionary!.first!
                print(dict)
                self.rooms[category]?.append([dict.key,dict.value.string!])
            }
        }
        //print(rooms)
        
        self.room_table.rowHeight = 90.0
        self.room_table.delegate = self
        self.room_table.dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        self.iniad_auth_initialize()
    }
    
    func iniad_auth_initialize(){
        if let keychainIdentifier = config.getValue(key: "keychain_identifier"){
            keyStore = Keychain.init(service: keychainIdentifier)
        }else{
            //環境変数にキーチェーンのidentifierが存在しない場合はアプリを強制終了させる
            assert(false,"Could not configure Keychain Store, Please check your Environment Variable File.")
        }
        
        if let iniad_api_authkey = keyStore["iniad_api_authkey"]{
            self.iniad_api_authkey = iniad_api_authkey
            let test_configuration_url = URL(string:"\(self.config.getValue(key: "iniad_api_url")!)/api/v1/iccards")!
            
            var header = HTTPHeaders()
            header["Authorization"] = "Basic \(iniad_api_authkey)"
            Alamofire.request(test_configuration_url,headers:header).responseJSON{ response in
                guard let status_code = response.response?.statusCode else{
                    return
                }
                
                let alert = UIAlertController(title: "エラー", message: "", preferredStyle: .alert)
                switch status_code{
                case 200:
                    return
                case 404:
                    return
                case 401:
                    alert.message = "INIADアカウントを再設定してください"
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                        try? self.keyStore.remove("iniad_api_authkey")
                        self.iniad_auth_initialize()
                    }))
                    self.present(alert, animated: true, completion: nil)
                case 503:
                    alert.message = "本アプリはINIAD LAN内でのみ利用できます\nアプリを終了します"
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                        exit(0)
                    }))
                    self.present(alert, animated: true, completion: nil)
                default:break
                }
            }
        }else{
            //TODO:INIADアカウントのIDとパスワードを入力させる処理
            NSLog("This device has not any Authenticate Information for INIAD System")
            
//            var isConfigured = false
            
            var raw_passphrase = ""
            var b64encoded_passphrase = ""
            let alert = UIAlertController(title: "INIAD IDとパスワードを設定してください", message: "IDとパスワードは端末内にのみ保存され、INIAD APIを操作するとき以外に使用はしません", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                text.placeholder = "INIAD ID"
                text.tag = 0
            })
            
            alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                text.placeholder = "Password"
                text.tag = 1
                text.isSecureTextEntry = true
            })
            
            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: {action in
                guard let textFields = alert.textFields else {
                    return
                }
                var iniad_id:String?
                var iniad_pw:String?
                
                for i in textFields{
                    if i.tag == 0{
                        iniad_id = i.text
                    }else{
                        iniad_pw = i.text
                    }
                }
                
                do{
                    raw_passphrase = "\(iniad_id!):\(iniad_pw!)"
                    let pass_data = raw_passphrase.data(using: .utf8)
                    if let str = pass_data?.base64EncodedString(){
                        b64encoded_passphrase = str
                    }else{
                        return
                    }
                }
                
                let url = URL(string: "\(self.config.getValue(key: "iniad_api_url")!)/api/v1/iccards")!
                var auth_header = HTTPHeaders()
                auth_header["Authorization"] = "Basic \(b64encoded_passphrase)"
                //NSLog(auth_header["Authorization"]!)
                
                Alamofire.request(url, method: .get, headers: auth_header).responseJSON{response in
                    if let statusCode = response.response?.statusCode{
                        let error_alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                        error_alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                            self.iniad_auth_initialize()
                        }))
                        
                        switch statusCode{
                        case 200,404:
                            self.keyStore["iniad_api_authkey"] = b64encoded_passphrase
                            let js_data = JSON.init(response.result.value!)
                            //print(js_data)
//                            isConfigured = true
                            break
                        case 403:
                            NSLog("Invalid ID or Password")
                            error_alert.title = "Permission denied"
                            error_alert.message = "INIAD IDまたはパスワードが違います"
                            self.present(error_alert, animated: true, completion: nil)
                        case 503:
                            NSLog("Service Available only at INIAD LAN")
                            error_alert.title = "Error"
                            error_alert.message = "初回操作はINIAD LAN内で行ってください"
                            self.present(error_alert, animated: true, completion: nil)
                        default:break
                        }
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
                exit(0)
            }))
            
            /*repeat {
             
             } while isConfigured == false*/
            self.present(alert, animated: true, completion: nil)
            
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return room_categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms[room_categories[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return config.vocabulary(key: room_categories[section])!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let room_obj = rooms[room_categories[indexPath.section]]![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "room_cell") as! roomCell
        
        cell.room_name.text = room_obj[0]
        cell.room_other_name.text = room_obj[1]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let room_obj = rooms[room_categories[indexPath.section]]![indexPath.row]
        
        let nextView = storyboard!.instantiateViewController(withIdentifier: "room_controller") as! RoomController
        nextView.room_num = room_obj[0]
        nextView.room_subname = room_obj[1]
        
        self.present(nextView, animated: true, completion: nil)
    }
}

