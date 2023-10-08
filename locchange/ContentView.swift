//
//  ContentView.swift
//  locchange
//
//  Created by parkm on 2023/02/01
//

import SwiftUI

struct ContentView: View {
    @AppStorage("Bakcode") var Bakcode: String = ""
    @AppStorage("Bakregion") var Bakregion: String = ""
    @State private var Avail = false
    @State var EndPopup = false
    @State var respringinfo = false
    @State var bakinfo = false
    @State var Customcode: String = ""
    @State var Customregion: String = ""
    @State var selafter = ""
    var body: some View {

        TabView {
            VStack{
                Image("Logo").resizable().frame(width: 150,height: 150)
                Text("region code to LL/A").padding()
                Button("Run") {
                    change(code:"LL/A",region:"US")
                    EndPopup = true
                }}.padding()
                .buttonStyle(.borderedProminent)
                .cornerRadius(10)
                .tint(.blue)
                .tabItem{
                    Image(systemName: "1.square.fill")
                    Text("Run")
                }
            VStack{
                Text("Wrong Combo may bootloop your device!").fontWeight(.bold).padding()
                TextField("Enter your region ex) US,KH,J,C", text: $Customregion).padding()
                TextField("Enter your code ex) LL/A,KH/A,J/A", text: $Customcode).padding()
                Button("Run"){
                    change(code: Customcode, region: Customregion)
                    EndPopup = true
                }}.padding()
                .buttonStyle(.borderedProminent)
                .cornerRadius(10)
                .tint(.red)

            .tabItem{
                Image(systemName: "2.square.fill")
                Text("Advanced")
            }
            VStack{
                Button("Backup current") {
                    let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
                    let stringsData = try! Data(contentsOf: URL(fileURLWithPath: dynamicPath))
                    var plist = try! PropertyListSerialization.propertyList(from: stringsData, options: [], format: nil) as! [String: Any]
                    plist = plist["CacheExtra"] as! [String: Any]
                    Bakcode = plist["zHeENZu+wbg7PUprwNwBWg"] as! String
                    Bakregion = plist["h63QSdBCiT/z0WU6rdQv6Q"] as! String
                    bakinfo = true
                }.padding()
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(10)
                    .tint(.green)

                Button("Check Backup")
                {
                    bakinfo = true
                }.padding()
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(10)
                    .tint(.blue)

                Button("Restore Backup"){
                    change(code:Bakcode, region:Bakregion)
                    EndPopup = true
                }.padding()
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(10)
                    .tint(.blue)

            }
            .tabItem{
                Image(systemName: "3.square.fill")
                Text("Backup")
            }
            
            VStack{
                Text("Developed by parkm").padding()
                Text("Some functions were from Dynamic Cow")
                Link("GitHub", destination: URL(string: "https://github.com/PARKasd/locchange")!)
            }
                .tabItem{
                    Image(systemName: "4.square.fill")
                    Text("Credit")
                }
        }
            .alert("Backup Info", isPresented: $bakinfo)
            {
                
            } message: {Text("\(Bakcode) and \(Bakregion) Saved!")}
            
            
            .alert("After action", isPresented: $EndPopup)
            {
                Button("Respring") {respring()}
                Button("Nothing", role: .cancel) {respringinfo = true}
            }
            
            
            .alert("Ended", isPresented: $respringinfo)
            {
                Button("OK"){}
                    
            } message: {Text("Rebooting or Respring is needed.")}
            
          
                
        }

    
        
        
    


    func overwriteFile(originPath: String, replacementData: Data) -> Bool {
#if false
        let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].path
        
        let pathToRealTarget = originPath
        let originPath = documentDirectory + originPath
        let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTarget))
        try! origData.write(to: URL(fileURLWithPath: originPath))
#endif
        
        // open and map original font
        let fd = open(originPath, O_RDONLY | O_CLOEXEC)
        if fd == -1 {
            print("Could not open target file")
            return false
        }
        defer { close(fd) }
        // check size of font
        let originalFileSize = lseek(fd, 0, SEEK_END)
        guard originalFileSize >= replacementData.count else {
            print("Original file: \(originalFileSize)")
            print("Replacement file: \(replacementData.count)")
            print("File too big")
            return false
        }
        lseek(fd, 0, SEEK_SET)
        
        // Map the font we want to overwrite so we can mlock it
        let fileMap = mmap(nil, replacementData.count, PROT_READ, MAP_SHARED, fd, 0)
        if fileMap == MAP_FAILED {
            print("Failed to map")
            return false
        }
        // mlock so the file gets cached in memory
        guard mlock(fileMap, replacementData.count) == 0 else {
            print("Failed to mlock")
            return true
        }
        
        // for every 16k chunk, rewrite
        print(Date())
        for chunkOff in stride(from: 0, to: replacementData.count, by: 0x4000) {
            print(String(format: "%lx", chunkOff))
            let dataChunk = replacementData[chunkOff..<min(replacementData.count, chunkOff + 0x4000)]
            var overwroteOne = false
            for _ in 0..<2 {
                let overwriteSucceeded = dataChunk.withUnsafeBytes { dataChunkBytes in
                    return unaligned_copy_switch_race(
                        fd, Int64(chunkOff), dataChunkBytes.baseAddress, dataChunkBytes.count)
                }
                if overwriteSucceeded {
                    overwroteOne = true
                    break
                }
                print("try again?!")
            }
            guard overwroteOne else {
                print("Failed to overwrite")
                return false
            }
        }
        print(Date())
        return true
    }
    func respring()
    {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else { return }
        while true {
            window.snapshotView(afterScreenUpdates: false)
        }}

    func plistChange(plistPath: String, key: String, value: String, key2: String, value2: String) {
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
        sleep(7)
        newPlist = changeValue(newPlist, key2, value2)
        
        let newData = try! PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0)
        
        if overwriteFile(originPath: plistPath, replacementData: newData) {
            // all actions completed
            DispatchQueue.main.asyncAfter(deadline: .now()){
            }
        }
    }
    //credit: DynamicCow
    func change(code: String, region: String)
    {
        
        let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
        plistChange(plistPath: dynamicPath, key: "zHeENZu+wbg7PUprwNwBWg", value: code, key2:"h63QSdBCiT/z0WU6rdQv6Q", value2: region)
        }
}

