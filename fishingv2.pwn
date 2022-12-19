/* ระบบ ตกปลา AFK  MaDe bY DewTY
*/
  
#include	<YSI_Coding\y_hooks>
#include 	<YSI_Coding\y_timers>
#include    <YSI_Server\y_colours>

//  พิกัดขายปลา (แก้ไขได้) 
#define   BUYBet_Pos_X    -2433.9868
#define   BUYBet_Pos_Y    2293.1665
#define   BUYBet_Pos_Z    4.9844

// พิกัดซื้อเบ็ดและเหยื่อ (แก้ไขได้) 
#define   SELLBet_Pos_X   -2433.5571
#define   SELLBet_Pos_Y   2313.7942
#define   SELLBet_Pos_Z   4.9844

// พิกัดตกปลา  (แก้ไขได้)
#define   Fishing_Pos_X   -2415.9370 
#define   Fishing_Pos_Y   2309.5261
#define   Fishing_Pos_Z   1.2652

#define ITEMBATNOR   "เบ็ดธรรมดา" 
#define IIEMBATI "เหยื่อ"

#define FishBatPrice 1500 //ราคาเบ็ต
#define BaitPrice 15 // ราคาเยือ

new PlayerText:FFishingTXD[MAX_PLAYERS][12];
new PlayerText:fishShoptd[MAX_PLAYERS][17];
new selectfish[MAX_PLAYERS];

enum FISH_DATA_V 
{
   FishName[66],
   FishPrice
};

new const arr_FishName[][FISH_DATA_V] = { // แก้ไขชนิดปลา
{"ปลายุทธ์", 12}, 
{"ปลาสวาย", 11}, 
{"GolddenFish", 13}, 
{"ปลาวิตร", 14}, 
{"ปลาตีน", 11}
};  


static  
  TakeFishingbat[MAX_PLAYERS], // เบ็ดธรรมดา
  StartFishingNor[MAX_PLAYERS], // เริ่มตก (เบ็ดธรรมดา)
  CountFishingNor[MAX_PLAYERS];  // นับเวลา AFK (เบ็ดธรรมดา)
  
hook OnGameModeInit()
{
   CreateDynamic3DTextLabel("{ffffff}ตกปลา AFK กด {FE8700}' N ' {ffffff}เพื่อเลือกรูปแบบการตกปลา", -1, Fishing_Pos_X,Fishing_Pos_Y,Fishing_Pos_Z+1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1);
   CreateDynamic3DTextLabel("{ffffff}ร้านค้าตกปลา กด {FE8700}' N ' {ffffff}เพื่อซื้อเบ็ดและเหยื่อ", -1, SELLBet_Pos_X,SELLBet_Pos_Y,SELLBet_Pos_Z+1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1);
   CreateDynamic3DTextLabel("{ffffff}ร้านรับซื้อปลา กด {FE8700}' N ' {ffffff}เพื่อขายปลา", -1, BUYBet_Pos_X,BUYBet_Pos_Y,BUYBet_Pos_Z+1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1); 
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_NO && !IsPlayerInAnyVehicle(playerid))
	{
        if(IsPlayerInRangeOfPoint(playerid, 6.0, Fishing_Pos_X,Fishing_Pos_Y,Fishing_Pos_Z)){ // ตกปลา
            new string100[1024];
            new string2[1024];
            format(string100, sizeof(string100), "ประเภท(เบ็ด) \tจำนวน\n");
            strcat(string2,string100);
            format(string100, sizeof(string100), "[%s]\t[%d]\n", ITEMBATNOR, Inventory_Count(playerid, ITEMBATNOR));
            strcat(string2,string100);
            Dialog_Show(playerid, FishingChoose, DIALOG_STYLE_TABLIST_HEADERS, "เลือกรูปแบบการตกปลา",string2,"ใช้งาน","ยกเลิก");
            return 1;
        }
        if(IsPlayerInRangeOfPoint(playerid, 6.0, SELLBet_Pos_X,SELLBet_Pos_Y,SELLBet_Pos_Z)){ // ซื้อเบ็ด
            ShowTextdarwShopFish(playerid);
        }
        if(IsPlayerInRangeOfPoint(playerid, 6.0, BUYBet_Pos_X,BUYBet_Pos_Y,BUYBet_Pos_Z)){ 
            static str[4096];
			str = "ปลา\tราคาขาย";
			for(new i = 0; i < sizeof(arr_FishName); i ++)
			{
			    format(str, sizeof(str), "%s\n%s\t$%d", str, arr_FishName[i][FishName], arr_FishName[i][FishPrice]);
		    }
		    Dialog_Show(playerid, Inputfish, DIALOG_STYLE_TABLIST_HEADERS, "[ขายปลากับลุงเริง]", str, "ขาย", "ออก");
        }
    }
   return 1;
}

Dialog:Inputfish(playerid, response, listitem, inputtext[])
{
	if(response)
	{ 
        new count = Inventory_Count(playerid, arr_FishName[listitem][FishName]);
        new price = arr_FishName[listitem][FishPrice];
        new result = count * price;
        if(count < 1) 
        return SendClientMessageEx(playerid, -1, "คุณมี %s น้อยกว่า 1", arr_FishName[listitem][FishName]);

        GivePlayerMoneyEx(playerid, result);
        Inventory_Remove(playerid, arr_FishName[listitem][FishName], count);
        SendClientMessageEx(playerid, -1, "คุณได้ขาย %s ทั้งหมดที่มีได้เป็นจำนวนเงิน %d", arr_FishName[listitem][FishName], result);
    }
    return 1;
}

hook OnPlayerClickPlayerTD(playerid, PlayerText:playertextid)
{
    if (playertextid == fishShoptd[playerid][3]) //
    {
        HideTextdarwShopFish(playerid);
    }
    if (playertextid == fishShoptd[playerid][11]) // ซื้อเบ็ด
    {
        if(GetPlayerMoneyEx(playerid) < FishBatPrice) return SendClientMessage(playerid, COLOR_RED, "[!] เงินไม่พอ");
        Inventory_Add(playerid, ITEMBATNOR, 1);
        SendClientMessage(playerid, COLOR_RED, "[!] คุณได้รับ "ITEMBATNOR" + 1");
        HideTextdarwShopFish(playerid);
    }
    if (playertextid == fishShoptd[playerid][16]) //
    {
        if(GetPlayerMoneyEx(playerid) < BaitPrice) return SendClientMessage(playerid, COLOR_RED, "[!] เงินไม่พอ");
        Inventory_Add(playerid, IIEMBATI, 1);
        SendClientMessage(playerid, COLOR_RED, "[!] คุณได้รับ "IIEMBATI" + 1");
        HideTextdarwShopFish(playerid);
    }
    return 1;
}

Dialog:FishingChoose(playerid, response, listitem, inputtext[])
{
	if (response)
	{
	    switch(listitem)
	    {
	        case 0:
	        {
              if(Inventory_Count(playerid, ITEMBATNOR) < 1) 
               return SendClientMessage(playerid, COLOR_RED, "[ ! ]{FFFFFF}คุณไม่มีเบ็ดเลย");
              
              Dialog_Show(playerid, Usebat, DIALOG_STYLE_LIST, "ใช้งาน(Use)", "ใช้งาน\nยกเลิก", "ตกลง", "กลับ");
          }
      }
    }
    return 1; 
}

Dialog:Usebat(playerid, response, listitem, inputtext[])
{
	if (response)
	{
	    switch(listitem)
	    {
	        case 0:
	        {
              if(TakeFishingbat[playerid] == 1) return Dialog_Show(playerid, waring1, DIALOG_STYLE_MSGBOX,  "คำเตือน", "{00FF00}คุณกำลังใช้งานเบ็ดอยู่", "ตกลง", "ตกลง"); 
              if(!Inventory_HasItem(playerid, ITEMBATNOR)) return Dialog_Show(playerid, waring1, DIALOG_STYLE_MSGBOX,  "คำเตือน", "{00FF00}คุณไม่มีเหยื่ออยู่ในตัวเลย", "ตกลง", "ตกลง"); 
              if(!Inventory_HasItem(playerid, IIEMBATI)) return Dialog_Show(playerid, waring1, DIALOG_STYLE_MSGBOX,  "คำเตือน", "{00FF00}คุณไม่มีเบ็ดตกปลาอยู่ในตัวเลย", "ตกลง", "ตกลง"); 
              CountFishingNor[playerid] = 1;
              StartFishingNor[playerid] = 1;
              TakeFishingbat[playerid] = 1;
              TogglePlayerControllable(playerid, 0);
              ShowTextDrawFishing(playerid);
          }
          case 1:
          {
              if(!TakeFishingbat[playerid]) return Dialog_Show(playerid, waring1, DIALOG_STYLE_MSGBOX, "คำเตือน", "{00FF00}คุณยังไม่ได้ใช้งานเบ็ด", "ตกลง", "ตกลง"); 
              CountFishingNor[playerid] = 0;
              StartFishingNor[playerid] = -1;
              TakeFishingbat[playerid] = -1;
              HideTextDrawFishing(playerid);
          }
      }
    }
    return 1; 
}

ptask fishingtimer[1000](playerid, index)
{
    foreach (new i : Player)
   	{
  	   if (CountFishingNor[i] > 0) 
       {
         // เปิดใช้งาน
        new FishRan = random(sizeof(arr_FishName));
        new string[444];
        new hours, minutes, seconds;
        CountFishingNor[i] ++;
        Inventory_Remove(playerid, IIEMBATI);
        GetElapsedTime(CountFishingNor[i], hours, minutes, seconds);
        ApplyAnimation(playerid, "SWORD", "sword_block", 50.0, 0, 1, 0, 1, 1);
        format(string, sizeof(string), "%02d:%02d:%02d", hours, minutes, seconds);
        PlayerTextDrawSetString(playerid, FFishingTXD[i][11], string);
        Inventory_Add(playerid, arr_FishName[FishRan][FishName], 1);
        SendClientMessageEx(playerid, COLOR_RED, "[ ! ]{FFFFFF}คุณได้รับปลา %s ", arr_FishName[FishRan][FishName]);
        if(StartFishingNor[i] == 1 && TakeFishingbat[i] == 1 && CountFishingNor[i] > 0)  
        {
            if(!Inventory_HasItem(playerid, IIEMBATI)){
                ClearAnimations(i);
                StartFishingNor[i] = -1;
                CountFishingNor[i] = 0;
                TakeFishingbat[i] = -1;
                TogglePlayerControllable(playerid, 1);
                Dialog_Show(playerid, waring2, DIALOG_STYLE_MSGBOX, "แจ้งเตือน", "เหยื่อของคุณหมดลงแล้ว", "ตกลง", "ตกลง"); 
                HideTextDrawFishing(playerid);
            }
            return 1;
        }
      }
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(StartFishingNor[playerid] == 1 &&  TakeFishingbat[playerid] == 0 && CountFishingNor[playerid] > 0){
        ClearAnimations(playerid);
        StartFishingNor[playerid] = -1;
        CountFishingNor[playerid] = 0;
        TakeFishingbat[playerid] = -1;
        HideTextDrawFishing(playerid);
        TogglePlayerControllable(playerid, 1);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    StartFishingNor[playerid] = 0;
    CountFishingNor[playerid] = 0;
    TakeFishingbat[playerid] = 0;
    selectfish[playerid] = -1;
    
    FFishingTXD[playerid][0] = CreatePlayerTextDraw(playerid, 307.000000, 290.000000, "_");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][0], 1.191668, 4.500003);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][0], 301.500000, 135.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][0], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][0], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][0], 2);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][0], -2686721);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][0], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][0], -2686721);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][0], 0);

    FFishingTXD[playerid][1] = CreatePlayerTextDraw(playerid, 307.000000, 290.000000, "_");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][1], 1);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][1], 1.158334, 4.300003);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][1], 301.500000, 135.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][1], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][1], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][1], 2);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][1], -2686721);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][1], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][1], 255);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][1], 0);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][1], 0);

    FFishingTXD[playerid][2] = CreatePlayerTextDraw(playerid, 307.000000, 291.000000, "_");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][2], 1);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][2], 1.158334, 4.300003);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][2], 301.500000, 135.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][2], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][2], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][2], 2);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][2], -2686721);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][2], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][2], -16776961);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][2], 0);

    FFishingTXD[playerid][3] = CreatePlayerTextDraw(playerid, 306.000000, 291.000000, "_");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][3], 1);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][3], 1.100000, 4.300003);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][3], 301.500000, 135.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][3], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][3], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][3], 2);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][3], -1);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][3], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][3], 247);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][3], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][3], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][3], 0);

    FFishingTXD[playerid][4] = CreatePlayerTextDraw(playerid, 221.000000, 267.000000, "ld_beat:chit");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][4], 4);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][4], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][4], 67.000000, 83.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][4], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][4], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][4], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][4], -16776961);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][4], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][4], 50);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][4], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][4], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][4], 0);

    FFishingTXD[playerid][5] = CreatePlayerTextDraw(playerid, 211.000000, 269.000000, "ld_beat:chit");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][5], 4);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][5], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][5], 70.000000, 77.500000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][5], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][5], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][5], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][5], 35839);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][5], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][5], 50);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][5], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][5], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][5], 0);

    FFishingTXD[playerid][6] = CreatePlayerTextDraw(playerid, 211.000000, 269.000000, "ld_beat:chit");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][6], 4);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][6], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][6], 78.000000, 87.500000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][6], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][6], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][6], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][6], -65281);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][6], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][6], 50);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][6], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][6], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][6], 0);

    FFishingTXD[playerid][7] = CreatePlayerTextDraw(playerid, 211.000000, 267.000000, "ld_beat:chit");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][7], 4);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][7], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][7], 78.000000, 87.500000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][7], 1);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][7], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][7], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][7], 255);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][7], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][7], 50);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][7], 1);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][7], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][7], 0);

    FFishingTXD[playerid][8] = CreatePlayerTextDraw(playerid, 189.000000, 237.000000, "Preview_Model");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][8], 5);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][8], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][8], 120.500000, 150.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][8], 0);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][8], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][8], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][8], -1);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][8], 0);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][8], 255);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][8], 0);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][8], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][8], 0);
    PlayerTextDrawSetPreviewModel(playerid, FFishingTXD[playerid][8], 18632);
    PlayerTextDrawSetPreviewRot(playerid, FFishingTXD[playerid][8], -10.000000, 0.000000, -20.000000, 1.000000);
    PlayerTextDrawSetPreviewVehCol(playerid, FFishingTXD[playerid][8], 1, 1);

    FFishingTXD[playerid][9] = CreatePlayerTextDraw(playerid, 347.000000, 241.000000, "Preview_Model");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][9], 5);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][9], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][9], 51.500000, 95.500000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][9], 0);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][9], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][9], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][9], -1);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][9], 0);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][9], 255);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][9], 0);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][9], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][9], 0);
    PlayerTextDrawSetPreviewModel(playerid, FFishingTXD[playerid][9], 1604);
    PlayerTextDrawSetPreviewRot(playerid, FFishingTXD[playerid][9], -1.000000, 9.000000, -67.000000, 1.000000);
    PlayerTextDrawSetPreviewVehCol(playerid, FFishingTXD[playerid][9], 1, 1);

    FFishingTXD[playerid][10] = CreatePlayerTextDraw(playerid, 275.000000, 289.000000, "TIME TO FISHING NOW");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][10], 2);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][10], 0.191666, 1.100000);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][10], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][10], 0);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][10], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][10], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][10], -1094795521);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][10], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][10], 50);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][10], 0);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][10], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][10], 0);

    FFishingTXD[playerid][11] = CreatePlayerTextDraw(playerid, 288.000000, 305.000000, "00:00:00");
    PlayerTextDrawFont(playerid, FFishingTXD[playerid][11], 3);
    PlayerTextDrawLetterSize(playerid, FFishingTXD[playerid][11], 0.433333, 1.599999);
    PlayerTextDrawTextSize(playerid, FFishingTXD[playerid][11], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, FFishingTXD[playerid][11], 0);
    PlayerTextDrawSetShadow(playerid, FFishingTXD[playerid][11], 0);
    PlayerTextDrawAlignment(playerid, FFishingTXD[playerid][11], 1);
    PlayerTextDrawColor(playerid, FFishingTXD[playerid][11], -741092353);
    PlayerTextDrawBackgroundColor(playerid, FFishingTXD[playerid][11], 255);
    PlayerTextDrawBoxColor(playerid, FFishingTXD[playerid][11], -1061109710);
    PlayerTextDrawUseBox(playerid, FFishingTXD[playerid][11], 0);
    PlayerTextDrawSetProportional(playerid, FFishingTXD[playerid][11], 1);
    PlayerTextDrawSetSelectable(playerid, FFishingTXD[playerid][11], 0);
    
    fishShoptd[playerid][0] = CreatePlayerTextDraw(playerid, 314.000000, 298.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][0], 0.395832, 1.899999);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][0], 297.500000, 76.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][0], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][0], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][0], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][0], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][0], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][0], 9109759);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][0], 0);

    fishShoptd[playerid][1] = CreatePlayerTextDraw(playerid, 384.000000, 129.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][1], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][1], 0.395832, 1.899999);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][1], 297.500000, 76.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][1], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][1], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][1], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][1], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][1], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][1], -1962934017);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][1], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][1], 0);

    fishShoptd[playerid][2] = CreatePlayerTextDraw(playerid, 384.000000, 130.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][2], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][2], 0.600000, 1.650001);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][2], 298.500000, 75.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][2], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][2], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][2], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][2], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][2], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][2], -16776961);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][2], 0);

    fishShoptd[playerid][3] = CreatePlayerTextDraw(playerid, 374.000000, 128.000000, "ld_chat:thumbdn");  // ปุ่มออก
    PlayerTextDrawFont(playerid, fishShoptd[playerid][3], 4);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][3], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][3], 20.500000, 19.500000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][3], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][3], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][3], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][3], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][3], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][3], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][3], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][3], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][3], 1);

    fishShoptd[playerid][4] = CreatePlayerTextDraw(playerid, 247.000000, 137.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][4], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][4], 0.600000, 10.300003);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][4], 294.500000, 43.500000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][4], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][4], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][4], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][4], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][4], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][4], -1094795521);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][4], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][4], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][4], 0);

    fishShoptd[playerid][5] = CreatePlayerTextDraw(playerid, 187.000000, 120.000000, "Preview_Model");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][5], 5);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][5], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][5], 112.500000, 150.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][5], 0);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][5], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][5], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][5], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][5], 0);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][5], 255);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][5], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][5], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][5], 0);
    PlayerTextDrawSetPreviewModel(playerid, fishShoptd[playerid][5], 18632);
    PlayerTextDrawSetPreviewRot(playerid, fishShoptd[playerid][5], -10.000000, 0.000000, -20.000000, 1.000000);
    PlayerTextDrawSetPreviewVehCol(playerid, fishShoptd[playerid][5], 1, 1);

    fishShoptd[playerid][6] = CreatePlayerTextDraw(playerid, 247.000000, 240.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][6], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][6], 0.600000, 10.300003);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][6], 294.500000, 43.500000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][6], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][6], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][6], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][6], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][6], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][6], -1094795521);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][6], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][6], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][6], 0);

    fishShoptd[playerid][7] = CreatePlayerTextDraw(playerid, 202.000000, 239.000000, "Preview_Model");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][7], 5);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][7], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][7], 78.500000, 87.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][7], 0);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][7], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][7], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][7], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][7], 0);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][7], 255);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][7], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][7], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][7], 0);
    PlayerTextDrawSetPreviewModel(playerid, fishShoptd[playerid][7], 757);
    PlayerTextDrawSetPreviewRot(playerid, fishShoptd[playerid][7], -10.000000, 0.000000, -20.000000, 1.000000);
    PlayerTextDrawSetPreviewVehCol(playerid, fishShoptd[playerid][7], 1, 1);

    fishShoptd[playerid][8] = CreatePlayerTextDraw(playerid, 284.000000, 160.000000, "HUD:radar_cash");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][8], 4);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][8], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][8], 11.500000, 14.500000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][8], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][8], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][8], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][8], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][8], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][8], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][8], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][8], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][8], 0);

    fishShoptd[playerid][9] = CreatePlayerTextDraw(playerid, 299.000000, 157.000000, "1500"); // Soll1
    PlayerTextDrawFont(playerid, fishShoptd[playerid][9], 2);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][9], 0.224999, 1.799999);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][9], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][9], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][9], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][9], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][9], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][9], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][9], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][9], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][9], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][9], 0);

    fishShoptd[playerid][10] = CreatePlayerTextDraw(playerid, 314.000000, 193.000000, "_");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][10], 1);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][10], 0.395832, 1.899999);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][10], 297.500000, 76.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][10], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][10], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][10], 2);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][10], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][10], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][10], 9109759);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][10], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][10], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][10], 0);

    fishShoptd[playerid][11] = CreatePlayerTextDraw(playerid, 302.000000, 192.000000, "BUY"); //ซื้อ
    PlayerTextDrawFont(playerid, fishShoptd[playerid][11], 2);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][11], 0.316666, 1.999997);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][11], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][11], 0);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][11], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][11], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][11], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][11], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][11], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][11], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][11], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][11], 1);

    fishShoptd[playerid][12] = CreatePlayerTextDraw(playerid, 284.000000, 263.000000, "HUD:radar_cash");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][12], 4);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][12], 0.600000, 2.000000);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][12], 11.500000, 14.500000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][12], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][12], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][12], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][12], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][12], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][12], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][12], 1);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][12], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][12], 0);

    fishShoptd[playerid][13] = CreatePlayerTextDraw(playerid, 299.000000, 260.000000, "10");//Soll2
    PlayerTextDrawFont(playerid, fishShoptd[playerid][13], 2);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][13], 0.224999, 1.799999);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][13], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][13], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][13], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][13], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][13], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][13], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][13], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][13], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][13], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][13], 0);

    fishShoptd[playerid][14] = CreatePlayerTextDraw(playerid, 218.000000, 219.000000, "fishing rod");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][14], 3);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][14], 0.320832, 1.449998);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][14], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][14], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][14], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][14], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][14], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][14], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][14], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][14], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][14], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][14], 0);

    fishShoptd[playerid][15] = CreatePlayerTextDraw(playerid, 219.000000, 329.000000, "bait");
    PlayerTextDrawFont(playerid, fishShoptd[playerid][15], 3);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][15], 0.320832, 1.449998);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][15], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][15], 1);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][15], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][15], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][15], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][15], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][15], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][15], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][15], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][15], 0);

    fishShoptd[playerid][16] = CreatePlayerTextDraw(playerid, 302.000000, 296.000000, "BUY"); //ซื้อเหยื่อ
    PlayerTextDrawFont(playerid, fishShoptd[playerid][16], 2);
    PlayerTextDrawLetterSize(playerid, fishShoptd[playerid][16], 0.316666, 1.999997);
    PlayerTextDrawTextSize(playerid, fishShoptd[playerid][16], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, fishShoptd[playerid][16], 0);
    PlayerTextDrawSetShadow(playerid, fishShoptd[playerid][16], 0);
    PlayerTextDrawAlignment(playerid, fishShoptd[playerid][16], 1);
    PlayerTextDrawColor(playerid, fishShoptd[playerid][16], -1);
    PlayerTextDrawBackgroundColor(playerid, fishShoptd[playerid][16], 255);
    PlayerTextDrawBoxColor(playerid, fishShoptd[playerid][16], 50);
    PlayerTextDrawUseBox(playerid, fishShoptd[playerid][16], 0);
    PlayerTextDrawSetProportional(playerid, fishShoptd[playerid][16], 1);
    PlayerTextDrawSetSelectable(playerid, fishShoptd[playerid][16], 1);
}


CMD:statsfish(playerid)
{
   if(playerData[playerid][pAdmin] > 1) return 1;
   SendClientMessageEx(playerid, -1, "StartFishingNor = %d CountFishingNor = %d TakeFishingbat = %d", StartFishingNor[playerid], CountFishingNor[playerid], TakeFishingbat[playerid]);
   return 1;
}


// textdraw zone ......


stock ShowTextDrawFishing(playerid)
{
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][0]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][1]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][2]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][3]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][4]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][5]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][6]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][7]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][8]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][9]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][10]);
    PlayerTextDrawShow(playerid, FFishingTXD[playerid][11]); 
    return 1;
}
 
stock HideTextDrawFishing(playerid)
{
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][0]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][1]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][2]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][3]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][4]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][5]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][6]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][7]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][8]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][9]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][10]);
    PlayerTextDrawHide(playerid, FFishingTXD[playerid][11]);
    return 1;

}

stock ShowTextdarwShopFish(playerid) 
{
    PlayerTextDrawShow(playerid, fishShoptd[playerid][0]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][1]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][2]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][3]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][4]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][5]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][6]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][7]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][8]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][9]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][10]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][11]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][12]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][13]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][14]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][15]);
    PlayerTextDrawShow(playerid, fishShoptd[playerid][16]);
    SelectTextDraw(playerid, 0xFF0000FF);
}


stock HideTextdarwShopFish(playerid) 
{
    PlayerTextDrawHide(playerid, fishShoptd[playerid][0]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][1]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][2]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][3]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][4]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][5]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][6]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][7]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][8]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][9]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][10]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][11]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][12]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][13]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][14]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][15]);
    PlayerTextDrawHide(playerid, fishShoptd[playerid][16]);
    CancelSelectTextDraw(playerid);
}
