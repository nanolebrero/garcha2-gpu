subroutine vec_init(Ene,Vec,N,vecnum,Mlr,NCO,Nvirt,Ndim)
   implicit none

   integer, intent(in) :: N, vecnum, Mlr, NCO, Nvirt, Ndim
   double precision, intent(in)  :: Ene(Mlr)
   double precision, intent(out) :: Vec(N,vecnum)

   integer :: ii, occ, virt, cont
   integer, dimension(:), allocatable :: ind
   double precision, dimension(:), allocatable :: deltaE

   allocate(deltaE(Ndim),ind(Ndim))
   
   ! Calculate delta molecular orbital energies
   cont = 1
   do ii=1,Ndim
      cont = ii - 1
      occ = NCO - (cont/Nvirt)
      virt = mod(cont,Nvirt) + NCO + 1
      deltaE(ii) = Ene(virt) - Ene(occ)
   enddo

   ! Sorting Energies
   ind = 0
   call eigsort(deltaE,ind,Ndim)

   Vec = 0.0D0
   do ii=1,vecnum
      Vec(ind(ii),ii) = 1.0D0
   enddo

   deallocate(deltaE,ind)
end subroutine vec_init

subroutine eigsort(a,b,N)

   implicit none

   integer, intent(in) :: N
   real*8, intent(in):: a(N)
   integer, intent(out) :: b(N)
   integer :: i,imin, temp_i
   real*8 :: temp_r
   real*8 :: a2(N)

   a2 = a
   do i = 1, N
      b(i) = i
   end do
   do i = 1, N-1
      imin = minloc(a2(i:),1) + i - 1
      if (imin /= i) then
         temp_r = a2(i); a2(i) = a2(imin); a2(imin) = temp_r
         temp_i = b(i) ; b(i)  = b(imin) ; b(imin)  = temp_i
      end if
   end do
end subroutine
