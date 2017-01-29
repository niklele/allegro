| `master` |
|:--------:|
| [![CircleCI](https://circleci.com/gh/TeamAllegro/allegro.svg?style=svg&circle-token=027c45e319de130d49216fe2fcc036eeb5a800f5)](https://circleci.com/gh/TeamAllegro/allegro) |

# Configuring Your Development Environment

1. Clone the repo
1. Run `pod install` to install Cocoapods dependencies
1. Run `carthage bootstrap` to install Carthage dependencies
1. Run `fastlane match development --readonly` to download the Development Provisioning Profile. You'll be prompted for a password. The password is farm.
1. Run `fastlane match appstore --readonly` to download the AppStore Provisioning Profile. Again, you'll be prompted for a password. Enter the same one as before.
1. Install Xcode 8 (for Swift 3)
1. Open `allegro.xcworkspace` in Xcode. macOS may attempt to woo you into opening `allegro.xcodeproj`. Resist. Because we use Cocoapods, we *must* use `allegro.xcworkspace`.

# Diving into the Code

1. Have a look at [AppDelegate.swift](https://github.com/TeamAllegro/allegro/blob/master/allegro/AppDelegate.swift). That's the entrypoint of the application. That's where we hold references to the objects we keep in memory. That's where we manage application lifecycle.
1. Notice the line below. `RootNavigationViewController` is a container that handles navigation. Into this, we inject the controller that handles the home screen.
1. Follow `HomeMenuViewController`

``` swift
window?.rootViewController = RootNavigationViewController(rootViewController: HomeMenuViewController())
```

# Resources

[Install Cocoapods](https://guides.cocoapods.org/using/getting-started.html)

[Install Carthage](https://github.com/Carthage/Carthage#installing-carthage)

[Install Fastlane](https://github.com/fastlane/fastlane#installation)

Installation on Hard Mode: Cocoapods and Fastlane are both made with Ruby. If you are familiar with Ruby,
you can install the two gems using the provided Gemfile. To do so, run `bundle
install`. Afterward, instead of running `pod install`, you run `bundle exec pod
install`. The same goes for Fastlane. Prefix your command with `bundle exec`.

[Awesome iOS](https://github.com/vsouza/awesome-ios)

[List of Musical Symbols](https://en.wikipedia.org/wiki/List_of_musical_symbols)

Swift Style Guides: [GitHub](https://github.com/github/swift-style-guide#only-explicitly-refer-to-self-when-required), [LinkedIn](https://github.com/linkedin/swift-style-guide)
