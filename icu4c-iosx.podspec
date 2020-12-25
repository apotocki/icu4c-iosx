Pod::Spec.new do |s|
    s.name         = "icu4c-iosx"
    s.version      = "68"
    s.summary      = "ICU libraries"
    s.homepage     = "https://github.com/apotocki/icu4c-iosx"
    s.license      = "BSD"
    s.author       = { "Alexander Pototskiy" => "alex.a.potocki@gmail.com" }
    s.social_media_url = "https://www.linkedin.com/in/alexander-pototskiy-62852a93"
    s.platform     = :ios, "12.0"
    s.prepare_command = "sh scripts/build.sh"
    s.source       = { :git => "https://github.com/apotocki/icu4c-iosx", :branch => "#{s.version}", :submodules => "true" }
    s.source_files = "product/include/**/*.{h}"
    s.header_mappings_dir = "product/include"
    s.public_header_files = "product/include/**/*.{h}"
    s.vendored_frameworks = "product/frameworks/icudata.xcframework", "product/frameworks/icui18n.xcframework", "product/frameworks/icuio.xcframework", "product/frameworks/icuuc.xcframework"
    s.preserve_paths = "product/include/**/*.{h}", "product/frameworks/**/*"
end
