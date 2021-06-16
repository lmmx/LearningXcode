import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
            CameraView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraView: View {
    @StateObject var camera = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                if camera.isTaken {
                    HStack {
                        Spacer()
                        
                        Button(action: camera.reTake, label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        })
                        .padding(.trailing, 10)
                    }
                }
                
                Spacer()
                
                HStack {
                    // if taken showing save and again take button...
                    if camera.isTaken {
                        Button(action: {if !camera.isSaved{camera.savePic()}}, label: {
                            Text(camera.isSaved ? "Saved" : "Save")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        })
                        .padding(.leading)
                        
                        Spacer()
                    }
                    else {
                        
                        Button(action: camera.takePic, label: {
                            ZStack {
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        })
                    }
                }
            }
        }
        .onAppear(perform: {
            camera.Check()
        })
    }
}

// Camera Model

class CameraModel: NSObject,ObservableObject,AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    // since we are going to read pic data
    @Published var output = AVCapturePhotoOutput()
    // preview...
    @Published var preview: AVCaptureVideoPreviewLayer!
    // pic data...
    @Published var isSaved = false
    @Published var picData = Data(count: 0)
    
    func Check() {
        print("Is this thing on?")
        // first checking camera has got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // Setting up session
        case .notDetermined:
            // requesting permission
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp() {
        // setting up camera...
        do {
            self.session.beginConfiguration()
            
            var defaultDevice: AVCaptureDevice?
            
            if let wideAngleCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultDevice = wideAngleCameraDevice
            } else if let trueDepthCameraDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                defaultDevice = trueDepthCameraDevice
            }
            let input = try AVCaptureDeviceInput(device: defaultDevice!)
            
            // check and add to session
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            // same for output
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func takePic() {
        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func reTake() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{
                    self.isTaken.toggle()
                }
                // clearing
                self.isTaken = false
                self.isSaved = false
                self.picData = Data(count: 0)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Finished processing photo")
        if error != nil {
            print("Ruh roh")
            return
        }
        print("Snap!")
        guard let imageData = photo.fileDataRepresentation() else {return}
        self.picData = imageData
    }
    
    func savePic() {
        print("Thinking about saving...")
        print(self.picData)
        guard let image = UIImage(data: self.picData) else {return}
        print("Saving")
        // saving image...
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        self.isSaved = true
        print("Saved successfully")
    }
}

// setting view for preview

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        // customisable properties
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        // starting session
        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // ...
    }
}
