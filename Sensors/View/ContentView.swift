//
//  ContentView.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-06.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var theVM : ViewModel
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Internal sensors", destination: InternalSensorView())
                NavigationLink("External sensor", destination: ExternalSensorView())
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ViewModel())
    }
}
