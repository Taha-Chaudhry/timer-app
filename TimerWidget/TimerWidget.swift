//
//  TimerWidget.swift
//  TimerWidget
//
//  Created by Taha Chaudhry on 13/08/2023.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let seconds = UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int
    
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), displayTime: seconds ?? 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> ()) {
        let entry = TimerEntry(date: Date(), displayTime: seconds ?? 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> ()) {
        let currentDate = Date()
        let timerString = UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") ?? 0
        let entry = TimerEntry(date: currentDate, displayTime: seconds ?? 0)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}


struct TimerEntry: TimelineEntry {
    let date: Date
    let displayTime: Int
}

struct TimerWidgetEntryView: View {
    var entry: TimerEntry
//    var seconds: Int = UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as! Int
    
    var body: some View {
        VStack {
            Text("\(entry.displayTime)")
//            Text("\(seconds)")
//            Text("\(print(UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int)")
                .font(.title)
                .padding()
            
            Button("d") {
                
            }
        }.onAppear {
            print(UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int)
        }
    }
}

struct TimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimerWidget", provider: Provider()) { entry in
            TimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Timer Widget")
        .description("Displays the timer status")
    }
}


struct TimerWidget_Previews: PreviewProvider {
    static var previews: some View {
        TimerWidgetEntryView(entry: TimerEntry(date: Date(), displayTime: 0))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
