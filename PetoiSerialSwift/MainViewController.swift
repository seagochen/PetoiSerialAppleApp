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
    
    // 蓝牙输出文本缓冲
    var outputString: String = ""
    
    // ble 消息栈
//    var bleHelper: BLECommunicationHandler!
    var helper: BLESignalStackHandler!
    
    // iOS 控件
    @IBOutlet weak var bleSearchBtn: UIButton!
    @IBOutlet weak var calibrationBtn: UIButton!
    @IBOutlet weak var restBtn: UIButton!
    @IBOutlet weak var gyroscopeBtn: UIButton!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var selectedDeviceLabel: UILabel!
    @IBOutlet weak var connectBtn: UIButton!
    
    
    // MARK: view被创建后，初始化一些基础设置
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("MainVC: viewDidLoad")
        
        // 对控件进行调整
        initWidgets()
        
        // 对信道蓝牙相关通信做准备
        let delegate = UIApplication.shared.delegate as! AppDelegate
        helper = BLESignalStackHandler(delegate: delegate, receive: { msg in
            
            if !self.helper.isEmpty() {
                // 对传入的消息进行比对，如果当前行和栈顶的key相同
                // 表示即将传入的下一行参数为value
                var top = self.helper.popupToken()
                top.feedback = msg
                
                // 默认操作
                self.helper.pushToken(token: top)
                self.helper.debugStack()
                
                // update the textbrowser
                DispatchQueue.main.async {
                    print("Output:\n\t" + self.helper.messageFromTop())
                    self.outputTextView.text = "Output:\n\t" + self.helper.messageFromTop()
                }
            }
        })
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

        WidgetTools.disable(button: connectBtn)
        disableAllFuncBtns()
        
        
        /**
         * 输出文本框
         */
        outputTextView.text = "Output:\n\t"
        outputTextView.delegate = self
        WidgetTools.roundCorner(textView: outputTextView, boardColor: bleSearchBtn.backgroundColor!)
    }


    func disableAllFuncBtns() {
        WidgetTools.disable(button: calibrationBtn)
        WidgetTools.disable(button: restBtn)
        WidgetTools.disable(button: gyroscopeBtn)
    }
    

    func enableAllFuncBtns() {
        WidgetTools.enable(button: calibrationBtn)
        WidgetTools.enable(button: restBtn)
        WidgetTools.enable(button: gyroscopeBtn)
    }
    
    
    // MARK: 搜索设备按钮，事件反馈
    @IBAction func searchBtnPressed(_ sender: UIButton) {
        
        // 搜索蓝牙设备
//        bleHelper.startScanPeripherals()
        helper.startScanPeripherals()

        // 把按钮设置为不可用
        WidgetTools.disable(button: bleSearchBtn)

        // 创建一个子线程，去检查可用的蓝牙设备
        Thread(target: self, selector: #selector(searchBLEDevices), object: nil).start()
    }
    

    // MARK: 连结设备按钮，事件反馈
    @IBAction func connectBtnPressed(_ sender: UIButton) {

        switch sender.currentTitle {
        case "Connect":
            
            // 对设备进行连结
            helper.connectPeripheral(success: {
                // 修改名字
                self.connectBtn.setTitle("Disconnect", for: .normal)
                
                // 允许使用全部的任务按钮
                self.enableAllFuncBtns()
                
                // 允许断开连结
                WidgetTools.enable(button: self.connectBtn)
                
            }, failure: {
                
                // 允许再次尝试连结
                WidgetTools.enable(button: self.connectBtn)
            })
                
            // 在信道创建完成之前，不允许用户再点击按钮
            WidgetTools.disable(button: connectBtn)

        case "Disconnect":
            
            // 断开蓝牙连结
            helper.disconnectPeripheral(success: {
                
                // 修改按钮文字
                connectBtn.setTitle("Connect", for: .normal)

                // 关闭功能按钮
                disableAllFuncBtns()
                
                // 允许再次尝试连结
                WidgetTools.enable(button: self.connectBtn)
            })

        default:
            break
        }
    }
    
    // MARK: 休息
    @IBAction func restPressed(_ sender: UIButton) {
//        bleHelper.sendCmdViaSerial(cmd: "d")
        helper.sendCmdViaSerial(msg: "d")
    }
    
    // MARK: 陀螺仪
    @IBAction func gyrosocopePressed(_ sender: UIButton) {
//        bleHelper.sendCmdViaSerial(cmd: "g")
        helper.sendCmdViaSerial(msg: "g")
    }
    
    // MARK: 校准
    @IBAction func calibrationBtnPressed(_ sender: Any) {
        // 先发送一个c
//        helper.sendCmdViaSerial(msg: "c")

        // 把蓝牙设备信息存储一下
        helper.saveBleInformation()

        // 跳转到 CalibrationVC
        let vc = self.storyboard?.instantiateViewController(identifier: "CalibrationVC") as! CalibrationViewController
        self.navigationController?.pushViewController(vc, animated: true)
        self.present(vc, animated: true, completion: nil)
    }
}


extension MainViewController {
    // MARK: 线程，查找BEL设备
    @objc func searchBLEDevices() {
        sleep(1)

        let devices = helper.stopScanPeripherals()

        // 弹出选择菜单
        DispatchQueue.main.async {

            let sender = self.bleSearchBtn

            if devices.count > 0 {
            
                // 给用户列出可用的设备名单
                ActionSheetStringPicker.show(withTitle: "可用蓝牙设备", rows: devices, initialSelection: 0, doneBlock: { [self]
                    picker, indexes, values in

                    // for debug
                    print("values = \(String(describing: values))")
                    print("indexes = \(indexes)")
                    print("picker = \(String(describing: picker))")
                    
                    // 显示选择的内容
                    self.selectedDeviceLabel.text = "Device: " + String(describing: values!)
                    
                    // 设置蓝牙连结
                    self.helper.selectPeripheral(index: indexes)
                 
                    // 把连结按钮调整为可用
                    WidgetTools.enable(button: connectBtn)
                    
                    return
                }, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
        
            } else {  // 没有可用的设备列表，要求用户进行设备搜索
            
                RMessage.showNotification(withTitle: "蓝牙设备列表为空", subtitle: "未能可用的设备列表，请先完成搜索过程后再尝试!", type: .normal, customTypeName: nil, duration: 3, callback: nil)
            }

            // 把按钮重新设置为可用
            WidgetTools.enable(button: self.bleSearchBtn)
        }
    }
}


extension MainViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}
