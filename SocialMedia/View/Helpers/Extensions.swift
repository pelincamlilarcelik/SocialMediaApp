//
//  Extensions.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI

// MARK: View Extensions for UI Building
extension View{
    //MARK: Closing All Active Keyboards
    func closeKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func disableWithOpacity(_ condition: Bool)->some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1.0)
    }
    
    func hAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxWidth:.infinity,alignment: alignment)
    }
    func vAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxHeight:.infinity,alignment: alignment)
    }
    // MARK: Custom Border View with  Padding
    func border(_ width: CGFloat,_ color: Color)->some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5,style: .continuous)
                    .stroke(color,lineWidth: width)
            }
    }
    func fillView(_ color: Color)->some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5,style: .continuous)
                    .fill(color)
            }
    }
}
