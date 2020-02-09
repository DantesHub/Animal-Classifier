//
//  ViewController.swift
//  Pokemon-Classifier
//
//  Created by Dante Kim on 2/7/20.
//  Copyright © 2020 Dante Kim. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import ColorThiefSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var label: UILabel!
    var pickedImage : UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let convertedCiImage = CIImage(image: userPickedImage) else {
                fatalError("could not convert image to ciImage")
            }
            pickedImage = userPickedImage
            detect(image: convertedCiImage)
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: PokemonClassifierModel().model) else {
            fatalError("Cannot import model")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify your picture")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(pokemonName: classification.identifier)
        }
        
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
        
    }
    
    func requestInfo(pokemonName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : pokemonName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikiapedia info.")
                print(response)
                
                let pokemonJSON: JSON = JSON(response.result.value!)
                let pageid = pokemonJSON["query"]["pageids"][0].stringValue
                let pokemonDescription = pokemonJSON["query"]["pages"][pageid]["extract"].stringValue
                let pokemonImageURL = pokemonJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.label.text = pokemonDescription
                //                self.imageView.sd_setImage(with: URL(string:  pokemonImageURL))
                
                self.imageView.sd_setImage(with: URL(string: pokemonImageURL), completed: { (image, error,  cache, url) in
                    
                    if let currentImage = self.imageView.image {
                        
                        guard let dominantColor = ColorThief.getColor(from: currentImage) else {
                            fatalError("Can't get dominant color")
                        }
                        
                        DispatchQueue.main.async {
                            self.navigationController?.navigationBar.isTranslucent = true
                            self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                        }
                    } else {
                        self.imageView.image = self.pickedImage
                        self.label.text = "Could not get information on Pokemon from Wikipedia."
                    }
                })
            }
            else {
                print("Error \(String(describing: response.result.error))")
                self.label.text = "Connection Issues"
                
                
                
            }
        }
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

