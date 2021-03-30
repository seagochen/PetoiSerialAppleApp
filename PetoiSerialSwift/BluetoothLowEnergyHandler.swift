//
//  BluetoothLowEnergyHandler.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/23.
//

import Foundation
import CoreBluetooth


class BluetoothLowEnergy: NSObject {
    
    // 一个蓝牙设备当中可能包含多个信道，一个UUID就是一个信道标记
    var uuids: [CBCharacteristic] = []
    
    // 中心对象
    var central : CBCentralManager!
    
    // 把中心设备扫描的外置设备保存起来
    var deviceList: [CBPeripheral] = []

    // 接收到的数据
    var peripheralData: Data?
    
    // Objective Databuffer
    var buffer: DataBuffer!
    
    
    // MARK: 0. 初始化
    override init() {
        super.init()
        
        // 初始化中心设备管理器
        // 它的delegate函数为centralManagerDidUpdateState
        // 其回调消息处理函数为：centralManager
        self.central = CBCentralManager.init(delegate:self, queue:nil, options:[CBCentralManagerOptionShowPowerAlertKey:false])
        
        // 初始化设备列表
        self.deviceList = []
        
        // 创建DataBuffer
        buffer = DataBuffer.init()
    }

    // MARK: 1. 扫描设备
    func startScanPeripheral(serviceUUIDS: [CBUUID]?,
                             options: [String: AnyObject]?) {
        // 清空列表
        deviceList = []  // 清空设备列表
        uuids = [] // 清空信道列表
        
        // 开始进行扫描
        self.central?.scanForPeripherals(withServices: serviceUUIDS, options: options)
    }
     
    // MARK: 2. 停止扫描
    func stopScanPeripheral() {
        self.central?.stopScan()
    }
    
    // MARK: 3. 获取搜索到的外接设备
    func getPeripheralList()-> [CBPeripheral] {
        return deviceList
    }
    
    // MARK: 4.1. 连结设备
    // 连接设备之前要先设置代理，正常情况，当第一次获取外设peripheral的时候就会同时设置代理
    func connect(peripheral: CBPeripheral) {
        if (peripheral.state != .connected) {
            central?.connect(peripheral , options: nil)
            
            // 将外接设备的回掉函数连结到self
            // 回掉消息处理函数为：peripheral
            peripheral.delegate = self
        }
    }
    
    // MARK: 4.2. 检测是否建立了连结
    func isConnected(peripheral: CBPeripheral) -> Bool {
        return peripheral.state == .connected
    }
    
    // MARK: 4.3. 获取到当前蓝牙设备可用的消息信道
    func getCharacteristic() -> [CBCharacteristic] {
        return uuids
    }
    
    // MARK: 4.4. 指定监听信道
    func setNotifyCharacteristic(peripheral: CBPeripheral, notify: CBCharacteristic) {
        peripheral.setNotifyValue(true, for: notify)
    }
    
    // MARK: 5.1. 发送数据
    func sendData(data: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic,
                  type: CBCharacteristicWriteType = CBCharacteristicWriteType.withResponse) {
        
        let step = 20
        for index in stride(from: 0, to: data.count, by: step) {
            var len = data.count - index
            if len > step {
                len = step
            }
            let pData: Data = (data as NSData).subdata(with: NSRange(location: index, length: len))
            peripheral.writeValue(pData, for: characteristic, type: type)
        }
    }

    // MARK: 5.2. 接收数据
    func recvData() -> Data? {
        return buffer.tryGetToken()
    }
    
    // MARK: 6. 断开连结
    func disconnect(peripheral: CBPeripheral) {
        central?.cancelPeripheralConnection(peripheral)
    }
}

extension BluetoothLowEnergy: CBCentralManagerDelegate {
    
    // MARK: 检查运行这个App的设备是不是支持BLE。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
     
        switch central.state {
        case .poweredOn:
            print("BLE poweredOn")
        case .poweredOff:
            print("BLE powered off")
        case .unknown:
            print("BLE unknown")
        case .resetting:
            print("BLE ressetting")
        case .unsupported:
            print("BLE unsupported")
        case .unauthorized:
            print("BLE unauthorized")
        @unknown default:
            print("BLE default")
        }
    }
    
    // MARK: 以ANCS协议请求的端，授权状态发生改变
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
//        print("\(#function)\n central:\(central)\n peripheral:\(peripheral)")
        
        // TODO
    }
    
    // MARK:
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        
//        print("\(#function)\n central:\(central)\n event: \(event)\n  peripheral:\(peripheral)")
        
        // TODO
    }
    
    // 开始扫描之后会扫描到蓝牙设备，扫描到之后走到这个代理方法
    // MARK: 中心管理器扫描到了设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard !deviceList.contains(peripheral), let deviceName = peripheral.name, deviceName.count > 0 else {
            return
        }
        
        // 把设备加入到列表中
        deviceList.append(peripheral)
    }
       
    // MARK: 连接外设成功，开始发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
//        print("\(#function)\n central:\(central)\n peripheral:\(peripheral)")
        
         // 设置代理
         peripheral.delegate = self
         
         // 开始发现服务
         peripheral.discoverServices(nil)
    }

       
    // MARK: 连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral:
                            CBPeripheral, error: Error?) {
//        print("\(#function)\n central:\(central)\n peripheral:\(peripheral)\n error:\(String(describing: error))")
        
        // TODO
    }
       
    // MARK: 连接丢失
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
//        print("\(#function)\n central:\(central)\n peripheral:\(peripheral)\n error:\(String(describing: error))")
        
       // TODO
    }
}


// MARK: 外置设备被绑定后的事件响应
extension BluetoothLowEnergy: CBPeripheralDelegate {
    
    // MARK: 匹配对应服务UUID
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        
        if error != nil { // failed
            print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n error:\(String(describing: error))")
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    // MARK: 服务下的特征
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service:
                        CBService, error: Error?) {
        
        if error != nil { // failed
            print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n service:\(String(describing: service))\n error:\(String(describing: error))")
            return
        }
        
        print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n service:\(String(describing: service))")
          
        for characteristic in service.characteristics ?? [] {
            uuids.append(characteristic)
        }
    }

    
    // MARK: 获取外设发来的数据
    // 注意，所有的，不管是 read , notify 的特征的值都是在这里读取
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n characteristic:\(String(describing: characteristic.description))\n error:\(String(describing: error))")
            return
        }
        
        print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n characteristic:\(String(describing: characteristic.description))")
        
        if let data = characteristic.value {
            print("recv from device with \(data.count) bytes")
            self.buffer.append(data)
        }
    }
    
    //MARK: 检测中心向外设写数据是否成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("\(#function)\n peripheral:\(String(describing: peripheral.name))\n characteristic:\(String(describing: characteristic.description))\n error:\(String(describing: error))")
            return
        }
        
        // TODO
    }
}
