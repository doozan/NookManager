/*
 * Copyright (C) 2012 Jeff Doozan
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>

#define to565(r,g,b)                                            \
    ((((r) >> 3) << 11) | (((g) >> 2) << 5) | ((b) >> 3))

int main(int argc, char **argv)
{
  char *bufIn, *pIn;
  short *bufOut, *pOut;
  FILE *pFileIn, *pFileOut;
  long lSize;
  size_t result;

  if (argc != 3)
    return 1;

  pFileIn = fopen (argv[1], "rb");
  if (pFileIn==NULL) {fputs ("1File error",stderr); exit (1);}

  pFileOut = fopen (argv[2], "wb");
  if (pFileOut==NULL) {fputs ("2File error",stderr); exit (1);}

  fseek (pFileIn , 0 , SEEK_END);
  lSize = ftell (pFileIn);
  rewind (pFileIn);

  bufIn = (char*) malloc (sizeof(char)*lSize);
  if (bufIn == NULL) {fputs ("Memory error",stderr); exit (2);}

  bufOut = (short*) malloc (sizeof(short)*(lSize/3*2));
  if (bufOut == NULL) {fputs ("Memory error",stderr); exit (2);}

  result = fread (bufIn,1,lSize,pFileIn);
  if (result != lSize) {fputs ("Reading error",stderr); exit (3);}
  pOut = bufOut;
  pIn = bufIn;
  while( pIn < (bufIn+lSize))
  {
    *pOut = to565(pIn[0],pIn[1],pIn[2]);
    pIn += 3;
    pOut++;
  }

  fwrite(bufOut, 1, (lSize/3*2), pFileOut);

  fclose(pFileIn);
  fclose(pFileOut);

  free (bufIn);
  free (bufOut);

  return 0;
}
