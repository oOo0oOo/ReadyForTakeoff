Setup Android Publishing
========================

Inspired by https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

```bash
# Install OpenJDK 11
sudo apt-get install libpython3.7 libpython3.7-dev libpython3.7-stdlib
sudo apt-get install openjdk-11-jre openjdk-11-jdk

# jarsigner could be at /usr/lib/jvm/java-11-openjdk-amd64/bin/jarsigner
# adb could be at /home/ooo/Libraries/android_sdk/platform-tools/adb

# Android SDK
# Download commandline tool
cd Libraries
mkdir android_sdk
cd android_sdk

./cmdline-tools/bin/sdkmanager "platform-tools" "build-tools;30.0.3" "platforms;android-31" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;21.4.7075529"
```
