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

class MainViewController: UIViewController  {
    
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
    var devices: [CBPeripheral]!
    
    // 蓝牙输出文本缓冲
    var outputString: String = ""
    
    // iOS 控件
    @IBOutlet weak var bleSearchBtn: UIButton!
    @IBOutlet weak var calibrationBtn: UIButton!
    @IBOutlet weak var restBtn: UIButton!
    @IBOutlet weak var gyroscopeBtn: UIButton!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var selectedDeviceLabel: UILabel!
    @IBOutlet weak var connectBtn: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 对控件进行调整
        initWidgets()
        
        // 对信道蓝牙相关通信做准备
        initUtilities()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        // 蓝牙设备管理类
        delegate.bluetooth = bluetooth
        
        // 蓝牙BLE设备
        delegate.peripheral = peripheral
        
        // 发送数据接口
        delegate.txdChar = txdChar
        
        // 接收数据接口
        delegate.rxdChar = rxdChar
        
        // 接收和发送蓝牙数据
        delegate.bleMsgHandler = bleMsgHandler
        
        // 设置蓝牙搜索的pickerview
        delegate.devices = devices
    }
    
    func initUtilities() {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        // 蓝牙设备管理类
        bluetooth = delegate.bluetooth
        
        // 蓝牙BLE设备
        peripheral = delegate.peripheral
        
        // 发送数据接口
        txdChar = delegate.txdChar
        
        // 接收数据接口
        rxdChar = delegate.rxdChar
        
        // 接收和发送蓝牙数据
        bleMsgHandler = delegate.bleMsgHandler
        
        // 设置蓝牙搜索的pickerview
        devices = delegate.devices
    }
    
    
    // MARK: 对面板控件进行初始化的函数
    func initWidgets() {
        /**
         * 标签风格
         */
        // 下划线的形式
        WidgetTools.underline(label: selectedDeviceLabel)
        // 修改标签内容
        selectedDeviceLabel.text = "Device: None"
       
      
        /**
         * 按钮
         */
        // 给按钮设置为圆角矩形
        WidgetTools.roundCorner(button: bleSearchBtn)
        WidgetTools.roundCorner(button: calibrationBtn)
        WidgetTools.roundCorner(button: restBtn)
        WidgetTools.roundCorner(button: gyroscopeBtn)
        WidgetTools.roundCorner(button: connectBtn)

        disableConnectBtn()
        disableAllFuncBtns()
        
        
        /**
         * 输出文本框
         */
        outputTextView.text = "Output:\n\t"
        WidgetTools.roundCorner(textView: outputTextView, boardColor: bleSearchBtn.backgroundColor!)
    }
    
    func disableConnectBtn() {
        connectBtn.isEnabled = false
        connectBtn.alpha = 0.4
    }

    
    func enableConnectBtn() {
        connectBtn.isEnabled = true
        connectBtn.alpha = 1
    }


    func disableAllFuncBtns() {
        calibrationBtn.alpha = 0.4
        calibrationBtn.isEnabled = false
        
        restBtn.alpha = 0.4
        restBtn.isEnabled = false
        
        gyroscopeBtn.alpha = 0.4
        gyroscopeBtn.isEnabled = false
    }
    

    func enableAllFuncBtns() {
        calibrationBtn.alpha = 1
        calibrationBtn.isEnabled = true
        
        restBtn.alpha = 1
        restBtn.isEnabled = true
        
        gyroscopeBtn.alpha = 1
        gyroscopeBtn.isEnabled = true
    }
    
    
    // MARK: 搜索设备按钮，事件反馈
    @IBAction func searchBtnPressed(_ sender: UIButton) {
        
        // 开始搜索可用设备
        bluetooth.startScanPeripheral(serviceUUIDS: nil, options: nil)
    
        // 清空列表，避免出现异常
        devices = []

        // 创建一个子线程，去检查可用的蓝牙设备
        Thread(target: self, selector: #selector(searchBLEDevices), object: nil).start()
    }
    

    // MARK: 连结设备按钮，事件反馈
    @IBAction func connectBtnPressed(_ sender: UIButton) {

        switch sender.currentTitle {
        case "Connect":
            // 对设备进行连结
            bluetooth.connect(peripheral: self.peripheral!)
                
            // 创建一个子线程，去检查蓝牙消息管道是否连通
            Thread(target: self, selector: #selector(setupBLETunnels), object: nil).start()
                
            // 在信道创建完成之前，不允许用户再点击按钮
            disableConnectBtn()

        case "Disconnect":
            // 停止alarm
            bleMsgHandler?.stopListen()
            
            // 断开蓝牙连结
            bluetooth.disconnect(peripheral: peripheral!)
            
            // 修改按钮文字
            connectBtn.setTitle("Connect", for: .normal)

            // 关闭功能按钮
            disableAllFuncBtns()
            
            // 打开连结按钮
            enableConnectBtn()

        default:
            break
        }
    }
    

    // MARK: 展开菜单按钮，事件反馈
    func showSelectableDevices(_ sender: UIButton) {
        
        if devices.count > 0 {
            
            // 获取可用设备的设备名
            var deviceNames:[String] = []
            for dev in devices {
                deviceNames.append(dev.name!)
            }
            
            ActionSheetStringPicker.show(withTitle: "可用蓝牙设备", rows: deviceNames, initialSelection: 0, doneBlock: { [self]
                picker, indexes, values in

                // for debug
                print("values = \(String(describing: values))")
                print("indexes = \(indexes)")
                print("picker = \(String(describing: picker))")
                
                // 显示选择的内容
                self.selectedDeviceLabel.text = "Device: " + String(describing: values!)
                
                // 设置蓝牙连结
                if self.connectBLEDevice(index: indexes) {
                    enableConnectBtn()
                }

                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
        
        } else {  // 没有可用的设备列表，要求用户进行设备搜索
            
            RMessage.showNotification(withTitle: "蓝牙设备列表为空", subtitle: "未能可用的设备列表，请先完成搜索过程后再尝试!", type: .normal, customTypeName: nil, duration: 3, callback: nil)
        }
    }
    
    
    // MARK: 休息
    @IBAction func restPressed(_ sender: UIButton) {
        outputString = ""
        
        bluetooth.sendData(data: Converter.cvtString(toData: "d"), peripheral: peripheral!, characteristic: txdChar!)
    }
    
    // 陀螺仪
    @IBAction func gyrosocopePressed(_ sender: UIButton) {
        outputString = ""
        
        bluetooth.sendData(data: Converter.cvtString(toData: "g"), peripheral: peripheral!, characteristic: txdChar!)
    }


    @objc func searchBLEDevices() {
        sleep(1)

        // 停止扫描
        bluetooth.stopScanPeripheral()

        // 清空列表，避免出现异常
        devices = []

        // 把可用设备写入列表中
        let peripherals = bluetooth.getPeripheralList()
        if !peripherals.isEmpty {
            for device in peripherals {
                if device.name != nil {
                    devices.append(device)
                }
            }
        }

        // 弹出选择菜单
        DispatchQueue.main.async {
            self.showSelectableDevices(self.bleSearchBtn)
        }
    }
    
    
    // MARK: 尝试建立管道
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
                    
                    // 允许按钮可用
                    self.enableConnectBtn()
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
                
                // 修改按钮信息
                self.connectBtn.setTitle("Disconnect", for: .normal)
                self.enableConnectBtn()

                // 允许用户使用全部的按钮
                self.enableAllFuncBtns()
            }
            
        } else {
            
            // 回到主线程，修改按钮信息
            DispatchQueue.main.async {
                
                // 弹出错误信息
                RMessage.showNotification(withTitle: "蓝牙设备连结失败", subtitle: "未能查找到可用的串口信号，请重新尝试!", type: .error, customTypeName: nil, duration: 3, callback: nil)
                
                // 修改按钮信息
                self.enableConnectBtn()
            }
        }
    }
    

    // MARK: 蓝牙连结处理函数
    func connectBLEDevice(index: Int) -> Bool {
        
        // 测试是否已有连结建立
        if let _peripheral = self.peripheral {
            // 蓝牙正在与远程设备连结
            if bluetooth.isConnected(peripheral: _peripheral) {
                bluetooth.disconnect(peripheral: _peripheral) // 断开连结
            }
        }
        
        // 记录当前被用户选定的蓝牙设备
        self.peripheral = devices[index]
        
        // 设置选定的蓝牙设备
        guard self.peripheral != nil else {
            
            // 连结失败，弹出错误信息
            RMessage.showNotification(withTitle: "蓝牙设备连结失败", subtitle: "未能连结到蓝牙设备，请重新尝试!", type: .error, customTypeName: nil, duration: 3, callback: nil)
            
            // 错误中断
            return false
        }

        // 建立连结中
        return true
    }


    // MARK: 蓝牙消息处理函数
    @objc func recv() {
        let data = bluetooth.recvData()
        if data != nil {
            if let feedback = String(data: data!, encoding: .utf8) {
                
                // 将当前的文本粘贴到输出的文本后面
                let trimstr = "Output:\n\t" + feedback.replacingOccurrences(of: "\r\n", with: "\n")
                
                // 更新数据
                DispatchQueue.main.async {
                    self.outputTextView.text = trimstr
                }
            }
        }
    }
}



extension MainViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
}
