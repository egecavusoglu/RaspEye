// Copyright © 2017-2019 Shawn Baker using the MIT License.
import Foundation
import SystemConfiguration.CaptiveNetwork
import UIKit

class Utils
{
    // public constants
    static let badTextColor = UIColor.red
    static let goodTextColor = UIColor.init(red: 0, green: CGFloat(192) / 255.0, blue: 0, alpha: 1)
    static let primaryColor = UIColor.init(red: CGFloat(214) / 255.0, green: CGFloat(25) / 255.0, blue: CGFloat(25) / 255.0, alpha: 1)
    static let ipAddressRegexString = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
    static let hostnameRegexString = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
    static let ipAddressRegex = try! NSRegularExpression(pattern: ipAddressRegexString)
    static let hostnameRegex = try! NSRegularExpression(pattern: hostnameRegexString)
    
    //**********************************************************************
    // getNetworkName
    //**********************************************************************
    class func getNetworkName() -> String
    {
        var ssid = ""
        if let interfaces = CNCopySupportedInterfaces() as NSArray?
        {
            for interface in interfaces
            {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary?
                {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as! String
                    break
                }
            }
        }
        return ssid
    }
    
    //**********************************************************************
    // connectedToNetwork
    //**********************************************************************
    class func connectedToNetwork() -> Bool
    {
        let name = getNetworkName();
        return !name.isEmpty;
    }
    
    //**********************************************************************
    // getNetworkInterfaces
    //**********************************************************************
    class func getNetworkInterfaces() -> [NetworkInterface]
    {
        var interfaces = [NetworkInterface]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0
        {
            var ptr = ifaddr
            while ptr != nil
            {
                defer { ptr = ptr?.pointee.ifa_next }
                
                if let interface = ptr?.pointee
                {
                    let family = interface.ifa_addr.pointee.sa_family
                    if family == UInt8(AF_INET) || family == UInt8(AF_INET6)
                    {
                        let flags = interface.ifa_flags
                        let name = String(cString: (interface.ifa_name)!)
                        var cAddress = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &cAddress, socklen_t(cAddress.count), nil, socklen_t(0), NI_NUMERICHOST)
                        let address = String(cString: cAddress)
                        var cNetmask = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_netmask, socklen_t(interface.ifa_netmask.pointee.sa_len), &cNetmask, socklen_t(cNetmask.count), nil, socklen_t(0), NI_NUMERICHOST)
                        let netmask = String(cString: cNetmask)
                        interfaces.append(NetworkInterface(name, flags, family, address, netmask))
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return interfaces
    }
    
    //**********************************************************************
    // getWirelessAddress
    //**********************************************************************
    class func getWirelessInterface() -> NetworkInterface
    {
        let upAndRunning = UInt32(IFF_UP | IFF_RUNNING)
        let interfaces = getNetworkInterfaces()
        for interface in interfaces
        {
            if interface.name == "en0" && interface.family == UInt8(AF_INET) &&
                (interface.flags & upAndRunning) == upAndRunning
            {
                return interface
            }
        }
        return NetworkInterface()
    }
    
    //**********************************************************************
    // getIPAddress
    //**********************************************************************
    class func getIPAddress() -> String
    {
        return getWirelessInterface().address
    }
    
    //**********************************************************************
    // getBaseIPAddress
    //**********************************************************************
    class func getBaseIPAddress(_ ipAddress: String) -> String
    {
        var address = ipAddress
        if !address.isEmpty, let i = address.range(of: ".", options: .backwards)?.lowerBound
        {
            address = String(address[...i])
        }
        return address
    }
    
    //**********************************************************************
    // isIpAddress
    //**********************************************************************
    class func isIpAddress(_ address: String) -> Bool
    {
        let range = NSRange(location: 0, length: address.utf16.count)
        return ipAddressRegex.firstMatch(in: address, options: [], range: range) != nil
    }
    
    //**********************************************************************
    // isHostname
    //**********************************************************************
    class func isHostname(_ address: String) -> Bool
    {
        let range = NSRange(location: 0, length: address.utf16.count)
        return hostnameRegex.firstMatch(in: address, options: [], range: range) != nil
    }
    
    //**********************************************************************
    // resolveHostname
    //**********************************************************************
    class func resolveHostname(_ hostname: String) -> String
    {
        var address = ""
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let addr = addresses.firstObject as? NSData
        {
            var name = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(addr.length),
                           &name, socklen_t(name.count), nil, 0, NI_NUMERICHOST) == 0
            {
                address = String(cString: name)
            }
        }
        return address
    }
    
    //**********************************************************************
    // getNetworkCameras
    //**********************************************************************
    class func getNetworkCameras(_ network: String, _ includeHostnames: Bool) -> [Camera]
    {
        var networkCameras = [Camera]()
        if !network.isEmpty
        {
            let app = UIApplication.shared.delegate as! AppDelegate
            for camera in app.cameras
            {
                let isIp = isIpAddress(camera.address)
                if (isIp && camera.network == network) || (!isIp && includeHostnames)
                {
                    networkCameras.append(camera)
                }
            }
        }
        
        return networkCameras
    }
    
    //**********************************************************************
    // getDefaultCameraName
    //**********************************************************************
    class func getDefaultCameraName() -> String
    {
        let app = UIApplication.shared.delegate as! AppDelegate
        return app.settings.cameraName
    }
    
    //**********************************************************************
    // getMaxCameraNumber
    //**********************************************************************
    class func getMaxCameraNumber(_ cameras: [Camera]) -> Int
    {
        var max = 0
        let defaultName = getDefaultCameraName() + " "
        for camera in cameras
        {
            if camera.name.hasPrefix(defaultName)
            {
                let index = camera.name.index(camera.name.startIndex, offsetBy: defaultName.count)
                if let num = Int(camera.name[index...]), num > max
                {
                    max = num
                }
            }
        }
        return max
    }
    
    //**********************************************************************
    // getNextCameraName
    //**********************************************************************
    class func getNextCameraName(_ cameras: [Camera]) -> String
    {
        return getDefaultCameraName() + " " + String(getMaxCameraNumber(cameras) + 1)
    }
    
    //**********************************************************************
    // getSnapshot
    //**********************************************************************
    class func getSnapshot(_ view: UIView) -> UIImage? {
        var image: UIImage? = nil
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image;
    }
    
    //**********************************************************************
    // getIntTextField
    //**********************************************************************
    class func getIntTextField(_ vc: UIViewController, _ intField: IntTextField, _ name: String) -> Int?
    {
        // make sure there's a value
        guard let value = intField.value else
        {
            let message = String(format: "errorNoValue".local, name.local)
            error(vc, message)
            return nil
        }
        
        // make sure it's in range
        guard value >= intField.min && value <= intField.max else
        {
            let message = String(format: "errorValueOutOfRange".local, name.local, intField.min, intField.max)
            error(vc, message)
            return nil
        }
        
        // return the value
        return value
    }
    
    //**********************************************************************
    // error
    //**********************************************************************
    class func error(_ vc: UIViewController, _ message: String)
    {
        let alert = UIAlertController(title: "error".local, message: message.local, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "ok".local, style: UIAlertAction.Style.default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
}
