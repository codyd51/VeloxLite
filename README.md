# Velox
Velox 2 for iOS 8, a quicker way to interact with your apps

Velox is a jailbroken modification built on Mobile Substrate that allows you to interact with your apps quickly from the homescreen. Apps can have their own specialized Velox views, or simply a generic notifications view. Velox includes an extensive API which enables third-party developers to also create specialized views for other apps, which can then be submitted to Cydia as addon-packages for Velox.

Velox is built using the theos makefile system.

To create Velox extensions, I have provided a theos template which sets up an extension for you. For the most part, it is a simple UIView. Extension files are automatically installed to `/Library/Application Support/Velox/API/` and read by VeloxNotificationController. Velox extensions may be published for any app, independent of me, and without requiring my explicit permission.

## Specialized Views
Within the core Velox package, the following apps currently have specialized views:

- Settings
- Clock
- Maps
- Weather
- Music
- Photos
- Safari
- Notes
- Youtube
- XKCD
- Camera
- Twitter
- Cydia
- Google
- App Store
- iTunes
- Phone
- Tweetbot
- Facebook
- Songza
- Spotify
- Pandora
- Messages
