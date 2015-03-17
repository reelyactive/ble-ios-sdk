Pod::Spec.new do |s|
  s.name         = "BeaconManager"
  s.version      = "0.1"
  s.summary      = "An Objective-C lib for detecting bluetooth beacons and iBeacons"
  s.description  = <<-DESC
  		   An Objective-C lib for detecting bluetooth beacons and iBeacons easily using a shared Manger.
                   DESC

  s.homepage     = "https://github.com/reelyactive/ble-ios-sdk"
  s.license      = "Apache License, Version 2.0"
  s.authors       = { "CallumOz" => "c@sidereo.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/reelyactive/ble-ios-sdk.git", :tag => s.version }
  s.source_files  = "Bluetooth/{Beacon,BeaconManager}.{h,m}"
  s.frameworks = "CoreBluetooth", "CoreLocation", "UIKit"
  s.requires_arc = true
end
