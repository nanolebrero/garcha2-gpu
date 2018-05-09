!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!%  LIONML_SUBS.F90  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! This file contains procedures to handle both lio and lionml namelists. It    !
! includes the following subroutines:                                          !
! * lionml_read: Reads both lio and lionml namelists from input file.          !
! * lionml_write: Prints both lio and lionml namelists to standard output.     !
! * lionml_check: Performs consistency checks on the namelist keywords. (TO-DO)!
!                                                                              !
! In addition, the following subroutines are meant only accessed internally:   !
! * lionml_write_dull: Prints namelists in a straightforward manner.           !
! * lionml_write_style: Prints namelists in a fancy manner.                    !
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
module lionml_subs
   implicit none
contains

!  The parameters are self explanatory: file_unit is the unit of an already
!  opened file, and return stat is a status that lets the caller know wether
!  the namelist was correctly read/written/checked or if there was a problem
!  during these processes. For sake of simplification, the opening and closing
!  of input/output files must be handled externally.
!  TODO: Implement a (simple) logger and use it for the error messages.
subroutine lionml_check(extern_stat)
   implicit none
   integer, intent(out), optional :: extern_stat
   integer                        :: intern_stat

   intern_stat = 0
   if ( present(extern_stat) ) extern_stat = 0
   return
end subroutine lionml_check

subroutine lionml_read(file_unit, extern_stat )

   use lionml_data, only: lionml, lio
   use fileio_data, only: verbose
   implicit none
   integer, intent(in)            :: file_unit
   integer, intent(out), optional :: extern_stat
   integer                        :: intern_stat

   ! Old lio namelist.
   intern_stat = 0
   rewind( unit = file_unit, iostat = intern_stat )
   if ( intern_stat /= 0 ) then
      write(*,'(A)') &
         "Cannot rewind LIO input file. Using defaults for namelist lio."
      if (verbose .gt. 3) write(*,'(A,I4)') "iostat = ", intern_stat
      if ( present(extern_stat) ) extern_stat = 1
      return
   end if

   intern_stat = 0
   read( unit = file_unit, nml = lio, iostat = intern_stat )
   if ( intern_stat /= 0 ) then
      write(*,'(A)') &
         "Cannot find lio namelist. Using defaults for namelist lio."
      if (verbose .gt. 3) write(*,'(A,I4)') "iostat = ", intern_stat
      if ( present(extern_stat) ) extern_stat = 2
      return
   end if

   ! New lionml namelist.
   intern_stat = 0
   rewind( unit = file_unit, iostat = intern_stat )
   if ( intern_stat /= 0 ) then
      write(*,'(A)') &
         "Cannot rewind LIO input file. Using defaults for namelist lionml."
      if (verbose .gt. 3) write(*,'(A,I4)') "iostat = ", intern_stat
      if ( present(extern_stat) ) extern_stat = 1
      return
   end if

   intern_stat = 0
   read( unit = file_unit, nml = lionml, iostat = intern_stat )
   if ( intern_stat /= 0 ) then
      write(*,'(A)') &
         "Cannot find lionml namelist. Using defaults for namelist lionml."
      if (verbose .gt. 3) write(*,'(A,I4)') "iostat = ", intern_stat
      if ( present(extern_stat) ) extern_stat = 2
      return
   end if

   if ( present(extern_stat) ) extern_stat = 0
   return
end subroutine lionml_read


subroutine lionml_write(extern_stat)
   use fileio_data, only: get_style
   implicit none
   integer, intent(out), optional :: extern_stat
   logical                        :: my_style

   call get_style(my_style)
   if (my_style) then
      call lionml_write_style()
   else
      call lionml_write_dull()
   endif

   return
end subroutine lionml_write

subroutine lionml_write_dull()
   use lionml_data, only: lio_input_data, get_namelist
   type(lio_input_data) :: inputs

   call get_namelist(inputs)

   return
end subroutine lionml_write_dull


subroutine lionml_write_style()
   use lionml_data, only: lio_input_data, get_namelist
   type(lio_input_data) :: inputs

   call get_namelist(inputs)
   if (inputs%verbose .lt. 4) return

   ! LIO Header
   write(*,8000); write(*,8100); write(*,8001)

   ! General options and theory level
   write(*,8000); write(*,8101); write(*,8002)
   write(*,8200) inputs%natom         ; write(*,8201) inputs%nsol
   write(*,8202) inputs%charge        ; write(*,8203) inputs%Nunp
   write(*,8204) inputs%open          ; write(*,8205) inputs%nmax
   write(*,8206) inputs%int_basis     ; write(*,8207) inputs%basis_set
   write(*,8208) inputs%fitting_set   ; write(*,8209) inputs%diis
   write(*,8210) inputs%ndiis         ; write(*,8211) inputs%gold
   write(*,8212) inputs%told          ; write(*,8213) inputs%Etold
   write(*,8214) inputs%hybrid_converg; write(*,8215) inputs%good_cut
   write(*,8216) inputs%Rmax          ; write(*,8217) inputs%RmaxS
   write(*,8218) inputs%Iexch         ; write(*,8219) inputs%Igrid
   write(*,8220) inputs%Igrid2        ; write(*,8221) inputs%PredCoef
   write(*,8222) inputs%initial_guess ; write(*,8223) inputs%dbug
   write(*,8003)

   ! File IO and Property calculations
   write(*,8000); write(*,8102); write(*,8002)
   write(*,8250) inputs%verbose     ; write(*,8251) inputs%style
   write(*,8252) inputs%timers      ; write(*,8253) inputs%writexyz
   write(*,8254) inputs%WriteForces ; write(*,8255) inputs%dipole
   write(*,8256) inputs%mulliken    ; write(*,8257) inputs%lowdin
   write(*,8258) inputs%fukui       ; write(*,8259) inputs%print_coeffs
   write(*,8260) inputs%restart_freq; write(*,8261) inputs%frestart
   write(*,8262) inputs%writedens   ; write(*,8263) inputs%td_rst_freq
   write(*,8264) inputs%vcinp       ; write(*,8265) inputs%Frestartin
   write(*,8266) inputs%Tdrestart   ; write(*,8267) inputs%gaussian_convert
   write(*,8003)

   ! TD-DFT and Fields
   write(*,8000); write(*,8103); write(*,8002)
   write(*,8300) inputs%timedep      ; write(*,8301) inputs%ntdstep
   write(*,8302) inputs%tdstep       ; write(*,8304) inputs%propagator
   write(*,8303) inputs%NBCH         ; write(*,8305) inputs%field
   write(*,8306) inputs%a0           ; write(*,8307) inputs%epsilon
   write(*,8308) inputs%Fx           ; write(*,8309) inputs%Fy
   write(*,8310) inputs%Fz           ; write(*,8311) inputs%nfields_iso
   write(*,8312) inputs%nfields_aniso; write(*,8313) inputs%field_iso_file
   write(*,8314) inputs%field_aniso_file
   write(*,8003)

   ! Effective Core Potential
   write(*,8000); write(*,8104); write(*,8002)
   write(*,8350) inputs%Ecpmode       ; write(*,8351) inputs%Ecptypes
   write(*,8352) inputs%TipeECP
   call write_Zlist_ECP(inputs%ZlistECP, inputs%Ecptypes)
   write(*,8354) inputs%Fock_ECP_read ; write(*,8355) inputs%Fock_ECP_write
   write(*,8356) inputs%cutECP        ; write(*,8357) inputs%cut2_0
   write(*,8358) inputs%cut3_0        ; write(*,8359) inputs%Verbose_ECP
   write(*,8360) inputs%ECP_debug     ; write(*,8361) inputs%fulltimer_ECP
   write(*,8362) inputs%local_nonlocal; write(*,8363) inputs%ECP_full_range_int
   write(*,8003)

   ! Minimization and restraints
   write(*,8000); write(*,8105); write(*,8002)
   write(*,8370) inputs%steep       ; write(*,8371) inputs%minimzation_steep
   write(*,8372) inputs%Energy_cut  ; write(*,8373) inputs%Force_cut
   write(*,8374) inputs%n_min_steeps; write(*,8375) inputs%lineal_search
   write(*,8376) inputs%n_points    ; write(*,8377) inputs%number_restr
   write(*,8003)

   ! CUBEGEN
   write(*,8000); write(*,8106); write(*,8002)
   write(*,8400) inputs%Cubegen_only ; write(*,8401) inputs%Cube_Res
   write(*,8402) inputs%Cube_Dens    ; write(*,8403) inputs%Cube_Dens_file
   write(*,8404) inputs%Cube_Orb     ; write(*,8405) inputs%Cube_Sel
   write(*,8406) inputs%Cube_Orb_File; write(*,8407) inputs%Cube_Elec
   write(*,8408) inputs%Cube_Elec_File
   write(*,8003)

   ! GPU Options
   write(*,8000); write(*,8107); write(*,8002)
   write(*,8420) inputs%assign_all_functions
   write(*,8421) inputs%energy_all_iterations
   write(*,8422) inputs%remove_zero_weights
   write(*,8423) inputs%max_function_exponent
   write(*,8424) inputs%min_points_per_cube
   write(*,8425) inputs%little_cube_size
   write(*,8426) inputs%free_global_memory
   write(*,8427) inputs%sphere_radius
   write(*,8003)

   ! Transport and DFTB
   write(*,8000); write(*,8108); write(*,8002)
   write(*,8450) inputs%transport_calc; write(*,8451) inputs%generate_rho0
   write(*,8452) inputs%driving_rate  ; write(*,8453) inputs%gate_field
   write(*,8454) inputs%pop_drive     ; write(*,8455) inputs%save_charge_freq
   write(*,8456) inputs%dftb_calc     ; write(*,8457) inputs%MTB
   write(*,8458) inputs%alfaTB        ; write(*,8459) inputs%betaTB
   write(*,8460) inputs%gammaTB       ; write(*,8461) inputs%Vbias_TB
   write(*,8462) inputs%start_tdtb    ; write(*,8463) inputs%end_tdtb
   write(*,8464) inputs%end_bTB       ; write(*,8465) inputs%TBload
   write(*,8466) inputs%TBsave
   write(*,8003)

   ! Ehrenfest
   write(*,8000); write(*,8109); write(*,8002)
   write(*,8500) inputs%ndyn_steps    ; write(*,8501) inputs%edyn_steps
   write(*,8502) inputs%nullify_forces; write(*,8503) inputs%wdip_nfreq
   write(*,8504) inputs%wdip_fname    ; write(*,8505) inputs%rsti_loads
   write(*,8506) inputs%rsto_saves    ; write(*,8507) inputs%rsto_nfreq
   write(*,8508) inputs%rsti_fname    ; write(*,8509) inputs%rsto_fname
   write(*,8510) inputs%eefld_on      ; write(*,8511) inputs%eefld_ampx
   write(*,8512) inputs%eefld_ampy    ; write(*,8513) inputs%eefld_ampz
   write(*,8514) inputs%eefld_timeamp ; write(*,8516) inputs%eefld_timepos
   write(*,8515) inputs%eefld_timegfh ; write(*,8517) inputs%eefld_timegih
   write(*,8518) inputs%eefld_wavelen
   write(*,8003)

   ! Fock Bias Potentials
   write(*,8000); write(*,8110); write(*,8002)
   write(*,8550) inputs%fockbias_is_active
   write(*,8551) inputs%fockbias_is_shaped
   write(*,8552) inputs%fockbias_timeamp0
   write(*,8553) inputs%fockbias_timegrow
   write(*,8554) inputs%fockbias_timefall
   write(*,8555) inputs%fockbias_readfile
   write(*,8003)

8000 FORMAT(4x,"╔═════════════════════════════════", &
"═════════════════╗")
8001 FORMAT(4x,"╚═════════════════════════════════", &
"═════════════════╝")
8002 FORMAT(4x,"╠══════════════════════╦══════════", &
"═════════════════╣")
8003 FORMAT(4x,"╚══════════════════════╩══════════", &
"═════════════════╝")
8100 FORMAT(4x,"║                     LIO Input                    ║")
8101 FORMAT(4x,"║             General and Theory Level             ║")
8102 FORMAT(4x,"║             Input and Output Control             ║")
8103 FORMAT(4x,"║            RT-TDDFT and Field Options            ║")
8104 FORMAT(4x,"║             Effective Core Potential             ║")
8105 FORMAT(4x,"║            Minimization and Restraints           ║")
8106 FORMAT(4x,"║                     CubeGen                      ║")
8107 FORMAT(4x,"║                   GPU Options                    ║")
8108 FORMAT(4x,"║                Transport and DFTB                ║")
8109 FORMAT(4x,"║                Ehrenfest Dynamics                ║")
8110 FORMAT(4x,"║               Fock Bias Potentials               ║")

!System and Theory Level
8200 FORMAT(4x,"║  Natom               ║  ",7x,i6,12x,"║")
8201 FORMAT(4x,"║  Nsol                ║  ",7x,i8,10x,"║")
8202 FORMAT(4x,"║  Charge              ║  ",9x,i5,11x,"║")
8203 FORMAT(4x,"║  Nunp                ║  ",i5,20x,"║")
8204 FORMAT(4x,"║  Open                ║  ",l,23x,"║")
8205 FORMAT(4x,"║  Nmax                ║  ",i5,20x,"║")
8206 FORMAT(4x,"║  Int_Basis           ║  ",l,23x,"║")
8207 FORMAT(4x,"║  Basis_Set           ║  ",a24," ║")
8208 FORMAT(4x,"║  Fitting_Set         ║  ",a24," ║")
8209 FORMAT(4x,"║  Diis                ║  ",l,23x,"║")
8210 FORMAT(4x,"║  Ndiis               ║  ",i3,22x,"║")
8211 FORMAT(4x,"║  Gold                ║  ",f14.8,11x,"║")
8212 FORMAT(4x,"║  Told                ║  ",f14.8,11x,"║")
8213 FORMAT(4x,"║  Etold               ║  ",f14.8,11x,"║")
8214 FORMAT(4x,"║  Hybrid_converg      ║  ",l,23x,"║")
8215 FORMAT(4x,"║  Good_cut            ║  ",f14.8,11x,"║")
8216 FORMAT(4x,"║  Rmax                ║  ",f14.8,11x,"║")
8217 FORMAT(4x,"║  RmaxS               ║  ",f14.8,11x,"║")
8218 FORMAT(4x,"║  Iexch               ║  ",i5,20x,"║")
8219 FORMAT(4x,"║  Igrid               ║  ",i3,22x,"║")
8220 FORMAT(4x,"║  Igrid2              ║  ",i3,22x,"║")
8221 FORMAT(4x,"║  PredCoef            ║  ",l,23x,"║")
8222 FORMAT(4x,"║  Initial_guess       ║  ",i5,20x,"║")
8223 FORMAT(4x,"║  Dbug                ║  ",l,23x,"║")
!IO Control
8250 FORMAT(4x,"║  Verbose             ║  ",i3,22x,"║")
8251 FORMAT(4x,"║  Style               ║  ",l,23x,"║")
8252 FORMAT(4x,"║  Timers              ║  ",i3,22x,"║")
8253 FORMAT(4x,"║  WriteXYZ            ║  ",l,23x,"║")
8254 FORMAT(4x,"║  WriteForces         ║  ",l,23x,"║")
8255 FORMAT(4x,"║  Dipole              ║  ",l,23x,"║")
8256 FORMAT(4x,"║  Mulliken            ║  ",l,23x,"║")
8257 FORMAT(4x,"║  Lowdin              ║  ",l,23x,"║")
8258 FORMAT(4x,"║  Fukui               ║  ",l,23x,"║")
8259 FORMAT(4x,"║  print_coeffs        ║  ",l,23x,"║")
8260 FORMAT(4x,"║  restart_freq        ║  ",i6,19x,"║")
8261 FORMAT(4x,"║  Frestart            ║  ",a25,"║")
8262 FORMAT(4x,"║  WriteDens           ║  ",l,23x,"║")
8263 FORMAT(4x,"║  td_rst_freq         ║  ",i6,19x,"║")
8264 FORMAT(4x,"║  VCinp               ║  ",l,23x,"║")
8265 FORMAT(4x,"║  Frestartin          ║  ",a25,"║")
8266 FORMAT(4x,"║  Tdrestart           ║  ",l,23x,"║")
8267 FORMAT(4x,"║  gaussian_convert    ║  ",l,23x,"║")
! TD and Field options
8300 FORMAT(4x,"║  Timedep             ║  ",i2,23x,"║")
8301 FORMAT(4x,"║  NTDstep             ║  ",i10,15x,"║")
8302 FORMAT(4x,"║  TDstep              ║  ",f14.8,11x,"║")
8303 FORMAT(4x,"║  Propagator          ║  ",i2,23x,"║")
8304 FORMAT(4x,"║  NBCH                ║  ",i4,21x,"║")
8305 FORMAT(4x,"║  Field               ║  ",l,23x,"║")
8306 FORMAT(4x,"║  A0                  ║  ",f14.7,11x,"║")
8307 FORMAT(4x,"║  Epsilon             ║  ",f14.7,11x,"║")
8308 FORMAT(4x,"║  Fx                  ║  ",f14.8,11x,"║")
8309 FORMAT(4x,"║  Fy                  ║  ",f14.8,11x,"║")
8310 FORMAT(4x,"║  Fz                  ║  ",f14.8,11x,"║")
8311 FORMAT(4x,"║  n_fields_iso        ║  ",i5,20x,"║")
8312 FORMAT(4x,"║  n_fields_aniso      ║  ",i5,20x,"║")
8313 FORMAT(4x,"║  field_iso_file      ║  ",a25,"║")
8314 FORMAT(4x,"║  field_aniso_file    ║  ",a25,"║")
!Effective Core Potential
8350 FORMAT(4x,"║  Ecpmode             ║  ",l,23x,"║")
8351 FORMAT(4x,"║  Ecptypes            ║  ", i3,22x,"║")
8352 FORMAT(4x,"║  TipeECP             ║  ",a25,"║")
8354 FORMAT(4x,"║  Fock_ECP_read       ║  ",l,23x,"║")
8355 FORMAT(4x,"║  Fock_ECP_write      ║  ",l,23x,"║")
8356 FORMAT(4x,"║  cutECP              ║  ",l,23x,"║")
8357 FORMAT(4x,"║  cut2_0              ║  ",f14.8,11x,"║")
8358 FORMAT(4x,"║  cut3_0              ║  ",f14.8,11x,"║")
8359 FORMAT(4x,"║  Verbose_ECP         ║  ",i2,23x,"║")
8360 FORMAT(4x,"║  ECP_debug           ║  ",l,23x,"║")
8361 FORMAT(4x,"║  fulltimer_ECP       ║  ",l,23x,"║")
8362 FORMAT(4x,"║  local_nonlocal      ║  ",i2,23x,"║")
8363 FORMAT(4x,"║  ECP_full_range_int  ║  ",l,23x,"║")
! Minimization and restraints
8370 FORMAT(4x,"║  Steep               ║  ",l,23x,"║")
8371 FORMAT(4x,"║  minimzation_steep   ║  ",f14.8,11x,"║")
8372 FORMAT(4x,"║  Energy_cut          ║  ",f14.8,11x,"║")
8373 FORMAT(4x,"║  Force_cut           ║  ",f14.8,11x,"║")
8374 FORMAT(4x,"║  n_min_steeps        ║  ",i5,20x,"║")
8375 FORMAT(4x,"║  lineal_search       ║  ",l,23x,"║")
8376 FORMAT(4x,"║  n_points            ║  ",i5,20x,"║")
8377 FORMAT(4x,"║  number_restr        ║  ",i5,20x,"║")
! Cubegen
8400 FORMAT(4x,"║  Cubegen_only        ║  ",l,23x,"║")
8401 FORMAT(4x,"║  Cube_Res            ║  ",i5,20x,"║")
8402 FORMAT(4x,"║  Cube_Dens           ║  ",l,23x,"║")
8403 FORMAT(4x,"║  Cube_Dens_file      ║  ",a25,"║")
8404 FORMAT(4x,"║  Cube_Orb            ║  ",l,23x,"║")
8405 FORMAT(4x,"║  Cube_Sel            ║  ",i5,20x,"║")
8406 FORMAT(4x,"║  Cube_Orb_File       ║  ",a25,"║")
8407 FORMAT(4x,"║  Cube_Elec           ║  ",l,23x,"║")
8408 FORMAT(4x,"║  Cube_Elec_File      ║  ",a25,"║")
! GPU options
8420 FORMAT(4x,"║  assign_all_functions║  ",l,23x,"║")
8421 FORMAT(4x,"║  energy_all_iteration║  ",l,23x,"║")
8422 FORMAT(4x,"║  remove_zero_weights ║  ",l,23x,"║")
8423 FORMAT(4x,"║  max_function_exponen║  ",i5,20x,"║")
8424 FORMAT(4x,"║  min_points_per_cube ║  ",i5,20x,"║")
8425 FORMAT(4x,"║  little_cube_size    ║  ",f14.8,11x,"║")
8426 FORMAT(4x,"║  free_global_memory  ║  ",f14.8,11x,"║")
8427 FORMAT(4x,"║  sphere_radius       ║  ",f14.8,11x,"║")
! Transport and DFTB
8450 FORMAT(4x,"║  transport_calc      ║  ",l,23x,"║")
8451 FORMAT(4x,"║  generate_rho0       ║  ",l,23x,"║")
8452 FORMAT(4x,"║  driving_rate        ║  ",f14.8,11x,"║")
8453 FORMAT(4x,"║  gate_field          ║  ",l,23x,"║")
8454 FORMAT(4x,"║  pop_drive           ║  ",i3,22x,"║")
8455 FORMAT(4x,"║  save_charge_freq    ║  ",i5,20x,"║")
8456 FORMAT(4x,"║  dftb_calc           ║  ",l,23x,"║")
8457 FORMAT(4x,"║  MTB                 ║  ",i5,20x,"║")
8458 FORMAT(4x,"║  alfaTB              ║  ",f14.8,11x,"║")
8459 FORMAT(4x,"║  betaTB              ║  ",f14.8,11x,"║")
8460 FORMAT(4x,"║  gammaTB             ║  ",f14.8,11x,"║")
8461 FORMAT(4x,"║  Vbias_TB            ║  ",f14.8,11x,"║")
8462 FORMAT(4x,"║  start_tdtb          ║  ",i5,20x,"║")
8463 FORMAT(4x,"║  end_tdtb            ║  ",i5,20x,"║")
8464 FORMAT(4x,"║  end_bTB             ║  ",i5,20x,"║")
8465 FORMAT(4x,"║  TBload              ║  ",l,23x,"║")
8466 FORMAT(4x,"║  TBsave              ║  ",l,23x,"║")
! Ehrenfest
8500 FORMAT(4x,"║  ndyn_steps          ║  ",i6,19x,"║")
8501 FORMAT(4x,"║  edyn_steps          ║  ",i6,19x,"║")
8502 FORMAT(4x,"║  nullify_forces      ║  ",l,23x,"║")
8503 FORMAT(4x,"║  wdip_nfreq          ║  ",i5,20x,"║")
8504 FORMAT(4x,"║  wdip_fname          ║  ",a25,"║")
8505 FORMAT(4x,"║  rsti_loads          ║  ",l,23x,"║")
8506 FORMAT(4x,"║  rsto_saves          ║  ",l,23x,"║")
8507 FORMAT(4x,"║  rsto_nfreq          ║  ",l,23x,"║")
8508 FORMAT(4x,"║  rsti_fname          ║  ",a25,"║")
8509 FORMAT(4x,"║  rsto_fname          ║  ",a25,"║")
8510 FORMAT(4x,"║  eefld_on            ║  ",l,23x,"║")
8511 FORMAT(4x,"║  eefld_ampx          ║  ",f14.8,11x,"║")
8512 FORMAT(4x,"║  eefld_ampy          ║  ",f14.8,11x,"║")
8513 FORMAT(4x,"║  eefld_ampz          ║  ",f14.8,11x,"║")
8514 FORMAT(4x,"║  eefld_timeamp       ║  ",f14.8,11x,"║")
8515 FORMAT(4x,"║  eefld_timepos       ║  ",f14.8,11x,"║")
8516 FORMAT(4x,"║  eefld_timegfh       ║  ",l,23x,"║")
8517 FORMAT(4x,"║  eefld_timegih       ║  ",l,23x,"║")
8518 FORMAT(4x,"║  eefld_wavelen       ║  ",f14.8,11x,"║")
! Fock Bias Potentials
8550 FORMAT(4x,"║  fockbias_is_active  ║  ",l,23x,"║")
8551 FORMAT(4x,"║  fockbias_is_shaped  ║  ",l,23x,"║")
8552 FORMAT(4x,"║  fockbias_timeamp0   ║  ",f14.8,11x,"║")
8553 FORMAT(4x,"║  fockbias_timegrow   ║  ",f14.8,11x,"║")
8554 FORMAT(4x,"║  fockbias_timefall   ║  ",f14.8,11x,"║")
8555 FORMAT(4x,"║  fockbias_readfile   ║  ",a25,"║")
end subroutine lionml_write_style

subroutine write_Zlist_ECP(ZlistECP, D)
   implicit none
   integer, intent(in) :: ZlistECP(128)
   integer, intent(in) :: D
   integer :: icount, kcount, lines, rest

   if (D .lt. 6) then
     if (D .eq. 1) write(*,8538) ZlistECP(1)
     if (D .eq. 2) write(*,8539) ZlistECP(1:2)
     if (D .eq. 3) write(*,8540) ZlistECP(1:3)
     if (D .eq. 4) write(*,8541) ZlistECP(1:4)
     if (D .eq. 5) write(*,8542) ZlistECP(1:5)
   else
      lines = D / 6
      rest  = mod(D, 6)
      write(*,8543) ZlistECP(1:6)
      do icount = 1, lines-1
         kcount = 6*icount + 1
         write(*,8544) ZlistECP(kcount:kcount+5)
      enddo
      if (rest .eq. 1) write(*,8545) ZlistECP(6*lines+1:D)
      if (rest .eq. 2) write(*,8546) ZlistECP(6*lines+1:D)
      if (rest .eq. 3) write(*,8547) ZlistECP(6*lines+1:D)
      if (rest .eq. 4) write(*,8548) ZlistECP(6*lines+1:D)
      if (rest .eq. 5) write(*,8549) ZlistECP(6*lines+1:D)
   endif

8538 FORMAT(4x,"║  Zlistecp            ║ ",i3,"                       ║")
8539 FORMAT(4x,"║  Zlistecp            ║ ",i3,i3,"                    ║")
8540 FORMAT(4x,"║  Zlistecp            ║ ",i3,i3,i3,"                 ║")
8541 FORMAT(4x,"║  Zlistecp            ║ ",i3,i3,i3,i3,"              ║")
8542 FORMAT(4x,"║  Zlistecp            ║ ",i3,i3,i3,i3,i3,"           ║")
8543 FORMAT(4x,"║  Zlistecp            ║ ",i3,i3,i3,i3,i3,i3,"        ║")
8544 FORMAT(4x,"║                      ║ ",i3,i3,i3,i3,i3,i3,"        ║")
8545 FORMAT(4x,"║                      ║ ",i3"                        ║")
8546 FORMAT(4x,"║                      ║ ",i3,i3,"                    ║")
8547 FORMAT(4x,"║                      ║ ",i3,i3,i3,"                 ║")
8548 FORMAT(4x,"║                      ║ ",i3,i3,i3,i3"               ║")
8549 FORMAT(4x,"║                      ║ ",i3,i3,i3,i3,i3"            ║")
end subroutine write_Zlist_ECP

end module
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
