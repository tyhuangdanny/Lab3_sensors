//
//  SensorsApp.swift
//  Sensors
//
//  Created by Elsa Netz on 2022-12-06.
//

import SwiftUI

@main
struct SensorsApp: App {
    @EnvironmentObject var theVM : ViewModel
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(ViewModel())
        }
    }
}
