# WearableToolKit 
# What is this App?
The wearable toolkit is an all purpose wearable that can be used with a variety of different activities. A bluetooth speaking device, in this case the BBC Microbit, is placed on the users body. This board is then connected to an IOS app on the users Iphone. The code for this app is what you see in this Github. This app will allow the user to video tape themselves, or have another person record them, while recieve sensor data from the bluetooth device, which for now is accleration data. The app will graph the data, and with the help of machine learning, learn to classify actions based off of the users criteria. The app could tell you if your swing is too slow, if you are extending to far out to one side, and more, not just with sports but  in other fields as well. Please note that work is still in program so the app is far from fully developed.
# How to Use this App
1. Make sure you change the name of the microbit in the ViewController.swift file to the name of your micro:bit right now it is "gepev" (if you don’t know the name of your microbit- you can connect using the “micro:bit” app from the app store. More specific instructions coming soon)

2. Create a simple microbit program that looks something like this, and download it to your micro:bit:



3. From Xcode: Make sure your iPhone is plugged into your laptop
4. Select your iPhone as the device you want to test on (this is on the top toolbar)
5. Update the developer to yourself
  a. Select LPC Wearable Toolkit at the app level and choose LPC Wearable Toolkit as a target
  b. Go to General
  c. Update Signing > Team to be yourself (also pictured above)
6. Make sure your iphone is unlocked
7. Press play button on xcode top toolbar
8. You will need to give the app permission to run on your phone, Xcode will tell you how to do this if it gives you that error
9. The app should launch on your phone
10. Press connect it should say on the top of the app when it has found the microbit
11. Press record, right now that will launch the camera
12. To see the graph, press use video
13. Press stop button on xcode top toolbar when you're done


