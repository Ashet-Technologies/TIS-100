#include <stdio.h>

int main(int argc, char **argv)
{
	setvbuf(stdout, NULL, _IONBF, 0);
	int cnt = 0;
	while(!feof(stdin))
	{
		int val = getc(stdin);
		
		if(cnt > 0 && (cnt % 10) == 0) {
			fprintf(stdout, "\n");
		}
		fprintf(stdout, "%3d ", val);
		if(val == 10) {
			fprintf(stdout, "\n");
		}
		fflush(stdout);
		
		cnt ++;
	}
	fprintf(stdout, "\n");
	fflush(stdout);

	return 0;
}