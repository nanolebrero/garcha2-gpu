! Performs EDIIS convergence.
! The algorithm is also prepared for ADIIS but it does not work properly.
! That's why EDIIS_not_ADIIS is not an input variable.

subroutine ediis_init(M_in, open_shell)
   use converger_data, only: nediis, ediis_fock, ediis_dens, BMAT, EDIIS_E,&
                             conver_method

   implicit none
   logical, intent(in) :: open_shell
   integer, intent(in) :: M_in

   if (conver_method < 6) return
   if (.not. allocated(EDIIS_E)) allocate(EDIIS_E(nediis))
   if (.not. open_shell) then
      if (.not. allocated(ediis_fock)) allocate(ediis_fock(M_in,M_in,nediis,1))
      if (.not. allocated(ediis_dens)) allocate(ediis_dens(M_in,M_in,nediis,1))
      if (.not. allocated(BMAT)      ) allocate(BMAT(nediis,nediis,1))
   else
      if (.not. allocated(ediis_fock)) allocate(ediis_fock(M_in,M_in,nediis,2))
      if (.not. allocated(ediis_dens)) allocate(ediis_dens(M_in,M_in,nediis,2))
      if (.not. allocated(BMAT)      ) allocate(BMAT(nediis,nediis,2))
   endif

   BMAT       = 0.0d0
   ediis_fock = 0.0d0
   ediis_dens = 0.0d0
   EDIIS_E    = 0.0d0
end subroutine ediis_init

subroutine ediis_finalise()
   use converger_data, only: ediis_fock, ediis_dens, BMAT, EDIIS_E, &
                             conver_method
   implicit none

   if (conver_method < 6) return
   if (allocated(EDIIS_E)   ) deallocate(EDIIS_E)
   if (allocated(ediis_fock)) deallocate(ediis_fock)
   if (allocated(ediis_dens)) deallocate(ediis_dens)
   if (allocated(BMAT)      ) deallocate(BMAT)

end subroutine ediis_finalise

subroutine ediis_update_energy_fock_rho(fock_op, dens_op, position, spin, &
                                        niter)
   use converger_data  , only: ediis_fock, ediis_dens, nediis
   use typedef_operator, only: operator
   
   integer       , intent(in) :: position, spin, niter
   
   type(operator), intent(in) :: fock_op, dens_op
   integer :: ii

   if (niter > nediis) then
      do ii = 1, nediis-1
         ediis_fock(:,:,ii,spin) = ediis_fock(:,:,ii+1,spin)
         ediis_dens(:,:,ii,spin) = ediis_dens(:,:,ii+1,spin)
      enddo
   endif

   call fock_op%Gets_data_ON(ediis_fock(:,:,position,spin))
   call dens_op%Gets_data_ON(ediis_dens(:,:,position,spin))
endsubroutine ediis_update_energy_fock_rho

subroutine ediis_update_bmat(BMAT_aux, energy, position, niter, M_in, spin)
   use converger_data  , only: nediis, ediis_fock, ediis_dens, BMAT, EDIIS_E, &
                               EDIIS_not_ADIIS
   use typedef_operator, only: operator

   implicit none
   real(kind=8), intent(in)    :: energy
   integer     , intent(in)    :: niter, position, spin, M_in
   real(kind=8), intent(inout) :: BMAT_aux(:,:)

   integer                   :: ii, jj
   real(kind=8)              :: trace, trace2, trace3, trace4
   BMAT_aux = 0.0D0

   if (EDIIS_not_ADIIS) then
      ! Calculates EDIIS components.

      ! Updating BMAT
      if (niter > nediis) then
         do jj = 1, position-1
            EDIIS_E(jj) = EDIIS_E(jj+1)
            do ii = 1, position-1
               BMAT_aux(ii,jj) = BMAT(ii+1,jj+1,spin)
            enddo
         enddo
      else if (niter > 1) then
         do jj = 1, position-1
         do ii = 1, position-1
            BMAT_aux(ii,jj) = BMAT(ii,jj,spin)
         enddo
         enddo
      endif

      jj          = position
      EDIIS_E(jj) = energy
      do ii = 1, position-1
         call matmul_trace(ediis_dens(:,:,ii,spin) - ediis_dens(:,:,jj,spin), &
                           ediis_fock(:,:,ii,spin) - ediis_fock(:,:,jj,spin), &
                           M_in, trace)

         BMAT_aux(ii,jj) = trace
         BMAT_aux(jj,ii) = trace
      enddo   
   else
      ! Calculates ADIIS components.
      EDIIS_E  = 0.0D0
      jj       = position
      do ii = 1, position-1
         call matmul_trace(ediis_dens(:,:,ii,spin), ediis_fock(:,:,jj,spin), &
                           M_in, trace)
         call matmul_trace(ediis_dens(:,:,jj,spin), ediis_fock(:,:,jj,spin), &
                           M_in, trace2)
         EDIIS_E(ii) = trace2 - trace
         do jj = 1, position-1
            call matmul_trace(ediis_dens(:,:,ii,spin), ediis_fock(:,:,jj,spin), &
                              M_in, trace3)
            call matmul_trace(ediis_dens(:,:,jj,spin), ediis_fock(:,:,jj,spin), &
                              M_in, trace4)
            BMAT_aux(ii,jj) = trace3 - trace4 - trace + trace2
         enddo
      enddo
   endif

   BMAT(1:position,1:position,spin) = BMAT_aux(1:position,1:position)
end subroutine ediis_update_bmat

subroutine ediis_get_new_fock(fock, BMAT_aux, position, spin)
   use converger_data, only: EDIIS_E, ediis_fock

   implicit none
   integer     , intent(in)  :: position, spin
   real(kind=8), intent(in)  :: BMAT_aux(:,:)
   real(kind=8), intent(out) :: fock(:,:)

   integer :: ii
   real(kind=8), allocatable :: EDIIS_coef(:)


   allocate(EDIIS_coef(position))
   do ii = 1, position
      EDIIS_coef(ii) = EDIIS_E(ii)
   enddo

   ! Solving linear equation and getting new Fock matrix:
   fock = 0.0D0
   call get_coefs_dfp(EDIIS_coef, EDIIS_E, BMAT_aux, position)
   do ii = 1, position
      fock(:,:) = fock(:,:) + EDIIS_coef(ii) * ediis_fock(:,:,ii,spin)
   enddo

   deallocate(EDIIS_coef)
end subroutine ediis_get_new_fock

subroutine matmul_trace(mat1,mat2, M_in, trace)
   implicit none
   integer     , intent(in)  :: M_in
   real(kind=8), intent(in)  :: mat1(M_in,M_in), mat2(M_in, M_in)
   real(kind=8), intent(out) :: trace
   integer      :: ii, jj
   real(kind=8) :: mat3(M_in)

   mat3  = 0.0d0
   trace = 0.0d0

   do ii=1, M_in
   do jj=1, M_in
      mat3(ii) = mat1(ii,jj) * mat2(jj,ii) + mat3(ii)
   enddo
   enddo

   do ii=1, M_in
      trace = trace + mat3(ii)
   enddo
end subroutine matmul_trace


subroutine get_coefs_dfp(coef, Ener, BMAT, ndim)
   implicit none
   integer     , intent(in)    :: ndim
   real(kind=8), intent(in)    :: Ener(ndim), BMAT(ndim,ndim)
   real(kind=8), intent(inout) :: coef(ndim)


   integer      :: n_iter, icount, jcount
   real(kind=8) :: funct_val, sum_p, step_max, temp_val, funct_ls, check_val, &
                   fac, fae, fad, sumdg, sumxi
   real(kind=8), allocatable :: hessian_inv(:,:), grad(:), coef_new(:), &
                                dgrad(:), hdgrad(:), xi(:)
     
   allocate(hessian_inv(ndim, ndim), xi(ndim), grad(ndim), coef_new(ndim), &
            dgrad(ndim), hdgrad(ndim))

   ! Initial guess
   coef = 0.0d0
   jcount = 1
   do icount = 2, ndim
      sumdg = Ener(icount) - BMAT(icount,icount)
      sumxi = Ener(jcount) - BMAT(jcount,jcount)
      if (sumdg < sumxi) jcount = icount
   enddo
   coef(jcount) = 0.9D0
   do icount = 1, jcount-1
      coef(icount) = (1.0D0 - coef(jcount)) / (ndim - 1)
   enddo
   do icount = jcount+1, ndim
      coef(icount) = (1.0D0 - coef(jcount)) / (ndim - 1)
   enddo
   coef = coef / sum(coef)
   
   call f_coef(Ener, BMAT, coef, funct_val, ndim)
   call gradient(coef, grad, Ener, BMAT, ndim)

   hessian_inv = 0.0D0
   xi = -grad
   sum_p = 0.0D0
   do icount = 1, ndim
      hessian_inv(icount,icount) = 1.0D0
      sum_p = sum_p + coef(icount) * coef(icount)
   enddo

   step_max = 100.0D0 * max(sqrt(sum_p), dble(ndim))
   do n_iter = 1, 500
      call line_search(ndim, coef, funct_val, grad, xi, coef_new, funct_ls, &
                      step_max, Ener, BMAT)

      ! Updates coefficients
      xi   = coef_new - coef
      coef = coef_new

      ! Checks convergence in coefficients.
      check_val = 0.0D0
      do icount = 1, ndim
         temp_val = abs(xi(icount)) / max(abs(coef(icount)), 1.0D0)
         if (check_val < temp_val) check_val = temp_val
      enddo
      if (check_val > 1.0D-7) exit
      
      dgrad = grad
      call gradient(coef, grad, Ener, BMAT, ndim)

      ! Checks convergence in gradient.
      check_val = 0.0D0
      do icount = 1, ndim
         temp_val = abs(grad(icount)) * max(abs(coef(icount)), 1.0D0) &
                    / max(abs(funct_ls), 1.0D0)
         if (check_val < temp_val) check_val = temp_val
      enddo
      if (check_val > 1.0D-7) exit

      dgrad  = grad - dgrad
      hdgrad = 0.0D0
      do icount = 1, ndim
      do jcount = 1, ndim
         hdgrad(icount) = hdgrad(icount) + hessian_inv(icount, jcount) &
                                         * dgrad(jcount)
      enddo
      enddo

      fac   = 0.0D0
      fae   = 0.0D0
      sumdg = 0.0D0
      sumxi = 0.0D0
      do icount = 1, ndim
         fac   = fac + dgrad(icount) * xi(icount)
         fae   = fae + dgrad(icount) * hdgrad(icount)
         sumdg = sumdg + dgrad(icount) * dgrad(icount)
         sumxi = sumxi + xi(icount)    * xi(icount)
      enddo

      ! Skips update if fac is not big enough
      if ((fac*fac) > (1D-7 * sumdg * sumxi)) then
         fac = 1.0D0 / fac
         fad = 1.0D0 / fae
         dgrad = fac * xi - fad * hdgrad
         
         do icount = 1, ndim
         do jcount = 1, ndim
            hessian_inv(icount,jcount) = hessian_inv(icount,jcount)            &
                                       + fac * xi(icount)     * xi(jcount)     &
                                       - fad * hdgrad(icount) * hdgrad(jcount) &
                                       + fae * dgrad(icount)  * dgrad(jcount)

         enddo
         enddo
      endif

      xi = 0.0D0
      do icount = 1, ndim
      do jcount = 1, ndim
         xi(icount) = xi(icount) - hessian_inv(icount, jcount) * grad(jcount)
      enddo
      enddo
   enddo
  
   if (n_iter > 500) stop "NO CONVERGENCE IN EDIIS"

   ! Standardizes coefficients so that the comply with the constrains.
   sumdg = 0.0D0
   do icount = 1, ndim
      sumdg = sumdg + coef(icount) * coef(icount)
   enddo
   do icount = 1, ndim
      coef(icount) = coef(icount) * coef(icount) / sumdg
   enddo   

   deallocate(hessian_inv, xi, grad, coef_new, dgrad, hdgrad)
end subroutine get_coefs_dfp

! linesearch(ndim, coef, funct_val, grad, xi, coef_new, funct_ls, step_max)
subroutine line_search(ndim, x_old, f_old, grad, xi, x_new, f_new, step_max, &
                       Ener, BMAT)
   implicit none
   integer     , intent(in)    :: ndim
   real(kind=8), intent(in)    :: x_old(ndim), grad(ndim), f_old, step_max, &
                                  Ener(ndim), BMAT(ndim, ndim)
   real(kind=8), intent(out)   :: x_new(ndim), f_new
   real(kind=8), intent(inout) :: xi(ndim)

   integer      :: icount
   logical      :: first_step
   real(kind=8) :: sum_x, slope, lambda_min, temp, lambda, lambda2, f_new2, &
                   f_old2, lambda_temp, rhs1, rhs2, temp2


   sum_x = 0.0D0
   do icount = 1, ndim
      sum_x = sum_x + xi(icount) * xi(icount)
   enddo
   sum_x = sqrt(sum_x)
   if (sum_x > step_max) xi = xi * step_max / sum_x

   slope = 0.0D0
   do icount = 1, ndim
      slope = slope + grad(icount) * xi(icount)
   enddo

   lambda_min = 0.0D0
   do icount = 1, ndim
      temp = abs(xi(icount)) / max(abs(x_old(icount)), 1.0D0)
      if (temp > lambda_min) lambda_min = temp
   enddo
   lambda_min = 1.0D-7 / lambda_min

   lambda  = 1.0D0
   lambda2 = 0.0D0
   f_new2  = 0.0D0
   f_old2  = 0.0D0
   first_step = .true.
   do
      x_new = x_old + lambda * xi
      call f_coef(Ener, BMAT, x_new, f_new, ndim)

      if (lambda < lambda_min) then
         ! Exits cycle if step is too small.
         x_new = x_old
         exit
      else if (f_new < (f_old + 1.0D-4 * lambda * slope)) then
         ! Exits cycle if function f is decreased sufficiently.
         exit
      else
         ! Runs normally
         if (first_step) then
            ! First step of the cycle
            lambda_temp = - slope / (2.0D0 * (f_new - f_old - slope))
            first_step = .false.
         else
            rhs1 = f_new  - f_old  - lambda  * slope
            rhs2 = f_new2 - f_old2 - lambda2 * slope

            temp  = (rhs1 / (lambda * lambda) - rhs2 / (lambda2 * lambda2)) / &
                    (lambda - lambda2)
            temp2 = (- lambda2 * rhs1 / (lambda  * lambda)   &
                     + lambda  * rhs2 / (lambda2 * lambda2)) &
                     / (lambda - lambda2)
            if (abs(temp) < 1E-37) then
               lambda_temp = - slope / (2.0D0 * temp2)
            else
               lambda_temp = (-temp2 + &
                              sqrt(temp2 * temp2 - 3.0D0 * temp * slope)) &
                              / (3.0D0 * temp)
            endif
            if (lambda_temp > 0.5D0 * lambda) lambda_temp = 0.5D0 * lambda
         endif
      endif

      lambda2 = lambda
      f_new2  = f_new
      f_old2  = f_old
      lambda  = max(lambda_temp, 0.1D0 * lambda)
   enddo
end subroutine line_search

subroutine gradient(coef, grad, Ener, BMAT ,ndim)
   use converger_data, only: EDIIS_not_ADIIS

   implicit none
   integer     , intent(in)  :: ndim
   real(kind=8), intent(in)  :: coef(ndim), Ener(ndim), BMAT(ndim,ndim)
   real(kind=8), intent(out) :: grad(ndim)
   integer :: ii, jj

   grad = 0.0d0
   if (EDIIS_not_ADIIS) then
      do ii = 1, ndim
         do jj = 1, ndim
            grad(ii) = grad(ii) - BMAT(ii,jj) * coef(jj) * 2.0D0
         enddo
         grad(ii) = grad(ii) + Ener(ii)
      enddo
   else
      do ii = 1, ndim
         do jj = 1, ndim
            grad(ii) = grad(ii) + BMAT(ii,jj) * coef(jj)
         enddo
         grad(ii) = grad(ii) + Ener(ii)
      enddo
   endif

end subroutine gradient

subroutine f_coef(Ener, BMAT, coef, result, ndim)
   use converger_data, only: EDIIS_not_ADIIS

   implicit none
   integer     , intent(in)  :: ndim
   real(kind=8), intent(in)  :: Ener(ndim), BMAT(ndim,ndim), coef(ndim)
   real(kind=8), intent(out) :: result
   integer      :: ii, jj
   real(kind=8) :: sum1, sum2

   sum1   = 0.0d0
   sum2   = 0.0d0
   result = 0.0d0

   do ii = 1, ndim
      sum1 = sum1 + Ener(ii) * coef(ii)
   enddo

   do jj = 1, ndim
   do ii = 1, ndim
      sum2 = sum2 + BMAT(ii,jj) * coef(ii) * coef(jj)
   enddo
   enddo

   if (EDIIS_not_ADIIS) then
      result = sum1 - sum2
   else
      result = 2.0D0 * sum1 + sum2
   endif
end subroutine