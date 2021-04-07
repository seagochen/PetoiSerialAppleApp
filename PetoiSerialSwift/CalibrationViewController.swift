//
//  CalibrationViewController.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/31.
//

import UIKit
import CoreBluetooth
import HexColors
import RMessage
import ActionSheetPicker_3_0


class CalibrationViewController: UIViewController {
    
    @IBOutlet weak var servoLabel: UILabel!
    @IBOutlet weak var servoBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var finStepper: UIStepper!
    
    
    // ble 消息栈
    var helper: BLESignalStackHandler!

    // 需要调整的舵机号，默认0号舵机
    var selectedServo = 0
    
    
    // MARK: view被创建后，初始化一些基础设置
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            
                // 更新文本框
                self.outputTextView.text = "Output:\n\t" + msg
//                let message = "Output:\n\t" + self.helper.messageFromTop()
//                self.outputTextView.text = message
                
                // 对回传的数据进行分析检测
                switch top.cmd {
                case "c":
                    self.checkCalibrationMessage(message: top.feedback)
                    
                default:
                    break
                }
            }
        })
    }
    
    
    // MARK: 对面板控件进行初始化的函数
    func initWidgets() {
        /**
         * 标签风格
         */
        WidgetTools.underline(label: servoLabel)
        WidgetTools.bringSubviewToFront(parent: self.view, child: servoLabel)
        servoLabel.text = "Servo: 舵机 0"
       
      
        /**
         * 按钮
         */
        WidgetTools.roundCorner(button: servoBtn)
        WidgetTools.roundCorner(button: clearBtn)
        WidgetTools.roundCorner(button: saveBtn)
        WidgetTools.roundCorner(button: OKBtn)
        WidgetTools.roundCorner(button: resetBtn)
        
        
        /**
         * 文本背景设置为透明，并把文本框挪到顶层的视图层
         */
        WidgetTools.transparent(textView: outputTextView, alpha: 0.4)
        WidgetTools.bringSubviewToFront(parent: self.view, child: outputTextView)
        outputTextView.text = ""
        outputTextView.delegate = self
        
        
        /**
         * stepper 值修改
         */
        finStepper.value = 10
    }
    
    // MARK: 不干什么事，主要在用户点击OK按钮后退出当前的界面，回到上级界面
    @IBAction func OKBtnPressed(_ sender: UIButton) {
        
//        helper.sendCmdViaSerial(msg: "d")
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK:
    @IBAction func fineAdjStepperPressed(_ sender: UIStepper) {
        print(sender.value)
    }
    
    // MARK:
    @IBAction func servoSelectBtnPressed(_ sender: Any) {
        
        // 舵机编号
        let servos = [
            "舵机 0",
            "舵机 8", "舵机 9", "舵机 10", "舵机 11",
            "舵机 12", "舵机 13", "舵机 14", "舵机 15"]
        
        // 弹出选择框
        ActionSheetStringPicker.show(withTitle: "可调舵机", rows: servos, initialSelection: 0, doneBlock: { picker, indexes, values in
            
            // 显示选择的内容
            self.servoLabel.text = "Servo: " + servos[indexes]
            
            // 更新选择的舵机号
            if (indexes > 0) {
                self.selectedServo = indexes + 7 // etc: 1 + 7 = servo 8
            } else {
                self.selectedServo = 0
            }
                                        
            // 更新标签
            self.servoLabel.text = "Servo: \(self.selectedServo)"

           return}, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
    }
    
    // MARK:
    @IBAction func calibrationBtnPressed(_ sender: Any) {
        helper.sendCmdViaSerial(msg: "c")
    }
    
    // MARK:
    @IBAction func saveBtnPressed(_ sender: Any) {
        helper.sendCmdViaSerial(msg: "s")
    }
    
    // MARK:
    @IBAction func resetBtnPressed(_ sender: UIButton) {
        let cmd = "c\(selectedServo) 0"
        helper.sendCmdViaSerial(msg: cmd)
    }
    
}


extension CalibrationViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}


extension CalibrationViewController {
    func checkCalibrationMessage(message: String?) {
        
        guard let msg = message else {
            return
        }
        
        // 舵机编号，不做处理
        if msg == "c0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15," {
            return
        }
        
        if msg == "c0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15," {
            return
        }
        
        // 其他情况
        let params = msg.split(separator: ",")
        var angles:[Int] = []
        
        if params.count == 16 { // c0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            
            for param in params {  // change cX to X
                if param.contains("c") {
                    let t = param.replacingOccurrences(of: "c", with: "")
                    angles.append(Int(t) ?? 0xFF)
                } else {
                    angles.append(Int(param) ?? 0xFF)
                }
            }
            
            // save to helper
            helper.saveMotorsAngleToDelegate(motors: angles)
        }
    }
}
