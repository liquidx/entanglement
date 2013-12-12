Entanglement
============

Mac to iOS Screen mirroring through USB.

This is intended to be a design proofing tool similar to Scala Preview,
Xscope Mirror or Sketch Mirror except that it works exclusively over USB
rather than over a network. This way your device and mac do not have to
be on the same physical network.

Status
------

Currently a barebones implementation of an iOS client app that talks to a
Mac server app over USB to share 1:1 images from the desktop to the mobile device.

Restrictions
------------

 * Only supports iPhone
 * Only supports iPhone 5 resolution (640 x 1136)
 * Only supports sharing top corner of the screen.
 * Does not support arbitrary image sources.
 * Does not do a high framerate yet.
 * Does not handle going to sleep or background.
 * Does not take in to account physical dimensions of the device.
 * Does not do pixel doubling if required.

