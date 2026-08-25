import CoreMediaIO
import CoreMedia
import CoreVideo
import Foundation
import OSLog

let source = ProviderSource()
let provider = CMIOExtensionProvider(source: source, clientQueue: nil)
source.provider = provider
CMIOExtensionProvider.startService(provider: provider)
RunLoop.main.run()

final class ProviderSource: NSObject, CMIOExtensionProviderSource {
    weak var provider: CMIOExtensionProvider? { didSet { buildDevice() } }
    private var deviceSource: DeviceSource?
    var availableProperties: Set<CMIOExtensionProperty> { [] }
    func connect(to client: CMIOExtensionClient) throws {}
    func disconnect(from client: CMIOExtensionClient) {}
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties { .init(dictionary: [:]) }
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}
    private func buildDevice() {
        guard let provider else { return }
        let ds=DeviceSource(); let device=CMIOExtensionDevice(localizedName:"Blusher Camera",deviceID:UUID(uuidString:"6D9D7F5C-4994-4D57-8BC6-69086B57A111")!,legacyDeviceID:"com.nixboi42.Blusher.Camera",source:ds); ds.device=device
        do { try provider.addDevice(device); deviceSource=ds } catch { Logger(subsystem:"com.nixboi42.Blusher.CameraExtension",category:"virtualCamera").error("Add device failed: \(error.localizedDescription)") }
    }
}

final class DeviceSource:NSObject,CMIOExtensionDeviceSource {
    weak var device:CMIOExtensionDevice? { didSet { buildStreams() } }
    private var relay:RelaySource?
    var availableProperties:Set<CMIOExtensionProperty>{[]}
    func deviceProperties(forProperties properties:Set<CMIOExtensionProperty>) throws->CMIOExtensionDeviceProperties{.init(dictionary:[:])}
    func setDeviceProperties(_ deviceProperties:CMIOExtensionDeviceProperties)throws{}
    private func buildStreams(){ guard let device else{return}; var desc:CMFormatDescription?; CMVideoFormatDescriptionCreate(allocator:kCFAllocatorDefault,codecType:kCVPixelFormatType_32BGRA,width:1280,height:720,extensions:nil,formatDescriptionOut:&desc); guard let desc else{return}; let duration=CMTime(value:1,timescale:30); let format=CMIOExtensionStreamFormat(formatDescription:desc,maxFrameDuration:duration,minFrameDuration:duration,validFrameDurations:nil); let relay=RelaySource(format:format); let source=CMIOExtensionStream(localizedName:"Blusher Camera",streamID:UUID(uuidString:"1A048B44-9F5C-43CA-9277-39D3A2B07001")!,direction:.source,clockType:.hostTime,source:relay); let sink=CMIOExtensionStream(localizedName:"Blusher Input",streamID:UUID(uuidString:"1A048B44-9F5C-43CA-9277-39D3A2B07002")!,direction:.sink,clockType:.hostTime,source:relay); relay.source=source; relay.sink=sink; do{try device.addStream(source);try device.addStream(sink);self.relay=relay}catch{Logger(subsystem:"com.nixboi42.Blusher.CameraExtension",category:"virtualCamera").error("Add stream failed: \(error.localizedDescription)")} }
}

final class RelaySource:NSObject,CMIOExtensionStreamSource {
    let format:CMIOExtensionStreamFormat; weak var source:CMIOExtensionStream?; weak var sink:CMIOExtensionStream?; private var running=false; private var client:CMIOExtensionClient?
    init(format:CMIOExtensionStreamFormat){self.format=format}
    var formats:[CMIOExtensionStreamFormat]{[format]}; var availableProperties:Set<CMIOExtensionProperty>{[]}
    func streamProperties(forProperties properties:Set<CMIOExtensionProperty>) throws->CMIOExtensionStreamProperties{let p=CMIOExtensionStreamProperties(dictionary:[:]);p.activeFormatIndex=0;p.frameDuration=CMTime(value:1,timescale:30);return p}
    func setStreamProperties(_ streamProperties:CMIOExtensionStreamProperties)throws{}
    func authorizedToStartStream(for client:CMIOExtensionClient)->Bool{self.client=client;return true}
    func startStream()throws{running=true;consume()}
    func stopStream()throws{running=false}
    private func consume(){guard running,let sink,let client else{return};sink.consumeSampleBuffer(from:client){[weak self] sample,_,discontinuity,more,error in guard let self else{return};if let sample{self.source?.send(sample,discontinuity:discontinuity,hostTimeInNanoseconds:DispatchTime.now().uptimeNanoseconds)};if self.running{self.consume()}}}
}
