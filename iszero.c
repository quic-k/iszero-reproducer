#include <cmath>
#include <math.h>



#ifdef fpclassify

#error

#endif



namespace {

int fpclassify();

int iszero();

}



int f(float x) { return std::fpclassify(x); }

int g(float x) { using namespace std; return fpclassify(x); }
