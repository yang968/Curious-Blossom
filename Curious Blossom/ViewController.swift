//
//  ViewController.swift
//  Curious Blossom
//
//  Created by Spencer Yang on 11/8/17.
//  Copyright © 2017 Seungho Yang. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerDetailsLabel: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    /// Converts userPickedImage to a CIImage to send it to VNCoreMLModel in detect()
    ///
    /// - Parameters:
    ///   - picker: UIImagePickerController
    ///   - info: Media or Image source
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not Convert to CIImage")
            }
            detect(image: ciImage)
//            imageView.image = userPickedImage
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    /// Detect flower from the CIImage using the FlowerClassifier model and update UI accordingly.
    /// Calls requestInfo() to collect information about the flower from Wikipedia
    ///
    /// - Parameter image: CIImage
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let firstResult = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image")
            }
            
            print(firstResult.identifier)
            self.navigationItem.title = firstResult.identifier.capitalized
            self.requestInfo(flowerName: firstResult.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    //MARK: - Networking
    /// Sends a get request with wikipediaURL to retrieve information about a flower identified by FlowerClassifier
    ///
    /// - Parameter flowerName: flower identified by FlowerClassifier
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON {
            (response) in
            if response.result.isSuccess {
                print("Got the Wikipedia Info")
                print(JSON(response.result.value!))
                
                let jsonData = JSON(response.result.value!)
                self.updateData(json: jsonData)
            }
        }
        
    }
    
    //MARK: - JSON Parsing
    /// Updates flowerDetailsLabel with information from Wikipedia and uses SDWebImage to set imageView
    /// with image displayed on Wikipedia.
    ///
    /// - Parameter json: Received JSON data from Wikipedia
    func updateData(json: JSON) {
        let pageid = json["query"]["pageids"][0].stringValue
        
        if let result = json["query"]["pages"][pageid]["extract"].string {
            flowerDetailsLabel.text = result
        }
        else {
            print("Unavailable")
        }
        
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
    }
    
    /// Resets flowerDetailsLabel which shows flower details and allows the user to take a picture using camera
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func cameraPressed(_ sender: Any) {
        flowerDetailsLabel.text = ""
        present(imagePicker, animated: true, completion: nil)
    }
    
}

