BKM-68X FPGA

This Verilog code tries to impersonate and work to some degree as to what most of the original BKM-68X does.
It should be noted that I am not proficient in HDL at all. This is the first actual HDL I've written since university like 13 years ago...
Improvements are welcome! At least there are no inferred latches...

This code does not do anything in regards to the aperture settings (or any other settings than internal/external sync, video output enable and then format detection).

It basically consists of two modules: monitor_interface and video_format_detector.

monitor_interface

The monitor_interface module handles the actual data stuff to and from the monitor. It handles the serial, interruption and so on.

Basically the flow is like this:

Monitor "tells" the card which slot it is in, by deasserting the slot_x_int_x signal while writing some information sequence of which one byte is the slot. The monitor first disables the
cards interrupt output by issuing a command for this.

The slot number specifies if the card should react to commands in the range of 2Xh (for slot 2, optional slot 1), 3Xh (for slot 3, optional slot 2), 4Xh (for slot 4, optional slot 3).

The cards interrupt pin INT_X is active until the monitor ends up clearing the interrupt flag.
When this happens the monitor then reads the type of the card, where the BKM-68X returns 88h, the 62HS returns 82h and the 61D returns 81h.

After some time, it seems like the original card reaches some boot state, and then de-asserts the INT_X again, thus interrupting the monitor.
The monitor clears the interrupt, and the issues a load of writes and reads until finally reading the serial.
This is most likely some part of a serial CRC routine or something because if they don't match, serial is read out wrong (card seemingly is still accepted and works properly).

When this is done, after some more time all the video stuff comes up (most likely when the power supplies are all booted up) and the video part comes up.
When this happens, the card again de-asserts INT_X, now specifying if there is a video signal coming in, and what that signal is.
The monitor clears the flag, reads the video format, and writes a bunch of data and then we're in business.

As the input signal comes on, or goes away, or changes, when it does, the card issues an interrupt, monitor clears it, and reads the video format.
So we need something to tell the monitor what format is present

video_format_detector

To figure out the video format and convey this to the monitor, the video_format_detector module uses the HSYNC and VSYNC inputs to determine the vertical sync frequency and the horizontal scan rate.
The 50MHz global clock is used to count the width of a vertical sync slice to determine the refresh rate, and similarly for the horizontal rate.
These two numbers combined specifies the video format, represented by a byte that the monitor understands as a specific format.
This byte is picked up by the monitor_interface module, which then interrupts and tells the monitor of the current video signal.

Other notable modules:

polarity_detector

As the monitor seemingly needs positive sync. To ensure signals that might vary, this module detects the sync polarity and reverses if needed.
This module is instantiated both for VSYNC and HSYNC input signals.

(2021) Martin Hejnfelt, martin@hejnfelt.com
