//
//  ViewController.swift
//  CertificatePinning
//
//  Created by Prashanth on 11/07/17.
//  Copyright © 2017 Prashanth. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URLSessionDelegate {
    
    // Get server certificate to do pinning
    // In terminal typing the below command will save the certificate in Mac's root directory
    // openssl s_client -connect www.google.com:443 -servername www.google.com < /dev/null | openssl x509 -outform DER > google.cer
    
    // Load Local certificates
    let certificates: [Data] = {
        let googleCert = Bundle.main.url(forResource: "google", withExtension: "cer")!
        let objcio = Bundle.main.url(forResource: "objcio", withExtension: "cer")!
        
        let googleData = try! Data(contentsOf:googleCert)
        let objcData = try! Data(contentsOf:objcio)
        
        return [googleData, objcData]
    }()

    @IBOutlet weak var myWebView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let myUrl = URL(string: "https://www.google.com")!
        let aSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = aSession.dataTask(with: myUrl) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            print("loaded!")
            if let data = data {
                DispatchQueue.main.async {
                    self.myWebView.load(data, mimeType: response?.mimeType ?? "", textEncodingName: response?.textEncodingName ?? "", baseURL: myUrl)
                }
            }
        }
        task.resume()
    }
}

extension ViewController {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0 {
            if let certificate = SecTrustGetCertificateAtIndex(trust, 0) {
                let data = SecCertificateCopyData(certificate) as Data
                if certificates.contains(data) {
                    completionHandler(.useCredential, URLCredential(trust: trust))
                    return
                }
            }
        }
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
