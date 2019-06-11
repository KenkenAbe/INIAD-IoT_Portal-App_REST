//
//  DeviceClasses.swift
//  INIAD IoT
//
//  Created by Kentaro on 2019/05/23.
//  Copyright © 2019 Kentaro. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import KeychainAccess

class doorlock:UIView{
    public var api_path:String?
    public var room_num:String?
    public var item_num:String?
    public var locked = true
    public var open = false

    private var api_key:String?
    private var api_url:String?
    
    @IBOutlet weak var lock_switch: UISwitch!
    @IBOutlet weak var item_name: UILabel!
    @IBOutlet weak var process_indicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    init(frame:CGRect,room_num:String,api_url:String,api_key:String){
        super.init(frame: frame)
        
        self.room_num = room_num
        
        self.api_key = api_key
        self.api_url = api_url
        
        var header = HTTPHeaders()
        header["Authorization"] = "Basic \(api_key)"
//        var isWait = true
        Alamofire.request(URL(string:api_url)!,method: .get,headers:header).responseJSON{ response in
            if let statusCode = response.response?.statusCode{
                if statusCode != 200{
//                    isWait = false
                }else{
                    
                    let js_data = JSON.init(response.result.value!)
                    //print(js_data)
                    
                    switch js_data["locked"].stringValue{
                    case nil:
                        break
                    case "true":
                        self.locked = true
                    case "false":
                        self.locked = false
                    default:break
                    }
                    
                    if let view = Bundle.main.loadNibNamed("doorlock", owner: self, options: nil)!.first as? doorlock{
                        view.frame = self.bounds
                        
                        view.room_num = self.room_num
                        view.item_num = self.item_num
                        view.api_key = self.api_key
                        view.api_url = self.api_url
                        view.lock_switch.setOn(self.locked, animated: false)
                        self.addSubview(view)
                    }
                    
//                    isWait = false
                }
            }else{
                //return
//                isWait = false
            }
        }
        
        /*let loop = RunLoop.current
        while isWait && loop.run(mode: .default, before: Date.init(timeIntervalSinceNow: 0.1)){
            NSLog("電気錠の情報を取得中・・・")
        }*/
    }
    
    func renew_status(response:JSON?){
        if let response = response{
            //既に通信が終了していて、表示させるのみの場合
            switch response["locked"].bool{
            case nil:
                break
            case true:
                self.locked = true
            case false:
                self.locked = false
            default:break
            }
            
            //self.lock_switch.setOn(self.locked, animated: true)
            for i in self.subviews{
                //print(i)
                if let lock_switch = i as? UISwitch{
                    lock_switch.setOn(self.locked, animated: true)
                }else if let indicator = i as? UIActivityIndicatorView{
                    indicator.stopAnimating()
                }
            }
        }else{
            var header = HTTPHeaders()
            header["Authorization"] = "Basic \(self.api_key!)"
            
            Alamofire.request(URL(string:self.api_url!)!, method: .get, parameters: nil, headers: header).responseJSON{response_data in
                if let value = response_data.result.value{
                    if response_data.response?.statusCode == 200{
                        let json_obj = JSON(value)
                        self.renew_status(response: json_obj)
                    }
                }
            }
            
        }
    }
    
    @IBAction func tapped_lock_switch(_ sender: Any) {
        change_lock_status(status: self.lock_switch.isOn)
    }
    
    override func layoutSubviews() {
        for i in self.subviews{
            switch i.restorationIdentifier{
            case "process_indicator":
                guard let layer = i as? UIActivityIndicatorView else{
                    break
                }
                
                layer.hidesWhenStopped = true
                break
            case "item_name":
                guard let layer = i as? UILabel else{
                    break
                }
                
                layer.text = "電気錠 \(self.item_num!)"
            default:break
            }
        }
    }
    
    func change_lock_status(status:Bool){
        for i in self.subviews{
            if i.restorationIdentifier != "process_indicator"{
                continue
            }
            
            guard let layer = i as? UIActivityIndicatorView else{
                continue
            }
            
            layer.startAnimating()
            break
        }
        
        var header = HTTPHeaders()
        header["Authorization"] = "Basic \(self.api_key!)"
        
        var values = Parameters()
        values["locked"] = String(describing: status)
        
        Alamofire.request(self.api_url!, method: .put, parameters: values, headers: header).responseJSON{ response in
            if let value = response.result.value{
                let response_json = JSON(value)
                //print(response_json)
                self.renew_status(response:response_json)
            }
        }
    }
    
}

class light:UIView{
    var room_num:String?
    var item_num:String?
    var api_path:String?
    var mode:String?
    var mode_range = [[String:String]]()
    
    private var api_key:String?
    private var api_url:String?
    
    @IBOutlet weak var light_status:UISegmentedControl!
    @IBOutlet weak var item_name: UILabel!
    @IBOutlet weak var process_indicator: UIActivityIndicatorView!
    
    
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    init(frame:CGRect,room_num:String,api_url:String,api_key:String){
        super.init(frame: frame)
        
        self.room_num = room_num
        
        self.api_key = api_key
        self.api_url = api_url
        
//        var isWait = true
        
        let config = AppConfiguration()
        
        var header = HTTPHeaders()
        header["Authorization"] = "Basic \(self.api_key!)"
        Alamofire.request(URL(string:self.api_url!)!,headers:header).responseJSON{ response in
            if let statusCode = response.response?.statusCode{
                if statusCode != 200{
//                    isWait = false
                }else{
                    
                    self.room_num = room_num
                    
                    let js_data = JSON.init(response.result.value!)
                    //print(js_data)
                    
                    if let view = Bundle.main.loadNibNamed("light", owner: self, options: nil)!.first as? light{
                        view.frame = self.bounds
                        
                        view.room_num = self.room_num
                        view.item_num = self.item_num
                        view.api_key = self.api_key
                        view.api_path = self.api_path
                        view.api_url = self.api_url
                        view.mode = js_data["mode"].string
                        var mode_num = 0
                        for mode in js_data["modes"]{
                            guard let mode = mode.1.string else{
                                continue
                            }
                            
                            if let ja_mode_name = config.vocabulary(key: mode){
                                self.mode_range.append([mode:ja_mode_name])
                            }else{
                                continue
                            }
                        }
                        
                        view.mode_range = self.mode_range
                        
                        self.addSubview(view)
                    }
                    
                    self.mode = js_data["mode"].string
                    
//                    isWait = false
                }
            }else{
//                isWait = false
                //return
            }
        }
        
        /*let loop = RunLoop.current
        while isWait && loop.run(mode: .default, before: Date.init(timeIntervalSinceNow: 0.1)){
            NSLog("照明の情報を取得中・・・")
        }*/
    }
    
    override func layoutSubviews() {
        for obj in self.subviews{
            if let obj = obj as? light{
                for layer in obj.subviews{
                    if let mode_segment = layer as? UISegmentedControl{
                        mode_segment.removeAllSegments()
                        //print(self.isUserInteractionEnabled)
                        
                        var mode_index = 0
                        for i in self.mode_range{
                            mode_segment.insertSegment(withTitle: i.first!.value, at: mode_index, animated: true)
                            
                            if self.mode == i.first!.key{
                                mode_segment.selectedSegmentIndex = mode_index
                            }
                            
                            mode_index += 1
                        }
                        continue
                    }else if layer.restorationIdentifier == "process_indicator"{
                        guard let layer = layer as? UIActivityIndicatorView else{
                            continue
                        }
                        
                        layer.hidesWhenStopped = true
                    }else if layer.restorationIdentifier == "item_name"{
                        guard let layer = layer as? UILabel else{continue}
                        layer.text = "照明 \(self.item_num!)"
                    }
                }
            }
        }
    }
    
    @IBAction func value_changed(_ sender: Any) {
        if let sender = sender as? UISegmentedControl{
            var headers = HTTPHeaders()
            var values = Parameters()
            
            headers["Authorization"] = "Basic \(self.api_key!)"
            values["mode"] = self.mode_range[sender.selectedSegmentIndex].first!.key
            
            for i in self.subviews{
                if i.restorationIdentifier != "process_indicator"{
                    continue
                }
                
                guard let layer = i as? UIActivityIndicatorView else{
                    continue
                }
                
                layer.startAnimating()
                break
            }
            
            Alamofire.request(URL(string:self.api_url!)!, method: .put, parameters: values, headers: headers).responseJSON{response in
                if let status = response.response?.statusCode{
                    if status == 200{
                        let js_dict = JSON(response.result.value!)
                        self.renew_status(response: js_dict)
                    }
                }
            }
        }
    }
    
    func renew_status(response:JSON?){
        if let response = response{
            //既に通信が終了していて、表示させるのみの場合
            var index = 0
            for i in mode_range{
                if i.first!.value != response["mode"].string{
                    index += 1
                }else{
                    break
                }
            }
            search:for i in self.subviews{
                if let layer = i as? light{
                    for obj in layer.subviews{
                        if let mode_switch = obj as? UISegmentedControl{
                            //UI更新処理
                            mode_switch.selectedSegmentIndex = index
                            break search
                        }
                    }
                }
            }
            
            for i in self.subviews{
                if i.restorationIdentifier != "process_indicator"{
                    continue
                }
                
                guard let layer = i as? UIActivityIndicatorView else{
                    continue
                }
                
                layer.stopAnimating()
                break
            }
            
        }else{
            var header = HTTPHeaders()
            header["Authorization"] = "Basic \(self.api_key!)"
            
            Alamofire.request(URL(string:self.api_url!)!, method: .get, headers: header).responseJSON{ response in
                if let status_code = response.response?.statusCode{
                    if status_code == 200{
                        let json_obj = JSON(response.result.value!)
                        self.renew_status(response: json_obj)
                    }
                        
                }
            }
        }
        
    }
    
}

class aircon:UIView{
    public var api_path:String?
    public var room_num:String?
    public var item_num:String?
    
    private var api_key:String?
    private var api_url:String?
    
    var mode_range:[[String:String]]?
    var temperature_range:[Float]?
    var humidity_range:[Float]?
    var wind_range:[[String:String]]?
    
    var temperature:Float?
    var wind:String?
    var mode:String?
    var on:Bool?
    var model_type:String?
    var allow_freshup = false
    
    @IBOutlet weak var on_switch: UISwitch!
    @IBOutlet weak var mode_switch: UISegmentedControl!
    @IBOutlet weak var wind_switch: UISegmentedControl!
    @IBOutlet weak var freshup_switch: UISwitch!
    @IBOutlet weak var temperature_text: UILabel!
    @IBOutlet weak var temperature_bar: UISlider!
    
    @IBOutlet weak var item_name: UILabel!
    @IBOutlet weak var process_indicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    init(frame:CGRect,room_num:String,api_url:String,api_key:String){
        super.init(frame: frame)
        
        self.room_num = room_num
        
        self.api_url = api_url
        self.api_key = api_key
        
        let config = AppConfiguration()
        
        var headers = HTTPHeaders()
        headers["Authorization"] = "Basic \(api_key)"
        Alamofire.request(api_url, method: .get, headers: headers).responseJSON{ response in
            if let value = response.result.value{
                if response.response!.statusCode != 200{
                    //通信が異常終了した場合の処理
                }else{
                    //通信が正常終了した場合の処理（この時点ではAPIからのレスポンスが返却されている）
                    let json_dict = JSON.init(value)
                    
                    //空調の種類
                    self.model_type = json_dict["model_type"].string
                    
                    if let on = json_dict["on"].bool{
                        self.on = on
                    }
                    
                    //動作モード
                    if let mode_range = json_dict["modes"].array{
                        self.mode_range = [[String:String]]()
                        for i in mode_range{
                            //Envファイルから日本語表記を検索し、存在した場合は操作可能なモードとして追加
                            if let ja_mode_name = config.vocabulary(key: i.string!){
                                self.mode_range!.append([i.string!:ja_mode_name])
                            }
                        }
                    }
                    if let mode = json_dict["mode"].string{
                        self.mode = mode
                    }
                    
                    //温度の設定
                    //self.temperature_bar.isContinuous = false
                    if let temperature_range = json_dict["temperature_range"].array{
                        self.temperature_range = [Float]()
                        for temperature in temperature_range{
                            self.temperature_range!.append(temperature.float!)
                        }
                        //self.temperature_bar.maximumValue = self.temperature_range!.first!
                    }
                    
                    if let temperature = json_dict["temperature"].float{
                        self.temperature = temperature
                    }
                    
                    //風量
                    if let wind_modes = json_dict["winds"].array{
                        self.wind_range = [[String:String]]()
                        for wind_mode in wind_modes{
                            //Envファイルから日本語表記を検索し、存在した場合は操作可能な風量として追加
                            if let ja_wind_mode_name = config.vocabulary(key: wind_mode.string!){
                                self.wind_range!.append([wind_mode.string!:ja_wind_mode_name])
                            }
                            
                            if wind_mode.string!.split(separator: "_").count > 1{
                                self.allow_freshup = true
                            }
                        }
                    }
                    
                    if let wind = json_dict["wind"].string{
                        self.wind = wind
                    }
                    
                    if let view = Bundle.main.loadNibNamed("aircon", owner: self, options: nil)!.first as? aircon{
                        view.frame = self.bounds
                        
                        view.room_num = self.room_num
                        view.item_num = self.item_num
                        view.api_key = self.api_key
                        view.api_url = self.api_url
                        
                        view.model_type = self.model_type
                        view.mode_range = self.mode_range
                        view.mode = self.mode
                        view.wind_range = self.wind_range
                        view.wind = self.wind
                        view.temperature_range = self.temperature_range
                        view.temperature = self.temperature
                        view.allow_freshup = self.allow_freshup
                        
                        self.addSubview(view)
                    }
                }
            }
        }
        
    }
    
    override func layoutSubviews() {
        //UIの更新処理
        for obj in self.subviews{
            if let base = obj as? aircon{
                for layer in base.subviews{
                    switch layer.restorationIdentifier{
                    case "process_indicator":
                        guard let indicator = layer as? UIActivityIndicatorView else{
                            break
                        }
                        
                        indicator.hidesWhenStopped = true
                    case "on_switch":
                        //動作スイッチ
                        guard let on_switch = layer as? UISwitch else{
                           break
                        }
                        if let on = self.on{
                            on_switch.setOn(on, animated: true)
                        }
                        break
                    case "mode_switch":
                        //動作モード
                        guard let mode_switch = layer as? UISegmentedControl else{
                            break
                        }
                        mode_switch.removeAllSegments()
                        
                        guard let mode_range = self.mode_range else{
                            mode_switch.isEnabled = false
                            break
                        }
                        var index = 0
                        for mode in mode_range{
                            mode_switch.insertSegment(withTitle: mode.first!.value, at: index, animated: true)
                            if self.mode == mode.first!.key{
                                mode_switch.selectedSegmentIndex = index
                            }
                            index += 1
                        }
                        
                        break
                    case "wind_switch":
                        //風量
                        guard let wind_switch = layer as? UISegmentedControl else{
                            break
                        }
                        wind_switch.removeAllSegments()
                        
                        guard let wind_range = self.wind_range else{
                            break
                        }
                        
                        guard var current_wind = self.wind else{
                            break
                        }
                        
                        let wind_splited = current_wind.split(separator: "_")
                        current_wind = String(describing: wind_splited[0])
                        
                        var index = 0
                        for wind in wind_range{
                            wind_switch.insertSegment(withTitle: wind.first!.value, at: index, animated: true)
                            if current_wind == wind.first!.key{
                                wind_switch.selectedSegmentIndex = index
                            }
                            index += 1
                        }
                        
                        break
                    case "freshup_switch":
                        //フレッシュアップ
                        //TODO:部室の値を確認してフレッシュアップの検知を確認する
                        guard let freshup_switch = layer as? UISwitch else{
                            break
                        }
                        
                        if allow_freshup == false{
                            freshup_switch.setOn(false, animated: true)
                            freshup_switch.isEnabled = false
                            freshup_switch.alpha = 0.5
                            
                            break
                        }
                        
                        guard let wind = self.wind else{
                            break
                        }
                        
                        let wind_splited = wind.split(separator: "_")
                        if wind_splited.count > 1{
                            freshup_switch.setOn(true, animated: true)
                        }else{
                            freshup_switch.setOn(false, animated: true)
                        }
                        
                        break
                    case "temperature_bar":
                        //温度設定
                        guard let temperature_bar = layer as? UISlider else{
                            break
                        }
                        
                        guard let temperature_range = self.temperature_range else{
                            break
                        }

                        temperature_bar.minimumValue = temperature_range[0]
                        temperature_bar.maximumValue = temperature_range[1]
                        
                        if let temperature = self.temperature{
                            temperature_bar.setValue(temperature, animated: true)
                        }
                        
                        
                        break
                    case "temp_text":
                        //温度設定（文字）
                        guard let temperature_text = layer as? UILabel else{
                            break
                        }
                        
                        if let temperature = self.temperature{
                            temperature_text.text = "\(Int(floorf(temperature))) ℃"
                        }else{
                            temperature_text.text = "温度操作不可"
                            temperature_text.alpha = 0.5
                        }
                        
                        break
                    case "item_name":
                        //デバイス名
                        guard let item_name = layer as? UILabel else{break}
                        item_name.text = "空調 \(self.item_num!)（\(self.model_type!)）"
                    default:break
                    }
                }
            }
        }
    }
    
    func renew_status(response:JSON?){
        if let response = response{
            //print(response)
            self.temperature = response["temperature"].float
            self.mode = response["mode"].string
            self.wind = response["wind"].string
            
            if let on = response["on"].bool{
                self.on = on
                
                for obj in self.subviews{
                    guard let base_layer = obj as? aircon else{
                        continue
                    }
                    
                    for layer in base_layer.subviews{
                        if layer.restorationIdentifier != "on_switch"{
                            continue
                        }
                        
                        guard let layer = layer as? UISwitch else{
                            continue
                        }
                        
                        layer.setOn(on, animated: true)
                        break
                    }
                    break
                }
            }
            
            mode_check:if let mode = response["mode"].string{
                var mode_index = 0
                guard let mode_range = self.mode_range else{
                    break mode_check
                }
                
                for i in mode_range{
                    if i.first!.key != mode{
                        mode_index += 1
                    }else{
                        break
                    }
                }
                
                for obj in self.subviews{
                    guard let base_layer = obj as? aircon else{
                        continue
                    }
                    
                    for layer in base_layer.subviews{
                        if layer.restorationIdentifier != "mode_switch"{
                            continue
                        }
                        
                        guard let layer = layer as? UISegmentedControl else{
                            break
                        }
                        
                        layer.selectedSegmentIndex = mode_index
                        break
                    }
                    break
                }
            }
            
            temperature_check:if let temperature = response["temperature"].float{
                for obj in self.subviews{
                    guard let base_layer = obj as? aircon else{
                        continue
                    }
                    
                    for layer in base_layer.subviews{
                        if layer.restorationIdentifier == "temp_text"{
                            guard let layer = layer as? UILabel else{
                                break
                            }
                            
                            layer.text = "\(Int(floorf(temperature))) ℃"
                        }else if layer.restorationIdentifier == "temperature_bar"{
                            guard let layer = layer as? UISlider else{
                                break
                            }
                            
                            layer.setValue(floorf(temperature), animated: true)
                        }
                    }
                    break
                }
            }
            
            wind_check:if var wind = response["wind"].string{
                var is_freshup = false
                
                var wind_index = 0
                guard let wind_range = self.wind_range else{
                    break wind_check
                }
                
                //フレッシュアップを示す文字列が存在するか
                let split_command = wind.split(separator: "_")
                if split_command.count >= 2{
                    wind = String(describing: split_command[0])
                    is_freshup = true
                }
                
                for i in wind_range{
                    
                    if i.first!.key != wind{
                        wind_index += 1
                    }else{
                        break
                    }
                }
                
                for obj in self.subviews{
                    guard let base_layer = obj as? aircon else{
                        continue
                    }
                    
                    for layer in base_layer.subviews{
                        if layer.restorationIdentifier == "wind_switch"{
                            guard let layer = layer as? UISegmentedControl else{
                                continue
                            }
                            
                            layer.selectedSegmentIndex = wind_index
                            continue
                        }else if layer.restorationIdentifier == "freshup_switch"{
                            guard let layer = layer as? UISwitch else{
                                continue
                            }
                            
                            layer.setOn(is_freshup, animated: true)
                        }
                    }
                    break
                }
            }
            
            for i in self.subviews{
                if i.restorationIdentifier != "process_indicator"{
                    continue
                }
                
                guard let layer = i as? UIActivityIndicatorView else{
                    continue
                }
                
                layer.stopAnimating()
                break
            }
            
        }else{
            //状態を通信で取得する
            var headers = HTTPHeaders()
            headers["Authorization"] = "Basic \(self.api_key!)"
            
            Alamofire.request(URL(string:self.api_url!)!, method: .get, headers: headers).responseJSON{ response in
                guard let status_code = response.response?.statusCode else{
                    return
                }
                
                if status_code != 200{
                    return
                }else{
                    guard let response_data = response.result.value else{
                        return
                    }
                    
                    self.renew_status(response: JSON(response_data))
                }
            }
        }
    }
    
    func change_status(parameters:Parameters){
        var headers = HTTPHeaders()
        headers["Authorization"] = "Basic \(self.api_key!)"
        
        for i in self.subviews{
            if i.restorationIdentifier != "process_indicator"{
                continue
            }
            
            guard let layer = i as? UIActivityIndicatorView else{
                continue
            }
            
            layer.startAnimating()
            break
        }
        
        Alamofire.request(URL(string:self.api_url!)!, method: .put, parameters: parameters, headers: headers).responseJSON{response in
            guard let status_code = response.response?.statusCode else{
                return
            }
            
            if status_code != 200{
                return
            }else{
                guard let response_data = response.result.value else{
                    return
                }
                
                self.renew_status(response: JSON(response_data))
            }
            
        }
    }
    
    
    @IBAction func set_on(_ sender: Any) {
        //動作のオンオフ
        guard let sender = sender as? UISwitch else{
            return
        }
        
        var parameters = Parameters()
        parameters["on"] = String(describing:sender.isOn)
        
        self.change_status(parameters: parameters)
    }
    
    @IBAction func set_mode(_ sender: Any) {
        //動作モードの設定
        guard let sender = sender as? UISegmentedControl else{
            return
        }
        
        guard let mode_range = self.mode_range else{
            return
        }
        
        var parameters = Parameters()
        parameters["mode"] = mode_range[sender.selectedSegmentIndex].first!.key
        self.change_status(parameters: parameters)
    }
    
    @IBAction func set_wind(_ sender: Any) {
        guard let sender = sender as? UISegmentedControl else{
            return
        }
        
        guard let wind_range = self.wind_range else{
            return
        }
        
        var parameters = Parameters()
        parameters["wind"] = wind_range[sender.selectedSegmentIndex].first!.key
        self.change_status(parameters: parameters)
    }
    
    @IBAction func changed_temperature(_ sender: Any) {
        guard let sender = sender as? UISlider else{
            return
        }
        
        //print(sender.value)
        
        /*for base_layer in self.subviews{
            
            break
        }*/
        
        guard let _ = self.temperature else{
            sender.setValue(0.5, animated: false)
            return
        }
        
        let base_layer = self
        
        for layer in base_layer.subviews{
            if layer.restorationIdentifier != "temp_text"{
                continue
            }
            
            guard let layer = layer as? UILabel else{
                continue
            }
            
            layer.text = "\(Int(floorf(sender.value))) ℃"
            break
        }
    }
    
    @IBAction func end_change_temperature(_ sender: Any) {
        guard let sender = sender as? UISlider else{
            return
        }
        
        guard let _ = self.temperature else{
            sender.setValue(0.5, animated: true)
            return
        }
        
        let base_layer = self
        for layer in base_layer.subviews{
            if layer.restorationIdentifier != "temp_text"{
                continue
            }
            
            guard let layer = layer as? UILabel else{
                continue
            }
            
            let value = floorf(sender.value)
            sender.setValue(value, animated: true)
            
            layer.alpha = 1.0
            layer.text = "\(Int(value)) ℃"
            
            var parameters = Parameters()
            parameters["temperature"] = value
            
            self.change_status(parameters: parameters)
            
            break
        }
    }
    
    
}

class sensor:UIView{
    @IBOutlet weak var temperature_text: UILabel!
    @IBOutlet weak var humidity_text: UILabel!
    @IBOutlet weak var airpressure_text: UILabel!
    @IBOutlet weak var illuminance_text: UILabel!
    
    public var room_num:String?
    public var temperature:Double?
    public var humidity:Double?
    public var airpressure:Double?
    public var illuminance:Double?
    public var allow_freshup = false
    
    private var api_url:String?
    private var api_key:String?
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect,room_num:String,api_url:String,api_key:String,init_data:JSON) {
        super.init(frame:frame)
        if let view = Bundle.main.loadNibNamed("sensors", owner: self, options: nil)!.first as? sensor{
            view.frame = self.bounds
            
            self.room_num = room_num
            view.room_num = self.room_num
            self.api_key = api_key
            view.api_key = self.api_key
            self.api_url = api_url
            view.api_url = self.api_url
            for data in init_data{
                guard let dict = data.1.dictionary else{
                    continue
                }
                
                switch dict["sensor_type"]?.string{
                case "illuminance":
                    self.illuminance = dict["value"]?.double
                case "airpressure":
                    self.airpressure = dict["value"]?.double
                case "humidity":
                    self.humidity = dict["value"]?.double
                case "temperature":
                    self.temperature = dict["value"]?.double
                default:break
                }
            }
            
            view.temperature = temperature
            view.humidity = humidity
            view.airpressure = airpressure
            view.illuminance = illuminance
            
            self.addSubview(view)
        }
    }
    
    override func layoutSubviews() {
        for layer in self.subviews{
            switch layer.restorationIdentifier{
            case "humidity_text":
                guard let layer = layer as? UILabel else{
                    break
                }
                
                layer.text = "\(self.humidity!) %"
            case "airpressure_text":
                guard let layer = layer as? UILabel else{
                    break
                }
                
                layer.text = "\(self.airpressure!) hPa"
            case "temperature_text":
                guard let layer = layer as? UILabel else{
                    break
                }
                
                layer.text = "\(self.temperature!) ℃"
            case "illuminance_text":
                guard let layer = layer as? UILabel else{
                    break
                }
                
                layer.text = "\(self.illuminance!) lux"
            default:break
            }
        }
    }
    
    func renew_status(response:JSON?){
        if let response = response{
            let init_data = JSON(response)
            for data in init_data{
                guard let dict = data.1.dictionary else{
                    continue
                }
                
                switch dict["sensor_type"]?.string{
                case "illuminance":
                    for base_layer in self.subviews{
                        guard let base_layer = base_layer as? sensor else{
                            continue
                        }
                        
                        for layer in base_layer.subviews{
                            if layer.restorationIdentifier != "illuminance_text"{
                                continue
                            }
                            guard let layer = layer as? UILabel else{
                                continue
                            }
                            
                            guard let value = dict["value"]?.double else{
                                continue
                            }
                            
                            layer.text = "\(value) lux"
                            break
                        }
                        break
                    }
                    self.illuminance = dict["value"]?.double
                case "airpressure":
                    for base_layer in self.subviews{
                        guard let base_layer = base_layer as? sensor else{
                            continue
                        }
                        
                        for layer in base_layer.subviews{
                            if layer.restorationIdentifier != "airpressure_text"{
                                continue
                            }
                            guard let layer = layer as? UILabel else{
                                continue
                            }
                            
                            guard let value = dict["value"]?.double else{
                                continue
                            }
                            
                            layer.text = "\(value) hPa"
                            break
                        }
                        break
                    }
                    self.airpressure = dict["value"]?.double
                case "humidity":
                    for base_layer in self.subviews{
                        guard let base_layer = base_layer as? sensor else{
                            continue
                        }
                        
                        for layer in base_layer.subviews{
                            if layer.restorationIdentifier != "humidity_text"{
                                continue
                            }
                            guard let layer = layer as? UILabel else{
                                continue
                            }
                            
                            guard let value = dict["value"]?.double else{
                                continue
                            }
                            
                            layer.text = "\(value) %"
                            break
                        }
                        break
                    }
                    self.humidity = dict["value"]?.double
                case "temperature":
                    for base_layer in self.subviews{
                        guard let base_layer = base_layer as? sensor else{
                            continue
                        }
                        
                        for layer in base_layer.subviews{
                            if layer.restorationIdentifier != "temperature_text"{
                                continue
                            }
                            guard let layer = layer as? UILabel else{
                                continue
                            }
                            
                            guard let value = dict["value"]?.double else{
                                continue
                            }
                            
                            layer.text = "\(value) ℃"
                            break
                        }
                        break
                    }
                    self.temperature = dict["value"]?.double
                default:break
                }
            }
        }else{
            var headers = HTTPHeaders()
            headers["Authorization"] = "Basic \(self.api_key!)"
            
            Alamofire.request(URL(string:self.api_url!)!,method:.get,headers:headers).responseJSON{ response in
                guard let status_code = response.response?.statusCode else{
                    return
                }
                
                if status_code != 200 {
                    return
                }
                
                guard let value = response.result.value else{
                    return
                }
                
                self.renew_status(response: JSON(value))
            }
        }
    }
}
