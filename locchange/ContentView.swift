//
//  ContentView.swift
//  locchange
//
//  Created by parkm on 2023/02/01
//

import SwiftUI

struct ContentView: View {
    @State private var showingActionSheet = false
    
    private let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    var body: some View {
        NavigationView{
            VStack{
                Image("Logo").resizable().frame(width: 150,height: 150)
                Text("Locchange")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button("시작") {
                    plistChange(plistPath: dynamicPath, key: "h63QSdBCiT/z0WU6rdQv6Q", value: "US")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                        plistChange(plistPath: dynamicPath, key: "zHeENZu+wbg7PUprwNwBWg", value: "LL/A")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                            respring()
                        }}}.padding()
            }
            .navigationBarItems(trailing:
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "info.circle")
                }
                .confirmationDialog("Select",
                                    isPresented: $showingActionSheet,
                                    actions: {
                Link("Developed by parkm04", destination: URL(string: "https://toss.me/parkm04")!)
                Link("Designed by gamjanakg", destination: URL(string: "https://toss.me/gamjanakg")!)
                Link("Discord", destination: URL(string: "https://discord.gg/4CepjXqVzK")!)
                Button("Dismiss", role: .cancel) { }
            })
            )
        }
        }
    }


func plistChange(plistPath: String, key: String, value: String) {
    let stringsData = try! Data(contentsOf: URL(fileURLWithPath: plistPath))
    
    let plist = try! PropertyListSerialization.propertyList(from: stringsData, options: [], format: nil) as! [String: Any]
    func changeValue(_ dict: [String: Any], _ key: String, _ value: String) -> [String: Any] {
        var newDict = dict
        for (k, v) in dict {
            if k == key {
                newDict[k] = value
            } else if let subDict = v as? [String: Any] {
                newDict[k] = changeValue(subDict, key, value)
            }
        }
        return newDict
    }

    var newPlist = plist
    newPlist = changeValue(newPlist, key, value)

    let newData = try! PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0)

    overwriteFile(newData, plistPath)
}


func respring(){
    guard let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else { return }
    while true {
       window.snapshotView(afterScreenUpdates: false)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
