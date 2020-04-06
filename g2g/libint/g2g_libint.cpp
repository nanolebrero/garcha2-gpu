#include <iostream>

#include <stdio.h>
#include <string.h>

#include "../common.h"
#include "../init.h"
#include "../partition.h"

#include "libintproxy.h"


using namespace G2G;


extern "C" void g2g_libint_init_(double* Cbas, int& recalc)
{
   
// INITIALIZATION LIBINT
   LIBINTproxy libintproxy;
   libintproxy.init( // inputs
                    fortran_vars.m, fortran_vars.atoms,
                    &fortran_vars.contractions(0),
                    Cbas, &fortran_vars.a_values(0,0),
                    &fortran_vars.atom_positions_pointer(0,0),
                    &fortran_vars.nucleii(0),
                    fortran_vars.s_funcs, fortran_vars.p_funcs,
                    fortran_vars.d_funcs, recalc);

//  libintproxy.PrintBasis();
}

// CLOSED SHELL
extern "C" void g2g_exact_exchange_(double* rho, double* fock, int* op)
{
  LIBINTproxy libintproxy;
  libintproxy.do_exchange(rho,fock,op);
   
/* TODO ver que pasa en do_exchnage, create un template
  switch (*op) {
     case 1:
        cout << "fock coulomb" << endl;
        libintproxy.do_exchange(rho,fock,Operator::coulomb);
        break;
     case 2:
        cout << "fock erfc_coulomb" << endl;
        libintproxy.do_exchange(rho,fock,Operator::erfc_coulomb);
        break;
     case 3:
        cout << "fock erf_coulomb" << endl;
        libintproxy.do_exchange(rho,fock,Operator::erf_coulomb);
        break;
     default:
        cout << "Unidentified Operator, Check HF bool array" << endl;
        exit(-1); break;
  }
*/

}

extern "C" void g2g_exact_exchange_gradient_(double* rho, double* frc)
{
  LIBINTproxy libintproxy;
  libintproxy.do_ExchangeForces(rho,frc);
}

// Excited State
extern "C" void g2g_calculate2e_(double* tao, double* fock, int& vecdim)
{
  LIBINTproxy libintproxy;
  libintproxy.do_CoulombExchange(tao,fock,vecdim);
}

// Exact Exchange Gradients in Excited States
extern "C" void g2g_exacgrad_excited_(double* rhoG,double* DiffExc,
                                     double* Xmat,double* fEE)
{
  LIBINTproxy libintproxy;
  libintproxy.do_ExacGradient(rhoG,DiffExc,Xmat,fEE);
}

// Gamma of Coulomb and Exchange
extern "C" void g2g_calcgammcou_(double* rhoG, double* Zmat, double* gamm)
{
  LIBINTproxy libintproxy;
  libintproxy.do_GammaCou(rhoG,Zmat,gamm);
}
////////////////////////////////////////////////////////////////////////

// OPEN SHELL
extern "C" void g2g_exact_exchange_open_(double* rhoA, double* rhoB,
                                         double* fockA, double* fockB)
{
  LIBINTproxy libintproxy;
  libintproxy.do_exchange(rhoA,rhoB,fockA,fockB);
}
////////////////////////////////////////////////////////////////////////

