#kiru!

kiru! is a file slicer for Windows. It has been tested in Windows XP and Windows 10 (not throughly). It should work with files up to 4GB.

You can select either the number of chunks or the required size for the chunks. All chunks will be the same size except for the last one that accounts for the reminder of the bytes and also adds an executable (as an option) that acts as a rejoiner when run.

The code is a mess. You should be able to compile with MASM32. Check good old [Iczelion's Win32 Assembly Homepage](http://win32assembly.programminghorizon.com/index.html)  for tips and tools.

The whole thing compiled is only 10kb.

<img width="489" alt="screen shot 2017-01-28 at 00 17 55" src="https://cloud.githubusercontent.com/assets/10778057/22392280/5457bb0e-e4ef-11e6-9c33-c5a574ed6737.png">
