//
//  ViewController.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/23.
//

import UIKit
import CoreBluetooth
import HexColors
import RMessage
import ActionSheetPicker_3_0

class ViewController: UIViewController  {
    
    // 蓝牙设备管理类
    var bluetooth: BluetoothLowEnergy!
    
    // 蓝牙BLE设备
    var peripheral: CBPeripheral?
    
    // 发送数据接口
    var txdChar: CBCharacteristic?
    
    // 接收数据接口
    var rxdChar: CBCharacteristic?
    
    // 接收和发送蓝牙数据
    var bleMsgHandler: BLEMessageDetector?
    
    // 设置蓝牙搜索的pickerview
    var devices: [String]!
    
    // iOS 控件
    @IBOutlet weak var bleSearchBtn: UIButton!
    @IBOutlet weak var bleDevicesText: UITextField!
    @IBOutlet weak var unfoldBtn: UIButton!
    @IBOutlet weak var calibrationBtn: UIButton!
    @IBOutlet weak var restBtn: UIButton!
    @IBOutlet weak var gyroscopeBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 对控件进行调整
        initWidgets()
        
        // 对工具进行初始化
        initUtilities()
    }
    
    
    func initWidgets() {
        // 修改文本框样式
        WidgetTools.underline(textfield: bleDevicesText, color: bleSearchBtn.backgroundColor!)
        
        // 设置文本框委托模式
        bleDevicesText.delegate = self
        
        // 设置展开菜单展开按钮
        unfoldBtn.setTitle("", for: .normal)
        
        // 修改按钮样式
        WidgetTools.roundCorner(button: bleSearchBtn)
        WidgetTools.roundCorner(button: calibrationBtn)
        WidgetTools.roundCorner(button: restBtn)
        WidgetTools.roundCorner(button: gyroscopeBtn)
    }
    

    func initUtilities() {
        // 初始化蓝牙
        bluetooth = BluetoothLowEnergy()
        
        // 初始化信道
        bleMsgHandler = BLEMessageDetector()
    }
    
    
    @IBAction func searchBtnPressed(_ sender: UIButton) {
        
        switch sender.currentTitle {
        case "Search":
            // 开始搜索可用设备
            bluetooth.startScanPeripheral(serviceUUIDS: nil, options: nil)
            
            // 清空列表，避免出现异常
            devices = []
            
            // 修改文字
            sender.setTitle("Stop", for: .normal)

        case "Stop":
            // 停止搜索
            bluetooth.stopScanPeripheral()

            // 把可用设备写入列表中
            let peripherals = bluetooth.getPeripheralList()
            if !peripherals.isEmpty {
                for device in peripherals {
                    if let name = device.name {
                        devices.append(name)
                    }
                }
            }
            
            // 修改文字
            sender.setTitle("Search", for: .normal)
            
            // 弹出提示信息
            if devices.count <= 0 {
                RMessage.showNotification(withTitle: "蓝牙设备搜索失败", subtitle: "未能找到可用的蓝牙设备，请重新尝试!", type: .error, customTypeName: nil, duration: 3, callback: nil)
            } else {
                RMessage.showNotification(withTitle: "找到了可用的设备", subtitle: "找到了\(devices.count)台可用设备", type: .success, customTypeName: nil, duration: 3, callback: nil)
            }
            
        default:
            break
        }
   
    }
    
    @IBAction func unfoldBtnPressed(_ sender: UIButton) {
        
        ActionSheetStringPicker.show(withTitle: "可用蓝牙设备", rows: devices, initialSelection: 0, doneBlock: { [self]
            picker, indexes, values in

            // for debug
            print("values = \(String(describing: values))")
            print("indexes = \(indexes)")
            print("picker = \(String(describing: picker))")
            
            // 显示选择的内容
            let stringVar = String(describing: values!)
            self.bleDevicesText.text = "Device: " + String(describing: stringVar)
            
            // 设置连结蓝牙设备
//            if peripheral != nil && bluetooth.isConnected(peripheral: peripheral) {
//                bluetooth.disconnect(peripheral: peripheral)
//            } else {
//                setupBluetoothConnection(index: indexes)
//            }
            
            return
        }, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
    }
    
    @objc func recv() {
        let data = bluetooth.recvData()

        if data.count > 0 {
            if let feedback = String(data: data, encoding: .utf8) {
                print(feedback)
            }
        }
    }
    
    func setupBluetoothConnection(index: Int) {
        // 尝试对设备进行连结
        let peripherals = self.bluetooth.getPeripheralList()
        self.peripheral = peripherals[index]
        self.bluetooth.connect(peripheral: self.peripheral!)
        
        // 设置信道
        guard let peripheral = peripheral else {
            print("peripheral is null")
            return
        }

        if bluetooth.isConnected(peripheral: peripheral) {
            let characteristics = bluetooth.getCharacteristic()
            if characteristics.count >= 2 {

                rxdChar = characteristics[0]
                txdChar = characteristics[1]

                // 设置接收数据
                guard let rxdChar = rxdChar else {
                    print("rxdChar is null")
                    return
                }

                bluetooth.setNotifyCharacteristic(peripheral: peripheral, notify: rxdChar)
        
        
            }
        }
        
        // 启动后台定时器，开始接收来自蓝牙设备的数据
        self.bleMsgHandler?.startListen(target: self, selector: #selector(recv))
    }
}



extension ViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
}
