import SwiftUI
#if !LOCAL_BUILD
import Sparkle
#endif

@main struct BlusherApp: App {
    @StateObject private var model=CameraModel()
    #if !LOCAL_BUILD
    private let updater=SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(model).frame(minWidth: 680,minHeight: 520) }
        #if !LOCAL_BUILD
        .commands { CommandGroup(after: .appInfo) { Button("Check for Updates…") { updater.checkForUpdates(nil) } } }
        #endif
        MenuBarExtra("Blusher", systemImage: model.blushing ? "face.smiling.inverse" : "video") { Text(model.status); Button("Quit") { NSApplication.shared.terminate(nil) } }
    }
}

struct ContentView: View {
    @EnvironmentObject var model: CameraModel
    var body: some View { VStack(spacing:14) {
        PreviewView(image:model.preview).clipShape(RoundedRectangle(cornerRadius:12)).overlay { if model.preview == nil { ContentUnavailableView("Camera unavailable",systemImage:"video.slash",description:Text(model.status)) } }
        HStack { Picker("Camera",selection:$model.selectedID) { ForEach(model.devices,id:\.uniqueID) { Text($0.localizedName).tag($0.uniqueID) } }.onChange(of:model.selectedID) { model.select($1) }; Toggle("Effect",isOn:$model.effectEnabled); Spacer(); Label(model.blushing ? "👉🏻👈🏻 Blushing" : "Normal",systemImage:model.blushing ? "heart.fill":"face.smiling") }
        #if DEBUG
        HStack { Toggle("Face diagnostics",isOn:$model.diagnosticsEnabled); Spacer(); Text(model.metrics).font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
        #endif
        #if LOCAL_BUILD
        HStack { Circle().fill(.orange).frame(width:8); Text("Virtual camera unavailable to Personal Team provisioning"); Spacer() }
        #else
        HStack { Circle().fill(model.extensionStatus.color).frame(width:8); Text(model.extensionStatus.text); Spacer(); Button("Activate Blusher Camera") { model.activateExtension() } }
        #endif
    }.padding().onAppear { model.start() } }
}

struct PreviewView: View { let image: CGImage?; var body: some View { GeometryReader { g in if let image { Image(decorative:image,scale:1).resizable().scaledToFill().frame(width:g.size.width,height:g.size.height).clipped() } }.background(.black).aspectRatio(16/9,contentMode:.fit) } }
