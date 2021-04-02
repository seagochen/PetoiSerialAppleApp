//
//  BLECmdHelper.swift
//  PetoiSerialSwift
//
// 尽量按照和QT：SerialSignalStackHandler 代码相似的业务逻辑做的简易消息栈
//
//  Created by Orlando Chen on 2021/4/1.
//

import UIKit
import Foundation
import CoreBluetooth
import HexColors
import RMessage

typealias DoneClosure = () -> Void


class BLESignalStackHandler:  NSObject {
    
    private var bluetooth: BLEPeripheralHandler!  // 蓝牙设备管理类
    private var peripheral: CBPeripheral?  // 蓝牙BLE设备
    private var txdChar: CBCharacteristic?  // 发送数据接口
    private var rxdChar: CBCharacteristic?  // 接收数据接口
    private var bleMsgHandler: BLEMessageDetector?  // 接收和发送蓝牙数据
    private var devices: [CBPeripheral]!  // 设置蓝牙搜索的pickerview
    
    private var output: UITextView! // 输出
    private var button: UIButton! // 一些特殊按键的状态反馈
    private weak var delegate: AppDelegate! // AppDelegate
    
    private var success: DoneClosure?
    private var failure: DoneClosure?
    
    private var buffer: StringBuffer!
    
    
    init(textview: UITextView, delegate: AppDelegate) {
        super.init()
        
        self.delegate = delegate
        self.buffer = StringBuffer()
        self.output = textview
        
        // 对蓝牙设备进行初始化
        loadBleInformation()
    }
    
    deinit {
        print("deinit BLE handler")
        
        // 销毁前，把现有的蓝牙设备状态及相关信息存储回delegate
        saveBleInformation()
        
        // 销毁不需要的数据资源
        self.buffer = nil
    }
    
    
    // MARK: 对蓝牙等设备初始化
    func loadBleInformation() {
        
        bluetooth = delegate.bluetooth
        peripheral = delegate.peripheral
        txdChar = delegate.txdChar
        rxdChar = delegate.rxdChar
        bleMsgHandler = delegate.bleMsgHandler
        devices = delegate.devices
        
        // 是否有在处理蓝牙消息
        if let handler = bleMsgHandler {
            if !handler.isRunning() { // 没有运行
                handler.startListen(target: self, selector: #selector(self.recv))
            }
        }
    }
    

    // MARK: 存储蓝牙设备信息
    func saveBleInformation() {
        
        delegate.bluetooth = bluetooth
        delegate.peripheral = peripheral
        delegate.txdChar = txdChar
        delegate.rxdChar = rxdChar
        delegate.bleMsgHandler = bleMsgHandler
        delegate.devices = devices
        
        if let handler = bleMsgHandler {
            if handler.isRunning() { // 暂停对蓝牙消息的处理
                bleMsgHandler?.stopListen()
            }
        }
    }
    
    
    // MARK: 开始搜索，查找附近可用蓝牙设备
    func startScanPeripherals() {
        // 开始搜索可用设备
        bluetooth.startScanPeripheral(serviceUUIDS: nil, options: nil)
    
        // 清空列表，避免出现异常
        devices = []
    }
    
    
    // MARK: 停止搜索，并返回可用设备列表
    func stopScanPeripherals() -> [String] {
        // 停止扫描
        bluetooth.stopScanPeripheral()

        // 清空列表，避免出现异常
        devices = []
        var device_names: [String] = []

        // 把可用设备写入列表中
        let peripherals = bluetooth.getPeripheralList()
        if !peripherals.isEmpty {
            for device in peripherals {
                if device.name != nil {
                    devices.append(device)
                    device_names.append(device.name!)
                }
            }
        }
        
        // 返回给用户可用的设备列表名称
        return device_names
    }
    
    
    // MARK: 选择即将要建立的BLE设备
    func selectPeripheral(index: Int){
        
        // 测试是否已有连结建立
        if let _peripheral = self.peripheral {
            // 蓝牙正在与远程设备连结
            if bluetooth.isConnected(peripheral: _peripheral) {
                bluetooth.disconnect(peripheral: _peripheral) // 断开连结
            }
        }
        
        // 记录当前被用户选定的蓝牙设备
        self.peripheral = devices[index]
    }
    
    
    // MARK: 选择即将要建立的BLE设备
    func selectPeripheral(name: String){
        
        // 测试是否已有连结建立
        if let _peripheral = self.peripheral {
            // 蓝牙正在与远程设备连结
            if bluetooth.isConnected(peripheral: _peripheral) {
                bluetooth.disconnect(peripheral: _peripheral) // 断开连结
            }
        }
        
        // 记录当前被用户选定的蓝牙设备
        for device in devices {
            if device.name == name {
                self.peripheral = device
            }
        }
    }
    
    
    func outputView(output: UITextView) {
        self.output = output
    }
    
    
    // MARK: 建立与选定设备之间的连结
    func connectPeripheral(success: @escaping DoneClosure, failure: @escaping DoneClosure) {
        if peripheral != nil {
            bluetooth.connect(peripheral: peripheral!)
        }
        
        self.success = success
        self.failure = failure
        
        // 创建一个子线程，去检查蓝牙消息管道是否连通
        Thread(target: self, selector: #selector(setupBLETunnels), object: nil).start()
    }
    
    
    // MARK: 断开与设备之间的连结
    func disconnectPeripheral(success: DoneClosure) {
        if peripheral != nil {
            
            // 停止alarm
            bleMsgHandler?.stopListen()
            
            // 断开蓝牙连结
            bluetooth.disconnect(peripheral: peripheral!)
            
            success()
        }
    }
}

// 与QT方法相似的部分
extension BLESignalStackHandler {
    func calibrationFeedbackCheck() {
        // TODO
    }

    func sendCmdViaSerial(cmd: String) {
        bluetooth.sendData(data: Converter.cvtString(toData: cmd), peripheral: self.peripheral!, characteristic: self.txdChar!)
        // TODO
    }

    func isEmpty() -> Bool {
        // TODO
        return true
    }
}


// 后台线程
extension BLESignalStackHandler {
    
    // MARK: 线程，蓝牙消息处理函数
    @objc func recv() {
        let data = bluetooth.recvData()
        if data != nil {
            if let feedback = String(data: data!, encoding: .utf8) {
                
                // 将当前的文本粘贴到输出的文本后面
                buffer.push(feedback.replacingOccurrences(of: "\r\n", with: "\n"))
                
                // 更新数据
                DispatchQueue.main.async {
                    
                    if self.buffer.size() > 10 {
                        if let batched = self.buffer.batchStr(true) {
                            self.output.text = "Output:\n\t" + batched
                        }
                        
                    } else {
                        if let batched = self.buffer.batchStr(false) {
                            self.output.text = "Output:\n\t" + batched
                        }
                    }
                }
            }
        }
    }
    
    
    
    // MARK: 线程，尝试建立管道
    @objc func setupBLETunnels() {
        
        for times in 1...10 {
            
            // 等待连结是否完成，没有完成就休眠等待
            if !bluetooth.isConnected(peripheral: self.peripheral!) {
                
                // 失败：休眠5秒
                sleep(5)
            } else {
                
                // 成功：跳出检查状态，进入到信道检测环节
                break
            }
            
            if times == 10 { // 没有连结成功，失败
                
                // 断开连结
                bluetooth.disconnect(peripheral: self.peripheral!)
    
                // 回到主线程
                DispatchQueue.main.async {
                    
                    // 弹出错误信息
                    RMessage.showNotification(withTitle: "蓝牙设备连结失败", subtitle: "未能连结到设备，请重新尝试!", type: .error, customTypeName: nil, duration: 3, callback: nil)
                    
                    self.failure!()
                }
                
                // 任务中断
                return
            }
        }
        
        // 获取可用的消息信道
        let characteristics = bluetooth.getCharacteristic()
        
        rxdChar = characteristics[0] // Petoi默认rxd串口信道
        txdChar = characteristics[1] // Petoi默认txd串口信道
                
        // 启动后台线程，监听RXD信道数据
        if let rxdChar = rxdChar {
                    
            // 设置监听信道
            bluetooth.setNotifyCharacteristic(peripheral: self.peripheral!, notify: rxdChar)
            
            // 回到主线程
            DispatchQueue.main.async {
                
                // 启动后台定时器，开始接收并处理来自蓝牙设备的数据
                self.bleMsgHandler?.startListen(target: self, selector: #selector(self.recv))
                
                // 弹出消息提示框
                RMessage.showNotification(withTitle: "蓝牙连结成功", subtitle: "已连结到设备\(String(describing: self.peripheral!.name!))，开始监听消息中...", type: .success, customTypeName: nil, duration: 3, callback: nil)
                
                // 恢复按键
                self.success!()
                
                // 清空全部的数据
                self.bluetooth.clearBuffer()
            }
            
        } else {
            
            // 回到主线程，修改按钮信息
            DispatchQueue.main.async {
                
                // 弹出错误信息
                RMessage.showNotification(withTitle: "蓝牙设备连结失败", subtitle: "未能查找到可用的串口信号，请重新尝试!", type: .error, customTypeName: nil, duration: 3, callback: nil)
                
                // 恢复按键
                self.failure!()
            }
        }
    }
}
