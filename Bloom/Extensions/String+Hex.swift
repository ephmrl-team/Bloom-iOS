//
//  String+Hex.swift
//  Bloom
//

import Foundation

extension String {
    func hexToBytes() -> [UInt8] {
        var bytes = [UInt8]()
        var temp = ""

        let cleanHex = self.replacingOccurrences(of: " ", with: "").lowercased()

        for char in cleanHex {
            temp += String(char)
            if temp.count == 2 {
                if let byte = UInt8(temp, radix: 16) {
                    bytes.append(byte)
                }
                temp = ""
            }
        }
        return bytes
    }
}
