#include "mbed.h"


// Blinking rate in milliseconds
//#define 	     1000ms

CAN     Can1(PA_11, PA_12, 125000);
static BufferedSerial serial_port(PA_2, PA_3, 38400);
char   ustr[256];

//---------------------------------------------------------------------------
// Char Code
//---------------------------------------------------------------------------
char    CharCode[] = {
//       0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 1
     0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, // 2
     1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, // 3
     1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, // 4
     1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, // 5
     1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, // 6
     1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0  // 7
};

//---------------------------------------------------------------------------
// シリアルからのコマンド入力
//---------------------------------------------------------------------------
char * get_cmd()
{
    int     n, m, k;
    char    buf[256];
static char ucmd[256];

    m = 0;
    while(true) {
        k = serial_port.read(buf, sizeof(buf));
        if(k != 0) {
            for(n = 0; n < k; n++) {
                if(buf[n] == '\r' || buf[n] == '\n') {
                    ucmd[m] = 0;
                    return(ucmd);
                } else {
                    ucmd[m] = buf[n];
                    m++;
                }
            }
        }
    }
}
//---------------------------------------------------------------------------
// CAN送信
//---------------------------------------------------------------------------
void CAN_Tx(int ID, char Cmd, int Obj, char Sub, int Data)
{
    char    TxD[8];

    TxD[0] = Cmd;
    TxD[1] =  Obj & 0x00FF;
    TxD[2] = (Obj & 0xFF00) >> 8;
    TxD[3] = Sub;
    TxD[4] =  Data & 0x000000FF;
    TxD[5] = (Data & 0x0000FF00) >> 8;
    TxD[6] = (Data & 0x00FF0000) >> 16;
    TxD[7] = (Data & 0xFF000000) >> 24;
    Can1.write(CANMessage(ID, &TxD[0], 8));
}
//---------------------------------------------------------------------------
// CAN受信
//---------------------------------------------------------------------------
int CAN_Rx()
{
    int     n;
static int  Data;
    CANMessage msg;

    for(n = 0; n < 10000; n++) {
        //ThisThread::sleep_for(1ms);
        if(Can1.read(msg)) {
            switch(msg.data[0]) {
                case    0x4F:
                    Data  = msg.data[4];
                    Data |= msg.data[5] << 8;
                    break;
                case    0x4B:
                    Data  = msg.data[4];
                    Data |= msg.data[5] << 8;
                    break;
                case    0x47:
                    Data  = msg.data[4];
                    Data |= msg.data[5] << 8;
                    Data |= msg.data[6] << 16;
                    break;
                case    0x60:
                case    0x43:
                    Data  = msg.data[4];
                    Data |= msg.data[5] << 8;
                    Data |= msg.data[6] << 16;
                    Data |= msg.data[7] << 24;
                    break;
            }
            return(Data);
        }
    }
    printf("ERROR CAN_Rx Timeout\r\n");
    return(0);
}
//---------------------------------------------------------------------------
// IGUS_BootUP
//---------------------------------------------------------------------------
int BootUP(int ID)
{
    int     n, k;

    Can1.reset();
    ThisThread::sleep_for(10ms);
    
    //---------------------------------------------------------
    // Enable Status Check
    //---------------------------------------------------------
    CAN_Tx(ID, 0x40, 0x6041, 0, 0);
    k = CAN_Rx();
   //printf("    Enable Status Check Status[%04X] & 0x0200\r\n", k);
    if((k & 0x0200) == 0) {
        printf("    ERROR IGUS_BootUP Digital Input 7 is LOW (Status bit 9)\r\n");
        return(-1);
    }
    //---------------------------------------------------------
    // Shutdown
    //---------------------------------------------------------
    for(n = 0, k = 0; n < 10 && (k & 0x0FFF) != 0x0621; n++) {
        CAN_Tx(ID, 0x2B, 0x6040, 0, 0x0006);
        ThisThread::sleep_for(10ms);
        k = CAN_Rx();
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
        //printf("    Shutdown            Status[%04X]\r\n", k);
    }
    if((k & 0x0FFF) != 0x0621) {
        printf("    ERROR IGUS_BootUP Shutdown 0x0621\r\n");
        return(-1);
    }
    //---------------------------------------------------------
    // Switch ON
    //---------------------------------------------------------
    for(n = 0, k = 0; n < 10 && (k & 0x0FFF) != 0x0623; n++) {
        CAN_Tx(ID, 0x2B, 0x6040, 0, 0x0007);
        ThisThread::sleep_for(10ms);
        k = CAN_Rx();
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
        //printf("    Switch ON           Status[%04X]\r\n", k);
    }
    if((k & 0x0FFF) != 0x0623) {
        printf("    ERROR IGUS_BootUP Switch ON 0x0623\r\n");
        return(-1);
    }
    //---------------------------------------------------------
    // Enable Operation
    //---------------------------------------------------------
    for(n = 0, k = 0; n < 10 && (k & 0x0F7F) != 0x0627; n++) {
        CAN_Tx(ID, 0x2B, 0x6040, 0, 0x000F);
        ThisThread::sleep_for(200ms);
        k = CAN_Rx();
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
        //printf("    Enable Operation    Status[%04X]\r\n", k);
    }
    if((k & 0x0F7F) != 0x0627) {
        printf("    ERROR IGUS_BootUP Enable Operation 0x0627\r\n");
        return(-1);
    }

    printf("BootUP[%04X][%04X]\r\n", ID, k & 0xFFFF);
    return(1);
}
//---------------------------------------------------------------------------
// Check Error Code
//---------------------------------------------------------------------------
void Check_Error(int ID)
{
    int     n, m, k;

    Can1.reset();
    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x40, 0x1003, 0, 0);
    m = CAN_Rx();
    //printf("Number of entries [%04X]\r\n", m);
    for(n = 1; n < m + 1 && n < 9; n++) {
        ThisThread::sleep_for(1ms);
        CAN_Tx(ID, 0x40, 0x1003, n, 0);
        k = CAN_Rx();
        //printf("Error Code%d  [%04X]\r\n", n, k);
    }
    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x40, 0x103F, 0, 0);
    k = CAN_Rx();
    switch(k) {
        case    0x0000: sprintf(ustr, "No Error");                         break;
        case    0x6320: sprintf(ustr, "Error Configuration");              break;
        case    0x2320: sprintf(ustr, "Motor Over-Current");               break;
        case    0x2311: sprintf(ustr, "Encoder Over-Current");             break;
        case    0x2312: sprintf(ustr, "10 V Output Over Current 2312h");   break;
        case    0x5114: sprintf(ustr, "I/O Supply Low");                   break;
        case    0x3222: sprintf(ustr, "Logic Supply Low");                 break;
        case    0x3112: sprintf(ustr, "Logic Supply High");                break;
        case    0x3221: sprintf(ustr, "Load  Supply Low");                 break;
        case    0x3211: sprintf(ustr, "Load  Supply High");                break;
        case    0x4310: sprintf(ustr, "Temperature High");                 break;
        case    0x8611: sprintf(ustr, "Following Error");                  break;
        case    0xFF00: sprintf(ustr, "Limit Switch");                     break;
        case    0x7306: sprintf(ustr, "Hall Sensor");                      break;
        case    0x7305: sprintf(ustr, "Encoder");                          break;
        case    0xFF01: sprintf(ustr, "Encoder Channel A");                break;
        case    0xFF02: sprintf(ustr, "Encoder Channel B");                break;
        case    0xFF03: sprintf(ustr, "Encoder Channel I");                break;
        case    0x7110: sprintf(ustr, "Braking Resistor Overload");        break;
        default:        sprintf(ustr, "Unknown Error[%04X]", k);           break;
    }

    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x40, 0x6041, 0, 0);
    k = CAN_Rx();
    //printf("Status_[%04X]\r\n", k & 0xFFFF);
    ThisThread::sleep_for(10ms);
    if((k & 0x0088) != 0) {
        CAN_Tx(ID, 0x2B, 0x6040, 0, 0x00CF);        // Error Reset = 1
        k = CAN_Rx();
        ThisThread::sleep_for(10ms);
        CAN_Tx(ID, 0x2B, 0x6040, 0, 0x004F);        // Error Reset = 0
        k = CAN_Rx();
    }
    
    for(n = 0, k = 0xFFFF; n < 10 && (k & 0x0008) != 0; n++) {
        ThisThread::sleep_for(100ms);
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
    }
    ThisThread::sleep_for(100ms);
    CAN_Tx(ID, 0x40, 0x6041, 0, 0);
    k = CAN_Rx();
    printf("Error Reset[%04X][%04X][%s]\r\n", ID, k & 0xFFFF, ustr);
}
//---------------------------------------------------------------------------
// Move Positioning (Relative / Absolute)
//---------------------------------------------------------------------------
void Move_REL(int ID, int Pos, int Mode, char Speed)
{
    int     n, m, k, CanDat;

    //---------------------------------------------------------
    // Profile Position mode
    //---------------------------------------------------------
    CAN_Tx(ID, 0x2F, 0x6060, 0, 1);
    k = CAN_Rx();

    //---------------------------------------------------------
    // Feed Constant
    //---------------------------------------------------------
    if(ID == 0x603) {
        CAN_Tx(ID, 0x23, 0x6092, 1, 4400);
    } else {
        CAN_Tx(ID, 0x23, 0x6092, 1, 7000);
    }
    k = CAN_Rx();
    CAN_Tx(ID, 0x23, 0x6092, 2, 1);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Target Position
    //---------------------------------------------------------
    CAN_Tx(ID, 0x23, 0x607A, 0, Pos);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Profile Acceleration
    //---------------------------------------------------------
    if(Speed == 'H') {
        CAN_Tx(ID, 0x23, 0x6083, 0, 8000);
    } else {
        CAN_Tx(ID, 0x23, 0x6083, 0, 2000);
    }
    
    k = CAN_Rx();
    //---------------------------------------------------------
    // Profile Velocity
    //---------------------------------------------------------
    if(Speed == 'H') {
        CAN_Tx(ID, 0x23, 0x6081, 0, 8000);
    } else {
        CAN_Tx(ID, 0x23, 0x6081, 0, 4000);
    }
    k = CAN_Rx();
    //---------------------------------------------------------
    // Profile Deceleration
    //---------------------------------------------------------
    if(Speed == 'H') {
        CAN_Tx(ID, 0x23, 0x6084, 0, 8000);
    } else {
        CAN_Tx(ID, 0x23, 0x6084, 0, 2000);
    }
    k = CAN_Rx();
    //---------------------------------------------------------
    // Controlword
    //---------------------------------------------------------
    if(Mode == 1) {
        CanDat = 0x004F;                                // Relative Positioning
    } else {
        CanDat = 0x000F;                                // Absolute Positioning
    }
    CAN_Tx(ID, 0x2B, 0x6040, 0, CanDat);  
    k = CAN_Rx();
    ThisThread::sleep_for(1ms);
    CAN_Tx(ID, 0x2B, 0x6040, 0, CanDat |= 0x0010);      // Start of Movement = 1
    k = CAN_Rx();
    for(n = 0, k = 0; n < 100 && (k & 0x1000) == 0; n++) {
        ThisThread::sleep_for(1ms);
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
        //printf("Status1[%04X]\r\n", k);
    }
    CAN_Tx(ID, 0x2B, 0x6040, 0, CanDat);                // Start of Movement = 0
    k = CAN_Rx();
    for(n = 0; n < 1000 && (k & 0x0400) == 0; n++) {     // Wait for Target reached
        ThisThread::sleep_for(100ms);
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
        //printf("Status2[%04X]\r\n", k);
    }
    //---------------------------------------------------------
    // Position Actual Value
    //---------------------------------------------------------
    CAN_Tx(ID, 0x40, 0x6064, 0, 0);
    m = CAN_Rx();
    ThisThread::sleep_for(10ms);
    //---------------------------------------------------------
    // Status
    //---------------------------------------------------------
    CAN_Tx(ID, 0x40, 0x6041, 0, 0);
    k = CAN_Rx();
    //printf("Status[%04X]\r\n", k & 0xFFFF);
    if((k & 0x0FFF) != 0x0627) {
        ThisThread::sleep_for(2s);
        CAN_Tx(ID, 0x40, 0x6041, 0, 0);
        k = CAN_Rx();
    }
    if((k & 0x0FFF) != 0x0627) {
        Check_Error(ID);
        BootUP(ID);
    }
    if(Mode == 1) {
        printf("Move[%04X][Relative][%04X][%d]\r\n", ID, k & 0xFFFF, m);
    } else {
        printf("Move[%04X][Absolute][%04X][%d]\r\n", ID, k & 0xFFFF, m);
    }
}
//---------------------------------------------------------------------------
// Homing
//---------------------------------------------------------------------------
void Homing(int ID)
{
    int     n, m, k;
    
    //---------------------------------------------------------
    // homing mode
    //---------------------------------------------------------
    CAN_Tx(ID, 0x2F, 0x6060, 0, 6);
    k = CAN_Rx();
    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x2B, 0x6040, 0, 0x004F);
    k = CAN_Rx();
    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x2B, 0x6040, 0, 0x00CF);
    k = CAN_Rx();
    ThisThread::sleep_for(10ms);
    CAN_Tx(ID, 0x2B, 0x6040, 0, 0x004F);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Feed Constant
    //---------------------------------------------------------
    //CAN_Tx(ID, 0x23, 0x6092, 1, 6897);
    CAN_Tx(ID, 0x23, 0x6092, 1, 7000);
    k = CAN_Rx();
    CAN_Tx(ID, 0x23, 0x6092, 2, 1);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Switch & Zero Search Speed
    //---------------------------------------------------------
    CAN_Tx(ID, 0x23, 0x6099, 1, 1000);
    k = CAN_Rx();
    CAN_Tx(ID, 0x23, 0x6099, 2, 1000);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Acceleration/deceleration for homing run
    //---------------------------------------------------------
    CAN_Tx(ID, 0x23, 0x609A, 1, 1000);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Referencing method
    //---------------------------------------------------------
    //CAN_Tx(ID, 0x2F, 0x6098, 0, 17);    // LSN Limit Switch Negativ
    CAN_Tx(ID, 0x2F, 0x6098, 0, 37);    // SCP Set Current Position
    k = CAN_Rx();
    //---------------------------------------------------------
    // Home Point Offset (optional in user interface)
    //---------------------------------------------------------
    CAN_Tx(ID, 0x23, 0x607C, 0, 0);
    k = CAN_Rx();
    //---------------------------------------------------------
    // Controlword
    //---------------------------------------------------------
    ThisThread::sleep_for(10ms);

    CAN_Tx(ID, 0x2B, 0x6040, 0, 0x005F);                // Start of Movement = 1
    //CAN_Tx(ID, 0x2B, 0x6040, 0, 0x0040);                // Start of Movement = 1
    k = CAN_Rx();
    ThisThread::sleep_for(100ms);

    CAN_Tx(ID, 0x2B, 0x6040, 0, 0x004F);                // Start of Movement = 0
    k = CAN_Rx();
    ThisThread::sleep_for(100ms);
    //---------------------------------------------------------
    // Position Actual Value
    //---------------------------------------------------------
    CAN_Tx(ID, 0x40, 0x6064, 0, 0);
    m = CAN_Rx();
    //---------------------------------------------------------
    // Profile Position mode
    //---------------------------------------------------------
    CAN_Tx(ID, 0x2F, 0x6060, 0, 1);
    k = CAN_Rx();
    ThisThread::sleep_for(100ms);
    //---------------------------------------------------------
    // Status
    //---------------------------------------------------------
    CAN_Tx(ID, 0x40, 0x6041, 0, 0);
    k = CAN_Rx();

    printf("Homing[%04X][%04X][%d]\r\n", ID, k & 0xFFFF, m);
}
//---------------------------------------------------------------------------
// Sys Start
//---------------------------------------------------------------------------
int SysStart()
{
    //---------------------------------------------------------
    // Error Check & Reset
    //---------------------------------------------------------
    Check_Error(0x601);
    Check_Error(0x602);
    Check_Error(0x603);
    //---------------------------------------------------------
    // Bootup
    //---------------------------------------------------------
    if(BootUP(0x601) < 0) {
        printf("Error X-axis Boot UP \r\n");
        return(-1);
    }
     if(BootUP(0x602) < 0) {
        printf("Error Y-axis Boot UP \r\n");
        return(-1);
    }
     if(BootUP(0x603) < 0) {
        printf("Error Z-axis Boot UP \r\n");
        return(-1);
    }
    //---------------------------------------------------------
    // Homing
    //---------------------------------------------------------
    Homing(0x601);
    Homing(0x602);
    Homing(0x603);
    //---------------------------------------------------------
    // Move to limit switch
    //---------------------------------------------------------
    Move_REL(0x603, -10000, 1, 'L');
    Move_REL(0x601, -53000, 1, 'L');
    Move_REL(0x602,  53000, 1, 'L');
    //---------------------------------------------------------
    // Error Check & Reset
    //---------------------------------------------------------
    Check_Error(0x601);
    Check_Error(0x602);
    Check_Error(0x603);
    //---------------------------------------------------------
    // Bootup
    //---------------------------------------------------------
    if(BootUP(0x601) < 0) {
        printf("Error X-axis Boot UP \r\n");
        return(-1);
    }
     if(BootUP(0x602) < 0) {
        printf("Error Y-axis Boot UP \r\n");
        return(-1);
    }
     if(BootUP(0x603) < 0) {
        printf("Error Z-axis Boot UP \r\n");
        return(-1);
    }
    //---------------------------------------------------------
    // Move to home point
    //---------------------------------------------------------
    Move_REL(0x601, 1000, 1, 'L');
    Move_REL(0x602, -51000, 1, 'L');
    Move_REL(0x603, 500, 1, 'L');
    //---------------------------------------------------------
    // Homing
    //---------------------------------------------------------
    Homing(0x601);
    Homing(0x602);
    Homing(0x603);
    printf("Sys Start Complte\r\n");
    return(1);
}
//---------------------------------------------------------------------------
// Help
//---------------------------------------------------------------------------
void Help()
{
    printf("--------------------------------------------------\r\n");
    printf("sta                   System Start\r\n");
    printf("ma/x/y/z (float)Pos   Move Absolute X/Y/Z-Axis\r\n");
    printf("mr/x/y/z (float)Pos   Move Relative X/Y/Z-Axis\r\n");
    printf("bo/x/y/z              Boot Up X/Y/Z-Axis\r\n");
    printf("er/x/y/z              Error Check & Rese X/Y/Z-Axis\r\n");
    printf("ho/x/y/z              Homing X/Y/Z-Axis\r\n");
    printf("po/x/y/z              Position Disp X/Y/Z-Axis\r\n");
    printf("st/x/y/z              Status Disp X/Y/Z-Axis\r\n");
    printf("he/?                  Help\r\n");
    printf("--------------------------------------------------\r\n");
}
//---------------------------------------------------------------------------
// Main
//---------------------------------------------------------------------------
int main()
{
    int     n, m, k, ID;
    char    ucmd[256];
    float   Position;
    CANMessage msg;

    serial_port.set_format(
        /* bits */ 8,
        /* parity */ BufferedSerial::None,
        /* stop bit */ 2
    );

    printf("IGS_D1_Cont Start\r\n");
    Help();

    while (true) {
        strcpy(ucmd, get_cmd());
        if(ucmd[0] == 0) {
            printf("\r\n");
        } else {
            printf("[%s]\r\n", ucmd);
        }
        //---------------------------------------------------------
        // Boot UP  bo/x/y/z
        //---------------------------------------------------------
        if(strncmp(ucmd, "bo", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) BootUP(ID);
        }
        //---------------------------------------------------------
        // Move Relative  mr/x/y/z (float)Pos
        //---------------------------------------------------------
        if(strncmp(ucmd, "mr", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) {
                for(n = 0; CharCode[ucmd[n]] != 0 && n < 8; n++);
                for(     ; ucmd[n] == ' ' || ucmd[n] == '\t'; n++);
                sscanf(&ucmd[n], "%f", &Position);
                Move_REL(ID, int(Position * 100), 1, 'L');
            }
        }
        //---------------------------------------------------------
        // Move Absolute  ma/x/y/z (float)Pos
        //---------------------------------------------------------
        if(strncmp(ucmd, "ma", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) {
                for(n = 0; CharCode[ucmd[n]] != 0 && n < 8; n++);
                for(     ; ucmd[n] == ' ' || ucmd[n] == '\t'; n++);
                sscanf(&ucmd[n], "%f", &Position);
                Move_REL(ID, int(Position * 100), 0, 'H');
            }
        }
        //---------------------------------------------------------
        // Error Check & Reset  er/x/y/z
        //---------------------------------------------------------
        if(strncmp(ucmd, "er", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) Check_Error(ID);
        }
        //---------------------------------------------------------
        // Homing
        //---------------------------------------------------------
        if(strncmp(ucmd, "ho", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) Homing(ID);
        }
        //---------------------------------------------------------
        // Position Disp  po/x/y/z
        //---------------------------------------------------------
        if(strncmp(ucmd, "po", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) {
                CAN_Tx(ID, 0x40, 0x6064, 0, 0);
                k = CAN_Rx();
                printf("Position_%c_[%9d]\r\n", ucmd[2], k);
            }
        }
        //---------------------------------------------------------
        // Status Disp  st/x/z
        //---------------------------------------------------------
        if(strncmp(ucmd, "st", 2) == 0) {
            switch(ucmd[2]) {
                case    'x':    ID = 0x601; break;
                case    'y':    ID = 0x602; break;
                case    'z':    ID = 0x603; break;
                default:        ID = 0;     break;
            }
            if(ID != 0) {
                Can1.reset();
                CAN_Tx(ID, 0x40, 0x6041, 0, 0);
                k = CAN_Rx();
                printf("Status_%c_[%04X]\r\n", ucmd[2], k & 0xFFFF);
            }
        }
        //---------------------------------------------------------
        // SysStart  sta
        //---------------------------------------------------------
        if(strncmp(ucmd, "sta", 3) == 0) {
            SysStart();
        }
        //---------------------------------------------------------
        // Help
        //---------------------------------------------------------
        if(strncmp(ucmd, "he", 2) == 0 || ucmd[0] == '?') {
            Help();
        }
    }
}