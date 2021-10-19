//+------------------------------------------------------------------+
//|                                                 ArrayListInt.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#include "ArrayListInt_Item.mqh"

class ArrayListInt
  {
private:
   void resizeIfNeeded(){
   }
   ArrayListInt_Item * get_item(int n){
      int i = 0;
      if (head != NULL){
         ArrayListInt_Item *curItem;
         curItem = head;
         while (i < n){
            if (curItem.next != NULL){
               curItem = curItem.next;
               i++;
            }
            else
               return NULL; //DIDNT FIND IT
         }
         return curItem;
      }
      return NULL; //ERRORRRRRRRRRRRRRRR!
   }
   
public:
   ArrayListInt();
   ~ArrayListInt();
   ArrayListInt_Item *head;
   
   int count;
   void pop(){
      if (head != NULL){
         if (head.next == NULL) //no next and no prev
            head = NULL;
         else { // prev will never be NULL
            ArrayListInt_Item *curItem;
            curItem = head.next; //same as (*head).next
            while (true){
               if (curItem.next != NULL){
                  curItem = curItem.next;
               } else {
                  curItem.prev.next = NULL;
                  //delete curItem;
               }
            }
         }
         count--;
      }
   }
   void pop(int n){
      if (head != NULL){
         if (n == 0){
            if (head.next != NULL){
               head.next.prev = NULL;
               head = head.next;
            } else {
               head = NULL;
            }
            count--;
         } else {
            int i = 1;
            ArrayListInt_Item *curItem;
            curItem = head.next;
            while (true){
               if(i != n){
                  if (curItem.next != NULL){
                     curItem = curItem.next;
                     i++;
                  } else {
                     // end of array
                     break;
                  }
               } else {
                  //pop the element
                  if (curItem.next != NULL){
                     curItem.next.prev = curItem.prev;
                     curItem.prev.next = curItem.next;
                  } else {
                     curItem.prev.next = NULL;
                  }
                  count--;
                  break;
               }
            }
         }
      }
   }
   void add(int val){
      ArrayListInt_Item * item = get_item(count-1);
      ArrayListInt_Item newItem(val);
      printf(newItem.value);
      if (item == NULL){
         printf("empty");
         head = &newItem;
         count++;
      } else {
         printf((item).value);
         (*item).next = &newItem;
         newItem.prev = item;
      }
      //item.next = &newItem;
   }
   void add(int pos, int val){
   }
      
   int getLast(){
      return get(count-1);
   }
   int get(int n){
      int i = 0;
      if (head != NULL){
         ArrayListInt_Item *curItem;
         curItem = head;
         while (i < n){
            if (curItem.next != NULL){
               curItem = curItem.next;
               i++;
            }
            else
               return -1; //DIDNT FIND IT
         }
         return curItem.value;
      }
      return -1; //ERRORRRRRRRRRRRRRRR!
   }
   string toString(){
      string result = "[";
      if (count > 0){
         result += (string)head.value;
         ArrayListInt_Item *curItem;
         curItem = head.next;
         for (int i = 1; i < count; i++)
            result += ", " + (string)curItem.value;
      }
      return result + "]";
   }
   
   
   
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ArrayListInt::ArrayListInt()
  {
   count = 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ArrayListInt::~ArrayListInt()
  {
  }
//+------------------------------------------------------------------+