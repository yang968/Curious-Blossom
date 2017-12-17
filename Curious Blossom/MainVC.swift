//
//  MainVC.swift
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
import CoreData

let appDelegate = UIApplication.shared.delegate as? AppDelegate

class MainVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerDetailsLabel: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    var pictureTaken = false
    var flowers : [Flower] = []
    
    var flowerName : String!
    var flowerImage : UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
        //self.navigationItem.title = "Press Camera Button"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchFlowers()
    }
    
    func fetchFlowers() {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<Flower>(entityName: "Flower")
        
        do {
            flowers = try managedContext.fetch(fetchRequest)
            print("MainVC: Successfully fetched data")
        } catch {
            debugPrint("Could not fetch: " + error.localizedDescription)
        }
    }

    func saveFlower() {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        for flower in flowers {
            if flower.name == flowerName! {
                return
            }
        }
        
        let flower = Flower(context: managedContext)
        flower.name = flowerName
        flower.image = UIImageJPEGRepresentation(flowerImage, 1)
        do {
            try managedContext.save()
            print("Successfully saved data")
        } catch {
            debugPrint("Could not save: \(error.localizedDescription)")
        }
    }
    
    /// Converts userPickedImage to a CIImage to send it to VNCoreMLModel in detect()
    ///
    /// - Parameters:
    ///   - picker: UIImagePickerController
    ///   - info: Media or Image source
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            flowerImage = userPickedImage
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
            self.requestInfo(flowerName: firstResult.identifier)
            self.pictureTaken = true
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
        self.flowerName = flowerName.capitalized
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
        
        saveFlower()
        
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        self.navigationItem.title = flowerName
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
        
        // Use this if you want to save the images downloaded from wikipedia
        /*
        let manager = SDWebImageManager.shared()
        manager.imageDownloader?.downloadImage(with: URL(string: flowerImageURL), options: .highPriority, progress: nil, completed: { (flowerImage, data, error, downloaded) in
            if downloaded {
                print("Download complete")
                self.imageView.image = flowerImage
            } else {
                print("Download failed")
            }
        })
        */
    }
    
    /// Resets flowerDetailsLabel which shows flower details and allows the user to take a picture using camera
    ///
    @IBAction func cameraPressed(_ sender: Any) {
        if !pictureTaken {
            flowerDetailsLabel.text = ""
        }
        
        present(imagePicker, animated: true, completion: nil)
    }
}









