//
//  InternalSensorView.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-20.
//

import SwiftUI

struct InternalSensorView: View {
    @EnvironmentObject var theVM : ViewModel
    let notificationKey = "newData"
    @State private var linAccAngle: Double = 0.0
    @State private var gyroAccAngle: Double = 0.0
    @State private var save: Bool = false
    
    var body: some View {
        VStack {
            Text("Internal sensors")
                .font(.largeTitle)
            
            Spacer()
            
            Text("Linear acceleration angle: \(self.linAccAngle)")
            .onReceive(theVM.$linAccAngle, perform: { angle in
                self.linAccAngle = angle
            })
            Text("Acc + gyro angle: \(self.gyroAccAngle)")
            .onReceive(theVM.$gyroAccAngle, perform: { angle in
                self.gyroAccAngle = angle
            })
            Divider()
            HStack {
                Button {
                    theVM.saveData()
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
        .padding()
    .onAppear(perform: theVM.calcAngles)
    }

}

struct InternalSensorView_Previews: PreviewProvider {
    static var previews: some View {
        InternalSensorView()
    }
}
