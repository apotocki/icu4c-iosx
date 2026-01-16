Pod::Spec.new do |s|
    s.name         = "icu4c-iosx"
    s.version      = "74.2.9"
    s.summary      = "ICU XCFramework for macOS, iOS, watchOS, tvOS, and visionOS, including builds for Mac Catalyst, iOS Simulator, watchOS Simulator, tvOS Simulator, and visionOS Simulator."
    s.homepage     = "https://github.com/apotocki/icu4c-iosx"
    s.license      = "BSD"
    s.author       = { "Alexander Pototskiy" => "alex.a.potocki@gmail.com" }
    s.social_media_url = "https://www.linkedin.com/in/alexander-pototskiy"
    s.ios.deployment_target = "13.4"
    s.osx.deployment_target = "11.0"
    s.tvos.deployment_target = "13.0"
    s.watchos.deployment_target = "11.0"
    s.visionos.deployment_target = "1.0"
    s.ios.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.ios.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.static_framework = true
    s.source       = { :git => "https://github.com/apotocki/icu4c-iosx.git", :tag => "#{s.version}" }
    s.source_files = "product/include/**/*.{h}"
    s.header_mappings_dir = "product/include"
    s.prepare_command = "sh scripts/build.sh"
    s.public_header_files = "product/include/**/*.{h}"
    s.vendored_frameworks = "product/frameworks/icudata.xcframework", "product/frameworks/icui18n.xcframework", "product/frameworks/icuio.xcframework", "product/frameworks/icuuc.xcframework"
end
