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
    @IBOutlet weak var outputTextView: UITextView!
    
    // ble 消息栈
    var bleHelper: BLESignalStackHandler!

    // 需要调整的舵机号，默认0号舵机
    var selectedServo = 0
    
    
    // MARK: view被创建后，初始化一些基础设置
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 对控件进行调整
        initWidgets()
        
        // 对信道蓝牙相关通信做准备
        let delegate = UIApplication.shared.delegate as! AppDelegate
        bleHelper = BLESignalStackHandler(textview: outputTextView, delegate: delegate)
    }
    
    
    // MARK: 对面板控件进行初始化的函数
    func initWidgets() {
        /**
         * 标签风格
         */
        // 下划线的形式
        WidgetTools.underline(label: servoLabel)
        // 修改标签内容
        servoLabel.text = "Servo: None"
       
      
        /**
         * 按钮
         */
        // 给按钮设置为圆角矩形
        WidgetTools.roundCorner(button: servoBtn)
        WidgetTools.roundCorner(button: clearBtn)
        WidgetTools.roundCorner(button: saveBtn)
        WidgetTools.roundCorner(button: OKBtn)
        
        
        /**
         * 文本背景设置为透明，并把文本框挪到顶层的视图层
         */
        WidgetTools.transparent(textView: outputTextView, alpha: 0.4)
        WidgetTools.bringSubviewToFront(parent: self.view, child: outputTextView)
    }
    
    // MARK: 不干什么事，主要在用户点击OK按钮后退出当前的界面，回到上级界面
    @IBAction func OKBtnPressed(_ sender: UIButton) {
        
        bleHelper.sendCmdViaSerial(cmd: "d")
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK:
    @IBAction func fineAdjStepperPressed(_ sender: UIStepper) {
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

           return}, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
    }
    
    // MARK:
    @IBAction func clearBtnPressed(_ sender: Any) {
        bleHelper.sendCmdViaSerial(cmd: "c")
    }
    
    // MARK:
    @IBAction func saveBtnPressed(_ sender: Any) {
        bleHelper.sendCmdViaSerial(cmd: "s")
    }
}
