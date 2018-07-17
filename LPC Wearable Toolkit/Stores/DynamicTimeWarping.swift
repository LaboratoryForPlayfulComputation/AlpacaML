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
    
    func distance(d1: (Double,Double,Double), d2: (Double,Double,Double)) -> Double {
        let total = pow(d1.0-d2.0,2) + pow(d1.1-d2.1,2) + pow(d1.2-d2.2,2)
        return sqrt(total)
    }
    
    func dtw(totAcc: [(Double, Double, Double)], newAcc: [(Double, Double, Double)]) -> Double {
        var DTWArray:[[Double]] = []
        let n = totAcc.count
        let m = newAcc.count
        for i in 0..<n {
            var column:[Double] = []
            for j in 0..<m {
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
                cost = distance(d1: totAcc[i], d2: newAcc[j])
                DTWArray[i][j] = cost + min(DTWArray[i-1][j], DTWArray[i][j-1], DTWArray[i-1][j-1])
            }
        }
        return DTWArray[n-1][m-1]
    }
}
