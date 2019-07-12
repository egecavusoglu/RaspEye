//
//  cameraViewController.swift
//  RaspEye
//
//  Created by Ege Çavuşoğlu on 7/9/19.
//  Copyright © 2019 Ege Çavuşoğlu. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox
import Photos

class CameraViewController: UIViewController {
    
    // constants
    let READ_SIZE = 16384
    let MAX_READ_ERRORS = 300
    let FADE_OUT_WAIT_TIME = 8.0
    let FADE_OUT_INTERVAL = 1.0
    let FADE_IN_INTERVAL = 0.1

    @IBOutlet weak var errorTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) {
            // Camera session has ended.
            
        }
    }
   
    // instance variables
    var camera: Camera?
    var fadeOutTimer: Timer?
    var running = false
    var close = false
    var dispatchGroup = DispatchGroup()
    var zoomPan: ZoomPan?
    let app = UIApplication.shared.delegate as! AppDelegate
    var formatDescription: CMVideoFormatDescription?
    var videoSession: VTDecompressionSession?
    var fullsps: [UInt8]?
    var fullpps: [UInt8]?
    var sps: [UInt8]?
    var pps: [UInt8]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        zoomPan = ZoomPan(imageView)
        UIApplication.shared.isIdleTimerDisabled = true
        app.videoViewController = self
        start()
    }
    
    func start() {
        imageView.image = nil
        
        // start reading the stream and decoding the video
        if createReadThread()
        {
            // fade out after a while
            startFadeOutTimer()
        }
        
        // start listening for orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    
    func createReadThread() -> Bool{
        if camera == nil
        {
            statusError("errorNoCamera".local)
            return false
        }
        
        var address = camera!.address
        if !Utils.isIpAddress(address)
        {
            address = Utils.resolveHostname(address)
            if address.isEmpty
            {
                let message = String(format: "errorCouldntResolveHostname".local, camera!.address)
                statusError(message)
                return false
            }
        }
        
        DispatchQueue.global(qos: .background).async
            {
                self.dispatchGroup.enter()
                self.dispatchGroup.notify(queue: .main)
                {
                    self.stopVideo()
                }
                let socket = openSocket(address, Int32(self.camera!.port), Int32(self.app.settings.scanTimeout))
                if (socket >= 0) // ?
                {
                    var numZeroes = 0
                    var numReadErrors = 0
                    var nal = [UInt8]()
                    let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: self.READ_SIZE)
                    let buffer = UnsafeMutableBufferPointer.init(start: ptr, count: self.READ_SIZE)
                    var gotHeader = false
                    self.running = true
                    while self.running && numReadErrors < self.MAX_READ_ERRORS
                    {
                        let len = readSocket(socket, ptr, Int32(self.READ_SIZE))
                        if len > 0
                        {
                            numReadErrors = 0
                            for i in 0..<len
                            {
                                let b = buffer[Int(i)]
                                if !self.running { break }
                                if b == 0
                                {
                                    numZeroes += 1
                                }
                                else
                                {
                                    if b == 1 && numZeroes >= 3
                                    {
                                        while numZeroes > 3
                                        {
                                            nal.append(0)
                                            numZeroes -= 1
                                        }
                                        if gotHeader
                                        {
                                            if !self.running { break }
                                            self.processNal(&nal)
                                        }
                                        nal = [0, 0, 0, 1]
                                        gotHeader = true
                                    }
                                    else
                                    {
                                        while numZeroes > 0
                                        {
                                            nal.append(0)
                                            numZeroes -= 1
                                        }
                                        nal.append(b)
                                    }
                                    numZeroes = 0
                                }
                            }
                        }
                        else
                        {
                            numReadErrors += 1
                        }
                    }
                    closeSocket(socket)
                    ptr.deallocate()
                }
                self.dispatchGroup.leave()
        }
        
        return true
    }
    func startFadeOutTimer()
    {
        stopFadeOutTimer()
        fadeOutTimer = Timer.scheduledTimer(timeInterval: FADE_OUT_WAIT_TIME, target: self, selector: #selector(fadeOut), userInfo: nil, repeats: false)
    }
    func stopFadeOutTimer()
    {
        if let timer = fadeOutTimer, timer.isValid
        {
            timer.invalidate()
        }
        fadeOutTimer = nil
    }
    
    
    @objc func orientationDidChange()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute:
            {
                self.zoomPan?.reset()
        })
    }
    
    func statusError(_ message: String)
    {
        stopFadeOutTimer()
    }
    
    func stopVideo()
    {
        // stop listening for orientation changes
        NotificationCenter.default.removeObserver(self)
        
        // stop fading out the controls
        stopFadeOutTimer()
        
        // terminate the video processing
        destroyVideoSession()
        
        // set the status label
        statusError("videoStopped".local)
        
        // close the controller if necessary
        if close
        {
            dismiss(animated: true)
        }
    }
    
    func processNal(_ nal: inout [UInt8])
    {
        // replace the start code with the NAL size
        let len = nal.count - 4
        var lenBig = CFSwapInt32HostToBig(UInt32(len))
        memcpy(&nal, &lenBig, 4)
        
        // create the video session when we have the SPS and PPS records
        let nalType = nal[4] & 0x1F
        if nalType == 7
        {
            fullsps = nal
        }
        else if nalType == 8
        {
            fullpps = nal
        }
        if fullsps != nil && fullpps != nil
        {
            destroyVideoSession()
            sps = Array(fullsps![4...])
            pps = Array(fullpps![4...])
            _ = createVideoSession()
            fullsps = nil
            fullpps = nil
            DispatchQueue.main.async
                {
                    //self.statusLabel.isHidden = true
            }
        }
        
        // decode the video NALs
        if videoSession != nil && (nalType == 1 || nalType == 5)
        {
            _ = decodeNal(nal)
        }
    }
    
    
    
    @objc func fadeOut()
    {
        stopFadeOutTimer()
        UIView.animate(withDuration: FADE_OUT_INTERVAL, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations:
            {
//                self.statusLabel.alpha = 0.0
//                self.nameLabel.alpha = 0.0
//                self.closeButton.alpha = 0.0
//                self.snapshotButton.alpha = 0.0
        },
                       completion: nil)
    }
    
    func destroyVideoSession()
    {
        if let session = videoSession
        {
            VTDecompressionSessionWaitForAsynchronousFrames(session)
            VTDecompressionSessionInvalidate(session)
            videoSession = nil
        }
        sps = nil
        pps = nil
        formatDescription = nil
    }
    
    private func createVideoSession() -> Bool
    {
        // create a new format description with the SPS and PPS records
        formatDescription = nil
        let parameters = [UnsafePointer<UInt8>(pps!), UnsafePointer<UInt8>(sps!)]
        let sizes = [pps!.count, sps!.count]
        var status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: UnsafePointer(parameters), parameterSetSizes: sizes, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDescription)
        if status != noErr
        {
            return false
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
        DispatchQueue.main.async
            {
                self.zoomPan?.setVideoSize(CGFloat(dimensions.width), CGFloat(dimensions.height))
        }
        
        // create the decoder parameters
        let decoderParameters = NSMutableDictionary()
        let destinationPixelBufferAttributes = NSMutableDictionary()
        destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
        
        // create the callback for getting snapshots
        var callback = VTDecompressionOutputCallbackRecord()
        callback.decompressionOutputCallback = globalDecompressionCallback
        callback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // create the video session
        status = VTDecompressionSessionCreate(allocator: nil, formatDescription: formatDescription!, decoderSpecification: decoderParameters, imageBufferAttributes: destinationPixelBufferAttributes, outputCallback: &callback, decompressionSessionOut: &videoSession)
        return status == noErr
    }
    
    private func decodeNal(_ nal: [UInt8]) -> Bool
    {
        // create the block buffer from the NAL data
        var blockBuffer: CMBlockBuffer? = nil
        let nalPointer = UnsafeMutablePointer<UInt8>(mutating: nal)
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nalPointer, blockLength: nal.count, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: nal.count, flags: 0, blockBufferOut: &blockBuffer)
        if status != kCMBlockBufferNoErr
        {
            return false
        }
        
        // create the sample buffer from the block buffer
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [nal.count]
        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, formatDescription: formatDescription, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)
        if status != noErr
        {
            return false
        }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, createIfNecessary: true)
        {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        
        // pass the sample buffer to the decoder
        if let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0
        {
            var infoFlags = VTDecodeInfoFlags(rawValue: 0)
            status = VTDecompressionSessionDecodeFrame(videoSession!, sampleBuffer: buffer, flags: ._EnableAsynchronousDecompression, frameRefcon: nil, infoFlagsOut: &infoFlags)
        }
        return true
    }
    func decompressionCallback(_ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime)
    {
        if running, let cvImageBuffer = imageBuffer
        {
            let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
            let size = CVImageBufferGetEncodedSize(cvImageBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: CGRect(origin: CGPoint.zero, size: size))
            {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async
                    {
                        self.imageView.image = uiImage
                }
            }
        }
    }
    
}

//**********************************************************************
// globalDecompressionCallback
//**********************************************************************
private func globalDecompressionCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) -> Void
{
    let videoController: CameraViewController = unsafeBitCast(decompressionOutputRefCon, to: CameraViewController.self)
    videoController.decompressionCallback(sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, presentationDuration)
}
