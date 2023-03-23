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
        button.layer.borderWidth = 6
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
        //label.text = "Select Image"
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
        
        //view.addSubview(imageView)

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(retake)
        )
        tap.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutter.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height - 100)
        
        label.frame = CGRect(
                    x: 20,
                    y: view.safeAreaInsets.top+(view.frame.size.width-40)+10,
                    width: view.frame.size.width-40,
                    height: 100
                )
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
        guard let buffer = image?.resize(size: CGSize(width: 299, height: 299))?
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
    
    @objc func retake()
    {
        DispatchQueue.global(qos: .background).async {
            self.session!.startRunning()
            
        }
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
        
        
        let targetSize = CGSize(width: 299, height: 299)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { (context) in
            image!.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        let imageView = UIImageView(image: resized)
        
        // if the code crashes then try changing the exlamation mark to question mark ********************************
        
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        
        
        //THIS ADDS THE RESIZED IMAGE TO THE DISPLAY, UNCOMMENT IF WANT TO IMPLEMENT
        //view.addSubview(imageView)
        analyzeImage(image: resized)
    }
}

