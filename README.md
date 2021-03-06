<h1> RaspEye </h1>

<ul>
<li>This app allows to view a video stream generated by a Raspberry Pi (or any TCP transmitting device) on an iOS device. Both the iOS Device and the transmitter must be connected to the same network in order to operate.</li>
<li>"RPi Camera Viewer" App (an open source project) was used for the communication source code. (http://frozen.ca/rpi-camera-viewer-for-ios/) I simplified the app so that more beginner users can understand the project thoroughly.</li>
<li>  

<p>Following command was used on the Raspberry Pi to start the stream.<br>
<code>raspivid -n -ih -t 0 -rot 180 -w 720 -h 1280 -fps 30 -b 1000000 -o - | nc -lkv4 5000</code>
  <ul>
    <li> <code>-rot</code> for the rotation of the video stream. (Some useful parameters are 90, 180, or 270)</li>
    <li> <code>-w</code> and <code>-h</code> are for the width and the height of the stream.</li>
    <li> <code>-fps</code> for Frames per Second parameter (usually 15 or 30 is a good fit).</li>
    <li> <code>-b</code> for the Bits per Second transmission rate. (1,000,000 is a suitable value)</li>
    <li> <code>-nc</code> command is used for the netcat software.</li>
    <li> <code>5000</code> at the end specifies the port number.</li>
    </ul>
</p>
</li>
</ul>
<p>For any questions, GitHub: <b>egecavusoglu</b></p>
