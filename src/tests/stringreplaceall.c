//
//  main.c
//  StringReplaceAll
//
//  Created by Gelei Chen on 15/5/19.
//  Copyright (c) 05/20/2015 Geilei_Chen. All rights reserved.
//

#include <stdio.h>
#include "stdlib.h"
#include "string.h"

char *strdup(const char *s);

char * replaceAll(char*src,char*from,char*to){
    //error boundary check
    if (src == NULL || from == NULL || to == NULL) {
        return NULL;
    }
    
    
    int numberOfOccurence = 0;
    char * s = (char*)malloc(sizeof(char)*strlen(src));
    strcpy(s, src);
    while (*s) {
        char * f = from;
        char * sAdd = s;
        char * sBegin = s;
        while((*f) && (*sBegin) && (*f == *sBegin)){
            f++;
            sBegin++;
        }
        if (!*f) {
            numberOfOccurence++;
        }
            s = sAdd + 1;
    }
    //printf("%d\n",numberOfOccurence);
    int length = (numberOfOccurence*strlen(to))+strlen(src)-(strlen(from)*numberOfOccurence);
    //printf("length:%d\n",length);
    s = (char*)malloc(length*sizeof(char));
    strcpy(s, src);
    
    char * stmp = s;
    
    while (*stmp) {
        char * f = from;
        char * sBegin = stmp;
        while((*f) && (*sBegin) && (*f == *sBegin)){
            f++;
            sBegin++;
        }
        if (!*f) {
            char * t = to;
            
            char * after = strdup(stmp + strlen(from));
            while (*t) {
                *stmp = *t;
                t++;
                stmp++;
            }
            
            while (*after) {
                *stmp = *after;
                stmp++;
                after++;
            }
        }
        stmp = sBegin + 1;
    }
    * (s+length) = '\0';
        return s;
        
}


int main(int argc, const char * argv[]) {
    // try my best to break the implementation
    //but it seems like I can pass all the test case below :)
    char * s = "appule pai ppoaoi";
    char * f = "pp";
    char * to = "";
    char * result = replaceAll(s,f,to);
    printf("expetced :\naule pai oaoi\n");
    printf("%s\n\n",result);
    
    s = "appule pai ppoaoi";
    f = "pp";
    to = "ou";
    result = replaceAll(s, f, to);
    printf("expetced :\naouule pai ouoaoi\n");
    printf("%s\n\n",result);
    
    s = "appule pai ppoaoi";
    f = "p";
    to = "ou";
    printf("expetced :\naououule ouai ououoaoi\n");
    result = replaceAll(s, f, to);
    printf("%s\n\n",result);
    
    s = "appule pai ppoaoi";
    f = "pai";
    to = "ou";
    printf("expetced :\nappule ou ppoaoi\n");
    result = replaceAll(s, f, to);
    printf("%s\n\n",result);
    
    s = "";
    f = "pai";
    to = "ou";
    printf("expetced :\n");
    result = replaceAll(s, f, to);
    printf("%s\n\n",result);
    
}
