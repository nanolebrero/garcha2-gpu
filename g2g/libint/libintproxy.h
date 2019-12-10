#ifndef LIBINTPROXY_H
#define LIBINTPROXY_H

#include <libint2.hpp>
#include "../init.h"
#include <string>

typedef Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> Matrix_E;

// namespace LIBINT
using libint2::Atom;
using libint2::BasisSet;
using libint2::Shell;
using libint2::Engine;
using libint2::Operator;
using libint2::BraKet;

// namespace STD
using std::vector;
using std::string;

typedef unsigned int uint;

// NEEDED TO RUN LIBINT IN PARALLEL
namespace libint2 {
extern int nthreads;

/// fires off \c nthreads instances of lambda in parallel
template <typename Lambda>
void parallel_do(Lambda& lambda) {
#ifdef _OPENMP
#pragma omp parallel
  {
    auto thread_id = omp_get_thread_num();
    lambda(thread_id);
  }
#endif
}
}

class LIBINTproxy
{
private:
       // Variables
       vector<Atom> atoms;         // atoms cordinates

       // Common Functions
       int libint_geom(double*,int);

       int make_basis(const
            vector<Atom>&,double*,double*,uint*,
            uint*,int,int,int,int);

       int map_shell();

       Matrix_E order_dfunc_rho(double*,int,int,int,int);

       void order_dfunc_fock(double*,Matrix_E&,
                             int,int,int,int);

       int error(string);

       size_t max_nprim();

       int max_l();

       // Save Integrals
       int save_ints(vector<Shell>& ,vector<int>&);

       // Closed shell
       Matrix_E exchange(vector<Shell>&,int,vector<int>&,Matrix_E&);

       Matrix_E exchange_saving(vector<Shell>&,int,vector<int>&,double*,Matrix_E&);

       vector<Matrix_E> CoulombExchange(vector<Shell>&,int,vector<int>&,double,int,vector<Matrix_E>&);

       vector<Matrix_E> compute_deriv(vector<Shell>&,vector<int>&,vector<int>&,
                              int,int,Matrix_E&);

       // Open shell
       vector<Matrix_E> exchange(vector<Shell>&,int,vector<int>&,Matrix_E&,Matrix_E&);

public:
       // General routines
       int init(int,uint,uint*,double*,double*,
                   double*,uint*,int,int,int,int); // Constructor

       ~LIBINTproxy(); // Destructor

       void PrintBasis(); // Print basis in libint format

       // Closed shell
       int do_exchange(double*, double*); // Energy calc.

       int do_ExchangeForces(double*, double*); // Gradients calc.

       int do_CoulombExchange(double*, double*, int, double); // Energy calc.

       // Open shell
       int do_exchange(double*, double*, double*, double*); // Energy calc.

};

#endif




