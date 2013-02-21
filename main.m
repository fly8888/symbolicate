/*

main.m ... Main for CrashReporter
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <getopt.h>
#include <string.h>

#import "symbolMaps.h"
#import "symbolicate.h"

void print_usage() {
    fprintf(stderr,
            "Usage: symbolicate [<options>] <file>\n"
            "\n"
            "Options:\n"
            "    -o <file>         Write output to file instead of to stdout.\n"
            "    -m <path,file>    Provide symbol map file for specified binary image path.\n"
            "    -n <step>         Send notifications of progress via notify_post().\n"
            "                      The notification name is \""PKG_ID".progress\".\n"
            "                      Progress percentage is obtainable via notify_get_state().\n"
            "                      Step value can be any integer 1-100.\n"
            "\n"
           );
}

int main(int argc, char *argv[]) {
    int ret = 1;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc == 1) {
        print_usage();
    } else {
        const char *outputFile = NULL;
        NSMutableDictionary *mapFiles = [NSMutableDictionary dictionary];
        unsigned progressStepping = 0;

        int c;
        while ((c = getopt (argc, argv, "o:m:n:")) != -1) {
            switch (c) {
                case 'o':
                    outputFile = optarg;
                    break;
                case 'm': {
                    char *path = strtok(optarg, ",");
                    char *file = strtok(NULL, ",");
                    if (path != NULL && file != NULL) {
                        [mapFiles setObject:[NSString stringWithCString:file encoding:NSUTF8StringEncoding]
                            forKey:[NSString stringWithCString:path encoding:NSUTF8StringEncoding]];
                    }
                    break;
                }
                case 'n':
                    progressStepping = atoi(optarg);
                    break;
                default:
                    break;
            }
        }

        const char *inputFile = (optind < argc) ? argv[optind] : NULL;
        if (inputFile == NULL) {
            print_usage();
        } else {
            NSString *filepath = [NSString stringWithUTF8String:inputFile];
            NSString *content = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:NULL];
            if (content != nil) {
                // Parse map files
                NSMutableDictionary *symbolMaps = [NSMutableDictionary dictionary];
                for (NSString *imagePath in mapFiles) {
                    NSString *mapFile = [mapFiles objectForKey:imagePath];
                    NSDictionary *result = parseMapFile(mapFile);
                    if (result != nil) {
                        [symbolMaps setObject:result forKey:imagePath];
                    }
                }

                // Symbolicate input file
                NSString *result = symbolicate(content, symbolMaps, progressStepping);
                if (result != nil) {
                    if (outputFile != NULL) {
                        NSString *path = [NSString stringWithUTF8String:outputFile];
                        [result writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
                        printf("Result written to %s.\n", outputFile);
                    } else {
                        printf("%s\n", [result UTF8String]);
                    }
                    ret = 0;
                }
            }
        }
    }

    [pool drain];
    return ret;
}

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
