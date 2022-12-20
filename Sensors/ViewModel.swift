//
//  ViewModel.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-08.
//

import Foundation
import CoreBluetooth

class ViewModel: ObservableObject {
    private var theModel = Model()
    let BLEConnect = BluetoothConnect()
    let notificationKey = "newData"
    let IMUnotificationKey = "newIMUData"
    @Published var linAccAngle: Double = 0.0
    @Published var gyroAccAngle: Double = 0.0
    @Published var IMUAngle: Double = 0.0
    var peripherals: [BluetoothConnect.Peripheral] = []
    
    func calcAngles() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewModel.notificationSent), name: Notification.Name(rawValue: notificationKey), object: nil)
        theModel.calcAngles()
    }
    
    func calcIMUAngles() {
        //NotificationCenter.default.addObserver(self, selector: #selector(ViewModel.IMUnotificationSent), name: Notification.Name(rawValue: IMUnotificationKey), object: nil)
        //theModel.calcIMUAngles()
        //self.IMUAngle = theModel.IMUlinAccAngle
    }
    
    @objc func notificationSent(_ notification: Notification) {
        let angles = notification.object as! [Double]
        self.linAccAngle = angles[0]
        self.gyroAccAngle = angles[1]
    }
    
    @objc func IMUnotificationSent(_ notification: Notification) {
        //self.IMUAngle = notification.object as! Double
        self.IMUAngle = theModel.calcIMUAngles(accData: notification.object as! [Double])
    }
    
    func saveData() {
        theModel.saveData()
    }
    
    func saveIMUData() {
        theModel.saveIMUData()
    }
    
    func stopSaving() {
        theModel.stopSaving()
    }
    
    func stopSavingIMU() {
        theModel.stopSavingIMU()
    }
    
    func getSensors() -> [BluetoothConnect.Peripheral] {
        self.peripherals = BLEConnect.peripheralBLEs
        return self.peripherals
    }
    
    func connectSensor(peripheralChoice: BluetoothConnect.Peripheral) {
        BLEConnect.connectSensor(peripheralChoice: peripheralChoice)
    }
    
    @IBAction func searchSensors() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewModel.IMUnotificationSent), name: Notification.Name(rawValue: IMUnotificationKey), object: nil)
        BLEConnect.start()
    }

}
