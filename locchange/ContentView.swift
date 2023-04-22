//
//  ContentView.swift
//  locchange
//
//  Created by parkm on 2023/02/01
//

import SwiftUI
import PopupView
struct ContentView: View {

    @State var EndPopup = false
    @State var RebootWarn = false
    private let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    var body: some View {
        VStack{
            Image("Logo").resizable().frame(width: 150,height: 150)
            Text("Locchange")
                .font(.title2)
                .fontWeight(.bold)
            Menu("시작하기"){
                Button("respring") {
                    respring()
                }
                Button("reboot")
                {
                    if #available(iOS 16.0, *)
                    {
                        trigger_memmove_oob_copy()
                    }else{RebootWarn = true
                    }
                }
                
                Button("change") {
                    change(code:"LL/A",local:"US")
                    EndPopup = true
                }
                Link("support",destination: URL(string: "https://discord.gg/4CepjXqVzK")!)
                
            }
            
        }
        .popup(isPresented: $EndPopup) { // 3
                HStack { // 4
                    Spacer()
                    Text("Ended. Reboot with key combo is recommended.")
                        .font(.headline)
                        .frame(width: 400, height: 60)
                        .cornerRadius(60.0)
                        .background(Color.blue.opacity(0.3))
                    Spacer()
                }
            }
        customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.spring())
                .closeOnTapOutside(true)
                .autohideIn(5)
        }
        .popup(isPresented: $RebootWarn) {
            HStack { // 4
                Spacer()
                Text("Only Supports ios 16 or above")
                    .font(.headline)
                    .frame(width: 300, height: 40)
                    .cornerRadius(60.0)
                    .background(Color(red: 0.45, green:0, blue:0).opacity(0.4))
                Spacer()
            }
        } customize: {
            $0
                .autohideIn(5)
                .animation(.spring())
                .closeOnTapOutside(true)
        }
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
    
    func change(code: String, local: String)
    {
        
        let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
        plistChange(plistPath: dynamicPath, key: "zHeENZu+wbg7PUprwNwBWg", value: code, key2:"h63QSdBCiT/z0WU6rdQv6Q", value2: local)
        }


    
}
