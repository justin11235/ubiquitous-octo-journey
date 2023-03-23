//
//  ViewController.swift
// 
//
//  Created by Lawrence Luo.
//

import CoreML
import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var session: AVCaptureSession?
    
    let output = AVCapturePhotoOutput()
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    private let shutter: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.borderWidth = 8
        button.layer.cornerRadius = 50
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Select Image"
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutter)
        checkCameraPermissions()
        
        shutter.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
        
        view.addSubview(label)
        view.addSubview(imageView)

//        let tap = UITapGestureRecognizer(
//            target: self,
//            action: #selector(didTapImage)
//        )
//        tap.numberOfTapsRequired = 1
//        imageView.isUserInteractionEnabled = true
//        imageView.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutter.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height - 150)
    }
    
    private func checkCameraPermissions()
    {
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async { self?.setUpCamera() }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera()
    {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video)
        {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input)
                {
                    session.addInput(input)
                }
                if session.canAddOutput(output)
                {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                session.startRunning()
                self.session = session
            }
            catch {
                print(error)
            }
        }
    }

//    @objc func didTapImage() {
//        let picker = UIImagePickerController()
//        picker.sourceType = .photoLibrary
//        picker.delegate = self
//        present(picker, animated: true)
//    }

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        imageView.frame = CGRect(
//            x: 20,
//            y: view.safeAreaInsets.top,
//            width: view.frame.size.width-40,
//            height: view.frame.size.width-40)
//        label.frame = CGRect(
//            x: 20,
//            y: view.safeAreaInsets.top+(view.frame.size.width-40)+10,
//            width: view.frame.size.width-40,
//            height: 100
//        )
//    }

    private func analyzeImage(image: UIImage?) {
        guard let buffer = image?.resize(size: CGSize(width: 224, height: 224))?
                .getCVPixelBuffer() else {
            return
        }

        do {
            let config = MLModelConfiguration()
            let model = try CreateML(configuration: config)
            let input = CreateMLInput(image: buffer)

            let output = try model.prediction(input: input)
            let text = output.classLabel
            label.text = text
        }
        catch {
            print(error.localizedDescription)
        }
    }

    // Image Picker

//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        // cancelled
//        picker.dismiss(animated: true, completion: nil)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true, completion: nil)
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            return
//        }
//        imageView.image = image
//        analyzeImage(image: image)
//    }
    
    @objc private func didTapTakePhoto()
    {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate
{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        let image = UIImage(data: data)
        
        session?.stopRunning()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
        analyzeImage(image: image)
    }
}

