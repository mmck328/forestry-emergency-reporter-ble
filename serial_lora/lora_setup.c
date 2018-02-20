#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <sys/ioctl.h>

//char menu[1030];
//int sfd;
//struct termios options;

#define MAX_DATA_LEN 1030
#define CRLF "\r\n"
#define ERR_PROMPT "NG 002"
#define OPRMODE_PROMPT "ready -----"
#define OPRMODE_CHK_OFFSET 14

static void exec_set_cmd(int sfd, char *cmd, char *response)
{
     char cmdbuf[16];
     memset(cmdbuf, '\0', 16);
     sprintf(cmdbuf, "%s\r\n", cmd);
     int cnt = write(sfd, cmdbuf, strlen(cmdbuf));

     usleep(100000);
     int readbytes;
     memset(response, 0, MAX_DATA_LEN);
     int pos = 0;
     unsigned int readlen = MAX_DATA_LEN;
     int err = 0;
     while(1){
         ioctl(sfd, FIONREAD, &readbytes);
         if(readbytes != 0 ) {
         	cnt = read(sfd, response+pos, readlen);
		pos += cnt;
                readlen -= cnt;
         }     
	 if(strncmp(response + (pos - strlen(ERR_PROMPT)-2), ERR_PROMPT, strlen(ERR_PROMPT)) == 0 ){
             err = 1;
	     break;
	 }
	 if(response[pos-2] == '>' ||  \
            strncmp(response + (pos - OPRMODE_CHK_OFFSET), OPRMODE_PROMPT, strlen(OPRMODE_PROMPT)) == 0  || \
            pos > MAX_DATA_LEN-2){
             break;
	 }
     }

     printf("%s\n", response);
}

static int init_lora( struct termios *options, char *menu)
{
    int sfd = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY);
    if(sfd < 0 ){
        printf("%d: %s\n", errno, strerror(errno));
	return -1;
    }
    
    tcgetattr(sfd, options);

    cfsetspeed(options, B115200);
    cfmakeraw(options);
    options->c_cflag &= ~CSTOPB;
    options->c_cflag |= CLOCAL;
    options->c_cflag |= CREAD;
    options->c_cflag &= ~CSIZE;
    options->c_cflag |= CS8;
    options->c_cflag &= ~PARENB;
    options->c_cc[VTIME] = 0;
    options->c_cc[VMIN] = 0;
    tcsetattr(sfd, TCSANOW, options);

    char cmd[] = "1\0";

    exec_set_cmd(sfd, cmd, menu);

    return sfd;
}

static int get_user_input(int sfd, char *response)
{
    char cmdbuf[256];
    memset(cmdbuf, 0, 256);
    memset(response, 0, MAX_DATA_LEN);
    printf("Your input: ");
    scanf("%s", cmdbuf);
    
    exec_set_cmd(sfd, cmdbuf, response);
}

int main(int argc, char **argv)
{

    int sfd;
    struct termios options;
    char response[MAX_DATA_LEN];

    sfd = init_lora( &options, response);

    int exit = 0;
    char usercmd[16];
    while(!exit){
	memset(usercmd, 0, 16);
        printf("Your input: ");
        scanf("%s", usercmd);
	if(usercmd[0] >= 'a' && usercmd[0] <= 'u'){
             exec_set_cmd(sfd, usercmd, response);
	     get_user_input(sfd, response);
	}
	else {
             exec_set_cmd(sfd, usercmd, response);
             if(usercmd[0] == 'z'){
                 printf("You have enter operation mode. Exiting\n");
                 break;
             }
             
	}
    }
   
    return 0;
}
