#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include "x10ephem.h"
#include <time.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

#define LATITUDE 33.4827
#define LONGITUDE -112.0321
#define TIMEZONE -7 		// could get the system value for that
#define MAXRAND 100	// how many unique random values will we use?
										// Beyond this, they're
#define RANDOM_SEED_FILENAME "/var/tmp/devcron-random-seed"
#define MISSING_DEVICE_RETRY 3

const char* randomSeedFilename = RANDOM_SEED_FILENAME;
const char* devicesDir = "/mnt/x10";
const char* timersDir = "/var/www/lights/timers";
const char* backupTimersDir = "/var/www/lights/timers-ro";
const char* rebootCommand = "/sbin/shutdown -r +1 &";
int Y = -1;
int M = -1;
int D = -1;
int currentHour = -1;
int currentMinute = -1;
char weekday[32];	// Cover most languages in UTF-8 we hope
float sunrise;
float sunset;
int seedInited = false;

enum {
	LINE_ON = 0,
	LINE_OFF,
	LINE_DAYS,
	LINE_DEVICE,
	LINE_OPTIONS,
	LINE_COUNT
};

/**
	Specialized rand(): uses the same pseudo-random sequence all day long.
	Uses different numbers each day though.
	So we store the seed in /var/tmp/devcron-random-seed in binary form,
	but if the file doesn't exist or it's now a new day (based on last changed time
	of the file), we re-create it, by taking 4 bytes from /dev/random.
*/
int randImpl(int range)
{
	if (!seedInited)
	{
		struct stat seedStat;
		int seedOK = true;
		if (stat(randomSeedFilename, &seedStat))
		{
			seedOK = false;
			if (errno != ENOENT)
			{
				perror("stat " RANDOM_SEED_FILENAME);
				exit(-1);
			}
		}
		if (seedOK)
		{
			struct tm* modTime = localtime(&seedStat.st_mtime);
			//~ printf("%s last modified on the %dth; today is the %dth\n",
				//~ randomSeedFilename, modTime->tm_mday, D);
			if (modTime->tm_mday != D)
				seedOK = false;
		}
		if (!seedOK)
		{
			// Create it and init the seed too
			unsigned int seed;
			int fd = open("/dev/random", O_RDONLY);
			read(fd, &seed, sizeof(seed));
			close(fd);
			srandom(seed);
			seedInited = true;
			fd = open(randomSeedFilename, O_WRONLY | O_CREAT, 0644);
			write(fd, &seed, sizeof(seed));
			close(fd);
			//~ printf("wrote new random seed %d\n", seed);
		}
		if (!seedInited)
		{
			int fd = open(randomSeedFilename, O_RDONLY);
			unsigned int seed;
			read(fd, &seed, sizeof(seed));
			close(fd);
			//~ printf("read random seed %d\n", seed);
			srandom(seed);
			seedInited = true;
		}
	}
	return range * random() / UINT_MAX;
}

/**
	@return device type, or number < 0 if something is wrong
		(indicating the probable need to reboot)
*/
int checkDeviceType(const char* devPath)
{
	struct stat devStat;
	if (stat(devPath, &devStat))
	{
		perror(devPath);
		return -1;
	}
	else
	{
		//~ printf("      stat says %s is of type ", devPath);
		switch (devStat.st_mode & S_IFMT)
		{
			case S_IFBLK:
				//~ printf("block device\n");
				break;
			case S_IFCHR:
				//~ printf("character device\n");
				break;
			case S_IFDIR:
				//~ printf("directory\n");
				break;
			case S_IFIFO:
				//~ printf("FIFO/pipe\n");
				break;
			case S_IFLNK:
				//~ printf("symlink\n");
				break;
			case S_IFREG:
				//~ printf("regular file\n");
				break;
			case S_IFSOCK:
				//~ printf("socket\n");
				break;
			default:
				//~ printf("unknown?\n");
				return -2;
				break;
		}
		return devStat.st_mode & S_IFMT;
	}
}

void onOff(const char* device, int state, bool log)
{
	char devPath[256];
	if (log)
		printf("      let's do it! %d -> %s\n", state, device);
	snprintf(devPath, 256, "%s/%s", devicesDir, device);
	int deviceType = checkDeviceType(devPath);

	int fd = open(devPath, O_WRONLY);
	if (fd > 0)
	{
		write(fd, (state ? "1" : "0"), 1);
		close(fd);
		sleep(1);
		fd = open(devPath, O_WRONLY);
		if (fd > 0)
		{
			write(fd, (state ? "1" : "0"), 1);
			close(fd);
		}
	}
	else
	{
		perror(devPath);
		if (deviceType == S_IFLNK)
			printf("reboot command '%s' returned %d\n", rebootCommand,
				system(rebootCommand));
	}
}

/**
	Calculate a "good" end time for the pool pump, based
	on the given start time and the sunrise/sunset times, such that
	it will run for a long time on long summer days and a short time
	on winter days, but never less than 6 hours or longer than 12 hours.
*/
float poolOffTimeCalculator(float startTime)
{
	// (* 2.5 (- 20.00 5.050000 8)) would be longer, 17.375 hours
	float ret = (sunset - sunrise - 8.0) * 1.5;
	//~ printf("      would like to run the pool pump for %f hours (before 6/12 boundary check)\n", ret);
	if (ret < 6.0)
		ret = 6.0;
	if (ret > 12.0)
		ret = 12.0;
	// Now we have a number of hours.  Add it to the start time to get the end time.
	ret += startTime;
	// But if we go past midnight, convert to time of the next day.
	if (ret >= 24.00)
		ret -= 24.00;
	//~ printf("      start time is %f so end time is %f\n", startTime, ret);
	return ret;
}

void handleTimerFile(const char* filepath)
{
	FILE* f = fopen(filepath, "r");
	if (f)
	{
		char line[80];
		bool dayMatch = false;
		bool babysitOn = false;
		bool babysitOff = false;
		int hours[2] = { -1, -1 };
		int mins[2] = { -1, -1 };
		char device[80] = "";
		int lineIdx = -1;
		while (fgets(line, 80, f) && ++lineIdx < LINE_COUNT)
		{
//			printf("   %s", line);
			if (lineIdx < LINE_DAYS)	// on time or off time
			{
				if (strstr(line, "sunrise") && lineIdx < 2)
				{
					hours[lineIdx] = (int)floor(sunrise);
					mins[lineIdx] = (int)((sunrise - floor(sunrise))*60);
					//~ printf("      sunrise means %02d:%02d\n", hours[lineIdx], mins[lineIdx]);
				}
				else if (strstr(line, "sunset"))
				{
					hours[lineIdx] = (int)floor(sunset);
					mins[lineIdx] = (int)((sunset - floor(sunset))*60);
					//~ printf("      sunset means %02d:%02d\n", hours[lineIdx], mins[lineIdx]);
				}
				else if (strstr(line, "pool-calc"))
				{
					if (lineIdx == LINE_ON)
					{
						hours[LINE_ON] = 20;
						mins[LINE_ON] = 0;
					}
					else
					{
						float offTime = poolOffTimeCalculator((float)hours[LINE_ON] + mins[LINE_ON] / 60.0);
						hours[lineIdx] = (int)floor(offTime);
						mins[lineIdx] = (int)((offTime - floor(offTime))*60);
					}
					//~ printf("      pool-calc gave us %02d:%02d\n", hours[lineIdx], mins[lineIdx]);
				}
				else if (isdigit(line[0]))
				{
					char* colon = 0;
					hours[lineIdx] = strtol(line, &colon, 10);
					mins[lineIdx] = strtol(colon + 1, NULL, 10);
					//~ printf("      read that as %02d:%02d\n", hours[lineIdx], mins[lineIdx]);
				}
				char* theRand = strstr(line, "rand");
				if (theRand)
				{
					int randRange = strtol(theRand + 5, NULL, 10);
					int randVal = randImpl(randRange);
					//~ printf("      + random(%d) -> %d minutes\n", randRange, randVal);
				}
			}
			else if (lineIdx == LINE_DAYS)
			{
				char* tok = strtok(line, " ");
				while (tok && tok[0] != '\n')
				{
					//~ printf("      is today %s?\n", tok);
					if (strcmp(tok, weekday) == 0)
					{
						//~ printf("      today's the day\n");
						dayMatch = true;
						tok = NULL;
					}
					else
						tok = strtok(NULL, " ");
				}
			}
			else if (lineIdx == LINE_DEVICE)
				strncpy(device, line, 80);
			else if (lineIdx == LINE_OPTIONS)
			{
				if (strstr(line, "babysit-on"))
				{
					babysitOn = true;
				}
				if (strstr(line, "babysit-off"))
				{
					babysitOff = true;
				}
//				printf("   babysitting on? %d off? %d", babysitOn, babysitOff);
			}
		}
		fclose(f);
		device[strlen(device) - 1] = 0;
		//~ printf("   test to turn it on: %d && %d == %d && %d == %d\n",
			//~ dayMatch, hours[0], currentHour, mins[0], currentMinute);
		if (dayMatch)
		{
			if (babysitOn || babysitOff)
			{
				int endHour = hours[1];
				if (endHour < hours[0])
					endHour += 24;
				bool shouldBeOn =
					((currentHour == hours[0] && currentMinute >= mins[0]) || currentHour > hours[0]) &&
					((currentHour == endHour && currentMinute < mins[1]) || currentHour < endHour) ||
					((currentHour + 24 == hours[0] && currentMinute >= mins[0]) || currentHour + 24 > hours[0]) &&
					((currentHour + 24 == endHour && currentMinute < mins[1]) || currentHour + 24 < endHour);
				//printf("      babysitting %s: comparing current time %02d:%02d to start %02d:%02d and end %02d:%02d; should be on? %d\n", device, currentHour, currentMinute, hours[0], mins[0], endHour, mins[1], shouldBeOn);
				if (babysitOn && shouldBeOn || babysitOff && !shouldBeOn)
					onOff(device, shouldBeOn, false);
			}
			if (hours[0] == currentHour && mins[0] == currentMinute)
			{
				onOff(device, 1, true);
			}
			else if (hours[1] == currentHour && mins[1] == currentMinute)
			{
				onOff(device, 0, true);
			}
		}
	}
}

int main()
{
	char filepath[512];
	struct dirent **namelist;
	int n;
	int startDay = -1;

	int itrash;
	float ftrash;

	// For how many minutes have we had trouble accessing certain devices?
	// If it exceeds MISSING_DEVICE_RETRY we will reboot.
	int problemDeviceCount = 0;

	// Redirect stdout to a log file
	freopen("/var/log/devcrond", "w", stdout);
	freopen("/var/log/devcrond", "w", stderr);

	while (1)
	{
		time_t wallclock;
		time(&wallclock);
		struct tm *tmp = localtime(&wallclock);
		Y = tmp->tm_year+1900;
		M = tmp->tm_mon+1;
		D = tmp->tm_mday;
		currentHour = tmp->tm_hour;
		currentMinute = tmp->tm_min;
		// If srandom(seed) is called again, we will restart the sequence.
		// So make sure that happens for each pass.
		seedInited = false;
		//~ printf("\n");
		if (D != startDay)
		{
			printf("It's a brand-new day!\n");
			strftime(weekday, 32, "%A", tmp);
			weekday[0] = tolower(weekday[0]);	// Not for UTF-8 though
			riseset(LATITUDE, LONGITUDE, TIMEZONE, Y, M, D, itrash, sunrise, ftrash,  itrash, sunset, ftrash, itrash);
			startDay = D;
		}
		//~ printf("Local time is %s %d/%02d/%02d %02d:%02d:%02d\n", weekday, Y, M, D, currentHour, currentMinute, tmp->tm_sec);
		//~ printf("sunrise %f sunset %f\n", sunrise, sunset);

		// Check all devices to make sure they exist.
		// If they don't, for MISSING_DEVICE_RETRY minutes in a row, then reboot.
		n = scandir(devicesDir, &namelist, 0, 0);
		if (n < 0)
			perror(devicesDir);
		else
		{
			int anyProblem = false;
			while (n--)
			{
				if (namelist[n]->d_name[0] != '.')
				{
					sprintf(filepath, "%s/%s", devicesDir, namelist[n]->d_name);
					if (checkDeviceType(filepath) < 0)
					{
						anyProblem = true;
						printf("PROBLEM with %s\n", filepath);
					}
				}
				free(namelist[n]);
			}
			free(namelist);
			if (anyProblem)
			{
				problemDeviceCount++;
				printf("problemDeviceCount %d\n", problemDeviceCount);
			}
			else
			{
				problemDeviceCount = 0;
				//~ printf("no problemo, all devices present\n");
			}
			if (problemDeviceCount > MISSING_DEVICE_RETRY)
				printf("reboot command '%s' returned %d\n", rebootCommand,
					system(rebootCommand));
		} // if scandir is OK

		// Check all timers in the writeable directory
		n = scandir(timersDir, &namelist, 0, 0);
		if (n < 0)
			perror(timersDir);
		else
		{
			while (n--)
			{
				if (namelist[n]->d_name[0] != '.')
				{
					sprintf(filepath, "%s/%s", timersDir, namelist[n]->d_name);
					//~ printf("%s:\n", filepath);
					handleTimerFile(filepath);
				}
				free(namelist[n]);
			}
			free(namelist);
		} // if scandir is OK

		// Check all timers in the backup read-only directory,
		// but ignore those with the same names as we already have
		// in the writeable directory.
		n = scandir(backupTimersDir, &namelist, 0, 0);
		if (n < 0)
			perror(backupTimersDir);
		else
		{
			while (n--)
			{
				if (namelist[n]->d_name[0] != '.')
				{
					char rwFilepath[512];
					struct stat rwStat;
					sprintf(filepath, "%s/%s", backupTimersDir, namelist[n]->d_name);
					sprintf(rwFilepath, "%s/%s", timersDir, namelist[n]->d_name);
					//~ printf("%s:\n", filepath);
					if (stat(rwFilepath, &rwStat) && errno == ENOENT)
						handleTimerFile(filepath);
					//~ else
						//~ printf("   ignoring because %s exists\n", rwFilepath);
				}
				free(namelist[n]);
			}
			free(namelist);
		} // if scandir is OK

		// Get the time again in case all that work took too long
		time(&wallclock);
		tmp = localtime(&wallclock);
		//~ printf("time is now %d seconds; sleep %d Local seconds\n", tmp->tm_sec, 60 - tmp->tm_sec);
		fflush(NULL);
		sleep(60 - tmp->tm_sec);
	} // while
}
