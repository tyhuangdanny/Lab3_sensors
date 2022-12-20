//
//  Model.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-08.
//

import Foundation
import CoreMotion

class Model {
    var BLEConnect = BluetoothConnect()
    var linAccAngles: [Double] = []
    var gyroAccAngles: [Double] = []
    var timestamps: [Double] = []
    var timestamp: Double = 0
    var linAccAngle: Double = 0
    var xLinAcc = EMWAfilter(value: 0.0)
    var yLinAcc = EMWAfilter(value: 0.0)
    var gyroAngle = GyroAngle(value: 0.0)
    var accAngle = AccAngle(value: 0.0)
    var gyroAccAngle: Double = 0
    var manager = CMMotionManager()
    let notificationKey = "newData"
    var timer = Timer()
    var timerStopped: Bool = false
    
    var IMUlinAccAngle: Double = 0
    var IMUyLinAcc = EMWAfilter(value: 0.0)
    var IMUzLinAcc = EMWAfilter(value: 0.0)
    var IMUlinAccAngles: [Double] = []
    let IMUnotificationKey = "newIMUData"
    var IMUtimer = Timer()
    var IMUtimerstopped: Bool = false
    var IMUtimestamps: [Int] = []
    var IMUtimestamp: Int = 0
    
    func calcAngles() {
        if manager.isGyroAvailable {
            manager.gyroUpdateInterval = 0.1
            manager.startGyroUpdates(to: .main) { [weak self] (data,error) in
                
                guard let s = self else { return }
                
                s.gyroAngle.gyroAngle(newZGyro: (data?.rotationRate.z)!)
            }
        }
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 0.1
            manager.startAccelerometerUpdates(to: .main) { [weak self] (data,error) in
                
                guard let s = self else { return }
                
                // Linear Acceleration
                s.xLinAcc.EMWA(newValue: (data?.acceleration.x)!)
                s.yLinAcc.EMWA(newValue: (data?.acceleration.y)!)
                
                s.linAccAngle = (atan(-s.xLinAcc.value/s.yLinAcc.value))*180 / .pi
                
                // Acceleration + Gyro
                s.accAngle.accAngle(newXAcc: (data?.acceleration.x)!, newYAcc: (data?.acceleration.y)!)
                
                // Complementary filter
                let F = 0.95
                s.gyroAccAngle = (F*s.accAngle.value + (1-F)*s.gyroAngle.value)
                
                self?.timestamp = data!.timestamp
                
                NotificationCenter.default.post(name: Notification.Name(self!.notificationKey), object: [s.linAccAngle,s.gyroAccAngle])
            }
        }
    }
    
    func calcIMUAngles(accData: [Double]) -> Double {
        IMUyLinAcc.EMWA(newValue: accData[0])
        IMUzLinAcc.EMWA(newValue: accData[1])
        IMUtimestamp = Int(accData[2])

        self.IMUlinAccAngle = (atan(-self.IMUzLinAcc.value/self.IMUyLinAcc.value))*180 / .pi
        
        return self.IMUlinAccAngle
    }
    
    func saveData() {
        var count = 0
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true) { timer in
            self.linAccAngles.append(self.linAccAngle)
            self.gyroAccAngles.append(self.gyroAccAngle)
            self.timestamps.append(self.timestamp)
            
            count += 1
            
            print(count)
            
            if count == 100 || self.timerStopped {
                timer.invalidate()
                let fileManager = FileManager.default
                let urls = fileManager.urls(for: .documentDirectory,in: .userDomainMask)
                
                if let url = urls.first {
                    var fileURL = url.appendingPathComponent("linAccAngle_data")
                    fileURL = fileURL.appendingPathExtension("json")
                    do {
                        let data = try JSONSerialization.data(withJSONObject: self.linAccAngles,options: [.prettyPrinted])
                        try data.write(to: fileURL,options: .noFileProtection)
                        print(fileURL)
                        self.timerStopped = false
                    } catch {
                        print("error")
                    }
                }
                if let url = urls.first {
                    var fileURL = url.appendingPathComponent("gyroAccAngle_data")
                    fileURL = fileURL.appendingPathExtension("json")
                    do {
                        let data = try JSONSerialization.data(withJSONObject: self.gyroAccAngles,options: [.prettyPrinted])
                        try data.write(to: fileURL,options: .noFileProtection)
                        print(fileURL)
                        self.timerStopped = false
                    } catch {
                        print("error")
                    }
                }
                if let url = urls.first {
                    var fileURL = url.appendingPathComponent("timestamp_data")
                    fileURL = fileURL.appendingPathExtension("json")
                    do {
                        let data = try JSONSerialization.data(withJSONObject: self.timestamps,options: [.prettyPrinted])
                        try data.write(to: fileURL,options: .noFileProtection)
                        print(fileURL)
                        self.timerStopped = false
                    } catch {
                        print("error")
                    }
                }
            }
        }
    }
    
    func saveIMUData() {
        var count = 0
        IMUtimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true) { timer in
            self.IMUlinAccAngles.append(self.IMUlinAccAngle)
            self.IMUtimestamps.append(self.IMUtimestamp)
            
            count += 1
            
            if count == 100 || self.IMUtimerstopped {
                self.IMUtimer.invalidate()
                let fileManager = FileManager.default
                let urls = fileManager.urls(for: .documentDirectory,in: .userDomainMask)
                
                if let url = urls.first {
                    var fileURL = url.appendingPathComponent("IMUAngle_data")
                    fileURL = fileURL.appendingPathExtension("json")
                    do {
                        let data = try JSONSerialization.data(withJSONObject: self.IMUlinAccAngles,options: [.prettyPrinted])
                        try data.write(to: fileURL,options: .noFileProtection)
                        print(fileURL)
                        self.IMUtimerstopped = false
                    } catch {
                        print("error")
                    }
                }

                if let url = urls.first {
                    var fileURL = url.appendingPathComponent("IMUtimestamps_data")
                    fileURL = fileURL.appendingPathExtension("json")
                    do {
                        let data = try JSONSerialization.data(withJSONObject: self.IMUtimestamps,options: [.prettyPrinted])
                        try data.write(to: fileURL,options: .noFileProtection)
                        print(fileURL)
                        self.IMUtimerstopped = false
                    } catch {
                        print("error")
                    }
                }
            }
        }
    }
    
    func stopSaving() {
        self.timerStopped = true
        self.timer.invalidate()
        self.saveData()
    }
    
    func stopSavingIMU() {
        self.IMUtimerstopped = true
        self.IMUtimer.invalidate()
        self.saveIMUData()
    }
    
    func getLinAccAngle() -> Double {
        return self.linAccAngle
    }
    
    struct EMWAfilter {
        var value: Double
        let F = 0.1
        
        mutating func EMWA(newValue: Double) {
            value = F*value + (1-F)*newValue
        }
    }
    
    struct GyroAngle {
        var value: Double
        let dt: Double = 1/52
        
        mutating func gyroAngle(newZGyro: Double) {
            value = value + dt*newZGyro
        }
    }
    
    struct AccAngle {
        var value: Double
        
        mutating func accAngle(newXAcc: Double,newYAcc: Double) {
            value = (atan(-newXAcc/newYAcc))*180 / .pi
        }
    }
}


