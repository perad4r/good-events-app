# Changelog

All notable changes to this project will be documented in this file.

## [2.7.6+76]

- Fix translate key when accept new bill
- Remove some unused key in dashboard model
- Add UI after select partner
- Improve UI modal in booking stage

## [2.7.5+75]

- Fix keyboard bug in IOS
- Add check for newbill
- Add new UI in account at partner side
- Add new button UI in my service screen
- Add new model in booking & after stage

## [2.7.4+74]

- Fix realtime bill overload error
- Fix service area overload error

## [2.7.3+73]

- Fix env

## [v2.7.2+72]

- Add option to remove applied voucher
- Add UI for voucher customer used in order

## [v2.7.1+71]

- Fix wrong API build

## [v2.7.0+70]

- Fix UI in bill detail at client side
- Fix can't click link in chat
- Fix review button still show after reviewed
- Add send image & location in chat
- Add partner service area
- Add completed image at partner side
- Add attach image in booking stage
- Add new notification form admin
- Add review view at partner side

## [v2.6.4+69]

- Add filter when click in bill count at client home
- Fix partner avatar not show in bill detail
- Add preview image in edit profile
- Change field background color in book stage
- Fix error snackbar in login screen

## [v2.6.3+68]

- Add validation for avatar, cccd, selfie image in profile
- Fix my service validate wrong file size

## [v2.6.2+67]

- Fix snackbar in verify screen

## [v2.6.1+66]

- Fix some partner data in bill detail at client side show wrong data
- Fix balance in partner home screen don't update without relogin

## [v2.6.0+65]

- Add interaction when user click to notification
- Fix some minor bug

## [v2.5.2+64]

- Fix google & apple login not handle unverified case
- Fix snackbar in login screen

## [v2.5.2+63]

- Fix verify exception take wrong code
- Add fixed noti at start off the chat

## [v2.5.1+62]

- Add new term of polices page

## [v2.5.0+61]

- Fix send verify email route user to input otp screen
- Remake forgot password flow to support multi method
- Fix fcm not update after login
- Update password validate in register screen
- Update password validate in forgot password
- Update password validate in change password screen
- Add allow etx image to my service

## [v2.4.19+60]

- Add verify feature
- fix user not verify can login without verify prompt

## [v2.4.18+59]

- Fixed wrong text on the home screen based on role
- Added TOS acceptance (required when signing in)
- Updated report bill UI
- Added report user functionality
- Added apple login feature

## [v2.4.17+58]

- Add ability for app to reload data in current order at client side & upcoming show in partner side when have new notification about show

## [v2.4.16+57]

- Added 5 mins auto reload for bill screen
- Fixed 'chat now' button not redirect to chat screen
- Reduced minimum allowed time gap for start time and end time when booking a new event

## [v2.4.15+56]

- Fixed not not syncing avatars for partner profiles

## [v2.4.14+55]

- Fixed notfication not showing in client side

## [v2.4.13+54]

- Fix category image not show in bill detail at client side
- Fix bill count not init right when boot in partner dashboard
- Add bill detail bottom sheet in new show at partner side

## [v2.4.12+53]

- Fix the chat page not refresh after user confirmed choosing a partner
- Added clicking on homepage stats card that switches to the orders tab (partner side)
- Added click action to profile image and name on top of the screen.
- Make 'booking forms' to be unselected by default
- Fixed reviews section to now showing because there were too many services

## [v2.4.11+52]

- Fix bill count data in partner home not update in many screen

## [v2.4.10+51]

- Fix flutter local notification take wrong app icon

## [v2.4.9+50]

- Added allow partner to un-accept the orders that are still at pending status.
- Fixed all the 'white screen' bugs when user switching tabs too quicky
- Fixed video intro haters

## [v2.4.8+49]

- Removed unnecessary email and phone details of partner profile preview
- Limited to iPhone only (removed iPad/macOS support)
- Fixed the bell icon always at 'ringing' state even with no new notifications
- Home screen now updates the stats widget like 'pending' and 'confirmed' count

## [v2.4.7+48]

- Fix partner profile preview
- Fix notification on iOS

## [v2.4.6+47]

- Add text to bottom navigation

## [v2.4.5+46]

- Fix new thread don't go to top when new message com
- change a bit of thread layout

## [v2.4.4+45]

- Fix accept new show don't change bill count in home
- Fix my show don't refresh when accept show

## [v2.4.3+44]

- Fix order count incrementing
- Add lang switch button to the very first intro screen
- Add missing translations for the guest screen

## [v2.4.2+43]

- Hide 'rate now' button if the order is already rated
- Fixed 'history order' tab not updating after the user cancel an order
- Reduced font size of the pricing in partner category detail
- Removed invalid translations
- The home screen now show avatar of the pending applicants
- Added partner category list on client home screen
- Added pull to refresh to the home screen

## [v2.4.1+42]

- Change some text translation
- Fix price size in partner category detail
- Add action for support button in partner category detail
- Add new behavior for list category bottom sheet in client home. now when return from partner category detail the bottom sheet auto open up

## [v2.4.0+41]

- Add change to partner/customer UI feature

## [v2.3.2+40]

- Fix app bottom navigation being blocked by system bottom navigation gesture

## [v2.3.1+39]

- Fix update profile success but still show error noti

## [v2.3.0+38]

- Update login, register, user verfiy screen UI

## [v2.2.0+37]

- Add filter for show, new show

## [v2.1.0+36]

- Add forgot password screen

## [v2.0.1+35]

- Fix release version can't run
- Fix app can't load img from web

## [v2.0.0+34]

- Massive update in UI/UX

## [v1.30.0+33]

- Intergation API to top up wallet
- Add top up result screen

## [v1.29.0+32]

- Update client home screen for better UI/UX
- Update client order detail (voucher)

## [v1.28.0+31]

- Added webview for openning external urls
- Fixed price tag too big
- Added video preview on details screen

## [v1.27.0+30]

- Intergetion API for fetch transaction history
- Add transaction detail view

## [v1.26.0+29]

- Update my account screen
- Update walltet UI

## [v1.25.0+28]

- Update home screen

## [v1.24.0+27]

- Update message screen
- Update chat screen

## [v1.23.0+26]

- Update my show screen UI

## [v1.22.0+25]

- Add change password screen

## [v1.21.0+24]

- Add analytic screen

## [v1.20.0+23]

- Add my service screen
- Add edit service view
- Add add service view
- Add service media manage view

## [v1.19.0+22]

- Add show calender screen

## [v1.18.0+21]

- Add my profile screen
- Add edit profile screen

## [v1.17.0+20]

- Update how chat handle websocket and optimize chat

## [v1.16.0+19]

- Intergartion pusher so app can receive realtime message

## [v1.15.0+18]

- Intergartion API for fetch thread messages

## [v1.14.0+17]

- Intergartion API for fetch threads list

## [v1.13.0+16]

- Intergartion API for complete show in my show at tab upcoming

## [v1.12.0+15]

- Add upload image component
- Add upload arrived image bottom sheet in my show at upcoming tab
- Intergartion API for upload arrived image to BE and change bill status

## [v1.11.0+14]

- Intergartion API for accept bill in realtime partner bill screen

## [v1.10.0+13]

- Intergartion fetch bill API for partner my show screen
- Add bill detail bottom sheet for partner my show screen

## [v1.9.0+12]

- Add pusher service
- Intergartion pusher for realtime partner billl (now user can get bill in realtime)

## [v1.8.0+11]

- Integration API for realtime partner bill (only for init fetch)

## [v1.7.0+10]

- Integration API for partner dashboard

## [v1.6.1+9]

- Add registration screen and features
- Add user verify screen and features

## [v1.5.2+8]

- Update function for quick action button in partner home
- Add more items into list in partner account screen
- Update layout in partner account screen

## [v1.4.2+7]

- Update android splash icon bg color
- Update app luancher icon

## [v1.4.1+6]

- Update app label

## [v1.4.0+5]

- Update partner show management UI

## [v1.3.0+4]

- Add client home screen

## [v1.2.0+3]

- Add partner home screen
- Add show management (show, new show)
- Add messaging feature
- Add account screen

## [v1.1.0+2]

- Add guest screen

## [v1.0.0+1]

- Initialize project
