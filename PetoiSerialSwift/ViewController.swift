//
//  ViewController.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/23.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController {
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化蓝牙
        bluetooth = BluetoothLowEnergy()
        
        // 初始化信道
        bleMsgHandler = BLEMessageDetector()
    }
    
    @objc func recv() {
        let data = bluetooth.recvData()

        if data.count > 0 {
            if let feedback = String(data: data, encoding: .utf8) {
                print(feedback)
            }
        }
    }
    
    @IBAction func searchBluetoothPeripherals(_ sender: UIButton) {
        
        if sender.currentTitle == "Search BLE devices" {
            // 搜索蓝牙
            bluetooth.startScanPeripheral(serviceUUIDS: nil, options: nil)
            
            // 修改名称
            sender.setTitle("Stop searching", for: .normal)
        } else if sender.currentTitle == "Stop searching" {
            
            // 停止搜索
            bluetooth.stopScanPeripheral()
            
            // 修改名称
            sender.setTitle("Search BLE devices", for: .normal)
        }
    }
    
    
    @IBAction func connectBluetoothPeripherals(_ sender: Any) {
        
        // 启动后台定时器
        bleMsgHandler?.startListen(target: self, selector: #selector(recv))
        
//        // connect to some centain device
//        let deviceList = bluetooth.getPeripheralList()
//        if !deviceList.isEmpty {
//            for device in deviceList {
//
//                print("found device: \(device.name ?? "")")
//
//                // 找到需要的设备
//                // TODO
//                if device.name == "JDY-23A-BLE" {
//                    bluetooth.connect(peripheral: device)
//
//                    // 记录需要的设备
//                    peripheral = device
//                }
//            }
//        }
//
//
//        // 获取需要的信道
//        guard let peripheral = peripheral else {
//            print("peripheral is null")
//            return
//        }
//
//        if bluetooth.isConnected(peripheral: peripheral) {
//            let characteristics = bluetooth.getCharacteristic()
//            if characteristics.count >= 2 {
//
//                rxdChar = characteristics[0]
//                txdChar = characteristics[1]
//
//                // 设置接收数据
//                guard let rxdChar = rxdChar else {
//                    print("rxdChar is null")
//                    return
//                }
//
//                bluetooth.setNotifyCharacteristic(peripheral: peripheral, notify: rxdChar)
//
//
//            }
//        }
        
    }
    
}
