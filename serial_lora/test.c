#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <sys/ioctl.h>

#define OK_PROMPT ">"

int main(int argc, char **argv)
{
    int sfd = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY);
    if(sfd < 0 ){
        printf("%d: %s\n", errno, strerror(errno));
	return -1;
    }
    
    struct termios options;
    tcgetattr(sfd, &options);

    cfsetspeed(&options, B115200);
    cfmakeraw(&options);
    options.c_cflag &= ~CSTOPB;
    options.c_cflag |= CLOCAL;
    options.c_cflag |= CREAD;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;
    options.c_cflag &= ~PARENB;
    options.c_cc[VTIME] = 0;
    options.c_cc[VMIN] = 0;
    tcsetattr(sfd, TCSANOW, &options);

    char buf[64];
    char rbuf[1050];

    char cmd = 'z';
    sprintf(buf, "%c\r\n", cmd);

    int cnt = write(sfd, buf, strlen(buf));

    usleep(1000000);
    int readbytes;
    ioctl(sfd, FIONREAD, &readbytes);
    if(readbytes != 0 ) {
        cnt = read(sfd, rbuf, 1050);
    }

    printf("%s\n", rbuf);
    printf("%c\n", rbuf[cnt-10]);
    printf("Read bytes: %d\n", cnt);

    return 0;
}
