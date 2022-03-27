# raspberry_pi_revision_bash
Bash code to decode the *"Revision:"* field of `/proc/cpuinfo` on the Raspberry Pi (also finds CPU architecture & Linux OS info).
### About
 - Similar to [raspberry_pi_revision](https://github.com/AndrewFromMelbourne/raspberry_pi_revision), but written in bash.
 - Successfully calculates [these test-cases](https://forums.raspberrypi.com/viewtopic.php?t=249283)
 - Stores found info in variables for your script to reference later.

*Feel free to copypasta/edit into your bash scripts if you need a function to identify Raspberry Pi hardware, CPU, and software.*

### References
 - [Official Raspberry Pi Hardware Documentation: Revision Codes subsection](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-revision-codes)
 - [Raspberry Pi GitHub: Revision Codes](https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/raspberry-pi/revision-codes.adoc)
 - [Generations and Series of the Raspberry Pi SBC](https://en.wikipedia.org/wiki/Raspberry_Pi#Series_and_generations)
