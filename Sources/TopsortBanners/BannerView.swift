import Foundation
import SwiftUI
import Topsort_Analytics

public struct TopsortBanner: View {
    @ObservedObject var sharedValues = SharedValues()

    var width: CGFloat
    var height: CGFloat
    var buttonClickedAction: (AuctionResponse?) -> Void
    var analytics: AnalyticsProtocol

    public init(
        apiKey: String,
        url: String,
        width: CGFloat,
        height: CGFloat,
        slotId: String,
        deviceType: String,
        buttonClickedAction: @escaping (AuctionResponse?) -> Void,
        analytics: AnalyticsProtocol = Analytics.shared
    ) {
        Analytics.shared.configure(apiKey: apiKey, url: url)
        self.width = width
        self.height = height
        self.buttonClickedAction = buttonClickedAction
        self.analytics = analytics

        self.run(deviceType: deviceType, slotId: slotId)
    }

    private func run(deviceType: String, slotId: String) {
        Task {
            await self.executeAuctions(deviceType: deviceType, slotId: slotId)
        }
    }

    internal func executeAuctions(deviceType: String, slotId: String) async {
        let auction: Auction = Auction(type: "banners", slots: 1, slotId: slotId, device: deviceType)
        let response = await analytics.executeAuctions(auctions: [auction])

        sharedValues.response = response
        sharedValues.setResolvedBidIdAndUrlFromResponse()
        sharedValues.loading = false

        let event = Event(resolvedBidId: sharedValues.resolvedBidId!, occurredAt: Date.now)
        analytics.track(impression: event)
    }

    private func buttonClicked() async {
        let event = Event(resolvedBidId: sharedValues.resolvedBidId!, occurredAt: Date.now)
        analytics.track(click: event)
        self.buttonClickedAction(sharedValues.response)
    }

    public var body: some View {
        VStack {
            if sharedValues.loading {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        await self.buttonClicked()
                    }
                }) {
                    AsyncImage(url: URL(string: sharedValues.urlString!))
                        .frame(width: self.width, height: self.height)
                        .clipped()
                }
                    .frame(width: self.width, height: self.height)
            }
        }
    }
}
