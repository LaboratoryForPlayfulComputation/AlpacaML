# ALPACA ML: Automated Learning and Prototyping for Athletics and Creative Activity with Machine Learning 
# What is this App?
The wearable toolkit is an all purpose wearable that can be used with a variety of different activities. A bluetooth speaking device, in this case the BBC Microbit, is placed on the users body. This board is then connected to an IOS app on the users iPhone. The code for this app is what you see in this Github. This app will allow the user to video tape themselves, or have another person record them, while recieve sensor data from the bluetooth device, which for now is accleration data. The app will graph the data, and with the help of machine learning, learn to classify actions based off of the users criteria. The app could tell you if your swing is too slow, if you are extending to far out to one side, and more, not just with sports but  in other fields as well. Please note that work is still in program so the app is far from fully developed.
# How to Use this App

# Setting up XCode and your iPhone (for first time setup only)
1. From Xcode: Make sure your iPhone is plugged into your laptop<p>
2. Select your iPhone as the device you want to test on (this is on the top toolbar)<p>
3. Update the developer to yourself a. Select LPC Wearable Toolkit at the app level and choose LPC Wearable Toolkit as a target     b. Go to General c. Update Signing > Team to be yourself (also pictured above)<p>
4. Make sure your iphone is unlocked<p>
5. Press play button on xcode top toolbar<p>
6. You will need to give the app permission to run on your phone, Xcode will tell you how to do this if it gives you that error<p>
7. The app should launch on your phone<p>

# Setting up for following runs
1. Navigate to the application on your phone<p>
  
# Setting up the MicroBit
1. Navigate to https://microbit.org/code/<p>
2. Click Let's Code<p>
3. Create a program that looks something like this<p>
![Imgur](https://i.imgur.com/VBDEQI6.png)<p>
4. Download the file to your MicroBit

# Connecting to MicroBit
1. Click on Connect to a new MicroBit<p>
2. Choose your MicroBit from the drag down menu<p>
3. Your MicroBit will display a diamond when you have connected<p>
4. Now Get Started should turn green-click on it<p>

# Setting up New Sports and Actions
1. Click plus button<p>
2. Enter sport/activity name<p>
3. Add a description<p>
4. Click done when you're finished<p>
5. Click on your sport<p>
6. Click select an action and Add new<p>
7. Click ok when done<p>
8. Choose your action from the drag down menu<p>

# Training Actions
1. Click train<p>
2. Click the camera icon to record a video<p>
3. Allow it to access your camera and microphone<p>
4. Attach the MicroBit to your wrist/leg/hand<p>
5. Click record & record a video of yourself doing the action<p>
6. Click allow to access photos<p>
7. Using your finger, highlight the areas on the graph which correspond to your action using a dragging motion <p>
8. Once you have selected a region, label it as good with thumbs up, bad with thumbs down, or no action with no action<p>
9. Do this for your actions as well as no actions on the graph<p>
10. When you are done select done<p>
11. Now select your action again<p>

# Testing Actions
1. Press test<p>
2. Click go and perform your action you will receive live feedback (good or bad)<p>
3. When done select done<p>
