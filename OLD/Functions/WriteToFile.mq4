//+------------------------------------------------------------------+
//|                                                  WriteToFile.mq4 |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                        www.fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "www.fancygamer.weebly.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   int fileHandle = FileOpen("hello.csv",FILE_READ|FILE_WRITE);
	FileSeek(fileHandle,0,SEEK_END); //set pos to end, it will 
   FileWrite(fileHandle,"aøL",TimeLocal());
   FileWrite(fileHandle,"aøL",TimeLocal()); 
   FileFlush(fileHandle); //save info instantly
   FileClose(fileHandle); //Closes the file
   


   /* WRITE TO TXT FILES
   int fileHandle = FileOpen("Info.txt",FILE_WRITE|FILE_TXT);
   FileWrite(fileHandle,"Hello World ", Symbol());
   */
  }
//+------------------------------------------------------------------+

void FileAppendTXT(string file_name,string txt)
{

   int handle = FileOpen(file_name,FILE_READ|FILE_WRITE);
	FileSeek(handle,0,SEEK_END);
	FileWrite(handle,txt);
	FileFlush(handle);
	FileClose(handle);
}  
