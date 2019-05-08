!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! Lineal search subroutines
!
! This procedure improve convergency in systems finding best lineal
! combinations of density matrix in steps n and n-1. To do so, it
! evaluates different combinations of rho(n) and rho(n-1), using the
! variable lambda as a weight. The possibilities it evaluates also
! depend on the performance of the algorithm in previous steps,
! which is regulated by the parameters Elast and Pstepsize.
!
! FFR comments: Rho_LS, changed_to_LS and P_oscilation_analysis are
! communication variables that appear here and in some external subs.
! P_oscilation_analysis and changed_to_LS are not even used inside here.
! These should be dealt with differently.
!
!------------------------------------------------------------------------------!
! LOG:
! V 1.00 September 2018 Final version - Nicolas Foglia
! V 1.01 September 2018 adaptation - FFR
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
subroutine rho_ls_init(open_shell, rho_alp, rho_bet)
   use converger_data, only: rho_lambda0, rho_lambda1, rho_lambda0_alpha, &
                             rho_lambda1_alpha, rho_lambda0_betha,        &
                             rho_lambda1_betha, rho_LS
   implicit none
   logical     , intent(in) :: open_shell
   real(kind=8), intent(in) :: rho_alp(:), rho_bet(:)

   integer :: MM

   if (rho_LS < 2) return
   MM = size(rho_alp,1)

   if (.not. allocated(rho_lambda1)) allocate(rho_lambda1(MM))
   if (.not. allocated(rho_lambda0)) allocate(rho_lambda0(MM))
   if (open_shell) then
      if (.not. allocated(rho_lambda1_alpha)) allocate(rho_lambda1_alpha(MM))
      if (.not. allocated(rho_lambda0_alpha)) allocate(rho_lambda0_alpha(MM))
      if (.not. allocated(rho_lambda1_betha)) allocate(rho_lambda1_betha(MM))
      if (.not. allocated(rho_lambda0_betha)) allocate(rho_lambda0_betha(MM))
      rho_lambda0_alpha = rho_alp
      rho_lambda0_betha = rho_bet
   end if
end subroutine rho_ls_init

subroutine rho_ls_switch(open_shell, rho_alp, rho_bet, switch_LS)
   use fileio        , only: write_ls_convergence
   use converger_data, only: nMax, rho_ls

   implicit none
   real(kind=8), intent(in)  :: rho_alp(:), rho_bet(:)
   logical     , intent(in)  :: open_shell
   logical     , intent(out) :: switch_LS

   call write_ls_convergence(NMAX)

   Rho_LS    = 3
   NMAX      = 2 * NMAX
   switch_LS = .true.
   call rho_ls_init(open_shell, rho_alp, rho_bet)
end subroutine rho_ls_switch

subroutine rho_ls_finalise()
   use converger_data, only: rho_lambda0, rho_lambda1, rho_lambda0_alpha, &
                             rho_lambda1_alpha, rho_lambda0_betha,        &
                             rho_lambda1_betha, rho_LS
   implicit none
   
   if (rho_LS < 1) return
   if (allocated(rho_lambda1))       deallocate(rho_lambda1)
   if (allocated(rho_lambda0))       deallocate(rho_lambda0)
   if (allocated(rho_lambda1_alpha)) deallocate(rho_lambda1_alpha)
   if (allocated(rho_lambda0_alpha)) deallocate(rho_lambda0_alpha)
   if (allocated(rho_lambda1_betha)) deallocate(rho_lambda1_betha)
   if (allocated(rho_lambda0_betha)) deallocate(rho_lambda0_betha)
end subroutine rho_ls_finalise

subroutine do_rho_ls(niter, En, E1, E2, Ex, rho_new, rho_old, Hmat_vec, &
                     Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec, int_memo, &
                     rhoa_new, rhob_new, rhoa_old, rhob_old)
   ! rho_LS values:
   !   = 0 calculate convergence criteria for actual density matrix.
   !   = 1 do linear search for density matrix if energy > previous energy.
   !   = 2 do linear search for density matrix in all steps.
   use converger_data, only: may_conv

   implicit none
   ! Step number and energies.
   integer     , intent(in)    :: niter
   real(kind=8), intent(inout) :: E1, E2, Ex, En
   
   ! Variables for electron integrals.
   logical     , intent(in)    :: int_memo
   real(kind=8), intent(inout) :: Hmat_vec(:), Fmat_vec(:), Fmat_vec2(:), &
                                  Gmat_vec(:), Ginv_vec(:)

   ! Density matrices of current and previous step. Due to how SCF works,
   ! the current step is in matrix form and the previous in vector form.
   real(kind=8), intent(inout) :: rho_old(:)
   real(kind=8), intent(inout) :: rho_new(:,:)
   real(kind=8), optional, intent(inout) :: rhoa_old(:)  , rhob_old(:)
   real(kind=8), optional, intent(inout) :: rhoa_new(:,:), rhob_new(:,:)

   ! True if predicted density != density of previous steep
   may_conv = .true.

   ! Makes separate calls for open and closed shell.
   if (present(rhoa_old)) then
      call rho_linear_calc(niter, En, E1, E2, Ex, may_conv, rho_new, rho_old, &
                           Hmat_vec, Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec, &
                           int_memo)
   else
      call rho_linear_calc(niter, En, E1, E2, Ex, may_conv, rho_new, rho_old, &
                           Hmat_vec, Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec, &
                           int_memo, rhoa_new, rhob_new, rhoa_old, rhob_old)
   endif  
end subroutine do_rho_ls

! The following subs are only internal.
subroutine rho_linear_calc(niter, En, E1, E2, Ex, may_conv, rho_new, rho_old, &
                         Hmat_vec, Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec, &
                         int_memo, rhoa_new, rhob_new, rhoa_old, rhob_old)
   use liosubs       , only: line_search
   use converger_data, only: rho_lambda0, rho_lambda1, rho_lambda0_alpha,   &
                             rho_lambda1_alpha, rho_lambda0_betha,          &
                             rho_lambda1_betha, Elast, pstepsize, rho_LS
   implicit none
   integer     , intent(in)    :: niter
   logical     , intent(in)    :: int_memo
   logical     , intent(inout) :: may_conv
   real(kind=8), intent(inout) :: En, E1, E2, Ex
   real(kind=8), intent(inout) :: Hmat_vec(:), Fmat_vec(:), Fmat_vec2(:), &
                                  Gmat_vec(:), Ginv_vec(:)
   ! Density matrices of the current and previous steps.
   real(kind=8), intent(inout) :: rho_old(:)
   real(kind=8), intent(inout) :: rho_new(:,:)
   real(kind=8), optional, intent(inout) :: rhoa_old(:)  , rhob_old(:)
   real(kind=8), optional, intent(inout) :: rhoa_new(:,:), rhob_new(:,:)

   ! Values for combination of density matrices 
   real(kind=8) :: dlambda, Blambda 
   
   ! Auxiliars
   integer :: M, MM, M2, jj, kk, Rposition, ilambda
   logical :: open_shell = .false.
   real(kind=8), allocatable :: RMM_temp(:),E_lambda(:)

   M  = size(rho_new,1)
   MM = size(rho_old,1)
   M2 = 2 * M
   if (present(rhoa_old)) open_shell = .true.

   allocate(E_lambda(0:10))
   allocate(RMM_temp(1:MM))

   if (niter == 1)  then
      Pstepsize   = 1.d0
      rho_lambda0 = rho_old
      if (open_shell) rho_lambda0_alpha = rhoa_old
      if (open_shell) rho_lambda0_betha = rhob_old
   end if
      
   do jj=1,M
   do kk=jj,M
      Rposition = kk + (M2 - jj) * (jj - 1) / 2
      rho_lambda1(Rposition) = rho_new(jj,kk)
      if (open_shell) rho_lambda1_alpha(Rposition) = rhoa_new(jj,kk)
      if (open_shell) rho_lambda1_betha(Rposition) = rhob_new(jj,kk)
   enddo
   enddo
   
   rho_old = rho_lambda1
   if (open_shell) rhoa_old = rho_lambda1_alpha
   if (open_shell) rhob_old = rho_lambda1_betha
   
   call give_me_energy(E_lambda(10), En, E1, E2, Ex, rho_old, Hmat_vec,    &
                       Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec, open_shell,&
                       int_memo)
   
   if ((Elast < E_lambda(10)) .or. (Rho_LS == 2)) then
      write(*,*) "Lambda this step: ", E_lambda(10), ", last step: ", Elast
      write(*,*) "Doing lineal interpolation in Rho."
      do ilambda = 0, 10
         dlambda = Pstepsize * dble(ilambda) / 10.d0
         if (dlambda > 1.d0) STOP "dlambda > 1.d0"

         rho_old = rho_lambda0 * (1.d0 - dlambda) + rho_lambda1 * dlambda 
         if (open_shell) rhoa_old = rho_lambda0_alpha * (1.d0 - dlambda) + &
                                    rho_lambda1_alpha * dlambda
         if (open_shell) rhob_old = rho_lambda0_betha * (1.d0 - dlambda) + &
                                    rho_lambda1_betha * dlambda
         call give_me_energy(E_lambda(ilambda), En, E1, E2, Ex, rho_old,       &
                             Hmat_vec, Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec,&
                             open_shell, int_memo)
         write(*,*) "Step n°", ilambda, ", energy: ", E_lambda(ilambda)
      end do
   
      call line_search(11, E_lambda, 1d0, Blambda)
      if (Blambda >= 1.d0) Blambda = Blambda - 1.0d0
      write(*,*) "Best lambda: ", Blambda
      Blambda = Blambda * Pstepsize / 10.d0
      write(*,*) "Fluctuation: ", Blambda
   else
      Blambda = Pstepsize
   end if
   
   rho_old = rho_lambda0 * (1.d0 - Blambda) + rho_lambda1 * Blambda
   if (open_shell) rhoa_old = rho_lambda0_alpha * (1.d0 - Blambda) + &
                              rho_lambda1_alpha * Blambda
   if (open_shell) rhob_old = rho_lambda0_betha * (1.d0 - Blambda) + &
                              rho_lambda1_betha * Blambda
   
   do jj = 1, M
      do kk = jj, M
         Rposition = kk + (M2 - jj) * (jj -1) / 2
         rho_new(jj,kk) = rho_old(Rposition)
         if (open_shell) rhoa_new(jj,kk) = rhoa_old(Rposition)
         if (open_shell) rhob_new(jj,kk) = rhob_old(Rposition)
      enddo
   enddo

   call give_me_energy(Elast, En, E1, E2, Ex, rho_old, Hmat_vec, &
                       Fmat_vec, Fmat_vec2, Gmat_vec, Ginv_vec,  &
                       open_shell, int_memo)
      
   RMM_temp    = rho_old
   rho_old     = rho_lambda0
   rho_lambda0 = RMM_temp
   
   if (open_shell) then
      RMM_temp          = rhoa_old
      rhoa_old          = rho_lambda0_alpha
      rho_lambda0_alpha = RMM_temp
   
      RMM_temp          = rhob_old
      rhob_old          = rho_lambda0_betha
      rho_lambda0_betha = RMM_temp
   end if
   
   if (Blambda <= 4.d-1 * Pstepsize) Pstepsize = Pstepsize * 0.5d0 
   if (Blambda >= 8.d-1 * Pstepsize) Pstepsize = Pstepsize * 1.2d0
   if (Pstepsize > 1.d0) Pstepsize = 1.d0
   if ((Blambda <= 2.d-1*Pstepsize) .and. (Pstepsize > 1d-4)) may_conv = .false.

   deallocate(E_lambda, RMM_temp)
end subroutine rho_linear_calc

subroutine give_me_energy(E, En, E1, E2, Ex, Pmat_vec, Hmat_vec, Fmat_vec, &
                          Fmat_vec2, Gmat_vec, Ginv_vec, open_shell, int_memo)
   !  return Energy components for a density matrix stored in Pmat_vec
   use faint_cpu, only: int3lu
   implicit none
   logical     , intent(in)    :: open_shell, int_memo
   real(kind=8), intent(in)    :: En
   real(kind=8), intent(out)   :: E, E1, E2, Ex
   real(kind=8), intent(inout) :: Pmat_vec(:), Hmat_vec(:), Fmat_vec(:), &
                                  Fmat_vec2(:), Gmat_vec(:), Ginv_vec(:)
   integer :: kk
      
   E  = 0.0D0; E1 = 0.0D0
   E2 = 0.0D0; Ex = 0.0D0
   
   do kk = 1, size(Pmat_vec,1)
      E1 = E1 + Pmat_vec(kk) * Hmat_vec(kk) !Computes 1e energy
   enddo

   ! Computes Coulomb part of Fock, and energy on E2.
   call int3lu(E2, Pmat_vec, Fmat_vec2, Fmat_vec, Gmat_vec, Ginv_vec, &
               Hmat_vec, open_shell, int_memo)

   ! Computes XC integration / Fock elements.
   call g2g_solve_groups(1,Ex,0)

   ! Adds all energy components.
   E = E1 + E2 + En + Ex

end subroutine give_me_energy