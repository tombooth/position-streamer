//
//  ViewController.swift
//  position-streamer
//
//  Created by Tom Booth on 06/04/2015.
//  Copyright (c) 2015 uk.co.tombooth. All rights reserved.
//

import CoreMotion
import UIKit

import Starscream

func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
    var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
    if NSJSONSerialization.isValidJSONObject(value) {
        if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        }
    }
    return ""
}

class ViewController: UIViewController, WebSocketDelegate, UITableViewDataSource {
    
    @IBOutlet
    var loggingTableView: UITableView!
    
    @IBOutlet
    var ipAddress: UITextField!
    
    @IBOutlet
    var port: UITextField!
    
    @IBOutlet
    var connectButton: UIButton!
    
    var socket: WebSocket? = nil
    
    var messages = [String]()
    
    let motionQueue = NSOperationQueue()
    let motionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        log("Hello!")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = messages[indexPath.row]
        
        return cell
    }
    
    func log(message: String) {
        messages.append(message)
        loggingTableView.reloadData()
    }
    
    @IBAction
    func connect() {
        if socket != nil {
            motionManager.stopDeviceMotionUpdates()
            socket?.disconnect();
            socket = nil
            connectButton.setTitle("Connect", forState: .Normal)
        } else {
            socket = WebSocket(url: NSURL(scheme: "ws", host: "\(ipAddress.text):\(port.text)", path: "/")!)
            socket?.delegate = self
            socket?.connect()
            connectButton.setTitle("Disconnect", forState: .Normal)
        }
    }
    
    func websocketDidConnect(ws: WebSocket) {
        log("websocket is connected")
        if motionManager.deviceMotionAvailable {
            log("Can get motion")
            motionManager.startDeviceMotionUpdatesToQueue(motionQueue, withHandler: {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                let dict = [
                    "attitude": [
                        "roll": data.attitude.roll,
                        "pitch": data.attitude.pitch,
                        "yaw": data.attitude.yaw,
                    ],
                    "rotationRate": [
                        "x": data.rotationRate.x,
                        "y": data.rotationRate.y,
                        "z": data.rotationRate.z,
                    ],
                    "gravity": [
                        "x": data.gravity.x,
                        "y": data.gravity.y,
                        "z": data.gravity.z,
                    ],
                    "userAcceleration": [
                        "x": data.userAcceleration.x,
                        "y": data.userAcceleration.y,
                        "z": data.userAcceleration.z,
                    ],
                    "magneticField": [
                        "x": data.magneticField.field.x,
                        "y": data.magneticField.field.y,
                        "z": data.magneticField.field.z,
                    ],
                ]
                
                ws.writeString(JSONStringify(dict))
            })
        } else {
            log("No motion :(")
        }
    }
    
    func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        if let e = error {
            log("websocket is disconnected: \(e.localizedDescription)")
        }
    }
    
    func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        log("Received text: \(text)")
    }
    
    func websocketDidReceiveData(ws: WebSocket, data: NSData) {
        log("Received data: \(data.length)")
    }


}

