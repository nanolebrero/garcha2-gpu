#include <iostream>
#include <string>
#include "libintproxy.h"

using namespace G2G;
using namespace std;

namespace libint2 {
  int nthreads;
}

int LIBINTproxy::init(int M,uint natoms,uint*ncont,
                         double*cbas,double*a,double*r,uint*nuc,
                         int sfunc,int pfunc,int dfunc, int recalc)
{
// LIBINT initialization
  cout << " " << endl;
  cout << " LIBINT initialization" << endl;
  libint2::initialize();
  Shell::do_enforce_unit_normalization(false);
  string folder;
  fortran_vars.center4Recalc = recalc;

  int err;

// Put coordinates in a object
  // set atoms object
  err = libint_geom(r,natoms); folder = "libint_geom";
  if ( err != 0 ) error(folder);

// Basis in LIBINT format
  // this set obs and shell2atom objects
  err = make_basis(atoms,a,cbas,ncont,nuc,sfunc,pfunc,dfunc,M);
  folder = "make_basis";
  if ( err != 0 ) error(folder);

// First basis in a shell and atom centre in the shell
  // this set shell2bf
  err = map_shell(); folder = "map_shell";
  if ( err != 0 ) error(folder);

// IF you save integrals in momory
  if ( fortran_vars.center4Recalc == 1 ) {
     err = save_ints(fortran_vars.obs, fortran_vars.shell2bf);
     folder = "save_ints";
     if ( err != 0 ) error(folder);
  } else {
     cout << " Recalculating Integrals" << endl;
  }

  return 0;
}

int LIBINTproxy::save_ints(vector<Shell>& obs,vector<int>& shell2bf)
{
   cout << " Saving Integrals in Memory" << endl;
   int num_ints = 0;
   double memory = 0.0f;
   int nshells = obs.size();

   // Counting Integrals
   for(int s1=0, s1234=0; s1<nshells; ++s1) {
      int n1 = obs[s1].size();
      for(int s2=0; s2<=s1; ++s2) {
         int n2 = obs[s2].size();
         for(int s3=0; s3<=s1; ++s3) {
            int n3 = obs[s3].size();
            int s4_max = (s1 == s3) ? s2 : s3;
            for(int s4=0; s4<=s4_max; ++s4) {
               int n4 = obs[s4].size();
               num_ints += n1 * n2 * n3 * n4;
            } 
         }
      }
   }
 
   // Print Information
   cout << " # of Integrals: " << num_ints << endl;
   memory = num_ints * 8.0f * 1e-9;
   if ( memory > 2.0f ) cout << " WARNING!!! " << endl;
   cout << " Memory requirements " << memory << " GB" << endl;

   // Allocate Memory
   if ( fortran_vars.integrals != NULL ) {
      cout << " Deallocate Memory Integrals" << endl;
      free(fortran_vars.integrals); fortran_vars.integrals = NULL;
   }
   fortran_vars.integrals = (double*) malloc(num_ints*sizeof(double));
   if ( fortran_vars.integrals == NULL ) {
      cout << " Cann't allocated Integrals memory" << endl;
      exit(-1);
   }

   // Libint Variables
   Engine engine(Operator::coulomb, max_nprim(), max_l(), 0);
   const auto& buf = engine.results();
   int inum = 0;

   // Calculated Integrals
   for(int s1=0; s1<obs.size(); ++s1) {
     int bf1_first = shell2bf[s1]; // first basis function in this shell
     int n1 = obs[s1].size();   // number of basis function in this shell

     for(int s2=0; s2<=s1; ++s2) {
       int bf2_first = shell2bf[s2];
       int n2 = obs[s2].size();

       for(int s3=0; s3<=s1; ++s3) {
         int bf3_first = shell2bf[s3];
         int n3 = obs[s3].size();

         int s4_lim = (s1 == s3) ? s2 : s3;
         for(int s4=0; s4<=s4_lim; ++s4) {
           int bf4_first = shell2bf[s4];
           int n4 = obs[s4].size();

           // compute the permutational degeneracy 
           int s12_deg = (s1 == s2) ? 2.0 : 1.0;
           int s34_deg = (s3 == s4) ? 2.0 : 1.0;
           int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 2.0 : 1.0) : 1.0;
           int s1234_deg = s12_deg * s34_deg * s12_34_deg;

           engine.compute(obs[s1],obs[s2],obs[s3],obs[s4]);
           const auto* buf_1234 = buf[0];

           if (buf_1234 == nullptr) {
              for(int f1=0, f1234=0; f1<n1; ++f1) {
                 const int bf1 = f1 + bf1_first;
                 for(int f2=0; f2<n2; ++f2) {
                    const int bf2 = f2 + bf2_first;
                    for(int f3=0; f3<n3; ++f3) {
                       const int bf3 = f3 + bf3_first;
                       for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                          const int bf4 = f4 + bf4_first;
                           
                          fortran_vars.integrals[inum] = 0.0f;
                          inum += 1;

                       }
                    }
                 }
              } // END f...
           } else {
              for(int f1=0, f1234=0; f1<n1; ++f1) {
                 const int bf1 = f1 + bf1_first;
                 for(int f2=0; f2<n2; ++f2) {
                    const int bf2 = f2 + bf2_first;
                    for(int f3=0; f3<n3; ++f3) {
                       const int bf3 = f3 + bf3_first;
                       for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                          const int bf4 = f4 + bf4_first;
                          const double value = buf_1234[f1234];
                          const double value_scal = value / s1234_deg;

                          fortran_vars.integrals[inum] = value_scal;
                          inum += 1;
            
                       }
                    }
                 }
              } // END f...
           } // END IF NULL
         }
       }
     }
   } // END s...

   int sal = 0;
   if ( num_ints != inum ) {
      cout << " Something is wrong num_ints != inum " << endl;
      sal = -1;
   }

   return sal;
}

int LIBINTproxy::error(string ff)
{
  cout << "Something is wrong in " << ff << endl;
  exit(-1);
}

LIBINTproxy::~LIBINTproxy()
{
// LIBINT DEINITIALIZATION
  libint2::finalize();
  vector<Atom>().swap(atoms);
}

int LIBINTproxy::libint_geom(double* r,int natoms)
{
/*
 This routine form an object with the positions of
 all QM atoms
*/
   atoms.resize(natoms);
   int err = 0;

   for(int i=0; i<natoms; i++) {
     atoms[i].x = r[i];
     atoms[i].y = r[i+natoms];
     atoms[i].z = r[i+natoms*2];
   }

   if ( atoms.empty() == true ) 
      err = -1;
   else
      err = 0;

   return err;
}

void LIBINTproxy::PrintBasis()
{
/*
 This routine prints basis in libint format
*/
  std::cout << "BASIS SET LIBINT" << std::endl; // print SET BASIS
  std::copy(begin(fortran_vars.obs), end(fortran_vars.obs),
         std::ostream_iterator<Shell>(std::cout, "\n"));
}

int LIBINTproxy::make_basis(
     const vector<Atom>& atoms,double*a,double*c,
     uint*ncont,uint*nuc,int s_func,int p_func,int d_func,int M)
{
/*
  This routine form an object with basis and positions of atoms
  in libint format. The basis order is different to LIO
*/
   int err = 0;
   int from = 0;
   int to = s_func;
   vector<Shell>().swap(fortran_vars.obs);
   vector<int>().swap(fortran_vars.shell2atom);

// FOR S FUNCTIONS
   for(int i=from; i<to; i++) {
     int centro = nuc[i]-1;
     int tam = ncont[i];
     vector<double> exp(tam);
     vector<double> coef(tam);
     for(int cont=0; cont<tam; cont++) {
        exp[cont] = a[i+M*cont];
        coef[cont] = c[i+M*cont];
     }
     fortran_vars.obs.push_back(
        {
          exp,
          { 
            {0, false, coef}
          },
          {{atoms[centro].x,atoms[centro].y,atoms[centro].z}}
        }
     );
     fortran_vars.shell2atom.push_back(centro);
     vector<double>().swap(exp);
     vector<double>().swap(coef);
   }

// FOR P FUNCTIONS
   from = s_func;
   to = s_func+p_func*3;
   for(int i=from; i<to; i=i+3) {
      int centro = nuc[i]-1;
      int tam = ncont[i];
      vector<double> exp(tam);
      vector<double> coef(tam);
      for(int cont=0; cont<tam; cont++) {
         exp[cont] = a[i+M*cont];
         coef[cont] = c[i+M*cont];
      }
      fortran_vars.obs.push_back(
         {
           exp,
           {
             {1, false, coef}
           },
           {{atoms[centro].x,atoms[centro].y,atoms[centro].z}}
         }
      );
      fortran_vars.shell2atom.push_back(centro);
      vector<double>().swap(exp);
      vector<double>().swap(coef);
   }

// FOR D FUNCTIONS
   from = s_func+p_func*3;
   to = M;
   for(int i=from; i<to; i=i+6) {
      int centro = nuc[i]-1;
      int tam = ncont[i];
      vector<double> exp(tam);
      vector<double> coef(tam);
      for(int cont=0; cont<tam; cont++) {
         exp[cont] = a[i+M*cont];
         coef[cont] = c[i+M*cont];
      }
      fortran_vars.obs.push_back(
         {
           exp,
           {
             {2, false, coef}
           },
           {{atoms[centro].x,atoms[centro].y,atoms[centro].z}}
         }
      );
      fortran_vars.shell2atom.push_back(centro);
      vector<double>().swap(exp);
      vector<double>().swap(coef);
    }

   err = -1;
   if ( fortran_vars.obs.empty() == false && fortran_vars.shell2atom.empty() == false ) 
      err = 0;

   return err;
}

int LIBINTproxy::map_shell()
{
/*
  This routine form shell2bf. This object contains the first basis
  function in each shells
*/
  int err = 0;
  vector<int>().swap(fortran_vars.shell2bf);
  fortran_vars.shell2bf.reserve(fortran_vars.obs.size());

  int n = 0;
  for (auto shell: fortran_vars.obs) {
    fortran_vars.shell2bf.push_back(n);
    n += shell.size();
  }
  
  err = -1;
  if ( fortran_vars.shell2bf.empty() == false ) 
     err = 0;

  return err;
  
}

vector<Matrix_E> LIBINTproxy::CoulombExchange_saving(vector<Shell>& obs, int M, vector<int>& shell2bf, 
                                              double fexc, int vecdim, double* Kmat, vector<Matrix_E>& P)
{

  vector<Matrix_E> WW(vecdim,Matrix_E::Zero(M,M));
  int nshells = obs.size();

#pragma omp parallel for
   for(int ivec=0; ivec<vecdim; ivec++) {
      int inum = 0;
      auto& g = WW[ivec];
      auto& T = P[ivec];

      for(int s1=0, s1234=0; s1<nshells; ++s1) {
         int bf1_first = shell2bf[s1];
         int n1 = obs[s1].size();

         for(int s2=0; s2<=s1; ++s2) {
            int bf2_first = shell2bf[s2];
            int n2 = obs[s2].size();

            for(int s3=0; s3<=s1; ++s3) {
               int bf3_first = shell2bf[s3];
               int n3 = obs[s3].size();

               int s4_max = (s1 == s3) ? s2 : s3;
               for(int s4=0; s4<=s4_max; ++s4) {
                  int bf4_first = shell2bf[s4];
                  int n4 = obs[s4].size();

                  for(int f1=0, f1234=0; f1<n1; ++f1) {
                     const int bf1 = f1 + bf1_first;
                     for(int f2=0; f2<n2; ++f2) {
                        const int bf2 = f2 + bf2_first;
                        for(int f3=0; f3<n3; ++f3) {
                           const int bf3 = f3 + bf3_first;
                           for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                              const int bf4 = f4 + bf4_first;
                              const double value_scal = Kmat[inum];

                              // Coulomb
                              const double Dens1 = ( T(bf3,bf4) + T(bf4,bf3) ) * 2.0f;
                              g(bf1,bf2) += value_scal * Dens1;
                              g(bf2,bf1) += value_scal * Dens1;

                              const double Dens2 = ( T(bf1,bf2) + T(bf2,bf1) ) * 2.0f;
                              g(bf3,bf4) += value_scal * Dens2;
                              g(bf4,bf3) += value_scal * Dens2;
                              // Exchange
                              g(bf1,bf3) -= value_scal * T(bf2,bf4) * fexc;
                              g(bf3,bf1) -= value_scal * T(bf4,bf2) * fexc;
                              g(bf2,bf4) -= value_scal * T(bf1,bf3) * fexc;
                              g(bf4,bf2) -= value_scal * T(bf3,bf1) * fexc;

                              g(bf1,bf4) -= value_scal * T(bf2,bf3) * fexc;
                              g(bf4,bf1) -= value_scal * T(bf3,bf2) * fexc;
                              g(bf2,bf3) -= value_scal * T(bf1,bf4) * fexc;
                              g(bf3,bf2) -= value_scal * T(bf4,bf1) * fexc;

                              inum += 1;
                           }
                        }
                     }
                  } // END f...
               }
            }
         }
      } // END s...

   } // END vectors

   return WW;
}

vector<Matrix_E> LIBINTproxy::CoulombExchange(vector<Shell>& obs, int M,
                      vector<int>& shell2bf, double fexc, int vecdim, vector<Matrix_E>& P)
{
   libint2::initialize();
   using libint2::nthreads;

#pragma omp parallel
   nthreads = omp_get_num_threads();

   int nshells = obs.size();
   vector<Matrix_E> G(nthreads*vecdim,Matrix_E::Zero(M,M));
   double precision = numeric_limits<double>::epsilon();

   // SET ENGINE LIBINT
   vector<Engine> engines(nthreads);

   engines[0] = Engine(Operator::coulomb, max_nprim(), max_l(), 0);
   engines[0].set_precision(precision);

   for(int i=1; i<nthreads; i++)
      engines[i] = engines[0];

   auto lambda = [&] (int thread_id) {
      auto& engine = engines[thread_id];
      const auto& buf = engine.results();

      for(int s1=0, s1234=0; s1<nshells; ++s1) {
         int bf1_first = shell2bf[s1];
         int n1 = obs[s1].size();

         for(int s2=0; s2<=s1; ++s2) {
            int bf2_first = shell2bf[s2];
            int n2 = obs[s2].size();

            for(int s3=0; s3<=s1; ++s3) {
               int bf3_first = shell2bf[s3];
               int n3 = obs[s3].size();

               int s4_max = (s1 == s3) ? s2 : s3;
               for(int s4=0; s4<=s4_max; ++s4) {
                  if( ( s1234++) % nthreads != thread_id ) continue;
                  int bf4_first = shell2bf[s4];
                  int n4 = obs[s4].size();

                  // compute the permutational degeneracy 
                  // (i.e. # of equivalents) of the given shell set
                  int s12_deg = (s1 == s2) ? 2.0 : 1.0;
                  int s34_deg = (s3 == s4) ? 2.0 : 1.0;
                  int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 2.0 : 1.0) : 1.0;
                  int s1234_deg = s12_deg * s34_deg * s12_34_deg;

                  auto add_shellset = [&] (int op, int idx, int coord1, int coord2) {
                     auto& g = G[op];
                     auto& T = P[idx];
                     const auto* shset = buf[0];
                     const double weight = s1234_deg;

                     for(int f1=0, f1234=0; f1<n1; ++f1) {
                        const int bf1 = f1 + bf1_first;
                        for(int f2=0; f2<n2; ++f2) {
                           const int bf2 = f2 + bf2_first;
                           for(int f3=0; f3<n3; ++f3) {
                              const int bf3 = f3 + bf3_first;
                              for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                                 const int bf4 = f4 + bf4_first;
                                 const double value = shset[f1234];
                                 const double value_scal = value / weight;

                                 // Coulomb
                                 const double Dens1 = ( T(bf3,bf4) + T(bf4,bf3) ) * 2.0f;
                                 g(bf1,bf2) += value_scal * Dens1;
                                 g(bf2,bf1) += value_scal * Dens1;

                                 const double Dens2 = ( T(bf1,bf2) + T(bf2,bf1) ) * 2.0f;
                                 g(bf3,bf4) += value_scal * Dens2;
                                 g(bf4,bf3) += value_scal * Dens2;
                                 // Exchange
                                 g(bf1,bf3) -= value_scal * T(bf2,bf4) * fexc;
                                 g(bf3,bf1) -= value_scal * T(bf4,bf2) * fexc;
                                 g(bf2,bf4) -= value_scal * T(bf1,bf3) * fexc;
                                 g(bf4,bf2) -= value_scal * T(bf3,bf1) * fexc;

                                 g(bf1,bf4) -= value_scal * T(bf2,bf3) * fexc;
                                 g(bf4,bf1) -= value_scal * T(bf3,bf2) * fexc;
                                 g(bf2,bf3) -= value_scal * T(bf1,bf4) * fexc;
                                 g(bf3,bf2) -= value_scal * T(bf4,bf1) * fexc;
                              }
                           }
                        }
                     } // END f...
                  }; // END SET TO SHELL

                  engine.compute2<Operator::coulomb, BraKet::xx_xx, 0>(
                      obs[s1],obs[s2],obs[s3],obs[s4]); // testear esto no se si esta bien
                  if (buf[0] == nullptr)
                      continue; // if all integrals screened out, skip to next quartet

                  for(int iv=0; iv<vecdim; ++iv) {
                     auto& g = G[thread_id * vecdim + iv];
                     int coord1 = 0, coord2 = 0;

                     add_shellset(thread_id*vecdim+iv,iv,coord1,coord2);
                  } // END for vector

               }
            }
         }
      } // END s...

   }; // END lambda function

   libint2::parallel_do(lambda);

  // accumulate contributions from all threads
  for(int t=1; t<nthreads; ++t) {
    for(int d=0; d<vecdim; ++d) {
       G[d] += G[t * vecdim + d];
    }
  }
 
  vector<Matrix_E> WW(vecdim);
  for(int d=0; d<vecdim; ++d) {
     WW[d] = G[d];
  }
  vector<Matrix_E>().swap(G);
  vector<Engine>().swap(engines);
  return WW;

}

//////////////////////////////////////////////////////////////

/*
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         CLOSED SHELL
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

int LIBINTproxy::do_exchange(double* rho, double* fock)
{
/*
  Main routine to calculate Fock of Exact Exchange
*/ 

   Matrix_E P = order_dfunc_rho(rho,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   Matrix_E F;

   switch (fortran_vars.center4Recalc) {
      case 0:
        F = exchange(fortran_vars.obs, fortran_vars.m, 
                             fortran_vars.shell2bf, P); break;
      case 1:
        F = exchange_saving(fortran_vars.obs, fortran_vars.m, fortran_vars.shell2bf, 
                            fortran_vars.integrals, P); break;
   
      default:
        cout << " Bad Value in fortran_vars.center4Recalc " << endl;
        exit(-1);
   }


   order_dfunc_fock(fock,F,fortran_vars.s_funcs,
                   fortran_vars.p_funcs,fortran_vars.d_funcs,
                   fortran_vars.m);

   // Free Memory
   P.resize(0,0);
   F.resize(0,0);
   return 0;
}

int LIBINTproxy::do_CoulombExchange(double* tao, double* fock, int vecdim, double fexc)
{
/*
  Main routine to calculate Fock of Coulomb
*/
   int M = fortran_vars.m;
   int M2 = M*M;
   vector<Matrix_E> T(vecdim,Matrix_E::Zero(M,M));

   for(int iv=0; iv<vecdim; iv++) {
      T[iv] = order_dfunc_rho(&tao[iv*M2],fortran_vars.s_funcs,fortran_vars.p_funcs,
                              fortran_vars.d_funcs,M);
   }

   vector<Matrix_E> F;

   switch (fortran_vars.center4Recalc) {
      case 0:
           F = CoulombExchange(fortran_vars.obs,fortran_vars.m,
                               fortran_vars.shell2bf, fexc, vecdim, T);
              break;
      case 1:
           F = CoulombExchange_saving(fortran_vars.obs,fortran_vars.m,fortran_vars.shell2bf,
                                      fexc, vecdim, fortran_vars.integrals, T);
              break;
      default:
        cout << " Bad Value in fortran_vars.center4Recalc " << endl;
        exit(-1);
   }

   for(int iv=0; iv<vecdim; iv++) {
       order_dfunc_fock(&fock[iv*M2],F[iv],fortran_vars.s_funcs,
                     fortran_vars.p_funcs,fortran_vars.d_funcs,
                     M);
   }

   // Free Memory
   vector<Matrix_E>().swap(T);
   vector<Matrix_E>().swap(F);
   return 0;
}

int LIBINTproxy::do_ExchangeForces(double* rho, double* For)
{
/*
  Main routine to calculate gradient of Exact Exchange
*/ 

   Matrix_E P = order_dfunc_rho(rho,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   int dim_atom = fortran_vars.atoms;
   vector<Matrix_E> G = compute_deriv(fortran_vars.obs,fortran_vars.shell2bf,
                                      fortran_vars.shell2atom,fortran_vars.m,
                                      dim_atom,P);
   double force;

   for(int atom=0,ii=0; atom<dim_atom; atom++) {
     for(int xyz=0; xyz<3; xyz++,ii++) {
        force = G[ii].cwiseProduct(P).sum();
        For[xyz*dim_atom+atom] += 0.25f*force;
     }
   }

   // Free Memory
   P.resize(0,0);
   vector<Matrix_E>().swap(G);
}

int LIBINTproxy::do_ExacGradient(double* rhoG, double* DiffExc,
                                 double* Xmat, double* For)
{
/*
   Main routine to calculate gradient of Exact Exchange in excited states calculation
   with differents density matrix
*/
   Matrix_E D = order_dfunc_rho(rhoG,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   Matrix_E P = order_dfunc_rho(DiffExc,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   Matrix_E T = order_dfunc_rho(Xmat,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   int dim_atom = fortran_vars.atoms;
   vector<Matrix_E> G = compute_deriv2(fortran_vars.obs,fortran_vars.shell2bf,
                                      fortran_vars.shell2atom,fortran_vars.m,
                                      dim_atom,D,P,T);

   double force;
   for(int atom=0,ii=0; atom<dim_atom; atom++) {
     for(int xyz=0; xyz<3; xyz++,ii++) {
        force = G[ii](0,0);
        For[xyz*dim_atom+atom] += 0.25f*force;
     }
   }

   // Free Memory
   D.resize(0,0);
   P.resize(0,0);
   T.resize(0,0);
   vector<Matrix_E>().swap(G);
}

vector<Matrix_E> LIBINTproxy::compute_deriv2(vector<Shell>& obs,
                              vector<int>& shell2bf,vector<int>& shell2atom,
                              int M, int natoms, Matrix_E& D, Matrix_E& P,
                              Matrix_E& T)
{
/*
  This routine calculate the derivative of 2e repulsion integrals in Exact Exchange
  in parallel with differnts densities Matrices
*/ 
  libint2::initialize();
  using libint2::nthreads;

#pragma omp parallel
  nthreads = omp_get_num_threads();

  // nderiv = 3 * N_atom, 3 = x y z
  int nderiv = libint2::num_geometrical_derivatives(natoms,1);
  vector<Matrix_E> W(nthreads*nderiv,Matrix_E::Zero(M,M));
  double precision = numeric_limits<double>::epsilon();

  // Set precision values
  vector<Engine> engines(nthreads);
  engines[0] = Engine(Operator::coulomb, max_nprim(), max_l(), 1);
  engines[0].set_precision(precision);
  for(int i=1; i<nthreads; i++)
    engines[i] = engines[0];

  // Run LIBINT in parallel
  auto lambda = [&](int thread_id) {
     auto& engine = engines[thread_id];
     const auto& buf = engine.results();
     int shell_atoms[4];

     // loop over shells
     for(int s1=0, s1234=0; s1<obs.size(); ++s1) {
       int bf1_first = shell2bf[s1];
       int n1 = obs[s1].size();
       shell_atoms[0] = shell2atom[s1];

       for(int s2=0; s2<=s1; ++s2) {
         int bf2_first = shell2bf[s2];
         int n2 = obs[s2].size();
         shell_atoms[1] = shell2atom[s2];

         for(int s3=0; s3<=s1; ++s3) {
           int bf3_first = shell2bf[s3];
           int n3 = obs[s3].size();
           shell_atoms[2] = shell2atom[s3];

           int s4_max = (s1 == s3) ? s2 : s3;
           for(int s4=0; s4<=s4_max; ++s4) {
              if( (s1234++) % nthreads != thread_id) continue;

              int bf4_first = shell2bf[s4];
              int n4 = obs[s4].size();
              shell_atoms[3] = shell2atom[s4];

              int s12_deg = (s1 == s2) ? 1.0 : 2.0;
              int s34_deg = (s3 == s4) ? 1.0 : 2.0;
              int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 1.0 : 2.0) : 2.0;
              int s1234_deg = s12_deg * s34_deg * s12_34_deg;

              auto add_shellset_to_dest = [&] (int op, int idx, int coord1, int coord2) {
                 auto& g = W[op];
                 auto shset = buf[idx];
                 const int weight = s1234_deg;

                 for (int f1=0,f1234=0; f1<n1; ++f1) {
                   const int bf1 = f1 + bf1_first;
                   for (int f2=0; f2<n2; ++f2) {
                     const int bf2 = f2 + bf2_first;
                     for (int f3=0; f3<n3; ++f3) {
                       const int bf3 = f3 + bf3_first;
                       for (int f4=0; f4<n4; ++f4,++f1234) {
                         const int bf4 = f4 + bf4_first;

                         const double wvalue = shset[f1234] * weight;
                         double matrix = D(bf1,bf3) * D(bf2, bf4);
                         matrix += P(bf1,bf4) * D(bf3,bf2);
                         matrix += P(bf4,bf1) * D(bf2,bf3);
                         matrix += P(bf3,bf1) * D(bf4,bf2);
                         matrix += P(bf1,bf3) * D(bf2,bf4);
                         matrix += 4.0f * T(bf3,bf1) * T(bf4,bf2);
                         matrix += 4.0f * T(bf1,bf3) * T(bf2,bf4);
                         g(0,0) -= 0.25f * matrix * wvalue;

                         matrix = D(bf2,bf4) * D(bf1,bf3);
                         matrix += P(bf2,bf3) * D(bf4,bf1);
                         matrix += P(bf3,bf2) * D(bf1,bf4);
                         matrix += P(bf4,bf2) * D(bf3,bf1);
                         matrix += P(bf2,bf4) * D(bf1,bf3);
                         matrix += 4.0f * T(bf4,bf2) * T(bf3,bf1);
                         matrix += 4.0f * T(bf2,bf4) * T(bf1,bf3);
                         g(0,0) -= 0.25f * matrix * wvalue;

                         matrix = D(bf1,bf4) * D(bf2,bf3);
                         matrix += P(bf1,bf3) * D(bf4,bf2);
                         matrix += P(bf3,bf1) * D(bf2,bf4);
                         matrix += P(bf4,bf1) * D(bf3,bf2);
                         matrix += P(bf1,bf4) * D(bf2,bf3);
                         matrix += 4.0f * T(bf4,bf1) * T(bf3,bf2);
                         matrix += 4.0f * T(bf1,bf4) * T(bf2,bf3);
                         g(0,0) -= 0.25f * matrix * wvalue;

                         matrix = D(bf2,bf3) * D(bf1,bf4);
                         matrix += P(bf2,bf4) * D(bf3,bf1);
                         matrix += P(bf4,bf2) * D(bf1,bf3);
                         matrix += P(bf3,bf2) * D(bf4,bf1);
                         matrix += P(bf2,bf3) * D(bf1,bf4);
                         matrix += 4.0f * T(bf3,bf2) * T(bf4,bf1);
                         matrix += 4.0f * T(bf2,bf3) * T(bf1,bf4);
                         g(0,0) -= 0.25f * matrix * wvalue;
                       }
                     }
                   }
                 }
              }; // END add_shellset_to_dest

              engine.compute2<Operator::coulomb, BraKet::xx_xx,1>
                             (obs[s1],obs[s2],obs[s3],obs[s4]);
              if (buf[0] == nullptr)
                  continue; // if all integrals screened out, skip to next quartet

              for(int d=0; d<12; ++d) {
                 const int a = d / 3;
                 const int xyz = d % 3;

                 int coord = shell_atoms[a] * 3 + xyz;
                 auto& g = W[thread_id * nderiv + coord];
                 int coord1 = 0, coord2 = 0;

                 add_shellset_to_dest(thread_id*nderiv+coord,d,coord1,coord2);
              } // END for d

           } // end s4
         } // end s3
       } // end s2
     } //end s1

  }; // END OF LAMBDA

  libint2::parallel_do(lambda);

  // accumulate contributions from all threads
  for(int t=1; t<nthreads; ++t) {
    for(int d=0; d<nderiv; ++d) {
       W[d] += W[t * nderiv + d];
    }
  }

  vector<Matrix_E> WW(nderiv);
  for(int d=0; d<nderiv; ++d) {
     WW[d] = 0.5f * ( W[d] + W[d].transpose() );
  }
  vector<Matrix_E>().swap(W);
  vector<Engine>().swap(engines);
  return WW;
}

vector<Matrix_E> LIBINTproxy::compute_deriv(vector<Shell>& obs,
                              vector<int>& shell2bf,vector<int>& shell2atom,
                              int M, int natoms, Matrix_E& D)
{
/*
  This routine calculate the derivative of 2e repulsion integrals in Exact Exchange
  in parallel
*/ 

  libint2::initialize();
  using libint2::nthreads;

#pragma omp parallel
  nthreads = omp_get_num_threads();

  // nderiv = 3 * N_atom, 3 = x y z
  int nderiv = libint2::num_geometrical_derivatives(natoms,1);
  vector<Matrix_E> W(nthreads*nderiv,Matrix_E::Zero(M,M));
  double precision = numeric_limits<double>::epsilon();

  // Set precision values
  vector<Engine> engines(nthreads);
  engines[0] = Engine(Operator::coulomb, max_nprim(), max_l(), 1);
  engines[0].set_precision(precision);
  for(int i=1; i<nthreads; i++)
    engines[i] = engines[0];

  // Run LIBINT in parallel
  auto lambda = [&](int thread_id) {
     auto& engine = engines[thread_id];
     const auto& buf = engine.results();
     int shell_atoms[4];

     // loop over shells
     for(int s1=0, s1234=0; s1<obs.size(); ++s1) {
       int bf1_first = shell2bf[s1];
       int n1 = obs[s1].size();
       shell_atoms[0] = shell2atom[s1];

       for(int s2=0; s2<=s1; ++s2) {
         int bf2_first = shell2bf[s2];
         int n2 = obs[s2].size();
         shell_atoms[1] = shell2atom[s2];

         for(int s3=0; s3<=s1; ++s3) {
           int bf3_first = shell2bf[s3];
           int n3 = obs[s3].size();
           shell_atoms[2] = shell2atom[s3];

           int s4_max = (s1 == s3) ? s2 : s3;
           for(int s4=0; s4<=s4_max; ++s4) {
              if( (s1234++) % nthreads != thread_id) continue;

              int bf4_first = shell2bf[s4];
              int n4 = obs[s4].size();
              shell_atoms[3] = shell2atom[s4];

              int s12_deg = (s1 == s2) ? 1.0 : 2.0;
              int s34_deg = (s3 == s4) ? 1.0 : 2.0;
              int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 1.0 : 2.0) : 2.0;
              int s1234_deg = s12_deg * s34_deg * s12_34_deg;

              auto add_shellset_to_dest = [&] (int op, int idx, int coord1, int coord2) {
                 auto& g = W[op];
                 auto shset = buf[idx];
                 const int weight = s1234_deg;

                 for (int f1=0,f1234=0; f1<n1; ++f1) {
                   const int bf1 = f1 + bf1_first;
                   for (int f2=0; f2<n2; ++f2) {
                     const int bf2 = f2 + bf2_first;
                     for (int f3=0; f3<n3; ++f3) {
                       const int bf3 = f3 + bf3_first;
                       for (int f4=0; f4<n4; ++f4,++f1234) {
                         const int bf4 = f4 + bf4_first;

                         const double value = shset[f1234];
                         const double wvalue = value * weight;

                         // COULOMB DER
                         //g(bf1, bf2) += D(bf3, bf4) * wvalue;
                         //g(bf3, bf4) += D(bf1, bf2) * wvalue;
                         // EXCHANGE DER
                         g(bf1, bf3) -= 0.25f * D(bf2, bf4) * wvalue;
                         g(bf2, bf4) -= 0.25f * D(bf1, bf3) * wvalue;
                         g(bf1, bf4) -= 0.25f * D(bf2, bf3) * wvalue;
                         g(bf2, bf3) -= 0.25f * D(bf1, bf4) * wvalue;
                       }
                     }
                   }
                 }
              }; // END add_shellset_to_dest

              engine.compute2<Operator::coulomb, BraKet::xx_xx,1>
                             (obs[s1],obs[s2],obs[s3],obs[s4]);
              if (buf[0] == nullptr)
                  continue; // if all integrals screened out, skip to next quartet

              for(int d=0; d<12; ++d) {
                 const int a = d / 3;
                 const int xyz = d % 3;

                 int coord = shell_atoms[a] * 3 + xyz;
                 auto& g = W[thread_id * nderiv + coord];
                 int coord1 = 0, coord2 = 0;

                 add_shellset_to_dest(thread_id*nderiv+coord,d,coord1,coord2);
              } // END for d

           } // end s4
         } // end s3
       } // end s2
     } //end s1

  }; // END OF LAMBDA

  libint2::parallel_do(lambda);

  // accumulate contributions from all threads
  for(int t=1; t<nthreads; ++t) {
    for(int d=0; d<nderiv; ++d) {
       W[d] += W[t * nderiv + d];
    }
  }

  vector<Matrix_E> WW(nderiv);
  for(int d=0; d<nderiv; ++d) {
     WW[d] = 0.5f * ( W[d] + W[d].transpose() );
  }
  vector<Matrix_E>().swap(W);
  vector<Engine>().swap(engines);
  return WW;
}

Matrix_E LIBINTproxy::exchange_saving(vector<Shell>& obs, int M,
                      vector<int>& shell2bf, double* Kmat, Matrix_E& D)
{
   Matrix_E g = Matrix_E::Zero(M,M);
   int inum = 0;

   // Calculated Integrals
   for(int s1=0; s1<obs.size(); ++s1) {
     int bf1_first = shell2bf[s1]; // first basis function in this shell
     int n1 = obs[s1].size();   // number of basis function in this shell

     for(int s2=0; s2<=s1; ++s2) {
       int bf2_first = shell2bf[s2];
       int n2 = obs[s2].size();

       for(int s3=0; s3<=s1; ++s3) {
         int bf3_first = shell2bf[s3];
         int n3 = obs[s3].size();

         int s4_lim = (s1 == s3) ? s2 : s3;
         for(int s4=0; s4<=s4_lim; ++s4) {
           int bf4_first = shell2bf[s4];
           int n4 = obs[s4].size();

           for(int f1=0, f1234=0; f1<n1; ++f1) {
              const int bf1 = f1 + bf1_first;
              for(int f2=0; f2<n2; ++f2) {
                 const int bf2 = f2 + bf2_first;
                 for(int f3=0; f3<n3; ++f3) {
                    const int bf3 = f3 + bf3_first;
                    for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                       const int bf4 = f4 + bf4_first;

                       g(bf1, bf3) += D(bf2, bf4) * Kmat[inum];
                       g(bf2, bf4) += D(bf1, bf3) * Kmat[inum];
                       g(bf1, bf4) += D(bf2, bf3) * Kmat[inum];
                       g(bf2, bf3) += D(bf1, bf4) * Kmat[inum];
                       inum += 1;
                    }
                 }
              }
           } // END f...
         }
       }
     }
   } // END s...

   Matrix_E GG = 0.5f * ( g + g.transpose() );
   g.resize(0,0);
   return GG;
}

Matrix_E LIBINTproxy::exchange(vector<Shell>& obs, int M, 
                      vector<int>& shell2bf, Matrix_E& D)
{
/*
  This routine calculates the 2e repulsion integrals in Exact Exchange 
  in parallel
*/
   libint2::initialize();
   using libint2::nthreads;

#pragma omp parallel
   nthreads = omp_get_num_threads();

   int nshells = obs.size();
   vector<Matrix_E> G(nthreads,Matrix_E::Zero(M,M));
   double precision = numeric_limits<double>::epsilon();
   
   // SET ENGINE LIBINT
   vector<Engine> engines(nthreads);

   engines[0] = Engine(Operator::coulomb, max_nprim(), max_l(), 0);
   engines[0].set_precision(precision);
   for(int i=1; i<nthreads; i++)
      engines[i] = engines[0];

   auto lambda = [&] (int thread_id) {
      auto& engine = engines[thread_id];
      auto& g = G[thread_id];
      const auto& buf = engine.results();

      for(int s1=0, s1234=0; s1<nshells; ++s1) {
         int bf1_first = shell2bf[s1];
         int n1 = obs[s1].size();

         for(int s2=0; s2<=s1; ++s2) {
            int bf2_first = shell2bf[s2];
            int n2 = obs[s2].size();

            for(int s3=0; s3<=s1; ++s3) {
               int bf3_first = shell2bf[s3];
               int n3 = obs[s3].size();

               int s4_max = (s1 == s3) ? s2 : s3;
               for(int s4=0; s4<=s4_max; ++s4) {
                  if( ( s1234++) % nthreads != thread_id ) continue;
                  int bf4_first = shell2bf[s4];
                  int n4 = obs[s4].size();
               
                  // compute the permutational degeneracy 
                  int s12_deg = (s1 == s2) ? 2.0 : 1.0;
                  int s34_deg = (s3 == s4) ? 2.0 : 1.0;
                  int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 2.0 : 1.0) : 1.0;
                  int s1234_deg = s12_deg * s34_deg * s12_34_deg;

                  engine.compute2<Operator::coulomb, BraKet::xx_xx, 0>(
                         obs[s1],obs[s2],obs[s3],obs[s4]); // testear esto no se si esta bien

                  const auto* buf_1234 = buf[0];
                  if (buf_1234 == nullptr) continue; // if all integrals screened out

                  for(int f1=0, f1234=0; f1<n1; ++f1) {
                     const int bf1 = f1 + bf1_first;
                     for(int f2=0; f2<n2; ++f2) {
                        const int bf2 = f2 + bf2_first;
                        for(int f3=0; f3<n3; ++f3) {
                           const int bf3 = f3 + bf3_first;
                           for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                              const int bf4 = f4 + bf4_first;

                              const double value = buf_1234[f1234];
                              const double value_scal = value / s1234_deg;
                              g(bf1, bf3) += D(bf2, bf4) * value_scal;
                              g(bf2, bf4) += D(bf1, bf3) * value_scal;
                              g(bf1, bf4) += D(bf2, bf3) * value_scal;
                              g(bf2, bf3) += D(bf1, bf4) * value_scal;
                           }
                        }
                     }
                  } // END f...
               }
            }
         }
      } // END s...

   }; // END lambda function
   
   libint2::parallel_do(lambda);

   // accumulate contributions from all threads
   for (int i=1; i<nthreads; i++) {
       G[0] += G[i];
   }
   Matrix_E GG = 0.5f * ( G[0] + G[0].transpose() );
   vector<Matrix_E>().swap(G);

   return GG;
}

/*
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         OPEN SHELL
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/
int LIBINTproxy::do_exchange(double* rhoA, double* rhoB, 
                             double* fockA, double* fockB)
{
/*
  Main routine to calculate Fock of Exact Exchange
*/

   Matrix_E Pa = order_dfunc_rho(rhoA,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   Matrix_E Pb = order_dfunc_rho(rhoB,fortran_vars.s_funcs,
                           fortran_vars.p_funcs,fortran_vars.d_funcs,
                           fortran_vars.m);

   vector<Matrix_E> Fock = exchange(fortran_vars.obs, fortran_vars.m,
                                    fortran_vars.shell2bf, Pa, Pb);

   order_dfunc_fock(fockA,Fock[0],fortran_vars.s_funcs,
                   fortran_vars.p_funcs,fortran_vars.d_funcs,
                   fortran_vars.m);

   order_dfunc_fock(fockB,Fock[1],fortran_vars.s_funcs,
                   fortran_vars.p_funcs,fortran_vars.d_funcs,
                   fortran_vars.m);

   // Free Memory
   Pa.resize(0,0);
   Pb.resize(0,0);
   vector<Matrix_E>().swap(Fock);

   return 0;

}

vector<Matrix_E> LIBINTproxy::exchange(vector<Shell>& obs, int M,
                      vector<int>& shell2bf, Matrix_E& Da, Matrix_E& Db)
{
/*
  This routine calculates the 2e repulsion integrals in Exact Exchange 
  in parallel
*/
   libint2::initialize();
   using libint2::nthreads;

#pragma omp parallel
   nthreads = omp_get_num_threads();

   int nshells = obs.size();
   vector<Matrix_E> Ga(nthreads,Matrix_E::Zero(M,M));
   vector<Matrix_E> Gb(nthreads,Matrix_E::Zero(M,M));
   double precision = numeric_limits<double>::epsilon();

   // SET ENGINE LIBINT
   vector<Engine> engines(nthreads);

   engines[0] = Engine(Operator::coulomb, max_nprim(), max_l(), 0);
   engines[0].set_precision(precision);
   for(int i=1; i<nthreads; i++)
      engines[i] = engines[0];

   auto lambda = [&] (int thread_id) {
      auto& engine = engines[thread_id];
      auto& ga = Ga[thread_id];
      auto& gb = Gb[thread_id];
      const auto& buf = engine.results();

      for(int s1=0, s1234=0; s1<nshells; ++s1) {
         int bf1_first = shell2bf[s1];
         int n1 = obs[s1].size();

         for(int s2=0; s2<=s1; ++s2) {
            int bf2_first = shell2bf[s2];
            int n2 = obs[s2].size();

            for(int s3=0; s3<=s1; ++s3) {
               int bf3_first = shell2bf[s3];
               int n3 = obs[s3].size();

               int s4_max = (s1 == s3) ? s2 : s3;
               for(int s4=0; s4<=s4_max; ++s4) {
                  if( ( s1234++) % nthreads != thread_id ) continue;
                  int bf4_first = shell2bf[s4];
                  int n4 = obs[s4].size();

                  // compute the permutational degeneracy 
                  // (i.e. # of equivalents) of the given shell set
                  int s12_deg = (s1 == s2) ? 1.0 : 2.0;
                  int s34_deg = (s3 == s4) ? 1.0 : 2.0;
                  int s12_34_deg = (s1 == s3) ? (s2 == s4 ? 1.0 : 2.0) : 2.0;
                  int s1234_deg = s12_deg * s34_deg * s12_34_deg;

                  engine.compute2<Operator::coulomb, BraKet::xx_xx, 0>(
                         obs[s1],obs[s2],obs[s3],obs[s4]); // testear esto no se si esta bien

                  const auto* buf_1234 = buf[0];
                  if (buf_1234 == nullptr) continue; // if all integrals screened out

                  for(int f1=0, f1234=0; f1<n1; ++f1) {
                     const int bf1 = f1 + bf1_first;
                     for(int f2=0; f2<n2; ++f2) {
                        const int bf2 = f2 + bf2_first;
                        for(int f3=0; f3<n3; ++f3) {
                           const int bf3 = f3 + bf3_first;
                           for(int f4 = 0; f4<n4; ++f4, ++f1234) {
                              const int bf4 = f4 + bf4_first;

                              const double value = buf_1234[f1234];
                              const double value_scal = value * s1234_deg;
                              // ALPHA
                              ga(bf1, bf3) += 0.25 * Da(bf2, bf4) * value_scal;
                              ga(bf2, bf4) += 0.25 * Da(bf1, bf3) * value_scal;
                              ga(bf1, bf4) += 0.25 * Da(bf2, bf3) * value_scal;
                              ga(bf2, bf3) += 0.25 * Da(bf1, bf4) * value_scal;
                            
                              // BETA
                              gb(bf1, bf3) += 0.25 * Db(bf2, bf4) * value_scal;
                              gb(bf2, bf4) += 0.25 * Db(bf1, bf3) * value_scal;
                              gb(bf1, bf4) += 0.25 * Db(bf2, bf3) * value_scal;
                              gb(bf2, bf3) += 0.25 * Db(bf1, bf4) * value_scal;
                           }
                        }
                     }
                  } // END f...
               }
            }
         }
      } // END s...
   }; // END lambda function

   libint2::parallel_do(lambda);

   // accumulate contributions from all threads
   for (int i=1; i<nthreads; i++) {
       Ga[0] += Ga[i];
       Gb[0] += Gb[i];
   }

   vector<Matrix_E> F(2,Matrix_E::Zero(M,M));

   F[0] = 0.5f * ( Ga[0] + Ga[0].transpose() );
   F[1] = 0.5f * ( Gb[0] + Gb[0].transpose() );
   vector<Matrix_E>().swap(Ga);
   vector<Matrix_E>().swap(Gb);

   return F;

}

void LIBINTproxy::order_dfunc_fock(double* fock, Matrix_E& F,
                                   int sfunc,int pfunc,int dfunc,
                                   int M)
{
/*
 This routine change the order in d functins in fock matrix
 The order in d functions btween LIO and LIBINT ar differents
 LIO:    XX, XY, YY, ZX, ZY, ZZ
 LIBINT: XX, XY, ZX, YY, ZY, ZZ
*/
   int stot = sfunc;
   int ptot = pfunc*3;
   int dtot = dfunc*6;
   double ele_temp;
   string folder;

   folder = "order_dfunc_fock";
   if ( stot+ptot+dtot != M )
      error(folder);

   // Copy block d and change format LIBINT->LIO
   // rows
   for(int ii=stot+ptot; ii<M; ii=ii+6) {
      for(int jj=0; jj<M; jj++) {
         ele_temp   = F(ii+2,jj);
         F(ii+2,jj) = F(ii+3,jj);
         F(ii+3,jj) = ele_temp;
      }
   }

   // cols
   for(int ii=stot+ptot; ii<M; ii=ii+6) {
      for(int jj=0; jj<M; jj++) {
         ele_temp   = F(jj,ii+2);
         F(jj,ii+2) = F(jj,ii+3);
         F(jj,ii+3) = ele_temp;
      }
   }

   for(int ii=0; ii<M; ii++) {
      fock[ii*M+ii] = F(ii,ii);
      for(int jj=0; jj<ii; jj++) {
         fock[ii*M+jj] = F(ii,jj);
         fock[jj*M+ii] = F(jj,ii);
      }
   }

}


Matrix_E LIBINTproxy::order_dfunc_rho(double* dens,int sfunc,
                         int pfunc,int dfunc,int M)
{
/*
 This routine change the order of d functions of density matrix
 The order in d functions btween LIO and LIBINT ar differents
 LIO:    XX, XY, YY, ZX, ZY, ZZ
 LIBINT: XX, XY, ZX, YY, ZY, ZZ
*/
   int stot = sfunc;
   int ptot = pfunc*3;
   int dtot = dfunc*6;
   double ele_temp;
   string folder;

   Matrix_E DE = Matrix_E::Zero(M,M);

   folder = "order_dfunc_rho";
   if ( stot+ptot+dtot != M ) 
      error(folder);

   // Copy All matrix
   for(int ii=0; ii<M; ii++) {
     DE(ii,ii) = dens[ii*M+ii];
     for(int jj=0; jj<ii; jj++) {
       DE(ii,jj) = dens[ii*M+jj];
       DE(jj,ii) = dens[jj*M+ii];
     }
   }
 
   // Copy block d and change format LIO->LIBINT
   // rows
   for(int ii=stot+ptot; ii<M; ii=ii+6) {
      for(int jj=0; jj<M; jj++) {
         ele_temp   = DE(ii+2,jj);
         DE(ii+2,jj)= DE(ii+3,jj);
         DE(ii+3,jj)= ele_temp;
      }
   }
   
   // cols
   for(int ii=stot+ptot; ii<M; ii=ii+6) {
      for(int jj=0; jj<M; jj++) {
         ele_temp    = DE(jj,ii+2);
         DE(jj,ii+2) = DE(jj,ii+3);
         DE(jj,ii+3) = ele_temp;
      }
   }

   return DE;
}

size_t LIBINTproxy::max_nprim() {
/*
  This routine extracts the max primitive number in each shell
*/
  size_t n = 0;
  for (auto shell:fortran_vars.obs)
    n = std::max(shell.nprim(), n);
  return n;
}

int LIBINTproxy::max_l() {
/*
  This routine extracts the max angular moment in each shell
*/
  int l = 0;
  for (auto shell:fortran_vars.obs)
    for (auto c: shell.contr)
      l = std::max(c.l, l);
  return l;
}
