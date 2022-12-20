//
//  BluetoothConnect.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-14.
//  From Jonas Github

import Foundation
import CoreBluetooth

class BluetoothConnect: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var peripheralBLE: CBPeripheral!
    public var peripheralBLEs: [Peripheral] = []
    private var names: [String] = []
    
    let GATTService = CBUUID(string: "fb005c80-02e7-f387-1cad-8acd2d8df0c8")
    let GATTCommand = CBUUID(string: "fb005c81-02e7-f387-1cad-8acd2d8df0c8")
    let GATTData = CBUUID(string: "fb005c82-02e7-f387-1cad-8acd2d8df0c8")
    
    let IMUnotificationKey = "newIMUData"
    var timestamp: Int = 0
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        @unknown default:
            print("unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("didDiscover")
        
        if let name = peripheral.name, name.contains("Polar") {
            print("Found Polar")
            peripheralBLE = peripheral
            peripheralBLE.delegate = self
            if peripheralBLEs.isEmpty {
                peripheralBLEs.append(Peripheral(id: peripheralBLEs.count, peripheral: peripheralBLE, pname: peripheralBLE.name!))
                names.append(peripheralBLE.name!)
            } else {
                if names.contains(peripheralBLE.name!) == false {
                    peripheralBLEs.append(Peripheral(id: peripheralBLEs.count, peripheral: peripheralBLE, pname: peripheralBLE.name!))
                    names.append(peripheralBLE.name!)
                }
            }
        }
    }
    
    func connectSensor(peripheralChoice: Peripheral) {
        print(peripheralChoice.pname)
        centralManager.connect(peripheralChoice.peripheral)
        centralManager.stopScan()
        peripheralBLEs.removeAll()
        names.removeAll()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("didConnect")
           peripheral.discoverServices(nil)
           central.scanForPeripherals(withServices: [GATTService], options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
         for service in peripheral.services!{
             print("Service Found")
             peripheral.discoverCharacteristics([GATTData, GATTCommand], for: service)
         }
     }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristics")
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == GATTData {
                print("Data")
                peripheral.setNotifyValue(true, for:characteristic)
            }
            if characteristic.uuid == GATTCommand{
                print("Command")
                
                //let parameter:[UInt8]  = [0x02, 0x00, 0x00, 0x01, 0x82, 0x00, 0x01, 0x01, 0x0E, 0x00]
                
                let parameter:[UInt8]  = [0x02, 0x02, 0x00, 0x01, 0x34, 0x00, 0x01, 0x01, 0x10, 0x00, 0x02, 0x01, 0x08, 0x00, 0x04, 0x01, 0x03]
                
       
          
                // 02 02 00 01
                // 34 00 01 01
                // 10 00 02 01
                // 08 00 04 01 03
                
                //let parameter:[UInt8]  = [0x02, 0x02]
                
                let data = NSData(bytes: parameter, length: 17)
        
                peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("New data")
        let data = characteristic.value
        var byteArray: [UInt8] = []
        for i in data! {
            let n : UInt8 = i
            byteArray.append(n)
        }
        
        //print(byteArray)
        
        var offset = 0
        let measId = data![offset]
        offset += 1
        
        let timeBytes = data!.subdata(in: 1..<9) as NSData
        var timeStamp: UInt64 = 0
        memcpy(&timeStamp,timeBytes.bytes,8)
        offset += 8
        
        let frameType = data![offset]
        offset += 1
        
        print("MessageID:\(measId) Time:\(timeStamp) Frame Type:\(frameType)")
        
        
        let xBytes = data!.subdata(in: offset..<offset+2) as NSData
        var xSample: Int16 = 0
        memcpy(&xSample,xBytes.bytes,2)
        offset += 2
        
        let yBytes = data!.subdata(in: offset..<offset+2) as NSData
        var ySample: Int16 = 0
        memcpy(&ySample,yBytes.bytes,2)
        offset += 2
        
        let zBytes = data!.subdata(in: offset..<offset+2) as NSData
        var zSample: Int16 = 0
        memcpy(&zSample,zBytes.bytes,2)
        offset += 2
        
        print("xRef:\(xSample >> 11) yRef:\(ySample >> 11) zRef:\(zSample >> 11)")
        
        let deltaSize = UInt16(data![offset])
        offset += 1
        let sampleCount = UInt16(data![offset])
        offset += 1
        
        print("deltaSize:\(deltaSize) Sample Count:\(sampleCount)")

        let bitLength = (sampleCount*deltaSize*UInt16(3))
        let length = Int(ceil(Double(bitLength)/8.0))
        let frame = data!.subdata(in: offset..<(offset+length))

        let deltas = BluetoothConnect.parseDeltaFrame(frame, channels: UInt16(3), bitWidth: deltaSize, totalBitLength: bitLength)
        
        deltas.forEach { (delta) in
            xSample = xSample + delta[0];
            ySample = ySample + delta[1];
            zSample = zSample + delta[2];
            
            self.timestamp = Int(timeStamp)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: IMUnotificationKey), object: [Double(ySample),Double(zSample),Double(self.timestamp)])
        }
    }
    
   
    static func parseDeltaFrame(_ data: Data, channels: UInt16, bitWidth: UInt16, totalBitLength: UInt16) -> [[Int16]]{
        // convert array to bits
        let dataInBits = data.flatMap { (byte) -> [Bool] in
            return Array(stride(from: 0, to: 8, by: 1).map { (index) -> Bool in
                return (byte & (0x01 << index)) != 0
            })
        }
        
        let mask = Int16.max << Int16(bitWidth-1)
        let channelBitsLength = bitWidth*channels
        
        return Array(stride(from: 0, to: totalBitLength, by: UInt16.Stride(channelBitsLength)).map { (start) -> [Int16] in
            return Array(stride(from: start, to: UInt16(start+UInt16(channelBitsLength)), by: UInt16.Stride(bitWidth)).map { (subStart) -> Int16 in
                let deltaSampleList: ArraySlice<Bool> = dataInBits[Int(subStart)..<Int(subStart+UInt16(bitWidth))]
                var deltaSample: Int16 = 0
                var i=0
                deltaSampleList.forEach { (bitValue) in
                    let bit = Int16(bitValue ? 1 : 0)
                    deltaSample |= (bit << i)
                    i += 1
                }
                
                if((deltaSample & mask) != 0) {
                    deltaSample |= mask;
                }
                return deltaSample
            })
        })
    }
    
    override init(){
        super.init()
    }
    
    func start(){
        print("centralManager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    struct Peripheral: Identifiable {
        var id: Int
        var peripheral: CBPeripheral
        var pname: String
    }
}
