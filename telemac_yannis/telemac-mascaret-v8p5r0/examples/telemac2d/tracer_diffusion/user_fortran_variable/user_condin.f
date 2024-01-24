!                   **********************
                    SUBROUTINE USER_CONDIN
!                   **********************
!
!
!***********************************************************************
! TELEMAC2D   V7P3
!***********************************************************************
!
!brief    USER INITIALISES THE PHYSICAL PARAMETERS
!
!history  J-M HERVOUET (LNHE)
!+        30/08/2007
!+        V6P0
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_TELEMAC2D
      USE TPXO
      USE OKADA
!
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
      INTEGER I
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      DO I=1,NPOIN
        VISC%R(I) = (X(I)/20.D0)*PROPNU
      ENDDO
!
!-----------------------------------------------------------------------
!
      RETURN
      END