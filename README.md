#kiru!

kiru! is a file slicer for Windows. It has been tested in Windows XP and Windows 10 (not throughly). It should work with files up to 4GB.

You can select either the number of chunks or the desired size for the chunks. All chunks will be the same size except for the last one that accounts for the reminder of the bytes and also adds an executable (as an option) to the last chunk that turns it into a re-joiner when run.

The code is a mess. You should be able to compile with MASM32. Check good old [Iczelion's Win32 Assembly Homepage](http://win32assembly.programminghorizon.com/index.html)  for tips and tools.

The whole thing compiled is only 10kb.

<p align="center">
<img width="488" alt="screen shot 2017-01-28 at 00 21 32" src="https://cloud.githubusercontent.com/assets/10778057/22392336/d140d60a-e4ef-11e6-8be8-cf7fb2c12bdb.png">
</p>
