//
//  SharePlateWidgetExtensionLiveActivity.swift
//  SharePlateWidgetExtension
//
//  Created by Divy Patel on 7/10/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SharePlateWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SharePlateWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SharePlateWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SharePlateWidgetExtensionAttributes {
    fileprivate static var preview: SharePlateWidgetExtensionAttributes {
        SharePlateWidgetExtensionAttributes(name: "World")
    }
}

extension SharePlateWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: SharePlateWidgetExtensionAttributes.ContentState {
        SharePlateWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SharePlateWidgetExtensionAttributes.ContentState {
         SharePlateWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SharePlateWidgetExtensionAttributes.preview) {
   SharePlateWidgetExtensionLiveActivity()
} contentStates: {
    SharePlateWidgetExtensionAttributes.ContentState.smiley
    SharePlateWidgetExtensionAttributes.ContentState.starEyes
}
