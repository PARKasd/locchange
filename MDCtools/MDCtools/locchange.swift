//
//  locchange.swift
//  MDCtools
//
//  Created by parkm on 2023/02/06.
//

import SwiftUI

struct locchange: View {
    @State private var per: Float = 0.0
    private let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    var body: some View {
        NavigationView{
            
            VStack{
                Image("Logo").resizable().frame(width: 150,height: 150)
                Text("Locchange")
                    .font(.title2)
                    .fontWeight(.bold)
                Menu("시작하기"){
                    Button("시작") {
                        
                        plistChange(plistPath: dynamicPath, key: "h63QSdBCiT/z0WU6rdQv6Q", value: "US")
                        per = 0.5
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                            plistChange(plistPath: dynamicPath, key: "zHeENZu+wbg7PUprwNwBWg", value: "LL/A")
                            per = 0.9
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                                per = 1.0
                                respring()
                            }}}
                    Link("지원",destination: URL(string: "https://discord.gg/4CepjXqVzK")!)
                    
                }
                ProgressView(value: per).scaleEffect(0.7, anchor: .center)
                    
                    .padding()
            }
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
func test() {}
struct locchange_Previews: PreviewProvider {
    static var previews: some View {
        locchange()
    }
}
