//
//  DynamicTimeWarping.swift
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 7/5/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//


import Foundation
import UIKit

class DTW {
    
    var trainingSet: [String:[[(Double,Double,Double)]]] = [:]
    
    func addToTrainingSet(label: String, data: [(Double,Double,Double)]) {
        if (trainingSet[label] != nil) {
            trainingSet[label]?.append(data)
        } else {
            trainingSet[label] = [data]
        }
    }
    
    // take best fit? or take one with most min distances?
    func classify(test: [(Double, Double, Double)]) -> String {
        var classification = ""
        var minDistance = Double.infinity
        for key in trainingSet.keys {
            let set = trainingSet[key]
            for example in set! {
                let result = dtw(trainingData: example, newData: test)
                if result < minDistance {
                    minDistance = result
                    classification = key
                }
            }
        }
        // will need some sort of threshold- what is no gesture detected?
        // should user set threshold? should user have to go through Varun's learning moment?
        return classification + " " + String(minDistance)
    }
    
    func distance(d1: (Double,Double,Double), d2: (Double,Double,Double)) -> Double {
        let total = pow(d1.0-d2.0,2) + pow(d1.1-d2.1,2) + pow(d1.2-d2.2,2)
        return sqrt(total)
    }
    
    func dtw(trainingData: [(Double, Double, Double)], newData: [(Double, Double, Double)]) -> Double {
        var DTWArray:[[Double]] = []
        let n = trainingData.count
        let m = newData.count
        for _ in 0..<n {
            var column:[Double] = []
            for _ in 0..<m {
                column.append(0.0)
            }
            DTWArray.append(column)
        }
        
        for i in 0..<n {
            DTWArray[i][0] =  Double.infinity
        }
        for i in 0..<m {
            DTWArray[0][i] = Double.infinity
        }
        DTWArray[0][0] = 0.0
        var cost = 0.0
        for i in 1..<n{
            for j in 1..<m{
                cost = distance(d1: trainingData[i], d2: newData[j])
                DTWArray[i][j] = cost + min(DTWArray[i-1][j], DTWArray[i][j-1], DTWArray[i-1][j-1])
            }
        }
        return DTWArray[n-1][m-1]
    }
}
