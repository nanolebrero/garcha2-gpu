! These routines set the values for C6 and C8 coefficients.
subroutine dftd3_set_c6c8(dists, n_atoms)
   use dftd3_data, only: c6_ab, c8_ab, c6_cn, c8_coef, r_cov
   implicit none
   integer     , intent(in) :: n_atoms
   real(kind=8), intent(in) :: dists(:,:)

   real(kind=8) :: Lij, Wsum, Zsum, cna, cnb, c6_tmp, r_min
   integer      :: iatom, jatom, cni, cnj
   ! This is the atomic coordination number.
   real(kind=8), allocatable :: atom_cn(:)

   allocate(atom_cn(n_atoms))
   call dftd3_calc_cn(atom_cn, dists, n_atoms, r_cov)

   Wsum   = 0.0D0
   Zsum   = 0.0D0
   r_min  = 1.0D99
   c6_ab  = 0.0D0
   c8_ab  = 0.0D0
   do iatom = 1      , n_atoms
   do jatom = iatom+1, n_atoms
      do cni = 1, 5
      do cnj = 1, 5
         if (c6_cn(iatom, jatom, cni, cnj, 1) > 0.0D0) then
            cna = c6_cn(iatom, jatom, cni, cnj, 2)
            cnb = c6_cn(iatom, jatom, cni, cnj, 3)

            Lij = (atom_cn(iatom) - cna) * (atom_cn(iatom) - cna) + &
                  (atom_cn(jatom) - cnb) * (atom_cn(jatom) - cnb)
            if (Lij < r_min) then
               r_min  = Lij
               c6_tmp = c6_cn(iatom, jatom, cni, cnj, 1)
            endif
            Lij = exp(-4.0D0 * Lij)

            Wsum = Wsum + Lij
            Zsum = Zsum + c6_cn(iatom, jatom, cni, cnj, 1) * Lij
         endif
      enddo
      enddo
      
      if (Wsum > 1.0D99) then
         c6_ab(iatom, jatom) = c6_tmp
      else
         c6_ab(iatom, jatom) = Zsum / Wsum
      endif
      c6_ab(jatom, iatom) = c6_ab(iatom, jatom)

      c8_ab(iatom, jatom) = 3.0D0 * c6_ab(iatom, jatom) * c8_coef(iatom) *&
                                    c8_coef(jatom)
      c8_ab(jatom, iatom) = c8_ab(iatom, jatom)
   enddo
   enddo
   
   deallocate(atom_cn)
end subroutine dftd3_set_c6c8

subroutine dftd3_calc_cn(atom_cn, dists, n_atoms, r_cov)
   implicit none
   integer     , intent(in)    :: n_atoms
   real(kind=8), intent(in)    :: dists(:,:), r_cov(:)
   real(kind=8), intent(inout) :: atom_cn(:)

   real(kind=8) :: term
   integer      :: iatom, jatom

   atom_cn = 0.0D0
   do iatom = 1, n_atoms
   do jatom = iatom+1, n_atoms
      term = (1.0D0 + exp(-16.0D0 * ((r_cov(iatom) + r_cov(jatom)) / &
                                      dists(iatom,jatom) - 1.0D0) ))
      atom_cn(iatom) = atom_cn(iatom) + 1.0D0 / term
      atom_cn(jatom) = atom_cn(jatom) + 1.0D0 / term
   enddo
   enddo
end subroutine dftd3_calc_cn