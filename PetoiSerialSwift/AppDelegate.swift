//
//  AppDelegate.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/23.
//

import UIKit
import CoreBluetooth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // 蓝牙设备管理类
    var bluetooth: BLEPeripheralHandler!
    
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
    
    // 设置电机角度
    var motors: [Int]!
    
    
    func initParameters() {
        // 初始化蓝牙
        bluetooth = BLEPeripheralHandler()
        
        // 初始化信道
        bleMsgHandler = BLEMessageDetector()
        
        // 清空列表，避免出现异常
        devices = []
        
        // 创建舵机旋转角度
        motors = [Int](repeating: 0, count: 16)
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 初始化与蓝牙有关的全部参数
        initParameters()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

