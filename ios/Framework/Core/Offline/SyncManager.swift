/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/
import Foundation


@objc public protocol SyncManagerDelegate {

	optional func syncManager(manager: SyncManager,
		itemsCount: UInt)

	optional func syncManager(manager: SyncManager,
		onItemSyncStartScreenlet screenlet: String,
		key: String,
		attributes: [String:AnyObject])

	optional func syncManager(manager: SyncManager,
		onItemSyncCompletedScreenlet screenlet: String,
		key: String,
		attributes: [String:AnyObject])

	optional func syncManager(manager: SyncManager,
		onItemSyncFailedScreenlet screenlet: String,
		error: NSError,
		key: String,
		attributes: [String:AnyObject])

}


@objc public class SyncManager: NSObject {

	public weak var delegate: SyncManagerDelegate?

	private let cacheManager: CacheManager

	private let syncQueue: NSOperationQueue

	public init(cacheManager: CacheManager) {
		self.cacheManager = cacheManager

		self.syncQueue = NSOperationQueue()
		self.syncQueue.maxConcurrentOperationCount = 1

		super.init()
	}

	public func startSync() {
		cacheManager.countPendingToSync { count in
			self.delegate?.syncManager?(self, itemsCount: count)

			if count > 0 {
				self.cacheManager.pendingToSync { (screenlet, key, attributes) -> Bool in
					self.delegate?.syncManager?(self,
						onItemSyncStartScreenlet: screenlet,
						key: key,
						attributes: attributes)

					self.enqueueSyncForScreenlet(screenlet, key, attributes)

					return true
				}
			}
		}
	}

	private func enqueueSyncForScreenlet(
			screenletName: String,
			_ key: String,
			_ attributes: [String:AnyObject]) {

		let sychronizers = [
			ScreenletName(UserPortraitScreenlet): userPortraitSynchronizer]

		if let sychronizerBuilder = sychronizers[screenletName] {
			let synchronizer = sychronizerBuilder(key, attributes)

			syncQueue.addOperationWithBlock(to_sync(synchronizer))
		}
	}

	private func userPortraitSynchronizer(key: String, _ attributes: [String:AnyObject]) -> Signal -> () {
		return { signal in
			let userId = attributes["userId"] as! NSNumber

			self.cacheManager.getImage(
					collection: ScreenletName(UserPortraitScreenlet),
					key: key) {

				if let image = $0 {
					let interactor = UploadUserPortraitInteractor(
						screenlet: nil,
						userId: userId.longLongValue,
						image: image)

					// this strategy saves the send date after the operation
					interactor.cacheStrategy = .CacheFirst

					interactor.onSuccess = {
						self.delegate?.syncManager?(self,
							onItemSyncCompletedScreenlet: ScreenletName(UserPortraitScreenlet),
							key: key,
							attributes: attributes)

						signal()
					}

					interactor.onFailure = { err in
						self.delegate?.syncManager?(self,
							onItemSyncFailedScreenlet: ScreenletName(UserPortraitScreenlet),
							error: err,
							key: key,
							attributes: attributes)

						// TODO retry?
						signal()
					}

					if !interactor.start() {
						signal()
					}
				}
				else {
					signal()
					// TODO err?
				}
			}
		}
	}

}