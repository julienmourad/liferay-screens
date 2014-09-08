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

public class DDLBooleanElement : DDLElement {

	override public init(attributes:[String:String], localized:[String:String]) {
		super.init(attributes: attributes, localized:localized)
	}

	override internal func convert(fromString value:String?) -> AnyObject? {
		return value != nil ? Bool.from(string: value!) : nil
	}

	override func convert(fromCurrentValue value: AnyObject?) -> String? {
		var result: String?

		if let boolValue = value as? Bool {
			result = boolValue ? "true" : "false"
		}

		return result
	}

}
