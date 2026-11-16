import Foundation

func fail(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

guard dlopen("/System/Library/PrivateFrameworks/SidecarCore.framework/SidecarCore", RTLD_LAZY) != nil,
      let managerClass = NSClassFromString("SidecarDisplayManager") as? NSObject.Type,
      let manager = managerClass.perform(Selector(("sharedManager")))?.takeUnretainedValue() as? NSObject,
      let devices = manager.perform(Selector(("devices")))?.takeUnretainedValue() as? [NSObject]
else { fail("SidecarCore is unavailable", 4) }

func name(_ device: NSObject) -> String {
    device.perform(Selector(("name")))?.takeUnretainedValue() as? String ?? ""
}

let wanted = CommandLine.arguments.dropFirst().first?.lowercased()
let matches = devices.filter { wanted == nil || name($0).lowercased() == wanted }
guard matches.count == 1, let device = matches.first else {
    print(devices.map(name).joined(separator: "\n"))
    fail(devices.isEmpty ? "No Sidecar devices in reach" : "Name one of the devices above", devices.isEmpty ? 2 : 3)
}

let done = DispatchSemaphore(value: 0)
var connectError: NSError?
let completion: @convention(block) (NSError?) -> Void = { error in
    connectError = error
    done.signal()
}
_ = manager.perform(Selector(("connectToDevice:completion:")), with: device, with: completion)
if done.wait(timeout: .now() + 30) == .timedOut { fail("Timed out connecting to \(name(device))", 4) }
if let connectError { fail("\(connectError)", 4) }
print("connected \(name(device))")
