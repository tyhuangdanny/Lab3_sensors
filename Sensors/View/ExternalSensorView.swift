//
//  ExternalSensorView.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-15.
//

import SwiftUI

struct ExternalSensorView: View {
    @EnvironmentObject var theVM : ViewModel
    @State private var IMUAngle: Double = 0.0
    
    var body: some View {
        VStack {
            Text("External sensor")
                .font(.largeTitle)
            
            Spacer()
            
            Menu("Connect sensor") {
                ForEach(theVM.getSensors()) { p in
                    Button {
                        theVM.connectSensor(peripheralChoice: p)
                    } label: {
                        Text("\(p.pname)")
                    }
                }
            }
            .onAppear(perform: theVM.searchSensors)
            
            Text("Linear acceleration angle: \(self.IMUAngle)")
                .onReceive(theVM.$IMUAngle, perform: { angle in
                    self.IMUAngle = angle
                })
            Divider()
            HStack {
                Button {
                    theVM.saveIMUData()
                } label: {
                    Text("Save data")
                }
                .buttonStyle(.bordered)
                Button {
                    theVM.stopSaving()
                } label: {
                    Text("Stop saving")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            Divider()
            Spacer()
        }
    }
}

struct ExternalSensorView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalSensorView().environmentObject(ViewModel())
    }
}
