################################################################################
# INTERNAL DEPENDENCIES
INCLUDES :=
INCLUDES += Sets_datamat.f90
INCLUDES += Gets_datamat.f90
INCLUDES += Diagon_datamat.f90
INCLUDES += Dens_build.f90
INCLUDES += Commut_data.f90
INCLUDES += BChange_data.f90
INCLUDES += Shift_diag.f90
INCLUDES += Idempotency_purify.f90

$(OBJPATH)/typedef_operator.o : $(INCLUDES) typedef_operator.mk
################################################################################
